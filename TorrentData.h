#import <Cocoa/Cocoa.h>

// status definitions from transmission sources
#define STATUS_UNKNOWN 0 // unknown status
#define STATUS_CHECK_WAIT 1 // waiting in queue to check files
#define STATUS_CHECK 2 // checking files
#define STATUS_DOWNLOAD 4 // downloading
#define STATUS_SEED 8 // seeding
#define STATUS_STOPPED 16 // torrent is stopped

@class RemoteDaemon;

@interface TorrentData : NSObject {
	RemoteDaemon *parentObject; // daemon
	
	NSString *uniqueId; // unique identifier
	NSString *title; // torrent title (name i mean)
	NSNumber *totalSize; // torrent data total size in bytes
	NSNumber *haveValid; // valid size in bytes
	NSNumber *haveUnchecked; // unchecked size in bytes
	NSUInteger status; // current status (downloading, seeding, verifying, paused, ...)
	NSUInteger seedsActive; // seeds (those you download from)
	NSUInteger peersActive; // peers count (those you give to)
	NSUInteger downloadSpeed; // download speed in bytes per second
	NSUInteger uploadSpeed; // upload speed in bytes per second
	NSInteger eta; // time in seconds until finished (could be negative)
	NSNumber *uploaded; // uploaded data in bytes
}

// initialization
- (id)initWithDaemon:(RemoteDaemon *)aDaemon uniqueId:(NSString *)aUniqueId;

// convert number into string
- (NSString *)stringFromULongLong:(unsigned long long)num;

@property (nonatomic, assign) RemoteDaemon *parentObject;
@property (nonatomic, readonly) NSString *uniqueId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *totalSize;
@property (nonatomic, copy) NSNumber *haveValid;
@property (nonatomic, copy) NSNumber *haveUnchecked;
@property (nonatomic) NSUInteger status;
@property (nonatomic) NSUInteger seedsActive;
@property (nonatomic) NSUInteger peersActive;
@property (nonatomic) NSUInteger downloadSpeed;
@property (nonatomic) NSUInteger uploadSpeed;
@property (nonatomic) NSInteger eta;
@property (nonatomic, copy) NSNumber *uploaded;

@property (nonatomic, readonly) NSString *stringTotalSize;
@property (nonatomic, readonly) NSString *stringDownloadSpeed;
@property (nonatomic, readonly) NSString *stringUploadSpeed;
@property (nonatomic, readonly) NSString *stringStatus;
@property (nonatomic, readonly) NSString *stringETA;
@property (nonatomic, readonly) NSString *stringUploaded;
@property (nonatomic, readonly) NSNumber *numberDone;

@property (nonatomic, readonly) NSUInteger filterType;

@end
