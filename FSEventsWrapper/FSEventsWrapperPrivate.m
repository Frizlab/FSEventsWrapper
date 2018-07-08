/*
 * FSEventsWrapper.m
 * Duplicated Sound Finder
 *
 * Created by François Lamboley on 12/7/14.
 * Copyright (c) 2014 Frost Land. All rights reserved.
 */

#import "FSEventsWrapperPrivate.h"

#import "CFSEventUserInfo.h"

/* !!! NO ARC IN THIS FILE !!! */



static const void *retainContextInfo(const void *info) {
	return [(CFSEventUserInfo *)info retain];
}

static void releaseContextInfo(const void *info) {
	[(CFSEventUserInfo *)info release];
}

static CFStringRef copyContextInfoDescription(const void *info) {
	return (CFStringRef)[[(CFSEventUserInfo *)info description] copy];
}



static void eventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo,
										  size_t numEvents, void *eventPathsAsVoidPtr,
										  const FSEventStreamEventFlags eventFlags[],
										  const FSEventStreamEventId eventIds[]) {
#if 0 /* ARC version. */
	/* Currently clientCallBackInfo is a "CFSEventUserInfo *". If it were a
	 * "CFSEventUserInfo **", we would access it this way: */
//	CFSEventUserInfo *handlerObj = *(__unsafe_unretained CFSEventUserInfo *)clientCallBackInfo;
	CFSEventUserInfo *handlerObj = (__bridge CFSEventUserInfo *)clientCallBackInfo;
#endif
	CFSEventUserInfo *userInfoObj = clientCallBackInfo;
	CFArrayRef eventPaths = eventPathsAsVoidPtr;
	
	NSLog(@"New event loop:");
	for (size_t i = 0; i < numEvents; ++i) {
		NSLog(@"   Event id: %llu, Event flags: 0x%x, Event path: %@", eventIds[i], eventFlags[i], CFArrayGetValueAtIndex(eventPaths, i));
		
		FSEventStreamEventId currentEventId = eventIds[i];
		NSString *currentEventPath = CFArrayGetValueAtIndex(eventPaths, i);
		FSEventStreamEventFlags currentEventFlags = eventFlags[i];
		BOOL fromUs = (currentEventFlags & kFSEventStreamEventFlagOwnEvent);
		currentEventFlags = (currentEventFlags & ~kFSEventStreamEventFlagOwnEvent);
		
		if (currentEventFlags == kFSEventStreamEventFlagNone) {
			if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsChangedInFolder:eventId:becauseOfUs:)])
				[userInfoObj.callbackHandler fsChangedInFolder:currentEventPath eventId:currentEventId becauseOfUs:fromUs];
		} else {
			FSItemType itemType = FSItemTypeUnknown;
			FSEventStreamEventFlags itemTypeFlags = (currentEventFlags & (kFSEventStreamEventFlagItemIsFile|kFSEventStreamEventFlagItemIsDir|kFSEventStreamEventFlagItemIsSymlink|kFSEventStreamEventFlagItemIsHardlink|kFSEventStreamEventFlagItemIsLastHardlink));
			switch (itemTypeFlags) {
				case kFSEventStreamEventFlagItemIsFile:         itemType = FSItemTypeFile;         break;
				case kFSEventStreamEventFlagItemIsDir:          itemType = FSItemTypeDir;          break;
				case kFSEventStreamEventFlagItemIsSymlink:      itemType = FSItemTypeSymlink;      break;
				case kFSEventStreamEventFlagItemIsHardlink:     itemType = FSItemTypeHardlink;     break;
				case kFSEventStreamEventFlagItemIsLastHardlink: itemType = FSItemTypeLastHardlink; break;
			}
			
			BOOL calledCallbackAtLeastOnce = NO;
			if ((currentEventFlags & kFSEventStreamEventFlagMustScanSubDirs) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsMustScanSubDirsAtPath:reason:eventId:fromUs:)]) {
					FSMustScanSubDirsReason reason = FSMustScanSubDirsReasonUnknown;
					BOOL userDropped = (currentEventFlags & kFSEventStreamEventFlagUserDropped);
					BOOL kernelDropped = (currentEventFlags & kFSEventStreamEventFlagKernelDropped);
					if      ( userDropped && !kernelDropped) {reason = FSMustScanSubDirsReasonUserDropped;}
					else if (!userDropped &&  kernelDropped) {reason = FSMustScanSubDirsReasonKernelDropped;}
					[userInfoObj.callbackHandler fsMustScanSubDirsAtPath:currentEventPath reason:reason eventId:currentEventId fromUs:fromUs];
				}
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagEventIdsWrapped) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsStreamEventIdsWrapped)])
					[userInfoObj.callbackHandler fsStreamEventIdsWrapped];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagHistoryDone) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsStreamHistoryDone)])
					[userInfoObj.callbackHandler fsStreamHistoryDone];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagRootChanged) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsRootChanged:)])
					[userInfoObj.callbackHandler fsRootChanged:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagMount) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsVolumeMountedAtPath:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsVolumeMountedAtPath:currentEventPath eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagUnmount) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsVolumeUnmountedAtPath:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsVolumeUnmountedAtPath:currentEventPath eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemCreated) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemCreatedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemCreatedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemRemoved) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemRemovedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemRemovedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemInodeMetaMod) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemInodeMetadataModifiedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemInodeMetadataModifiedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemRenamed) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemRenamedToPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemRenamedToPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemModified) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemDataModifiedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemDataModifiedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemFinderInfoMod) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemFinderInfoModifiedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemFinderInfoModifiedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemChangeOwner) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemOwnershipModifiedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemOwnershipModifiedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemXattrMod) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemXattrModifiedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemXattrModifiedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if ((currentEventFlags & kFSEventStreamEventFlagItemCloned) != 0) {
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsItemClonedAtPath:itemType:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsItemClonedAtPath:currentEventPath itemType:itemType eventId:currentEventId becauseOfUs:fromUs];
				calledCallbackAtLeastOnce = YES;
			}
			if (!calledCallbackAtLeastOnce) {
				NSLog(@"Got unknown event %u for path %@", currentEventFlags, currentEventPath);
				if ([userInfoObj.callbackHandler respondsToSelector:@selector(fsChangedInFolder:eventId:becauseOfUs:)])
					[userInfoObj.callbackHandler fsChangedInFolder:currentEventPath eventId:currentEventId becauseOfUs:fromUs];
			}
		}
	}
}

FSEventStreamRef CCreateFSEventStream(CFArrayRef cfpaths, FSEventStreamEventId startId, CFTimeInterval updateInterval,
												  FSEventStreamCreateFlags flags, id <FSEventStreamCallbackHandler> callbackHandler) {
	NSCParameterAssert((flags & kFSEventStreamCreateFlagUseCFTypes) != 0);
	CFSEventUserInfo *userInfo = [CFSEventUserInfo eventUserInfoWithStreamFlags:flags andHandler:callbackHandler];
	FSEventStreamContext context = {.version = 0, .info = userInfo, .retain = &retainContextInfo, .release = &releaseContextInfo, .copyDescription = &copyContextInfoDescription};
	return FSEventStreamCreate(kCFAllocatorDefault,  /* Allocator */
										&eventStreamCallback, /* Callback function */
										&context,             /* Event stream context. Passed to the callback function. */
										cfpaths,              /* Monitored folders */
										startId,              /* When do we start getting events from */
										updateInterval,       /* Delay before getting new events */
										flags                 /* Flags */);
}
