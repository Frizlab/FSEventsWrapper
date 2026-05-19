import Foundation



/* Needed to guard the availability of `AsyncStream.makeStream`.
 * Once Xcode 15 is released, it should be safe to remove this. */
#if compiler(>=5.9)

/** An AsyncSequence of `FSEvent` objects. */
@available(macOS 10.15, *)
public struct FSEventAsyncStream : AsyncSequence {
	
	public typealias Element = FSEvent
	
	public struct FSEventAsyncIterator : AsyncIteratorProtocol {
		
		private let eventStream: FSEventStream?
		private var streamIterator: AsyncStream<FSEvent>.Iterator
		
		init(path: String, since startId: FSEventStreamEventId?, updateInterval: CFTimeInterval, flags: FSEventStreamCreateFlags) {
			let (stream, continuation) = AsyncStream<FSEvent>.makeStream()
			
			self.eventStream = FSEventStream(path: path, fsEventStreamFlags: flags, callback: { _, event in
				continuation.yield(event)
			})
			
			self.streamIterator = stream.makeAsyncIterator()
			self.eventStream?.startWatching()
			
			if eventStream == nil {
				continuation.finish()
			}
		}
		
		public mutating func next() async -> FSEvent? {
			await streamIterator.next()
		}
		
	}
	
	public let path: String
	public let startId: FSEventStreamEventId?
	public let updateInterval: CFTimeInterval
	public let flags: FSEventStreamCreateFlags
	
	public init(path: String,
				since startId: FSEventStreamEventId? = nil,
				updateInterval: CFTimeInterval = 0,
				flags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)) {
		self.path = path
		self.startId = startId
		self.updateInterval = updateInterval
		self.flags = flags
	}
	
	public func makeAsyncIterator() -> FSEventAsyncIterator {
		FSEventAsyncIterator(path: path, since: startId, updateInterval: updateInterval, flags: flags)
	}
	
}

#endif
