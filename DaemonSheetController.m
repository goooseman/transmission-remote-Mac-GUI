#import "DaemonSheetController.h"
#import "DaemonTransmission.h"

@implementation DaemonSheetController

@synthesize sheet;

- (void)awakeFromNib {
	[toolbar setSelectedItemIdentifier:
	 [[[toolbar items] objectAtIndex:0]
	  itemIdentifier]];
}

- (IBAction)endSheet:(id)sender {
	[NSApp endSheet:sheet returnCode:[sender tag]];
}

- (IBAction)selectDaemonType:(id)sender {
	[tabs selectTabViewItemAtIndex:[sender tag]];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)_toolbar {
	return [[_toolbar items] valueForKey:@"itemIdentifier"];
}

- (RemoteDaemon *)newDaemonFromSelectedTab {
	RemoteDaemon *daemon = nil;
	NSTabViewItem *tabItem = [tabs selectedTabViewItem];						// get the selected tab view item
	NSString *className = [tabItem identifier];									// item identifier (class name)
	if ([className isEqualToString:@"DaemonTransmission"])
		daemon = [[DaemonTransmission alloc] initWithTitle:[title stringValue]
										   updateFrequency:[refresh integerValue]
												controller:daemonTransmission];
	return daemon;
}

- (void)updateSettingsForDaemon:(RemoteDaemon *)daemon {
	[daemon stopAllDaemonOperations];
	NSTabViewItem *tabItem = [tabs selectedTabViewItem];						// get the selected tab view item
	NSString *className = [tabItem identifier];									// item identifier (class name)
	if ([className isEqualToString:@"DaemonTransmission"])
		[daemon initWithTitle:[title stringValue]
			  updateFrequency:[refresh integerValue]
				   controller:daemonTransmission];
	[daemon startDaemonUpdateProcess];
}

- (void)prepareForAddDaemon {
	[sheet setTitle:@"Add Daemon"];												// window title
	NSArray *toolbarItemsArray = [toolbar items]; 
	for (NSToolbarItem *item in toolbarItemsArray) {							// enable all toolbar items
		[item setAutovalidates:YES];
		[item setEnabled:YES];
	}
	[refresh setIntegerValue:[[NSUserDefaults standardUserDefaults]				// fill default value for refresh rate
							  integerForKey:@"RefreshFrequency"]];
	[title setStringValue:@""];													// default value for daemon title
	
	// TODO fill with default settings
}

- (void)prepareForSettingsChangeWithDaemon:(RemoteDaemon *)daemon {
	[sheet setTitle:@"Daemon Settings"];										// window title

	NSString *className = [daemon className];
	[tabs selectTabViewItemWithIdentifier:className];							// select tab
	NSTabViewItem *tabItem = [tabs selectedTabViewItem];						// get tab selected
	NSInteger tabItemIndex = [tabs indexOfTabViewItem:tabItem];					// get index of selected tab

	NSArray *toolbarItemsArray = [toolbar items]; 
	for (NSToolbarItem *item in toolbarItemsArray) {							// disable toolbar items except selected one
		if ([item tag] == tabItemIndex)											// select item
			[toolbar setSelectedItemIdentifier:[item itemIdentifier]];
		else {																	// disable item
			[item setAutovalidates:NO];
			[item setEnabled:NO];
		}
	}
	
	// fill base values
	[title setStringValue:[daemon title]];
	[refresh setIntegerValue:[daemon frequency]];
	if ([className isEqualToString:@"DaemonTransmission"])						// fill tab with daemon values
		[daemon saveDaemonSettingsToController:daemonTransmission];
}

@end
