#import <Cocoa/Cocoa.h>

@class RemoteDaemon;
@class TransmissionTabController;

@interface DaemonSheetController : NSObject {
	IBOutlet NSWindow *sheet;									// main window
	IBOutlet NSTextField *title;								// daemon title
    IBOutlet NSTextField *refresh;								// refresh rate
	IBOutlet NSToolbar *toolbar;								// toolbar for sheet
	IBOutlet NSTabView *tabs;									// tab view
	
	// Controllers outlets.
	IBOutlet TransmissionTabController *daemonTransmission;		// controller for transmission tab
}

// end sheet action
- (IBAction)endSheet:(id)sender;

// select daemon tab (from toolbar)
- (IBAction)selectDaemonType:(id)sender;

// message allocates new initialized RemoteDaemon class implementation
- (RemoteDaemon *)newDaemonFromSelectedTab;

// daemon settings update
- (void)updateSettingsForDaemon:(RemoteDaemon *)daemon;

// cleanup sheet with default values
- (void)prepareForAddDaemon;

// select tab and fill it with data
- (void)prepareForSettingsChangeWithDaemon:(RemoteDaemon *)daemon;

// properties
@property (nonatomic, readonly) IBOutlet NSWindow *sheet;

@end
