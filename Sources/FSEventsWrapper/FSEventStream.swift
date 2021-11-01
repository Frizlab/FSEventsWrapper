/*
 * FSEventStream.swift
 * FSEventsWrapper
 *
 * Created by François Lamboley on 10/11/14.
 * Copyright (c) 2014 Frost Land. All rights reserved.
 */

import CoreServices
import Foundation



public class FSEventStream {
	
	public let callback: (FSEventStream, FSEvent) -> Void
	
	internal let eventStream: FSEventStreamRef
	internal let eventStreamFlags: FSEventStreamCreateFlags
	
	public let runLoop: CFRunLoop
	public let runLoopMode: RunLoop.Mode
	
	private var isScheduled = false
	private(set) var isStarted = false
	
	public convenience init?(
		path: String,
		since startId: FSEventStreamEventId? = nil, updateInterval: CFTimeInterval = 0, fsEventStreamFlags flags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone),
		runLoop rl: RunLoop = .current, runLoopMode rlm: RunLoop.Mode = .default,
		callback: @escaping (FSEventStream, FSEvent) -> Void
	) {
		self.init(paths: [path], since: startId, updateInterval: updateInterval, fsEventStreamFlags: flags, runLoop: rl, runLoopMode: rlm, callback: callback)
	}
	
	/**
	 - parameter paths: The paths to monitor.
	 
	 - parameter startId:
	 When do we start monitoring the paths from?
	 Allows replaying older events at the given paths.
	 
	 If `nil`, will start from now.
	 
	 - parameter updateInterval:
	 The minimum interval of time between two calls to the callback object.
	 
	 If the given FSEvent flags contains the `kFSEventStreamCreateFlagNoDefer` flag,
	 you'll be called directly when the first event occurs in the folders you watch,
	 then no more than once per the given interval.
	 
	 If the flag is not present, the given delay will occur first, then your handler will be called.
	 
	 - parameter fsEventStreamFlags:
	 The flags to use to create the `FSEvent` stream.
	 
	  **Note**: The `...UseCFTypes` flag will always be added to the flags used to create the stream.
	 
	 - parameter callbackHandler: Your handler object.
	 
	 - parameter runLoop:
	 The run loop on which the stream should be scheduled.
	 If `nil`, the stream will be scheduled on the **current** run loop.
	 
	 - parameter runLoopMode:
	 The run loop mode on which the stream should be scheduled.
	 If `nil`, the default run loop mode will be used. */
	public init?(
		paths: [String],
		since startId: FSEventStreamEventId? = nil, updateInterval: CFTimeInterval = 0,
		fsEventStreamFlags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone),
		runLoop: RunLoop = .current, runLoopMode: RunLoop.Mode = .default,
		callback: @escaping (FSEventStream, FSEvent) -> Void
	) {
		let cfpaths: CFArray = paths as CFArray
		let actualStartId = startId ?? FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
		let actualFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | Int(fsEventStreamFlags))
		
		self.callback = callback
		
		self.runLoopMode = runLoopMode
		self.runLoop = runLoop.getCFRunLoop()
		
		let objcWrapper = FSEventStreamObjCWrapper()
		var context = FSEventStreamContext(
			version: 0,
			info: Unmanaged.passUnretained(objcWrapper).toOpaque(),
			retain: { ptrToRetain in
				guard let ptrToRetain = ptrToRetain else {return nil}
				let u = Unmanaged.passRetained(Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(ptrToRetain).takeUnretainedValue())
				return unsafeBitCast(u.takeUnretainedValue(), to: UnsafeRawPointer.self)
			},
			release: { ptrToRelease in
				guard let ptrToRelease = ptrToRelease else {return}
				Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(ptrToRelease).release()
			},
			copyDescription: nil /* I do not know how to trigger this block, so cannot test, so we set to nil! */
		)
		guard let s = FSEventStreamCreate(kCFAllocatorDefault, eventStreamCallback, &context, cfpaths, actualStartId, updateInterval, actualFlags) else {
			return nil
		}
		self.eventStream = s
		self.eventStreamFlags = actualFlags
		
		objcWrapper.swiftStream = self
	}
	
	deinit {
		stopWatching()
		FSEventStreamUnscheduleFromRunLoop(eventStream, runLoop, runLoopMode as CFString)
		FSEventStreamInvalidate(eventStream)
		FSEventStreamRelease(eventStream) /* I thought the release would be automatic, it seems it is not. */
	}
	
	public func startWatching() {
		if isStarted {return}
		
		if !isScheduled {FSEventStreamScheduleWithRunLoop(eventStream, runLoop, runLoopMode as CFString); isScheduled = true}
		FSEventStreamStart(eventStream)
		isStarted = true
	}
	
	public func stopWatching() {
		if !isStarted {return}
		
		FSEventStreamStop(eventStream)
		isStarted = false
	}
	
}


private class FSEventStreamObjCWrapper : NSObject {
	
	weak var swiftStream: FSEventStream?
	
}


