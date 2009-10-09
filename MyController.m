#import "MyController.h"
#import "MyOutlineView.h"
#import "DaemonSheetController.h"
#import "TorrentProgressController.h"
#import "DaemonCollection.h"
#import "TorrentFilter.h"
#import "RemoteDaemon.h"
#import "ProgressCell.h"
#import "TorrentData.h"

#define VSPLIT_MIN_LEFT 100 // left frame mininum width
#define VSPLIT_MIN_RIGHT 300 // right frame mininum width

@implementation MyController

#pragma mark Initialization.

+ (void)initialize {
	// Application defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *appDefaultsKeys = [NSArray arrayWithObjects:@"RefreshFrequency", nil];
	NSArray *appDefaultsValues = [NSArray arrayWithObjects:@"5", nil];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects:appDefaultsValues
															forKeys:appDefaultsKeys];
	[defaults registerDefaults:appDefaults];
}

- (void)awakeFromNib {
	// creating/restoring data model
	NSData *encodedDataModel = [[NSUserDefaults standardUserDefaults]				// restoring daemon list from preferences
								dataForKey:@"DaemonsData"];
	if (encodedDataModel != nil) {
		daemons = (DaemonCollection *)[[NSKeyedUnarchiver unarchiveObjectWithData:
								 encodedDataModel] retain];
	} else
		daemons = [[DaemonCollection alloc] init];
	
	// setup outline view
	[outlineView setDelegate:daemons];												// delegate for outline view
	[outlineView setDataSource:daemons];											// setting data source for outline view
	[self outlineViewReloadWithGroupsExpanding];									// reloading every data in outline view
																					//	and expanding group items
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:1]					// select filter "All"
			 byExtendingSelection:YES];
	[self outlineViewSelectionDidChange:nil];
	
	// registering notifications.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewSelectionDidChange:)
												 name:NSOutlineViewSelectionDidChangeNotification
											   object:outlineView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(tableViewSelectionDidChange:)
												 name:NSTableViewSelectionDidChangeNotification
											   object:tableView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(daemonDataWillChange:)
												 name:DaemonDataWillChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(daemonDataDidChange:)
												 name:DaemonDataDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(torrentWillRemoveFromFilter:)
												 name:TorrentWillRemoveFromFilterNotification
											   object:nil];
}


#pragma mark Data from outline and table view.

- (RemoteDaemon *)selectedDaemon {
	id result = [outlineView itemAtRow:[outlineView selectedRow]];
	if (!result)
		return nil;
	
	if ([result isKindOfClass:[TorrentFilter class]])
		result = [result parentObject];
	if (![result isKindOfClass:[RemoteDaemon class]])
		return nil;
		
	return result;
}

- (NSArray *)selectedTorrents {
	NSMutableArray *result = [NSMutableArray array];
	id source = [tableView dataSource];														// torrent data source
	NSIndexSet *indexes = [tableView selectedRowIndexes];									// get selected indexes
	NSUInteger index = [indexes firstIndex];												// iterate trough indexes
	while (index != NSNotFound) {
		TorrentData *torrent = [source torrentAtIndex:index];								// get torrent using index
		[result addObject:torrent];															// add torrent to result array
		index = [indexes indexGreaterThanIndex:index];										// next index
	}
	return result;
}

#pragma mark Menu and toolbar items validation.

