/*
 * FSEventsWrapperTests.swift
 * FSEventsWrapperTests
 *
 * Created by François Lamboley on 06/07/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import XCTest
@testable import FSEventsWrapper



class FSEventsWrapperTests: XCTestCase {
	
	var monitoredFolder: String!
	
	override func setUp() {
		super.setUp()
		
		monitoredFolder = (NSTemporaryDirectory() as NSString).appendingPathComponent("test.\(Int.random(in: 0 ... .max))")
		try! FileManager.default.createDirectory(at: URL(fileURLWithPath: monitoredFolder, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
	}
	
	override func tearDown() {
		_ = try? FileManager.default.removeItem(atPath: monitoredFolder)
		
		super.tearDown()
	}
	
	func testBasicMonitoring() {
		let handler = { (stream: FSEventStream, event: FSEvent) in
			stream.stopWatching()
			NSLog("ok")
		}
		
		guard let e = FSEventStream(path: monitoredFolder, callback: handler) else {
			XCTFail("Cannot create FSEventStream")
			return
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
	
}
