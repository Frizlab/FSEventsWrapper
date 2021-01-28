#!/usr/bin/swift sh

import Foundation

import SwiftShell // @kareman ~> 5.1.0


/* swift-sh creates a binary whose path is not one we expect, so we cannot use
 * main.path directly.
 * Using the _ env variable is **extremely** hacky, but seems to do the job…
 * See https://github.com/mxcl/swift-sh/issues/101 */
let filepath = ProcessInfo.processInfo.environment["_"] ?? main.path
main.currentdirectory = URL(fileURLWithPath: filepath).deletingLastPathComponent().appendingPathComponent("..").path



do {
	guard main.arguments.count <= 1 else {
		exit(errormessage: "usage: \(filepath) [version]\n\nIf version is set, the generated Package.swift file will contain the path to the GitHub release. Should be used by CI pipelines only.")
	}
	
	let version = main.arguments.first
	
	let buildFolderURL = URL(fileURLWithPath: "./build", isDirectory: true)
	let archivesFolderURL = buildFolderURL.appendingPathComponent("archives")
	let types = [
		(name: "static",  xcframeworkArgs: { (_ archiveURL: URL) -> [String] in [
			"-library", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("usr").appendingPathComponent("local").appendingPathComponent("lib").appendingPathComponent("libFSEventsWrapper.a").absoluteURL.path)",
			"-headers", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("usr").appendingPathComponent("local").appendingPathComponent("include").absoluteURL.path)"
		] }),
		
		(name: "dynamic", xcframeworkArgs: { (_ archiveURL: URL) -> [String] in [
			"-framework", "\(archiveURL.appendingPathComponent("Products").appendingPathComponent("Library").appendingPathComponent("Frameworks").appendingPathComponent("FSEventsWrapper.framework").absoluteURL.path)",
			"-debug-symbols", "\(archiveURL.appendingPathComponent("dSYMs").appendingPathComponent("FSEventsWrapper.framework.dSYM").absoluteURL.path)"
		] })
	]
	
	/* Hints:
	 *    - https://mokacoding.com/blog/xcodebuild-destination-options/
	 *    - xcodebuild -scheme FSEventsWrapper-dynamic-macOS -showdestinations */
	let targets = [
		(sdk: "macOS", platform: "macOS"),
	]
	
	try writePackageFile(version: version, checksums: Dictionary(uniqueKeysWithValues: types.map{ ($0.name, nil) }))
	
	var checksums = [String: String]()
	for type in types {
		var xcframeworkArgs = ["-create-xcframework"]
		for target in targets {
			let archiveURL = archivesFolderURL.appendingPathComponent("FSEventsWrapper-\(type.name)-\(target.sdk)-\(target.platform).xcarchive")
			try runAndPrint(
				"xcodebuild", "archive",
				"-project", "FSEventsWrapper.xcodeproj",
				"-scheme", "FSEventsWrapper-\(type.name)",
				"-destination", "generic/platform=\(target.platform)",
				"-archivePath", "\(archiveURL.absoluteURL.path)",
				"SKIP_INSTALL=NO", "BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
			)
			xcframeworkArgs.append(contentsOf: type.xcframeworkArgs(archiveURL))
		}
		
		let xcframeworkURL = buildFolderURL.appendingPathComponent("FSEventsWrapper-\(type.name).xcframework")
		let zipXCFrameworkURL = xcframeworkURL.appendingPathExtension("zip")
		xcframeworkArgs.append(contentsOf: ["-output", xcframeworkURL.absoluteURL.path])
		try runAndPrint("xcodebuild", xcframeworkArgs)
		
		if let version = version {
			var zipContext = CustomContext(main)
			zipContext.currentdirectory = zipXCFrameworkURL.absoluteURL.deletingLastPathComponent().path
			try zipContext.runAndPrint("zip", "-r", zipXCFrameworkURL.absoluteURL.path, xcframeworkURL.lastPathComponent)
			
			let checksumResult = run("swift", "package", "compute-checksum", zipXCFrameworkURL.absoluteURL.path)
			if let e = checksumResult.error {print(checksumResult.stderror); throw e}
			
			checksums[type.name] = checksumResult.stdout
		}
	}
	if let version = version {
		try writePackageFile(version: version, checksums: checksums)
	}
} catch {
	exit(error)
}


func writePackageFile(version: String?, checksums: [String: String?]) throws {
	let types = checksums.keys.sorted(by: { $0.count < $1.count })
	
	var packageString = """
		// swift-tools-version:5.3
		import PackageDescription
		
		
		/* Binary package definition for FSEventsWrapper.
		 * Use the xcodeproj if you want to work on the FSEventsWrapper project. */
		
		let package = Package(
			name: "FSEventsWrapper",
			products: [
				/* Sadly the line below does not work. The idea was to have a
				 * library where SPM chooses whether to take the dynamic or static
				 * version of the target, but it fails (Xcode 12B5044c). */
		//		.library(name: "FSEventsWrapper", targets: [
		"""
	
	packageString.append(types.map{ #""FSEventsWrapper-\#($0)""# }.joined(separator: ", ") + "]),\n")
	packageString.append(types.map{ #"\#t\#t.library(name: "FSEventsWrapper-\#($0)", targets: ["FSEventsWrapper-\#($0)"])"# }.joined(separator: ",\n") + "\n")
	packageString.append("""
			],
			targets: [
		
		""")
	packageString.append(types.map{ type in
		let checksum = checksums[type]!
		if let checksum = checksum {
			return #"\#t\#t.binaryTarget(name: "FSEventsWrapper-\#(type)", url: "https://github.com/happn-tech/FSEventsWrapper/releases/download/\#(version!)/FSEventsWrapper-\#(type).xcframework.zip", checksum: "\#(checksum)")"#
		} else {
			return #"\#t\#t.binaryTarget(name: "FSEventsWrapper-\#(type)", path: "./build/FSEventsWrapper-\#(type).xcframework")"#
		}
	}.joined(separator: ",\n") + "\n")
	packageString.append("""
			]
		)
		
		""")
	try Data(packageString.utf8).write(to: URL(fileURLWithPath: "Package.swift"))
}