- (BOOL)validateUsingSelector:(SEL)sel {
	if (sel == @selector(menuRemoveDaemon:) ||												// remove daemon
		sel ==  @selector(menuDaemonSettings:)) {											// change daemon settings
		if ([self selectedDaemon] != nil)													//	then check if daemon selected
			return YES;
		return NO;
	} else if (sel == @selector(menuPauseTorrent:) ||
		sel == @selector(menuResumeTorrent:)) {
		BOOL enableItem = NO;
		NSArray *torrents = [self selectedTorrents];										// selected torrents
		for (TorrentData *torrent in torrents) {												// iterate
			if ((sel == @selector(menuPauseTorrent:) && [torrent status] != STATUS_STOPPED) ||
				(sel == @selector(menuResumeTorrent:) && [torrent status] == STATUS_STOPPED)) {
				enableItem = YES;
				break;
			}
		}
		return enableItem;
	} else if (sel == @selector(menuRemoveTorrent:) ||
			   sel == @selector(menuRemoveTorrentWithData:)) {
		if ([[self selectedTorrents] count])
			return YES;
		return NO;
	} else if (sel == @selector(menuAddTorrentFromFile:) ||
			   sel == @selector(menuAddTorrentFromLink:)) {
		if ([self selectedDaemon] != nil)													//	then check if daemon selected
			return YES;
		return NO;
	}
	return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([toolbarView customizationPaletteIsRunning])								// if customization is running, disable menu
        return NO;
	if ([NSApp modalWindow] != nil)
		return NO;
	if ([[NSApp mainWindow] attachedSheet] != nil)
		return NO;
	return [self validateUsingSelector:[menuItem action]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
	return [self validateUsingSelector:[toolbarItem action]];
}

#pragma mark Add daemons and torrents menu action.

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSString *)contextInfo {
	[sheet orderOut:nil];
	if ([contextInfo isEqualToString:@"menuAddDaemon"] && returnCode == NSOKButton) {
		RemoteDaemon *daemon = [daemonSheetCtrl newDaemonFromSelectedTab];			// create a daemon with selected type
		[daemons addDaemon:daemon];													//	and add it into array
		[daemon release];
		[self outlineViewReloadWithGroupsExpanding];								// reload every data in outline view
	} else if ([contextInfo isEqualToString:@"menuDaemonSettings"] && returnCode == NSOKButton) {
		[daemonSheetCtrl updateSettingsForDaemon:[self selectedDaemon]];			// update settings
		[outlineView reloadItem:[self selectedDaemon]];								// maybe daemon title changed
	} else if ([contextInfo isEqualToString:@"menuRemoveDaemon"] && returnCode == NSAlertDefaultReturn) {
		[daemons removeDaemon:[self selectedDaemon]];								// remove daemon registered
		[self outlineViewReloadWithGroupsExpanding];								// reload every data in outline view
		[outlineView deselectAll:self];												// select nothing
	} else if ([contextInfo isEqualToString:@"menuAddTorrentFromFile"] && returnCode == NSOKButton) {
		[NSApp beginSheet:[torrentProgressSheet sheet]								// begin sheet with progress
		   modalForWindow:[NSApp mainWindow]
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:@"addTorrentProgress"];
		[torrentProgressSheet beginAddTorrents:[(NSOpenPanel *)sheet URLs]			// starting torrents add
									 forDaemon:[self selectedDaemon]];
	} else if ([contextInfo isEqualToString:@"addTorrentProgress"] && returnCode == NSAlertErrorReturn) {
		// TODO Show error sheet with disclosure triangle.
		NSString *msg = nil;
		if ([[torrentProgressSheet errorData] count] == 1)
			msg = [NSString stringWithFormat:@"%u of %u torrent was not added due to some errors.",
						 [[torrentProgressSheet errorData] count], [torrentProgressSheet lastTorrentsCount]];
		else
			msg = [NSString stringWithFormat:@"%u of %u torrents were not added due to some errors.",
				   [[torrentProgressSheet errorData] count], [torrentProgressSheet lastTorrentsCount]];
		NSString *inf = @"Check internet connectivity then try to repeat last operation. "
						@"For more information push disclosure triangle below.";
		NSBeginAlertSheet(msg, @"Close", nil, nil, [NSApp mainWindow], self,
						  @selector(sheetDidEnd:returnCode:contextInfo:),
						  NULL, NULL, inf, nil);
	}
}

- (IBAction)menuAddDaemon:(id)sender {
	[daemonSheetCtrl prepareForAddDaemon];											// clean main values
	[NSApp beginSheet:[daemonSheetCtrl sheet]
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:@"menuAddDaemon"];
}

- (IBAction)menuDaemonSettings:(id)sender {
	[daemonSheetCtrl prepareForSettingsChangeWithDaemon:[self selectedDaemon]];		// select tab for selected daemon type
	[NSApp beginSheet:[daemonSheetCtrl sheet]
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:@"menuDaemonSettings"];
}

