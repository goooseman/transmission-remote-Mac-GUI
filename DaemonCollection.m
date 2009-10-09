#import "DaemonCollection.h"
#import "RemoteDaemon.h"

@implementation DaemonCollection

@synthesize groups;
@synthesize daemons;
@synthesize filterIndex;
@synthesize filters;

@dynamic currentFilter;

#pragma mark Data model initialization methods.

- (id)initWithCoder:(NSCoder *)coder { 
	if (self = [super init]) {
		if (coder != nil)
			daemons = [[coder decodeObjectForKey:@"DaemonsArray"] retain];
		else
			daemons = [[NSMutableArray alloc] init];
		
		// group objects
		groups = [[NSArray alloc] initWithObjects:
				  [NSString stringWithString:GROUP_NAME_TRANSFERS],
				  [NSString stringWithString:GROUP_NAME_DAEMONS],
				  nil];

		for (NSInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
			filteredTorrents[i] = [[NSMutableArray alloc] init];

		// filters
		filters = [[NSArray alloc] initWithObjects:
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_ALL parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_VERIFYING parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_DOWNLOADING parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_COMPLETED parent:self] autorelease],
				   [[[TorrentFilter alloc] initWithType:FILTER_TYPE_INACTIVE parent:self] autorelease],
				   nil];
		
		// starting update of every
		for (int i = 0; i < [daemons count]; i ++) {
			[[daemons objectAtIndex:i] setParentObject:self];
			[[daemons objectAtIndex:i] startDaemonUpdateProcess];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:daemons forKey:@"DaemonsArray"];
}

- (id)init {
	return [self initWithCoder:nil];
}

#pragma mark Public methods to add or remove daemon, working with items.

- (void)addDaemon:(RemoteDaemon *)daemon {
	[daemon setParentObject:self];														// set parent object before everything
	[daemons addObject:daemon];															// adding daemon to array
	[daemon startDaemonUpdateProcess];													// starting daemon update
}

- (void)removeDaemon:(RemoteDaemon *)daemon {
	[daemon stopAllDaemonOperations];													// stop all pending requests
	NSArray *torrents = [daemon allTorrentsForFilter:FILTER_TYPE_ALL];					// get all torrents
	for (NSInteger i = 0; i < FILTER_TYPE_COUNT; i ++)									// remove from local array
		[filteredTorrents[i] removeObjectsInArray:torrents];
	
	// TODO send update notification
	
	[daemons removeObject:daemon];														// remove object
}

#pragma mark Datasource for outline view.

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		if ([daemons count] > 1)
			return [groups count];
		return 1;
	} else if (item == [groups objectAtIndex:0])
		return [filters count];
	else if (item == [groups objectAtIndex:1])
		return [daemons count];
	else if ([item isKindOfClass:[RemoteDaemon class]])
		return [[item filters] count] - 1;
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if (item == nil)
		return NO;
	else if (item == [groups objectAtIndex:0])
		return YES;
	else if (item == [groups objectAtIndex:1])
		return [daemons count] ? YES : NO;
	else if ([item isKindOfClass:[RemoteDaemon class]])
		return YES;
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
	if (item == nil)
		return [groups objectAtIndex:index];
	else if (item == [groups objectAtIndex:0]) {
		if ([daemons count] != 1)
			return [filters objectAtIndex:index];
		return [[[daemons objectAtIndex:0] filters] objectAtIndex:index];
	}
	else if (item == [groups objectAtIndex:1])
		return [daemons objectAtIndex:index];
	else if ([item isKindOfClass:[RemoteDaemon class]])
		return [[item filters] objectAtIndex:(index + 1)];
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [item description];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[RemoteDaemon class]]) {
		RemoteDaemon *daemon = (RemoteDaemon *)item;
		[daemon setTitle:[object description]];
	}
}

#pragma mark Delegate methods for outline view.

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	if ([groups indexOfObject:item] != NSNotFound)
		return NO;
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	if ([groups indexOfObject:item] != NSNotFound)
		return YES;
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
	if ([groups indexOfObject:item] != NSNotFound)
		return NO;
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([item isKindOfClass:[RemoteDaemon class]])
		return YES;
	return NO;
}

#pragma mark Data source for table view and filter setup.

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [filteredTorrents[[self filterIndex]] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	TorrentData *torrent = [filteredTorrents[[self filterIndex]]
							objectAtIndex:rowIndex];
	if ([aTableColumn identifier] == nil)
		return nil;
	return [torrent valueForKey:[aTableColumn identifier]];
}

#pragma mark Torrents update process.

- (void)insertTorrent:(TorrentData *)torrent {
	[filteredTorrents[FILTER_TYPE_ALL] addObject:torrent];						// add object into "all" filter array
	[self changedFilterTypeOfTorrent:torrent from:FILTER_TYPE_ALL];				// filter torrent
}

- (void)removeTorrents:(NSArray *)objects {
	if (![objects count])														// return if no torrents to delete
		return;
	for (NSUInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
		[filteredTorrents[i] removeObjectsInArray:objects];						// remove torrents from filters
	[filteredTorrents[FILTER_TYPE_ALL] removeObjectsInArray:objects];			// remove torrents from array
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
	if (filterType != FILTER_TYPE_ALL)											// add to new filter
		[filteredTorrents[filterType] addObject:torrent];
}

- (TorrentFilter *)currentFilter {
	return [filters objectAtIndex:filterIndex];
}

#pragma mark Get torrents.

- (TorrentData *)torrentAtIndex:(NSInteger)index {
	return [filteredTorrents[filterIndex] objectAtIndex:index];
}

#pragma mark Deallocation.

- (void)dealloc {
	for (NSInteger i = 0; i < FILTER_TYPE_COUNT; i ++)
		[filteredTorrents[i] release];
	[filters release];
	[groups release];
	[daemons release];
	[super dealloc];
}

@end
