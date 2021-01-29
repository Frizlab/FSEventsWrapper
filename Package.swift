// swift-tools-version:5.1
import PackageDescription


let package = Package(
	name: "FSEventsWrapper",
	products: [
		.library(name: "FSEventsWrapper", targets: ["FSEventsWrapper"]),
	],
	targets: [
		.target(name: "FSEventsWrapper", dependencies: []),
		.testTarget(name: "FSEventsWrapperTests", dependencies: ["FSEventsWrapper"])
	]
)
