#import <Cocoa/Cocoa.h>
#import "RemoteDaemon.h"

@interface DaemonTransmission : RemoteDaemon <NSCoding> {
	
	// daemon settings
	NSString *daemonAddress; // daemon address
	NSString *daemonUsername; // user name for access
	NSString *daemonPassword; // password
	NSInteger daemonTimeout; // operation timeout
	NSInteger daemonPort; // daemon port to access
	BOOL daemonPassflag; // needs password to access
	
	// proxy settings
	NSString *proxyAddress; // proxy address
	NSString *proxyUsername; // proxy user name
	NSString *proxyPassword; // proxy password
	NSInteger proxyPreftype; // proxy settings type
	NSInteger proxyPort; // proxy port to access
	BOOL proxyPassflag; // is proxy needs password
	
	// current session identifier
	NSString *sessionId;

	// update of torrent list and torrent basic data
	CFReadStreamRef torrentListUpdateStream; // update stream for torrent list
	NSMutableData *torrentListUpdateData; // server response
	NSDate *torrentListUpdateTime; // the time when update has been started
	
	// process torrent add
	CFReadStreamRef torrentAddStream; // http stream
	NSMutableData *torrentAddData; // server response
	SEL torrentAddEndSelector; // selector
	id torrentAddDelegate; // delegate
	
	// process torrent commands (pause/resume, remove, remove data)
	NSMutableDictionary *torrentMethodDict; // dictionary for storing pending requests
}

// request callback
- (void)handleEventHasBytesAvailableForStream:(CFReadStreamRef)stream;
- (void)handleEventEndEncounteredForStream:(CFReadStreamRef)stream;
- (void)handleEventErrorOccurredForStream:(CFReadStreamRef)stream;
- (void)handleEventTimeoutOccurredForStream:(id)streamObject;

// updating torrents with received information
- (void)updateTorrentsWithDataReceived:(void *)jsonRoot;


@property (nonatomic, copy) NSString *daemonAddress;
@property (nonatomic, copy) NSString *daemonUsername;
@property (nonatomic, copy) NSString *daemonPassword;
@property (nonatomic) NSInteger daemonTimeout;
@property (nonatomic) NSInteger daemonPort;
@property (nonatomic) BOOL daemonPassflag;

@property (nonatomic, copy) NSString *proxyAddress;
@property (nonatomic, copy) NSString *proxyUsername;
@property (nonatomic, copy) NSString *proxyPassword;
@property (nonatomic) NSInteger proxyPreftype;
@property (nonatomic) NSInteger proxyPort;
@property (nonatomic) BOOL proxyPassflag;

@property (nonatomic, retain) NSString *sessionId;

@end