- (IBAction)menuRemoveDaemon:(id)sender {
	NSString *msg = [NSString stringWithFormat:@"Do you really want to remove %@ daemon registration?",
					 [[self selectedDaemon] description]];
	NSString *inf = @"All registration data will be lost.";
	NSBeginAlertSheet(msg, @"OK", @"Cancel", nil,
					  [NSApp mainWindow], self,
					  @selector(sheetDidEnd:returnCode:contextInfo:),
					  NULL, @"menuRemoveDaemon", inf, nil);
}

- (IBAction)menuPauseTorrent:(id)sender {
	[self resumeSelectedTorrents:NO];
}

- (IBAction)menuResumeTorrent:(id)sender {
	[self resumeSelectedTorrents:YES];
}

- (void)resumeSelectedTorrents:(BOOL)flag {
	NSMutableDictionary *_daemons = [NSMutableDictionary dictionary];				// dictionary for storing array of torrents to change state
	NSArray *torrents = [self selectedTorrents];									// array for torrents to pause
	for (TorrentData *torrent in torrents) {
		NSNumber *index = [NSNumber numberWithInteger:								// get daemon index in collection
						   [[daemons daemons] indexOfObject:
							[torrent parentObject]]];
		if ([_daemons objectForKey:index] == nil)									// check for daemon
			[_daemons setObject:[NSMutableArray array] forKey:index];
		[[_daemons objectForKey:index] addObject:torrent];							// add torrent for daemon
	}
	for (NSNumber *index in _daemons) {												// do command for every daemon
		RemoteDaemon *daemon = [[daemons daemons]
								objectAtIndex:[index integerValue]];
		if (flag)
			[daemon resumeTorrents:[_daemons objectForKey:index]];
		else
			[daemon pauseTorrents:[_daemons objectForKey:index]];
	}
}

- (IBAction)menuRemoveTorrent:(id)sender {
	[self removeSelectedTorrentsWithData:NO];
}

- (IBAction)menuRemoveTorrentWithData:(id)sender {
	[self removeSelectedTorrentsWithData:YES];
}

- (void)removeSelectedTorrentsWithData:(BOOL)flag {
	
	// TODO we should ask user about torrent removing
	
	NSMutableDictionary *_daemons = [NSMutableDictionary dictionary];				// dictionary for storing array of torrents to change state
	NSArray *torrents = [self selectedTorrents];									// array for torrents to pause
	for (TorrentData *torrent in torrents) {
		NSNumber *index = [NSNumber numberWithInteger:								// get daemon index in collection
						   [[daemons daemons] indexOfObject:
							[torrent parentObject]]];
		if ([_daemons objectForKey:index] == nil)									// check for daemon
			[_daemons setObject:[NSMutableArray array] forKey:index];
		[[_daemons objectForKey:index] addObject:torrent];							// add torrent for daemon
	}
	for (NSNumber *index in _daemons) {												// do command for every daemon
		RemoteDaemon *daemon = [[daemons daemons]
								objectAtIndex:[index integerValue]];
		[daemon removeTorrents:[_daemons objectForKey:index] withData:flag];
	}
}

- (IBAction)menuAddTorrentFromFile:(id)sender {
	NSArray *fileTypes = [NSArray arrayWithObjects:@"torrent", nil];

	NSOpenPanel *openDlg = [NSOpenPanel openPanel];
	[openDlg setAllowsMultipleSelection:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setCanChooseFiles:YES];
	
	[openDlg beginSheetForDirectory:nil
							   file:nil
							  types:fileTypes
					 modalForWindow:[NSApp mainWindow]
					  modalDelegate:self
					 didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
						contextInfo:@"menuAddTorrentFromFile"];
}

- (IBAction)menuAddTorrentFromLink:(id)sender {
}

#pragma mark Outline and table view methods and notifications.

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	id source = nil;																// data source
	id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];			// get selected item
	
	// calculate data source and filter for right table view
	if ([selectedItem isKindOfClass:[TorrentFilter class]]) {						// filter selected
		source = [selectedItem parentObject];
		[source setFilterIndex:[selectedItem filterType]];
	} else if ([selectedItem isKindOfClass:[RemoteDaemon class]]) {					// specific torrent selected
		source = selectedItem;
		[source setFilterIndex:FILTER_TYPE_ALL];
	}
	
	// update right table view
	if ([tableView dataSource] == nil) {
		[tableView setDataSource:source];
	} else {
		[tableView setDataSource:source];
		[tableView deselectAll:self];
		[tableView reloadData];
	}
}

