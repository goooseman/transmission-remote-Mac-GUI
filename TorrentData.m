#import "TorrentData.h"
#import "TorrentFilter.h"

@implementation TorrentData

@synthesize parentObject;

@synthesize uniqueId;
@synthesize title;
@synthesize totalSize;
@synthesize haveValid;
@synthesize haveUnchecked;
@synthesize status;
@synthesize seedsActive;
@synthesize peersActive;
@synthesize downloadSpeed;
@synthesize uploadSpeed;
@synthesize eta;
@synthesize uploaded;

@dynamic stringTotalSize;
@dynamic stringDownloadSpeed;
@dynamic stringUploadSpeed;
@dynamic stringStatus;
@dynamic stringETA;
@dynamic stringUploaded;
@dynamic numberDone;

@dynamic filterType;

- (id)initWithDaemon:(RemoteDaemon *)aDaemon uniqueId:(NSString *)aUniqueId {
	if (self = [super init]) {
		[self setParentObject:aDaemon];
		uniqueId = [[NSString alloc] initWithString:aUniqueId];
		[self setStatus:STATUS_UNKNOWN];
	}
	return self;
}

- (NSString *)stringFromULongLong:(unsigned long long)num {
	if (num < 1024)
		return [NSString stringWithFormat:@"%llu B", num];
	else if (num < 1048576)
		return [NSString stringWithFormat:@"%.2f KB", num / 1024.0];
	else if (num < 1073741824)
		return [NSString stringWithFormat:@"%.2f MB", num / 1048576.0];
	return [NSString stringWithFormat:@"%.2f GB", num / 1073741824.0];
}

- (NSString *)stringTotalSize {
	return [self stringFromULongLong:[[self totalSize] unsignedLongLongValue]];
}

- (NSString *)stringDownloadSpeed {
	if ([self downloadSpeed] != 0)
		return [NSString stringWithFormat:@"%@/s",
				[self stringFromULongLong:[self downloadSpeed]]];
	return nil;
}

- (NSString *)stringUploadSpeed {
	if ([self uploadSpeed] != 0)
		return [NSString stringWithFormat:@"%@/s",
				[self stringFromULongLong:[self uploadSpeed]]];
	return nil;
}

- (NSString *)stringUploaded {
	return [self stringFromULongLong:[[self uploaded] unsignedLongLongValue]];
}

- (NSString *)stringETA {
	NSInteger _eta = [self eta];
	if (_eta < 0)
		return nil;
	else if (_eta < 60)
		return [NSString stringWithFormat:@"%u sec", _eta];
	else if (_eta < 3600)
		return [NSString stringWithFormat:@"%.1f min", _eta / 60.];
	else if (_eta < 86400)
		return [NSString stringWithFormat:@"%.1f hrs", _eta / 3600.];
	return [NSString stringWithFormat:@"%.1f days", _eta / 86400.];
}

- (NSString *)stringStatus {
	if ([self status] == STATUS_CHECK_WAIT)
		return @"Waiting";
	if ([self status] == STATUS_CHECK)
		return @"Verifying";
	if ([self status] == STATUS_DOWNLOAD)
		return @"Downloading";
	if ([self status] == STATUS_SEED)
		return @"Seeding";
	if ([self status] == STATUS_STOPPED)
		return @"Paused";
	return @"Unknown";
}

- (NSNumber *)numberDone {
	unsigned long long totalHave = [haveValid unsignedLongLongValue] + [haveUnchecked unsignedLongLongValue];
	return [NSNumber numberWithFloat:(totalHave / (double)[totalSize unsignedLongLongValue]) * 100.];
}

- (NSUInteger)filterType {
	if ([self status] == STATUS_CHECK_WAIT || [self status] == STATUS_CHECK)
		return FILTER_TYPE_VERIFYING;
	if ([self status] == STATUS_DOWNLOAD)
		return FILTER_TYPE_DOWNLOADING;
	if ([self status] == STATUS_SEED)
		return FILTER_TYPE_COMPLETED;
	if ([self status] == STATUS_STOPPED)
		return FILTER_TYPE_INACTIVE;
	return FILTER_TYPE_ALL;
}

- (void)dealloc {
	NSLog(@"dealloc: %@", self);

	[title release];
	[totalSize release];
	[haveValid release];
	[haveUnchecked release];
	[uniqueId release];
	[uploaded release];
	[super dealloc];
}

@end
