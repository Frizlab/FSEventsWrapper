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
	
	for (size_t i = 0; i < numEvents; ++i) {
		if (eventFlags[i] == kFSEventStreamEventFlagNone) {
			NSLog(@"Got a non event");
			[userInfoObj.callbackHandler fsChangedInFolder:CFArrayGetValueAtIndex(eventPaths, i) becauseOfUs:NO];
		} else {
			NSLog(@"Got other event %u for path %@", eventFlags[i], CFArrayGetValueAtIndex(eventPaths, i));
			[userInfoObj.callbackHandler fsChangedInFolder:CFArrayGetValueAtIndex(eventPaths, i) becauseOfUs:NO];
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
