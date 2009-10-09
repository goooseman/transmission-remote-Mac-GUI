#import "TorrentProgressController.h"
#import "RemoteDaemon.h";

@implementation TorrentProgressController

@synthesize sheet;
@synthesize errorData;
@synthesize lastTorrentsCount;

- (void)awakeFromNib {
	errorData = [[NSMutableArray alloc] init];
}

- (void)beginAddTorrents:(NSArray *)anURLs forDaemon:(RemoteDaemon *)aDaemon {
	[errorData removeAllObjects];														// reset error
	torrentURLs = [anURLs retain];														// remember torrents
	lastTorrentsCount = [anURLs count];													// torrents count
	daemon = aDaemon;																	// remember daemon
	curIndex = 0;
	
	[daemonTitle setStringValue:[aDaemon title]];										// set daemon title
	[progress startAnimation:self];														// start animation

	[self performSelector:@selector(perfromTorrentAddOperation)							// begin torrent add
			   withObject:nil];
}

- (void)perfromTorrentAddOperation {
	NSURL *torrentURL = [torrentURLs objectAtIndex:curIndex];
	[fileName setStringValue:[torrentURL isFileURL] ?									// set file name
	 [torrentURL relativePath] : [torrentURL description]];
	[daemon addTorrent:torrentURL delegate:self											// do torrent add
		   endSelector:@selector(torrentDidAddWithResult:errorMessage:)];
}

- (void)torrentDidAddWithResult:(NSInteger)result errorMessage:(NSString *)msg {
	if (result != TORRENT_ADD_SUCCESS) {												// check for result
		NSArray *keys = [NSArray arrayWithObjects:@"URL", @"message", nil];
		NSArray *objects = [NSArray arrayWithObjects:
							[torrentURLs objectAtIndex:curIndex],
							msg, nil];
		NSDictionary *data = [NSDictionary dictionaryWithObjects:objects
														 forKeys:keys];
		[errorData addObject:data];
	}

	curIndex = curIndex + 1;															// check for return
	if (curIndex >= [torrentURLs count]) {
		[progress stopAnimation:self];													// stop everything
		[torrentURLs release];
		torrentURLs = nil;

		[NSApp endSheet:sheet returnCode:												// return
		 ([errorData count] ? NSAlertErrorReturn : NSAlertDefaultReturn)];
		return;
	}
	
	[self performSelector:@selector(perfromTorrentAddOperation)							// begin torrent add
			   withObject:nil];
}

- (void)dealloc {
	[torrentURLs release];
	[errorData release];
	[super dealloc];
}

@end
