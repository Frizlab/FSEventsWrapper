/*
 * FSEventsWrapper.swift
 * Duplicated Sound Finder
 *
 * Created by François LAMBOLEY on 10/11/14.
 * Copyright (c) 2014 Frost Land. All rights reserved.
 */

import Foundation



class FSEventsWrapper {
	
	let eventStream: FSEventStreamRef
	
	let runLoop: CFRunLoop
	let runLoopMode: RunLoop.Mode
	
	fileprivate var isStarted = false
	fileprivate var isScheduled = false
	
	convenience init(path: String, callbackHandler: FSEventStreamCallbackHandler) {
		self.init(paths: [path], since: nil, updateInterval: 0, fsEventStreamFlags: nil, callbackHandler: callbackHandler, runLoop: nil, runLoopMode: nil)
	}
	
	convenience init(path: String, since startId: FSEventStreamEventId?, updateInterval: CFTimeInterval, callbackHandler: FSEventStreamCallbackHandler) {
		self.init(paths: [path], since: startId, updateInterval: updateInterval, fsEventStreamFlags: nil, callbackHandler: callbackHandler, runLoop: nil, runLoopMode: nil)
	}
	
	convenience init(paths: [String], since startId: FSEventStreamEventId?, updateInterval: CFTimeInterval, callbackHandler: FSEventStreamCallbackHandler) {
		self.init(paths: paths, since: startId, updateInterval: updateInterval, fsEventStreamFlags: nil, callbackHandler: callbackHandler, runLoop: nil, runLoopMode: nil)
	}
	
	/**
	- parameter paths: The paths to monitor.
	
	- parameter since?:
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
	
	- parameter runLoop?:
		The run loop on which the stream should be scheduled. If nil, the stream
		will be scheduled on the **current** run loop.
	
	- parameter runLoopMode?:
		The run loop mode on which the stream should be scheduled. If nil, the
		default run loop mode will be used.
	*/
	init(
		paths: [String],
		since startId: FSEventStreamEventId?, updateInterval: CFTimeInterval, fsEventStreamFlags flags: FSEventStreamCreateFlags?,
		callbackHandler: FSEventStreamCallbackHandler,
		runLoop rl: CFRunLoop?, runLoopMode rlm: RunLoop.Mode?
	) {
		let cfpaths: CFArray = paths as CFArray
		let actualStartId = startId ?? FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
		let actualFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | (flags != nil ? Int(flags!) : 0))
		
		runLoopMode = rlm ?? .default
		runLoop = rl ?? RunLoop.current.getCFRunLoop()
		eventStream = CCreateFSEventStream(cfpaths, actualStartId, updateInterval, actualFlags, callbackHandler)
	}
	
	deinit {
		stopWatching()
		FSEventStreamUnscheduleFromRunLoop(eventStream, runLoop, runLoopMode as CFString)
	}
	
	func startWatching() {
		if isStarted {return}
		
		if !isScheduled {FSEventStreamScheduleWithRunLoop(eventStream, runLoop, runLoopMode as CFString); isScheduled = true}
		FSEventStreamStart(eventStream)
		isStarted = true
	}
	
	func stopWatching() {
		if !isStarted {return}
		
		FSEventStreamStop(eventStream)
		isStarted = false
	}
	
	#if false
	/**
	The original function that was created to create the FSEventStream. However,
	due to multiple "unsafe" usage and workaround needed to make things work in
	Swift, the stream creation has finally been moved to an Objective-C file.
	*/
	func createStreamToWatchFolders(
		paths: [String],
		since startId: FSEventStreamEventId?,
		updateInterval: CFTimeInterval,
		fsEventStreamFlags flags: FSEventStreamCreateFlags?,
		callbackHandler: FSEventStreamCallbackHandler
	) -> FSEventStreamRef {
		let cfpaths: CFArray = paths
		let actualStartId = (startId != nil ? startId! : FSEventStreamEventId(kFSEventStreamEventIdSinceNow))
		
		/* Original version to get unsafeHandler:
		let addr = unsafeAddressOf(callbackHandler)
		let cPtr = COpaquePointer(addr)
		let unsafeHandler = UnsafeMutablePointer<Void>(cPtr) */
		let unsafeHandler = UnsafeMutablePointer<Void>(unsafeAddressOf(callbackHandler))
	
		var context = FSEventStreamContext(version: 0, info: unsafeHandler, retain: nil, release: nil, copyDescription: nil)
		return FSEventStreamCreate(
			kCFAllocatorDefault,            /* Allocator */
			CFSEventStreamCallbackFunction, /* Callback function */
			&context,                       /* Event stream context. Passed to the callback function */
			cfpaths,                        /* Monitored folders */
			actualStartId,                  /* When do we start getting events from */
			updateInterval,                 /* Delay before getting new events */
			flags                           /* Flags */
		)
	}
	#endif
	
}
