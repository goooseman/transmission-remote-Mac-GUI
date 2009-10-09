#import <Cocoa/Cocoa.h>
#import "TorrentFilter.h"

#define GROUP_NAME_TRANSFERS @"TRANSFERS"
#define GROUP_NAME_DAEMONS @"DAEMONS"

@class RemoteDaemon, TorrentData;

@interface DaemonCollection : NSObject {
	// group items for outline view
	NSArray *groups;
	
	// filters for torrents
	NSMutableArray *filteredTorrents[FILTER_TYPE_COUNT]; // filtered torrents
	NSUInteger filterIndex; // current filter type (== index)
	NSArray *filters;
	
	// daemon array
	NSMutableArray *daemons;
}

// adding and removing daemon
- (void)addDaemon:(RemoteDaemon *)daemon;
- (void)removeDaemon:(RemoteDaemon *)daemon;

// working with torrents update process
- (void)insertTorrent:(TorrentData *)torrent;
- (void)removeTorrents:(NSArray *)objects;
- (void)changedFilterTypeOfTorrent:(TorrentData *)torrent from:(NSUInteger)old;

// get torrents
- (TorrentData *)torrentAtIndex:(NSInteger)index;

@property (nonatomic, readonly) NSArray *groups;
@property (nonatomic, readonly) NSArray *filters;
@property (nonatomic, readonly) TorrentFilter *currentFilter;
@property (nonatomic, readonly) NSMutableArray *daemons;
@property (nonatomic) NSUInteger filterIndex;

@end
