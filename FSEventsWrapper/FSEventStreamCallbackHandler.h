/*
 * FSEventStreamCallbackHandler.h
 * Duplicated Sound Finder
 *
 * Created by François Lamboley on 24/05/15.
 * Copyright (c) 2015 Frost Land. All rights reserved.
 */

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSUInteger, FSMustScanSubDirsReason) {
	FSMustScanSubDirsReasonUnknown = 0,
	
	FSMustScanSubDirsReasonUserDropped,
	FSMustScanSubDirsReasonKernelDropped
};

typedef NS_ENUM(NSUInteger, FSItemType) {
	FSItemTypeUnknown = 0,
	
	FSItemTypeFile,
	FSItemTypeDir,
	FSItemTypeSymlink
};

/* NOT a Swift protocol because there can't be optional methods in a pure Swift
 * protocol... */
@protocol FSEventStreamCallbackHandler <NSObject>
@optional

/* *** For all methods, the notion of whether the event comes from us or not is
 *     relevant only if the kFSEventStreamCreateFlagMarkSelf flag was defined
 *     when the stream was created. (It will always be NO if the flag was not
 *     set.)
 *     The notion corresponds to the kFSEventStreamEventFlagOwnEvent flag. *** */

/* kFSEventStreamEventFlagNone */
- (void)fsChangedInFolder:(NSString *)folderPath becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagMustScanSubDirs,
 * kFSEventStreamEventFlagUserDropped &
 * kFSEventStreamEventFlagKernelDropped */
- (void)fsMustScanSubDirsAtPath:(NSString *)path reason:(FSMustScanSubDirsReason)reason fromUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagEventIdsWrapped
 * You typically have nothing to do when this happens.
 * Note: There is no "becauseOfUs:" part in this method because I assume
 *       FSEvents will not set the OwnEvent flag for the EventIdsWrapped flag
 *       (it would not make much sense). However, I do not have any confirmation
 *       from any doc that it is the actual behaviour.
 *       In any case, the event id counter _never_ wraps... (too big to wrap!) */
- (void)fsStreamEventIdsWrapped;

/* kFSEventStreamEventFlagHistoryDone
 * Not called if monitoring started from now. */
- (void)fsStreamHistoryDone;

/* kFSEventStreamEventFlagRootChanged
 * Not called if kFSEventStreamCreateFlagWatchRoot is not set when creating the
 * stream.
 * Note (TODO): I don't know if the "event is from us" flag is set for this event. */
- (void)fsRootChanged:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagMount
 * Note (TODO): I don't know if the "event is from us" flag is set for this event. */
- (void)fsVolumeMountedAtPath:(NSString *)path becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagUnmount
 * Note (TODO): I don't know if the "event is from us" flag is set for this event. */
- (void)fsVolumeUnmountedAtPath:(NSString *)path becauseOfUs:(BOOL)isEventFromUs;

/* *** All methods below are called only if kFSEventStreamCreateFlagFileEvents
 *     was set when the stream was created... says the doc. But actually, it is
 *     not true on Yosemite (not tested on other OSs)! The events for file
 *     creation, deletion, renaming, etc. are set even when the flag was not
 *     set... The only difference is the events are sent for the parent folder
 *     only, and not for each file when the flag is not set. *** */
/* itemType refers to the kFSEventStreamEventFlagItemIsFile,
 * kFSEventStreamEventFlagItemIsDir and kFSEventStreamEventFlagItemIsSymlink
 * flags. */

/* kFSEventStreamEventFlagItemCreated */
- (void)fsItemCreatedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemRemoved */
- (void)fsItemRemovedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemInodeMetaMod */
- (void)fsItemInodeMetadataModifiedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemRenamed
 * TODO: Verify the path given is the new path of the item. */
- (void)fsItemRenamedToPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemModified */
- (void)fsItemDataModifiedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemFinderInfoMod */
- (void)fsItemFinderInfoModifiedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemChangeOwner */
- (void)fsItemOwnershipModifiedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemXattrMod */
- (void)fsItemXattrModifiedAtPath:(NSString *)path itemType:(FSItemType)itemType becauseOfUs:(BOOL)isEventFromUs;

@end
