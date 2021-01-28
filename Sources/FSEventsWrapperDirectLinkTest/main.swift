/*
 * main.swift
 * FSEventsWrapperDirectLinkTest
 *
 * Created by François Lamboley on 09/07/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import Foundation



/* This target has been created to check whether the “mark self” options would
 * work when the wrapper is linked directly and not from a Framework. Alas, it
 * does not… */


class CallbackHandler : NSObject {
	
	func fsChanged(inFolder folderPath: String, eventId: FSEventStreamEventId, becauseOfUs isEventFromUs: Bool) {
		NSLog("%@ - %@", String(isEventFromUs), folderPath)
	}
	
}


let callbackHandler = CallbackHandler()
let w = FSEventStream(path: "/Users/frizlab/Downloads", fsEventStreamFlags: FSEventStreamCreateFlags(kFSEventStreamCreateFlagMarkSelf), callbackHandler: callbackHandler)
w.startWatching()

Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false){ t in
	let f = fopen("/Users/frizlab/Downloads/FSEventsWrapperDirectLinkTest.\(Int.random(in: 0..<250)).test", "w+")
	Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false){ t in
		var i: UInt = 0
		fwrite(&i, MemoryLayout<UInt>.size, 1, f)
		fclose(f)
	}
}

repeat {
	RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
} while true
