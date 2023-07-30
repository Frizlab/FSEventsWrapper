// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "FSEventsWrapper",
	platforms: [.macOS(.v10_13)],
	products: [
		.library(name: "FSEventsWrapper", targets: ["FSEventsWrapper"]),
	],
	targets: [
		.target(name: "FSEventsWrapper", path: "Sources"),
		.testTarget(name: "FSEventsWrapperTests", dependencies: ["FSEventsWrapper"], path: "Tests")
	]
)
