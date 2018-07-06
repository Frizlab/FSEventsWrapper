/*
 * CFSEventUserInfo.h
 * Duplicated Sound Finder
 *
 * Created by François Lamboley on 24/05/15.
 * Copyright (c) 2015 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "FSEventStreamCallbackHandler.h"



@interface CFSEventUserInfo : NSObject

+ (instancetype)eventUserInfoWithStreamFlags:(FSEventStreamCreateFlags)flags andHandler:(id <FSEventStreamCallbackHandler>)handler;

@property(assign) FSEventStreamCreateFlags streamEventFlags;
@property(weak) id <FSEventStreamCallbackHandler> callbackHandler;

@end
