#import <Cocoa/Cocoa.h>

@class RemoteDaemon;

@interface TorrentProgressController : NSObject {
	IBOutlet NSWindow *sheet;									// main window
	IBOutlet NSTextField *daemonTitle;							// daemon title
	IBOutlet NSTextField *fileName;								// file name
	IBOutlet NSProgressIndicator *progress;						// progress
	
	NSArray *torrentURLs;										// torrent urls
	RemoteDaemon *daemon;										// daemon
	NSUInteger curIndex;										// index of current torrent
	
	NSMutableArray *errorData;									// errors dist (URL, message)
	NSUInteger lastTorrentsCount;								// count of torrents
}

- (void)beginAddTorrents:(NSArray *)anURLs forDaemon:(RemoteDaemon *)aDaemon;			// begin torrent add
- (void)torrentDidAddWithResult:(NSInteger)result errorMessage:(NSString *)msg;			// torrent add result
- (void)perfromTorrentAddOperation;														// call daemon add method

// properties
@property (nonatomic, readonly) IBOutlet NSWindow *sheet;
@property (nonatomic, readonly) NSMutableArray *errorData;
@property (nonatomic, readonly) NSUInteger lastTorrentsCount;

@end
