/*
 * FSEventsWrapperTests.swift
 * FSEventsWrapperTests
 *
 * Created by François Lamboley on 06/07/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import XCTest
@testable import FSEventsWrapper



class FSEventsWrapperTests: XCTestCase, FSEventStreamCallbackHandler {
	
	var callbackCount = 0
	var monitoredFolder: String!
	
	var fsChangedHandler: ((_ folder: String, _ eventId: FSEventStreamEventId, _ fromUs: Bool) -> Void)?
	
	override func setUp() {
		super.setUp()
		
		callbackCount = 0
		fsChangedHandler = nil
		
		monitoredFolder = (NSTemporaryDirectory() as NSString).appendingPathComponent("test.\(Int.random(in: 0 ... .max))")
		try! FileManager.default.createDirectory(at: URL(fileURLWithPath: monitoredFolder, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
	}
	
	override func tearDown() {
		try! FileManager.default.removeItem(atPath: monitoredFolder)
		
		super.tearDown()
	}
	
	func testBasicMonitoring() {
		let e = FSEventsWrapper(path: monitoredFolder, callbackHandler: self)
		
		fsChangedHandler = { folder, eventId, fromUs in
			e.stopWatching()
		}
		
		e.startWatching()
		
		DispatchQueue(label: "testBasicMonitoring").asyncAfter(deadline: .now() + .milliseconds(500)){
			FileManager.default.createFile(atPath: (self.monitoredFolder as NSString).appendingPathComponent("testBasicMonitoring"), contents: nil, attributes: nil)
		}
		
		let startDate = Date()
		repeat {
			RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 9))
		} while e.isStarted && -startDate.timeIntervalSinceNow < 9
		XCTAssert(!e.isStarted)
	}
	
	func fsChanged(inFolder folderPath: String, eventId: FSEventStreamEventId, becauseOfUs isEventFromUs: Bool) {
		fsChangedHandler?(folderPath, eventId, isEventFromUs)
	}
	
}
