#import "TorrentFilter.h"

@implementation TorrentFilter

@synthesize parentObject;
@synthesize filterType;

- (id)initWithType:(NSInteger)aType parent:(id)aParent {
	if (self = [super init]) {
		[self setParentObject:aParent];
		[self setFilterType:aType];
	}
	return self;
}

- (NSString *)description {
	if ([self filterType] == FILTER_TYPE_ALL)
		return @"All";
	if ([self filterType] == FILTER_TYPE_VERIFYING)
		return @"Verifying";
	if ([self filterType] == FILTER_TYPE_DOWNLOADING)
		return @"Downloading";
	if ([self filterType] == FILTER_TYPE_COMPLETED)
		return @"Seeding";
	if ([self filterType] == FILTER_TYPE_INACTIVE)
		return @"Paused";
	return nil;
}

- (void)dealloc {
	NSLog(@"dealloc: %@", self);

	[super dealloc];
}

@end
