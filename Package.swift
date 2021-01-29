// swift-tools-version:5.1
import PackageDescription


let package = Package(
	name: "FSEventsWrapper",
	products: [
		.library(name: "FSEventsWrapper", targets: ["FSEventsWrapper"]),
	],
	targets: [
		.target(name: "FSEventsWrapper", dependencies: []),
		.testTarget(name: "FSEventsWrapperTests", dependencies: ["FSEventsWrapper"]),
		
		/* I’d have prefered the Sources of this target to be declared the way it
		 * is in the comment, but SPM complains w/ a “overlapping sources” error,
		 * so I created a soft link of FSEventsWrapper in
		 * FSEventsWrapperDirectLinkTest instead. */
		.target(name: "FSEventsWrapperDirectLinkTest", dependencies: []/*, path: "Sources", sources: ["FSEventsWrapper", "FSEventsWrapperDirectLinkTest"]*/)
	]
)
