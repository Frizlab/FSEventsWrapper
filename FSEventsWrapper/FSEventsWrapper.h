/*
 * FSEventsWrapper.h
 * FSEventsWrapper
 *
 * Created by François Lamboley on 06/07/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

#import <Foundation/Foundation.h>

/** Project version number for FSEventsWrapper. */
FOUNDATION_EXPORT double FSEventsWrapperVersionNumber;

/** Project version string for FSEventsWrapper. */
FOUNDATION_EXPORT const unsigned char FSEventsWrapperVersionString[];


#import <FSEventsWrapper/FSEventStreamCallbackHandler.h>

/* For compilation reasons, this must be imported here. But do NOT use the
 * CCreateFSEventStream method! (There might be a way to circumvent this; I did
 * not try…) */
#import <FSEventsWrapper/FSEventsWrapperPrivate.h>
