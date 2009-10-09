#import "RemoteDaemon.h"
#import "TorrentData.h"
#import "DaemonCollection.h"

@implementation RemoteDaemon

@synthesize title;
@synthesize frequency;
@synthesize parentObject;
@synthesize filterIndex;
@synthesize filters;

@dynamic currentFilter;

#pragma mark Base methods (have no implementation).

- (id)initWithTitle:(NSString *)aTitle updateFrequency:(NSUInteger)aFrequency controller:(id)aController {
	// no implementation
	return nil;
}

- (void)saveDaemonSettingsToController:(id)aController {
}

- (void)startDaemonUpdateProcess {
	// no implementation
}

- (void)resumeTorrents:(NSArray *)torrents {
	// no implementation
}

- (void)pauseTorrents:(NSArray *)torrents {
	// no implementation
}

- (void)removeTorrents:(NSArray *)torrents withData:(BOOL)flag {
	// no implementation
}

- (void)stopAllDaemonOperations {
	// no implementation
}

- (void)addTorrent:(NSURL *)url delegate:(id)delegate endSelector:(SEL)endSelector {
	[delegate performSelector:endSelector
				   withObject:(id)TORRENT_ADD_SUCCESS
				   withObject:nil];
}

#pragma mark Initialization.

- (id)initWithTitle:(NSString *)aTitle updateFrequency:(NSUInteger)aFrequency {
	if (self = [super init]) {
		[self setTitle:aTitle];
		[self setFrequency:aFrequency];
		[self setFilterIndex:FILTER_TYPE_ALL];
		
		// allocate torrents
		torrentsDict = [[NSMutableDictionary alloc] init];
		for (NSInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
			filteredTorrents[i] = [[NSMutableArray alloc] init];
		
		// create filters
		filters = [[NSArray alloc] initWithObjects:
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_ALL parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_VERIFYING parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_DOWNLOADING parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_COMPLETED parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_INACTIVE parent:self] autorelease],
				   nil];		
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder { 
	NSString *aTitle = [coder decodeObjectForKey:@"title"];
	NSInteger aFrequency = [coder decodeIntegerForKey:@"frequency"];
	return [self initWithTitle:aTitle updateFrequency:aFrequency];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:[self title] forKey:@"title"];
	[coder encodeInteger:[self frequency] forKey:@"frequency"];
}

#pragma mark Data source for table view.

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [filteredTorrents[filterIndex] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	TorrentData *torrent = [filteredTorrents[filterIndex]
							objectAtIndex:rowIndex];
	if ([aTableColumn identifier] == nil)
		return nil;
	return [torrent valueForKey:[aTableColumn identifier]];
}

#pragma mark Methods overriding.

- (NSString *)description {
	return [self title];
}

#pragma mark Working with torrents.

- (void)daemonDataWillChange {
	[[NSNotificationCenter defaultCenter] postNotificationName:DaemonDataWillChangeNotification
														object:self];
}

- (void)insertTorrent:(TorrentData *)torrent {
	[torrentsDict setObject:torrent forKey:[torrent uniqueId]];					// add torent into dictionary
	[filteredTorrents[FILTER_TYPE_ALL] addObject:torrent];						// add object into "all" filter array
	[self changedFilterTypeOfTorrent:torrent from:FILTER_TYPE_ALL];				// filter torrent
	[parentObject insertTorrent:torrent];										// parent object
}

- (void)removeTorrentsWithKeys:(NSArray *)keys {
	if (![keys count])															// return if no torrents to delete
		return;
	NSMutableArray *objects = [NSMutableArray array];
	for (NSString *key in keys) {
		TorrentData *torrent = [torrentsDict objectForKey:key];
		[objects addObject:torrent];
	}
	for (NSUInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
		[filteredTorrents[i] removeObjectsInArray:objects];						// remove torrents from filters
	[filteredTorrents[FILTER_TYPE_ALL] removeObjectsInArray:objects];			// remove torrents from array
	[torrentsDict removeObjectsForKeys:keys];									// remove torrents from dictionary
	[parentObject removeTorrents:objects];										// parent object
}

- (void)changedFilterTypeOfTorrent:(TorrentData *)torrent from:(NSUInteger)old {
	NSInteger filterType = [torrent filterType];								// torrent new filter
	if (old != FILTER_TYPE_ALL) {												// remove from old filter
		NSNumber *index = [NSNumber numberWithInteger:[filteredTorrents[old] indexOfObject:torrent]];
		NSArray *params = [NSArray arrayWithObjects:[filters objectAtIndex:old], index, nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:TorrentWillRemoveFromFilterNotification
															object:params];
		[filteredTorrents[old] removeObject:torrent];
	}
	if (filterType != FILTER_TYPE_ALL) {										// add to new filter
		[filteredTorrents[filterType] addObject:torrent];
	}
	[parentObject changedFilterTypeOfTorrent:torrent from:old];					// parent object
}

- (void)daemonDataDidChange {
	[[NSNotificationCenter defaultCenter] postNotificationName:DaemonDataDidChangeNotification
														object:self];
}

- (TorrentFilter *)currentFilter {
	return [filters objectAtIndex:filterIndex];
}

#pragma mark Get torrents.

- (TorrentData *)torrentAtIndex:(NSUInteger)index {
	return [filteredTorrents[filterIndex] objectAtIndex:index];
}

- (NSArray *)allTorrentsForFilter:(NSUInteger)index {
	return filteredTorrents[index];
}

#pragma mark Deallocation.

- (void)dealloc {
	for (NSInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
		[filteredTorrents[i] release];
	[torrentsDict release];
	[filters release];
	[title release];
	[super dealloc];
}

@end
