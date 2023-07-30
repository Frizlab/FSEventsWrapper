/*
 * FSEvent.swift
 * FSEventsWrapper
 *
 * Created by François Lamboley on 2018/07/09.
 * Copyright © 2018 François Lamboley.
 */

import CoreServices
import Foundation



public enum FSEvent : Sendable {
	
	public enum MustScanSubDirsReason : Sendable {
		
		case userDropped
		case kernelDropped
		
		case unknown
		
	}
	
	public enum ItemType : Sendable {
		
		case file
		case dir
		case symlink
		case hardlink
		case lastHardlink
		
		case unknown
		
	}
	
	/* For all event types, the “fromUs” var (whether the event comes from us) will only be set to a non-nil value if kFSEventStreamCreateFlagMarkSelf is set.
	 *
	 * The notion corresponds to the kFSEventStreamEventFlagOwnEvent flag.
	 *
	 * Note: If kFSEventStreamCreateFlagIgnoreSelf is set in addition to kFSEventStreamCreateFlagMarkSelf, fromUs should always be false.
	 * Note2: The flag does not seem to work for whatever reason… We might wanna try disabling SIP and see if flag still does not work ¯\_(ツ)_/¯ */
	
	/** `kFSEventStreamEventFlagNone` or unknown flag. */
	case generic(path: String, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/**
	 `kFSEventStreamEventFlagMustScanSubDirs`, `kFSEventStreamEventFlagUserDropped` &
	 `kFSEventStreamEventFlagKernelDropped`.
	 
	 - Note: Not sending the event stream id; it probably has no meaning here. */
	case mustScanSubDirs(path: String, reason: MustScanSubDirsReason)
	
	/**
	 `kFSEventStreamEventFlagEventIdsWrapped`
	 
	 The important thing to know is you should retrieve the UUID for the monitored device with `FSEventsCopyUUIDForDevice`
	  if you plan on saving the event id to replay from the last seen event id when you program relaunch.
	 When receiving the “event id wrapped” event, you should retrieve the new UUID for the device because it changes when the event id wraps.
	 [More info here](<https://stackoverflow.com/a/26281273>).
	 
	 - Note: There is no "fromUs" part in this case because I assume FSEvents will not set the OwnEvent flag for this event (it would not make much sense).
	 However, I do not have any confirmation from any doc that it is the actual behaviour.
	 In any case, the event id counter will probably never wrap (too big to wrap). */
	case eventIdsWrapped
	
	/**
	 `kFSEventStreamEventFlagHistoryDone`
	 
	 Not called if monitoring started from now. */
	case streamHistoryDone
	
	/**
	 `kFSEventStreamEventFlagRootChanged`
	 
	 Not called if `kFSEventStreamCreateFlagWatchRoot` is not set when creating the stream.
	 
	 The event id is not sent with this method as it is always 0 (says the doc) for this event.
	 
	 - Note: I don't know if the “event is from us” flag is set for this event. */
	case rootChanged(path: String, fromUs: Bool?)
	
	/**
	 `kFSEventStreamEventFlagMount`
	 
	 - Note: I don't know if the “event is from us” flag is set for this event, nor if the event id has any meaning here…
	 I don’t know if there is a valid event id for this event (probably not). */
	case volumeMounted(path: String, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/**
	 `kFSEventStreamEventFlagUnmount`
	 
	 - Note: I don't know if the “event is from us” flag is set for this event, nor if the event id has any meaning here…
	 I don’t know if there is a valid event id for this event (probably not). */
	case volumeUnmounted(path: String, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/* **************************************************************************
	 * All methods below are called only if kFSEventStreamCreateFlagFileEvents was set when the stream was created… says the doc.
	 * But actually, it is not true on Yosemite (not tested on other OSs).
	 * The events for file creation, deletion, renaming, etc. are set even when the flag was not set.
	 * The only difference is the events are sent for the parent folder only, and not for each file when the flag is not set.
	 * ************************************************************************** */
	
	/* itemType refers to the following flags:
	 *  kFSEventStreamEventFlagItemIsFile
	 *  kFSEventStreamEventFlagItemIsDir
	 *  kFSEventStreamEventFlagItemIsSymlink
	 *  kFSEventStreamEventFlagItemIsHardlink
	 *  kFSEventStreamEventFlagItemIsLastHardlink */
	
	/** `kFSEventStreamEventFlagItemCreated` */
	case itemCreated(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemRemoved` */
	case itemRemoved(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemInodeMetaMod` */
	case itemInodeMetadataModified(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/**
	 `kFSEventStreamEventFlagItemRenamed`
	 
	 `path` is either the new name or the old name of the file.
	 
	 You should be called twice, once for the new name, once for the old name (assuming both names are in the monitored folder or one of their descendants).
	 There are no sure way (AFAICT) to know which is which.
	 
	 From my limited testing, both events are sent in the same callback call (you don’t have the information of the callback call from FSEventsWrapper) at one event interval,
	  the first one being the original name, the second one the new name.
	 
	 Note you cannot know if two events are from the same callback call using `FSEventsWrapper` for now. */
	case itemRenamed(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemModified` */
	case itemDataModified(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemFinderInfoMod` */
	case itemFinderInfoModified(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemChangeOwner` */
	case itemOwnershipModified(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/** `kFSEventStreamEventFlagItemXattrMod` */
	case itemXattrModified(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
	/**
	 `kFSEventStreamEventFlagItemCloned`
	 
	 Only available from macOS 10.13 and macCatalyst 11.0, but we cannot use @available on an enum case with associated values. */
//	@available(macOS 10.13, macCatalyst 11.0, *)
	case itemClonedAtPath(path: String, itemType: ItemType, eventId: FSEventStreamEventId, fromUs: Bool?)
	
}
