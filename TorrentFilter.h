#import <Cocoa/Cocoa.h>

#define FILTER_TYPE_ALL 0
#define FILTER_TYPE_VERIFYING 1
#define FILTER_TYPE_DOWNLOADING 2
#define FILTER_TYPE_COMPLETED 3
#define FILTER_TYPE_INACTIVE 4
#define FILTER_TYPE_COUNT 5

@interface TorrentFilter : NSObject {
	id parentObject; // parent object (daemon collection or daemon)
	NSInteger filterType; // filter type
}

// initialization
- (id)initWithType:(NSInteger)aType parent:(id)aParent;

// description
- (NSString *)description;

@property (nonatomic, assign) id parentObject; // weak link
@property (nonatomic) NSInteger filterType;

@end
