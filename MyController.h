#import <Cocoa/Cocoa.h>

@class MyOutlineView;

@class DaemonCollection;
@class DaemonSheetController;
@class TorrentProgressController;
@class TorrentFilter;
@class RemoteDaemon;

@interface MyController : NSObject {
	// data model
	DaemonCollection *daemons;									// daemons
	
	// main views
    IBOutlet MyOutlineView *outlineView;						// outline view (left)
	IBOutlet NSTableView *tableView;							// table view (right top)
	IBOutlet NSToolbar *toolbarView;							// main toolbar
	
	// controllers
	IBOutlet DaemonSheetController *daemonSheetCtrl;			// controller for daemon sheet
	IBOutlet TorrentProgressController *torrentProgressSheet;	// controller for progress sheet
	
	// working with selection in table view
	NSMutableIndexSet *torrentSelection;
}

// get data from outline and table view
- (RemoteDaemon *)selectedDaemon;
- (NSArray *)selectedTorrents;

// menu actions
- (IBAction)menuAddDaemon:(id)sender;							// showing add daemon sheet
- (IBAction)menuRemoveDaemon:(id)sender;						// remove selected daemon
- (IBAction)menuDaemonSettings:(id)sender;						// daemon connection settings

- (IBAction)menuPauseTorrent:(id)sender;						// pause selected torrents
- (IBAction)menuResumeTorrent:(id)sender;						// resume selected torrents

- (IBAction)menuRemoveTorrent:(id)sender;						// remove selected torrents
- (IBAction)menuRemoveTorrentWithData:(id)sender;				// remove selected torrents (with data)

- (void)removeSelectedTorrentsWithData:(BOOL)flag;				// remove selected torrents

- (IBAction)menuAddTorrentFromFile:(id)sender;					// adding torrent from file
- (IBAction)menuAddTorrentFromLink:(id)sender;					// adding torrent from link

- (void)resumeSelectedTorrents:(BOOL)flag;						// resumse or pause selected torrents

// methods for outline view
- (void)outlineViewReloadWithGroupsExpanding;					// reloading outline view

// notifications of torrents changes
- (void)daemonDataWillChange:(NSNotification *)notification;
- (void)daemonDataDidChange:(NSNotification *)notification;
- (void)torrentWillRemoveFromFilter:(NSNotification *)notification;

@end
