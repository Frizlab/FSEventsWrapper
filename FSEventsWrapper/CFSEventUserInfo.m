/*
 * CFSEventUserInfo.m
 * FSEventsWrapper
 *
 * Created by François Lamboley on 24/05/15.
 * Copyright (c) 2015 Frost Land. All rights reserved.
 */

#import "CFSEventUserInfo.h"



@implementation CFSEventUserInfo

+ (instancetype)eventUserInfoWithStreamFlags:(FSEventStreamCreateFlags)flags andHandler:(id <FSEventStreamCallbackHandler>)handler
{
	CFSEventUserInfo *ret = [self new];
	ret.streamEventFlags = flags;
	ret.callbackHandler = handler;
	return ret;
}

@end
