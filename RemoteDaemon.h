#import <Cocoa/Cocoa.h>
#import "TorrentFilter.h"

#define DaemonDataWillChangeNotification @"DaemonDataWillChange"
#define DaemonDataDidChangeNotification @"DaemonDataDidChange"

#define TorrentWillRemoveFromFilterNotification @"TorrentWillRemoveFromFilterNotification"

#define TORRENT_ADD_SUCCESS 0
#define TORRENT_ADD_ERROR -1

@class TorrentData, DaemonCollection;

@interface RemoteDaemon : NSObject <NSCoding> {	
	NSString *title; // daemon title
	NSUInteger frequency; // data update frequency	
	DaemonCollection *parentObject; // parent collection
	
	NSMutableDictionary *torrentsDict; // dictionary for torrent
	NSMutableArray *filteredTorrents[FILTER_TYPE_COUNT]; // filtered torrents
	NSUInteger filterIndex; // current filter type (== index)
	NSArray *filters; // filters for torrents
}

// special methods for child classes to suppress warnings
- (id)initWithTitle:(NSString *)aTitle											// initialization for child classes
	updateFrequency:(NSUInteger)aFrequency
		 controller:(id)aController;
- (void)saveDaemonSettingsToController:(id)aController;							// fill controller with settings for changes

- (void)addTorrent:(NSURL *)url													// add torrent with delegate
		  delegate:(id)delegate
	   endSelector:(SEL)endSelector;

- (void)startDaemonUpdateProcess;												// start information update
- (void)resumeTorrents:(NSArray *)torrents;										// torrents resuming
- (void)pauseTorrents:(NSArray *)torrents;										// torrents pausing
- (void)removeTorrents:(NSArray *)torrents withData:(BOOL)flag;					// torrents removing
- (void)stopAllDaemonOperations;												// stopping every daemon operation

// daemon base initialization
- (id)initWithTitle:(NSString *)aTitle
	updateFrequency:(NSUInteger)aFrequency;

// description
- (NSString *)description;

// working with torrents update process
- (void)daemonDataWillChange;
- (void)insertTorrent:(TorrentData *)torrent;
- (void)removeTorrentsWithKeys:(NSArray *)keys;
- (void)changedFilterTypeOfTorrent:(TorrentData *)torrent from:(NSUInteger)old;
- (void)daemonDataDidChange;

// get torrents
- (TorrentData *)torrentAtIndex:(NSUInteger)index;
- (NSArray *)allTorrentsForFilter:(NSUInteger)index;

// properties
@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSUInteger frequency;
@property (nonatomic, assign) DaemonCollection *parentObject;
@property (nonatomic, readonly) NSArray *filters;
@property (nonatomic, readonly) TorrentFilter *currentFilter;
@property (nonatomic) NSUInteger filterIndex;

@end