- (void)outlineViewReloadWithGroupsExpanding {
	[outlineView reloadData];
	NSArray *groupItems = [daemons groups];
	for (id item in groupItems)
		[outlineView expandItem:item];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
}

#pragma mark Torrents data was chaged.

- (void)daemonDataWillChange:(NSNotification *)notification {
	torrentSelection = [[NSMutableIndexSet alloc]									// remember current selection
						initWithIndexSet:[tableView selectedRowIndexes]];
}

- (void)daemonDataDidChange:(NSNotification *)notification {
	[tableView reloadData];															// reloading data
	[tableView selectRowIndexes:torrentSelection									// set new selection
		   byExtendingSelection:NO];
	[torrentSelection release];														// release selection
	[toolbarView validateVisibleItems];												// validate items for better performance
}

- (void)torrentWillRemoveFromFilter:(NSNotification *)notification {
	TorrentFilter *selectedFilter = [[tableView dataSource] currentFilter];			// check if current table view
	TorrentFilter *notifiedFilter = [[notification object] objectAtIndex:0];		//	data source filter is equal
	if ([selectedFilter isEqualTo:notifiedFilter]) {								//	to notification filter
		NSInteger index = [[[notification object] objectAtIndex:1] integerValue];	// get torrent index
		[torrentSelection removeIndex:index];										// remove index
		[torrentSelection shiftIndexesStartingAtIndex:index + 1						// shift indexes
												   by:-1];
	}
}

#pragma mark Split delegate methods.

- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset {
	NSRect frame = [sender frame];
	
	if ([sender isVertical]) {
		if (proposedPosition < VSPLIT_MIN_LEFT)										// check left view constrains
			proposedPosition = VSPLIT_MIN_LEFT;
		if (proposedPosition > frame.size.width - proposedPosition)					// check right view constrains
			proposedPosition = frame.size.width / 2.;
		if ((frame.size.width - proposedPosition) < VSPLIT_MIN_RIGHT)
			proposedPosition = frame.size.width - VSPLIT_MIN_RIGHT;
	}
	return proposedPosition;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSRect newFrame = [sender frame];												// get new frame
	float divider = [sender dividerThickness];										// devider thickness
	
	if ([sender isVertical]) {														// if vertical splitter
		NSRect leftFrame, rightFrame;
		NSView *leftView, *rightView;
		
		leftView = [[sender subviews] objectAtIndex:0];								// get views
		rightView = [[sender subviews] objectAtIndex:1];
		leftFrame = [leftView frame];												// get views frames
		rightFrame = [rightView frame];
		
		leftFrame.size.height = newFrame.size.height;								// adjusting views height
		rightFrame.size.height = newFrame.size.height;
		
		if (newFrame.size.width < oldSize.width) {									// do left view adjust
			if (leftFrame.size.width > rightFrame.size.width)
				leftFrame.size.width = rightFrame.size.width;
			if (rightFrame.size.width < VSPLIT_MIN_RIGHT)
				leftFrame.size.width = newFrame.size.width - VSPLIT_MIN_RIGHT;
		}
		
		rightFrame.origin.x = leftFrame.size.width + divider;						// adjust rigth view
		rightFrame.size.width = newFrame.size.width - (leftFrame.size.width + divider);								
		
		[leftView setFrame:leftFrame];												// tile
		[rightView setFrame:rightFrame];
	} else {																		// in case of horizontal splitter
		[sender adjustSubviews];
	}
}


#pragma mark Application behaviour on exit.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSData *encodedDataModel = [NSKeyedArchiver archivedDataWithRootObject:daemons];	// encoding data model
	[[NSUserDefaults standardUserDefaults] setObject:encodedDataModel					// saving as user preferences
											  forKey:@"DaemonsData"];
	return NSTerminateNow;
}

#pragma mark Deallocation.

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[daemons release];
	[super dealloc];
}

@end
