#import <Cocoa/Cocoa.h>

#define TRANSMISSION_PROXY_TYPE_DETECT 1
#define TRANSMISSION_PROXY_TYPE_DIRECT 2
#define TRANSMISSION_PROXY_TYPE_MANUAL 3

@interface TransmissionTabController : NSObject {
    IBOutlet NSTextField *daemonAddress;
    IBOutlet NSButton *daemonPassflag;
    IBOutlet NSTextField *daemonPassword;
    IBOutlet NSTextField *daemonPort;
    IBOutlet NSTextField *daemonTimeout;
    IBOutlet NSTextField *daemonUsername;
    IBOutlet NSTextField *proxyAddress;
    IBOutlet NSButton *proxyPassflag;
    IBOutlet NSTextField *proxyPassword;
    IBOutlet NSTextField *proxyPort;
    IBOutlet NSMatrix *proxyPreftype;
    IBOutlet NSTextField *proxyUsername;
}

// actions
- (IBAction)daemonPasswordChanged:(id)sender;
- (IBAction)proxyPasswordOrTypeChanged:(id)sender;

// properties
@property (nonatomic, readonly) IBOutlet NSTextField *daemonAddress;
@property (nonatomic, readonly) IBOutlet NSButton *daemonPassflag;
@property (nonatomic, readonly) IBOutlet NSTextField *daemonPassword;
@property (nonatomic, readonly) IBOutlet NSTextField *daemonPort;
@property (nonatomic, readonly) IBOutlet NSTextField *daemonTimeout;
@property (nonatomic, readonly) IBOutlet NSTextField *daemonUsername;
@property (nonatomic, readonly) IBOutlet NSTextField *proxyAddress;
@property (nonatomic, readonly) IBOutlet NSButton *proxyPassflag;
@property (nonatomic, readonly) IBOutlet NSTextField *proxyPassword;
@property (nonatomic, readonly) IBOutlet NSTextField *proxyPort;
@property (nonatomic, readonly) IBOutlet NSMatrix *proxyPreftype;
@property (nonatomic, readonly) IBOutlet NSTextField *proxyUsername;

@end
