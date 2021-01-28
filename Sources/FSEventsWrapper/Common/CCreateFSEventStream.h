/*
 * FSEventsWrapperPrivate.h
 * FSEventsWrapper
 *
 * Created by François Lamboley on 12/7/14.
 * Copyright (c) 2014 Frost Land. All rights reserved.
 */

@import Foundation;

#import "FSEventStreamCallbackHandler.h"



/* TODO: Get rid of the C callbacks and go pure Swift! */
FSEventStreamRef CCreateFSEventStream(CFArrayRef paths, FSEventStreamEventId startId,
												  CFTimeInterval updateInterval,
												  FSEventStreamCreateFlags flags,
												  id callbackHandler);
