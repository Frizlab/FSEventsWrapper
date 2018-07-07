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
	FSItemTypeSymlink,
	FSItemTypeHardlink,
	FSItemTypeLastHardlink
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
- (void)fsChangedInFolder:(nonnull NSString *)folderPath eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagMustScanSubDirs,
 * kFSEventStreamEventFlagUserDropped &
 * kFSEventStreamEventFlagKernelDropped
 * Note sure if event id has a real meaning here... */
- (void)fsMustScanSubDirsAtPath:(nonnull NSString *)path reason:(FSMustScanSubDirsReason)reason eventId:(FSEventStreamEventId)eventId fromUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagEventIdsWrapped
 * TODO: Doc for when this happens (reset of disk UUID). https://stackoverflow.com/a/26281273/1152894
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
 * The event id is not sent with this method as it is always 0 (says the doc)
 * for this event.
 * Note (TODO): I don't know if the "event is from us" flag is set for this event. */
- (void)fsRootChanged:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagMount
 * Note (TODO): I don't know if the "event is from us" flag is set for this
 * event, nor if the event id has any meaning here. */
- (void)fsVolumeMountedAtPath:(nonnull NSString *)path eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagUnmount
 * Note (TODO): I don't know if the "event is from us" flag is set for this
 * event, nor if the event id has any meaning here. */
- (void)fsVolumeUnmountedAtPath:(nonnull NSString *)path eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* *** All methods below are called only if kFSEventStreamCreateFlagFileEvents
 *     was set when the stream was created... says the doc. But actually, it is
 *     not true on Yosemite (not tested on other OSs)! The events for file
 *     creation, deletion, renaming, etc. are set even when the flag was not
 *     set... The only difference is the events are sent for the parent folder
 *     only, and not for each file when the flag is not set. *** */
/* itemType refers to the kFSEventStreamEventFlagItemIsFile,
 * kFSEventStreamEventFlagItemIsDir, kFSEventStreamEventFlagItemIsSymlink,
 * kFSEventStreamEventFlagItemIsHardlink and
 * kFSEventStreamEventFlagItemIsLastHardlink flags. */

/* kFSEventStreamEventFlagItemCreated */
- (void)fsItemCreatedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemRemoved */
- (void)fsItemRemovedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemInodeMetaMod */
- (void)fsItemInodeMetadataModifiedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemRenamed
 * TODO: Verify the path given is the new path of the item. */
- (void)fsItemRenamedToPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemModified */
- (void)fsItemDataModifiedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemFinderInfoMod */
- (void)fsItemFinderInfoModifiedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemChangeOwner */
- (void)fsItemOwnershipModifiedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemXattrMod */
- (void)fsItemXattrModifiedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs;

/* kFSEventStreamEventFlagItemCloned */
- (void)fsItemClonedAtPath:(nonnull NSString *)path itemType:(FSItemType)itemType eventId:(FSEventStreamEventId)eventId becauseOfUs:(BOOL)isEventFromUs __OSX_AVAILABLE_STARTING(__MAC_10_13, __IPHONE_11_0);

@end
