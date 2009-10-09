#import "TransmissionTabController.h"

@implementation TransmissionTabController

@synthesize daemonAddress;
@synthesize daemonPassflag;
@synthesize daemonPassword;
@synthesize daemonPort;
@synthesize daemonTimeout;
@synthesize daemonUsername;
@synthesize proxyAddress;
@synthesize proxyPassflag;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyPreftype;
@synthesize proxyUsername;

- (IBAction)daemonPasswordChanged:(id)sender {
	BOOL enabled = ([daemonPassflag state] == NSOnState);
	[daemonUsername setEnabled:enabled];
	[daemonPassword setEnabled:enabled];
}

- (IBAction)proxyPasswordOrTypeChanged:(id)sender {
	BOOL enabled01 = ([proxyPreftype selectedTag] == TRANSMISSION_PROXY_TYPE_MANUAL);
	[proxyPassflag setEnabled:enabled01];
	[proxyAddress setEnabled:enabled01];
	[proxyPort setEnabled:enabled01];
	
	BOOL enabled02 = ([proxyPassflag state] == NSOnState);
	[proxyUsername setEnabled:(enabled01 & enabled02)];
	[proxyPassword setEnabled:(enabled01 & enabled02)];
}

@end
