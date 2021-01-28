/*
 * FSEventStream.swift
 * FSEventsWrapper
 *
 * Created by François Lamboley on 10/11/14.
 * Copyright (c) 2014 Frost Land. All rights reserved.
 */

import Foundation



public class FSEventStream {
	
	internal let eventStream: FSEventStreamRef
	
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
		When do we start monitoring the paths from? Allows replaying older events
		at the given paths.
		
		If `nil`, will start from now.
	
	- parameter updateInterval:
		The minimum interval of time between two calls to the callback object.
		
		If the given FSEvent flags contains the `kFSEventStreamCreateFlagNoDefer`
		flag, you'll be called directly when the first event occurs in the folders
		you watch, then no more than once per the given interval.
		
		If the flag is not present, the given delay will occur first, then your
		handler will be called.
	
	- parameter fsEventStreamFlags:
		The flags to use to create the `FSEvent` stream.
		
		**Note**: The `...UseCFTypes` flag will always be added to the flags used
		to create the stream.
	
	- parameter callbackHandler: Your handler object.
	
	- parameter runLoop:
		The run loop on which the stream should be scheduled. If nil, the stream
		will be scheduled on the **current** run loop.
	
	- parameter runLoopMode:
		The run loop mode on which the stream should be scheduled. If nil, the
		default run loop mode will be used. */
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
		
		self.runLoopMode = runLoopMode
		self.runLoop = runLoop.getCFRunLoop()
		
		guard let s = FSEventStreamCreate(
			kCFAllocatorDefault,
			eventStreamCallback,
			nil, //UnsafeMutablePointer<FSEventStreamContext>?
			cfpaths,
			actualStartId,
			updateInterval,
			actualFlags
		) else {
			return nil
		}
		self.eventStream = s
	}
	
	deinit {
		stopWatching()
		FSEventStreamUnscheduleFromRunLoop(eventStream, runLoop, runLoopMode as CFString)
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


private func eventStreamCallback(
	streamRef: ConstFSEventStreamRef,
	clientCallBackInfo: UnsafeMutableRawPointer?,
	numEvents: Int,
	eventPathsAsVoidPtr: UnsafeMutableRawPointer,
	eventFlags: UnsafePointer<FSEventStreamEventFlags>,
	eventIds: UnsafePointer<FSEventStreamEventId>
) {
	NSLog("Hello!")
}