private func eventStreamCallback(
	streamRef: ConstFSEventStreamRef,
	clientCallBackInfo: UnsafeMutableRawPointer?,
	numEvents: Int,
	eventPathsAsVoidPtr: UnsafeMutableRawPointer,
	eventFlags: UnsafePointer<FSEventStreamEventFlags>,
	eventIds: UnsafePointer<FSEventStreamEventId>
) {
	guard let clientCallBackInfo = clientCallBackInfo,
			let swiftStream = Unmanaged<FSEventStreamObjCWrapper>.fromOpaque(clientCallBackInfo).takeUnretainedValue().swiftStream
	else {
		return
	}
	guard let eventPaths = unsafeBitCast(eventPathsAsVoidPtr, to: CFArray.self) as? [String] else {
		NSLog("***** ERROR: Expected eventPathsAsVoidPtr to be a CFArray of CFStrings, got something I did not recognised.")
		return
	}
	
//	NSLog("New event loop:");
	for i in 0..<numEvents {
		let currentEventPath = eventPaths[i]
		let currentEventId = eventIds.advanced(by: i).pointee
		var currentEventFlags = eventFlags.advanced(by: i).pointee
//		NSLog("   Event id: %llu, Event flags: 0x%x, Event path: %@", currentEventId, currentEventFlags, currentEventPath);
		
		let fromUs = (
			(swiftStream.eventStreamFlags & FSEventStreamCreateFlags(kFSEventStreamCreateFlagMarkSelf)) != 0 ?
				(currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagOwnEvent)) != 0 :
				nil
		)
		currentEventFlags = (currentEventFlags & ~FSEventStreamEventFlags(kFSEventStreamEventFlagOwnEvent))
		
		if currentEventFlags == kFSEventStreamEventFlagNone {
			swiftStream.callback(swiftStream, .generic(path: currentEventPath, eventId: currentEventId, fromUs: fromUs))
		} else {
			let itemType: FSEvent.ItemType
			let itemTypeFlags = (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile|kFSEventStreamEventFlagItemIsDir|kFSEventStreamEventFlagItemIsSymlink|kFSEventStreamEventFlagItemIsHardlink|kFSEventStreamEventFlagItemIsLastHardlink))
			switch itemTypeFlags {
				case FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile):         itemType = .file
				case FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir):          itemType = .dir
				case FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsSymlink):      itemType = .symlink
				case FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsHardlink):     itemType = .hardlink
				case FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsLastHardlink): itemType = .lastHardlink
				default:                                                                 itemType = .unknown
			}
			
			var calledCallbackAtLeastOnce = false
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) != 0 {
				let reason: FSEvent.MustScanSubDirsReason
				let userDropped   = (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagUserDropped))   != 0
				let kernelDropped = (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagKernelDropped)) != 0
				if       userDropped && !kernelDropped {reason = .userDropped}
				else if !userDropped &&  kernelDropped {reason = .kernelDropped}
				else                                   {reason = .unknown}
				swiftStream.callback(swiftStream, .mustScanSubDirs(path: currentEventPath, reason: reason))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagEventIdsWrapped)) != 0 {
				swiftStream.callback(swiftStream, .eventIdsWrapped)
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone)) != 0 {
				swiftStream.callback(swiftStream, .streamHistoryDone)
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged)) != 0 {
				swiftStream.callback(swiftStream, .rootChanged(path: currentEventPath, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagMount)) != 0 {
				swiftStream.callback(swiftStream, .volumeMounted(path: currentEventPath, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagUnmount)) != 0 {
				swiftStream.callback(swiftStream, .volumeUnmounted(path: currentEventPath, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) != 0 {
				swiftStream.callback(swiftStream, .itemCreated(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0 {
				swiftStream.callback(swiftStream, .itemRemoved(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemInodeMetaMod)) != 0 {
				swiftStream.callback(swiftStream, .itemInodeMetadataModified(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0 {
				swiftStream.callback(swiftStream, .itemRenamed(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) != 0 {
				swiftStream.callback(swiftStream, .itemDataModified(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemFinderInfoMod)) != 0 {
				swiftStream.callback(swiftStream, .itemFinderInfoModified(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemChangeOwner)) != 0 {
				swiftStream.callback(swiftStream, .itemOwnershipModified(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod)) != 0 {
				swiftStream.callback(swiftStream, .itemXattrModified(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
				calledCallbackAtLeastOnce = true
			}
			if #available(macOS 10.13, *) {
				if (currentEventFlags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCloned)) != 0 {
					swiftStream.callback(swiftStream, .itemClonedAtPath(path: currentEventPath, itemType: itemType, eventId: currentEventId, fromUs: fromUs))
					calledCallbackAtLeastOnce = true
				}
			}
			if !calledCallbackAtLeastOnce {
				NSLog("*** WARNING: Got unknown event %u for path %@", currentEventFlags, currentEventPath)
				swiftStream.callback(swiftStream, .generic(path: currentEventPath, eventId: currentEventId, fromUs: fromUs))
			}
		}
	}
}
