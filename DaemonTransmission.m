#include <SystemConfiguration/SystemConfiguration.h>

#import "DaemonTransmission.h"
#import "TransmissionTabController.h"
#import "TorrentData.h"

#import "base64.h"
#import "json_escape.h"
#import "json.h"

// function definition
void responseLoadCallback(CFReadStreamRef stream, CFStreamEventType type, void *info);

@implementation DaemonTransmission

@synthesize daemonAddress;
@synthesize daemonUsername;
@synthesize daemonPassword;
@synthesize daemonTimeout;
@synthesize daemonPort;
@synthesize daemonPassflag;

@synthesize proxyAddress;
@synthesize proxyUsername;
@synthesize proxyPassword;
@synthesize proxyPreftype;
@synthesize proxyPort;
@synthesize proxyPassflag;

 @synthesize sessionId;

- (id)initWithTitle:(NSString *)aTitle updateFrequency:(NSUInteger)aFrequency controller:(id)aController {
	if (self = [super initWithTitle:aTitle updateFrequency:aFrequency]) {
		TransmissionTabController *ctrl = (TransmissionTabController *)aController;

		// set initial values for daemon
		[self setDaemonAddress:[[ctrl daemonAddress] stringValue]];
		[self setDaemonPort:[[ctrl daemonPort] integerValue]];
		[self setDaemonUsername:[[ctrl daemonUsername] stringValue]];
		[self setDaemonPassword:[[ctrl daemonPassword] stringValue]];
		[self setDaemonTimeout:[[ctrl daemonTimeout] integerValue]];
		[self setDaemonPassflag:[[ctrl daemonPassflag] integerValue]];
		
		// settings for proxy
		[self setProxyPreftype:[[ctrl proxyPreftype] selectedTag]];
		[self setProxyAddress:[[ctrl proxyAddress] stringValue]];
		[self setProxyPort:[[ctrl proxyPort] integerValue]];
		[self setProxyUsername:[[ctrl proxyUsername] stringValue]];
		[self setProxyPassword:[[ctrl proxyPassword] stringValue]];
		[self setProxyPassflag:[[ctrl proxyPassflag] integerValue]];
		
		// initialization
		torrentMethodDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		// values for daemon
		[self setDaemonAddress:[coder decodeObjectForKey:@"daemonAddress"]];
		[self setDaemonPort:[coder decodeIntegerForKey:@"daemonPort"]];
		[self setDaemonUsername:[coder decodeObjectForKey:@"daemonUsername"]];
		[self setDaemonPassword:[coder decodeObjectForKey:@"daemonPassword"]];
		[self setDaemonTimeout:[coder decodeIntegerForKey:@"daemonTimeout"]];
		[self setDaemonPassflag:[coder decodeBoolForKey:@"daemonPassflag"]];

		// settings for proxy
		[self setProxyPreftype:[coder decodeIntegerForKey:@"proxyPreftype"]];
		[self setProxyAddress:[coder decodeObjectForKey:@"proxyAddress"]];
		[self setProxyPort:[coder decodeIntegerForKey:@"proxyPort"]];
		[self setProxyUsername:[coder decodeObjectForKey:@"proxyUsername"]];
		[self setProxyPassword:[coder decodeObjectForKey:@"proxyPassword"]];
		[self setProxyPassflag:[coder decodeBoolForKey:@"proxyPassflag"]];

		// initialization
		torrentMethodDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	// encoding base values
	[super encodeWithCoder:coder];
	
	// encoding daemon values
	[coder encodeObject:[self daemonAddress] forKey:@"daemonAddress"];
    [coder encodeInteger:[self daemonPort] forKey:@"daemonPort"];
	[coder encodeObject:[self daemonUsername] forKey:@"daemonUsername"];
	[coder encodeObject:[self daemonPassword] forKey:@"daemonPassword"];
    [coder encodeInteger:[self daemonTimeout] forKey:@"daemonTimeout"];
	[coder encodeBool:[self daemonPassflag] forKey:@"daemonPassflag"];

	// encoding proxy values
    [coder encodeInteger:[self proxyPreftype] forKey:@"proxyPreftype"];
    [coder encodeObject:[self proxyAddress] forKey:@"proxyAddress"];
    [coder encodeInteger:[self proxyPort] forKey:@"proxyPort"];
	[coder encodeObject:[self proxyUsername] forKey:@"proxyUsername"];
	[coder encodeObject:[self proxyPassword] forKey:@"proxyPassword"];
	[coder encodeBool:[self proxyPassflag] forKey:@"proxyPassflag"];
}

#pragma mark Fill controller with daemon settings.

- (void)saveDaemonSettingsToController:(id)aController {
	TransmissionTabController *ctrl = (TransmissionTabController *)aController;

	// set initial values for daemon
	[[ctrl daemonAddress] setStringValue:[self daemonAddress]];
	[[ctrl daemonPort] setIntegerValue:[self daemonPort]];
	[[ctrl daemonUsername] setStringValue:[self daemonUsername]];
	[[ctrl daemonPassword] setStringValue:[self daemonPassword]];
	[[ctrl daemonTimeout] setIntegerValue:[self daemonTimeout]];
	[[ctrl daemonPassflag] setIntegerValue:[self daemonPassflag]];
	[ctrl daemonPasswordChanged:self];

	// settings for proxy
	[[ctrl proxyPreftype] selectCellWithTag:[self proxyPreftype]];
	[[ctrl proxyAddress] setStringValue:[self proxyAddress]];
	[[ctrl proxyPort] setIntegerValue:[self proxyPort]];
	[[ctrl proxyUsername] setStringValue:[self proxyUsername]];
	[[ctrl proxyPassword] setStringValue:[self proxyPassword]];
	[[ctrl proxyPassflag] setIntegerValue:[self proxyPassflag]];
	[ctrl proxyPasswordOrTypeChanged:self];
}

#pragma mark Creating read stream with request body.

- (CFReadStreamRef)createReadStreamWithBody:(NSString *)bodyString {
	CFReadStreamRef result = 0;
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%i/transmission/rpc",		// create url
									   [self daemonAddress], [self daemonPort]]];
	CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)@"POST",	// create request
														  (CFURLRef)url, kCFHTTPVersion1_1);
	if ([self sessionId] != nil)																		// add necessary request headers
		CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)@"X-Transmission-Session-Id",			//	session identifier
										 (CFStringRef)[self sessionId]);
	//CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)@"Accept-Encoding",							//	deflate encoding
	//								 (CFStringRef)@"deflate");
	NSData *bodyData = [NSMutableData dataWithData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	CFHTTPMessageSetBody(request, (CFDataRef)bodyData);
	
	// create basic authentification
	if ([self daemonPassflag])
		CFHTTPMessageAddAuthentication(request, NULL, (CFStringRef)[self daemonUsername],
									   (CFStringRef)[self daemonPassword], kCFHTTPAuthenticationSchemeBasic,
									   FALSE);
	
	// create reading stream
	if ([self proxyPreftype] == TRANSMISSION_PROXY_TYPE_DETECT) {										// use global proxy settings
		CFDictionaryRef proxyDict = SCDynamicStoreCopyProxies(NULL);
		result = CFReadStreamCreateForHTTPRequest(NULL, request);
		CFReadStreamSetProperty(result, kCFStreamPropertyHTTPProxy, proxyDict);
		CFRelease(proxyDict);
	} else if ([self proxyPreftype] == TRANSMISSION_PROXY_TYPE_MANUAL) {								// manual proxy settings
		NSMutableDictionary* proxyDict = [NSMutableDictionary dictionaryWithCapacity:2];
		[proxyDict setObject:[self proxyAddress] forKey:(id)kCFStreamPropertyHTTPProxyHost];
		[proxyDict setObject:[NSNumber numberWithInt:[self proxyPort]] forKey:(id)kCFStreamPropertyHTTPProxyPort];
		if ([self proxyPassflag])
			CFHTTPMessageAddAuthentication(request, NULL, (CFStringRef)[self proxyUsername],
										   (CFStringRef)[self proxyPassword], kCFHTTPAuthenticationSchemeBasic,
										   TRUE);
		result = CFReadStreamCreateForHTTPRequest(NULL, request);
		CFReadStreamSetProperty(result, kCFStreamPropertyHTTPProxy, proxyDict);
	} else																								// direct connection
		result = CFReadStreamCreateForHTTPRequest(NULL, request);
	CFRelease(request);																					// release request
	
	// setup callback and run loop
	CFStreamClientContext callbackContext = { 0, self, NULL, NULL, NULL };
	CFReadStreamSetClient(result, kCFStreamEventHasBytesAvailable |										// setup callback
						  kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered, 
						  responseLoadCallback, &callbackContext);
	CFReadStreamScheduleWithRunLoop(result, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	return result;
}

#pragma mark Starting and releasing torrents list update.

- (void)releaseDaemonUpdateProcess {
	[NSObject cancelPreviousPerformRequestsWithTarget:self												// cancelling update
											 selector:@selector(startDaemonUpdateProcess)
											   object:nil];
	if (torrentListUpdateStream != NULL) {																// release network stream
		[NSObject cancelPreviousPerformRequestsWithTarget:self											// cancelling timeout check
												 selector:@selector(handleEventTimeoutOccurredForStream:)
												   object:(id)torrentListUpdateStream];
		CFReadStreamSetClient(torrentListUpdateStream, 0, NULL, NULL);
		CFReadStreamUnscheduleFromRunLoop(torrentListUpdateStream, CFRunLoopGetCurrent(),
										  kCFRunLoopCommonModes);
		CFRelease(torrentListUpdateStream);
		torrentListUpdateStream = NULL;
	}
	[torrentListUpdateData release];																	// release data
	torrentListUpdateData = nil;
	[torrentListUpdateTime release];																	// release timer
	torrentListUpdateTime = nil;
}

- (void)startDaemonUpdateProcess {
	NSLog(@"[%@:%i]: torrent-get: send post request", [self daemonAddress], [self daemonPort]);
	NSString *bodyString = [NSString stringWithString:													// creating request body
							@"{\"arguments\":"
							"{\"fields\":[\"id\",\"name\",\"totalSize\",\"haveValid\","
							"\"haveUnchecked\",\"status\",\"peersSendingToUs\","
							"\"peersGettingFromUs\",\"rateDownload\",\"rateUpload\","
							"\"eta\",\"uploadedEver\",\"uploadRatio\"]},"
							"\"method\":\"torrent-get\","
							"\"tag\":0}"];
	torrentListUpdateStream = [self createReadStreamWithBody:bodyString];

	// open read stream and schedule run loop
	if (CFReadStreamOpen(torrentListUpdateStream)) {													// stream opened
		torrentListUpdateData = [[NSMutableData alloc] init];											// create reqsponse data
		torrentListUpdateTime = [[NSDate alloc] init];													// remember the time of request
		[self performSelector:@selector(handleEventTimeoutOccurredForStream:)							// should handle timeout
				   withObject:(id)torrentListUpdateStream
				   afterDelay:[self daemonTimeout]];
	} else {																							// stream error
		CFStreamError error = CFReadStreamGetError(torrentListUpdateStream);
		NSLog(@"[%@:%i]: torrent-get: could not open read stream (%i, %i)",
			  [self daemonAddress], [self daemonPort], error.domain, error.error);
		[self releaseDaemonUpdateProcess];																// release data
		
		// TODO handle error
	}
}

#pragma mark Resuming, pausing and removing of torrents.

- (void)releaseMethodForAllStreams {
	for (NSString *key in torrentMethodDict) {
		NSDictionary *params = [torrentMethodDict objectForKey:key];
		CFReadStreamRef stream = (CFReadStreamRef)[params objectForKey:@"stream"];
		[NSObject cancelPreviousPerformRequestsWithTarget:self												// cancelling timeout check
												 selector:@selector(handleEventTimeoutOccurredForStream:)
												   object:(id)stream];
		CFReadStreamSetClient(stream, 0, NULL, NULL);														// releasing stream
		CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(),									
										  kCFRunLoopCommonModes);
		CFRelease(stream);
	}
	[torrentMethodDict removeAllObjects];
}

- (void)releaseMethodForStream:(CFReadStreamRef)stream {
	[torrentMethodDict removeObjectForKey:[(id)stream description]];									// remove data from dictionary
	[NSObject cancelPreviousPerformRequestsWithTarget:self												// cancelling timeout check
											 selector:@selector(handleEventTimeoutOccurredForStream:)
											   object:(id)stream];
	CFReadStreamSetClient(stream, 0, NULL, NULL);														// releasing stream
	CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(),									
									  kCFRunLoopCommonModes);
	CFRelease(stream);
}

- (void)startMethod:(NSString *)method forTorrents:(NSArray *)torrents {
	NSLog(@"[%@:%i]: %@: send post request",
		  [self daemonAddress], [self daemonPort], method);

	NSMutableArray *list = [NSMutableArray array];														// torrent ids array
	for (TorrentData *torrent in torrents)
		[list addObject:[torrent uniqueId]];
	NSString *bodyString = [NSString stringWithFormat:													// request body
							@"{\"arguments\":{\"ids\":[%@]},\"method\":\"%@\","
							"\"tag\":0}", [list componentsJoinedByString:@","],
							method];
 
	// prepare stream for torrent resuming/pausing
	CFReadStreamRef stream = [self createReadStreamWithBody:bodyString];
	if (CFReadStreamOpen(stream)) {																		// stream opened
		NSArray *keys = [NSArray arrayWithObjects:@"stream", @"method", @"torrents", @"response", nil];
		NSArray *objects = [NSArray arrayWithObjects:(id)stream, method, torrents, [NSMutableData data], nil];
		NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[torrentMethodDict setObject:params forKey:[(id)stream description]];
		[self performSelector:@selector(handleEventTimeoutOccurredForStream:)							// should handle timeout
				   withObject:(id)stream
				   afterDelay:[self daemonTimeout]];
	} else {
		CFStreamError error = CFReadStreamGetError(stream);
		NSLog(@"[%@:%i]: %@: could not open read stream (%i, %i)",
			  [self daemonAddress], [self daemonPort], method,
			  error.domain, error.error);
		[self releaseMethodForStream:stream];															// free stream data
		
		// TODO handle error
	}
 }

- (void)resumeTorrents:(NSArray *)torrents {
	[self startMethod:@"torrent-start" forTorrents:torrents];
}

- (void)pauseTorrents:(NSArray *)torrents {
	[self startMethod:@"torrent-stop" forTorrents:torrents];
}

- (void)removeTorrents:(NSArray *)torrents withData:(BOOL)flag {
	// TODO implement removing torrent
}

#pragma mark Adding new torrents.

- (void)releaseAddTorrent {
	if (torrentAddStream != NULL) {																	// release network stream
		[NSObject cancelPreviousPerformRequestsWithTarget:self										// cancelling timeout check
												 selector:@selector(handleEventTimeoutOccurredForStream:)
												   object:(id)torrentAddStream];
		CFReadStreamSetClient(torrentAddStream, 0, NULL, NULL);
		CFReadStreamUnscheduleFromRunLoop(torrentAddStream, CFRunLoopGetCurrent(),
										  kCFRunLoopCommonModes);
		CFRelease(torrentAddStream);
		torrentAddStream = NULL;
	}
	[torrentAddData release];																		// release data
	torrentAddData = nil;
}

- (void)addTorrent:(NSURL *)url delegate:(id)delegate endSelector:(SEL)endSelector {
	NSString *bodyString = nil;
	NSLog(@"[%@:%i]: torrent-add: send post request (url=%@)",
		  [self daemonAddress], [self daemonPort], url);
	if ([url isFileURL]) {
		NSData *data = [NSData dataWithContentsOfFile:[url relativePath]];							// open and read file
		if (data == nil) {
			NSString *msg = [NSString stringWithFormat:@"Unable to open torrent file \"%@\".",
							 [url relativePath]];
			[delegate performSelector:endSelector
						   withObject:(id)TORRENT_ADD_ERROR
						   withObject:msg];
			return;
		}
		
		// encode torrent into base64 and create request body
		char *encoded = NULL;
		base64_encode([data bytes], [data length], &encoded);
		bodyString = [NSString stringWithFormat:
					  @"{\"arguments\":{\"metainfo\":\"%s\"},\"method\":\"torrent-add\","
					  "\"tag\":0}", encoded];
		free(encoded);
	} else {
		[delegate performSelector:endSelector
					   withObject:(id)TORRENT_ADD_ERROR
					   withObject:@"Not implemented yet!"];
		return;
	}
	
	// prepare stream for torrent adding
	torrentAddStream = [self createReadStreamWithBody:bodyString];
	if (CFReadStreamOpen(torrentAddStream)) {
		torrentAddData = [[NSMutableData alloc] init];													// create reqsponse data
		torrentAddEndSelector = endSelector;															// remember delegate and selector
		torrentAddDelegate = delegate;

		[self performSelector:@selector(handleEventTimeoutOccurredForStream:)							// should handle timeout
				   withObject:(id)torrentAddStream
				   afterDelay:[self daemonTimeout]];
	} else {
		CFStreamError error = CFReadStreamGetError(torrentAddStream);
		NSLog(@"[%@:%i]: torrent-add: could not open read stream (%i, %i)",
			  [self daemonAddress], [self daemonPort], error.domain, error.error);
		[delegate performSelector:endSelector
					   withObject:(id)TORRENT_ADD_ERROR
					   withObject:nil];
		[self releaseAddTorrent];																		// free stream data
	}
}

#pragma mark Stopping every daemon network operation.

- (void)stopAllDaemonOperations {
	[self releaseMethodForAllStreams];
	[self releaseDaemonUpdateProcess];
	[self releaseAddTorrent];
}

#pragma mark Event handler for core foundation network.

- (void)handleEventHasBytesAvailableForStream:(CFReadStreamRef)stream {
	UInt8 buf[2048];
	CFIndex bytesRead = 0;
	CFIndex len = sizeof(buf) / sizeof(*buf);
	NSDictionary *params = nil;
	do {
		bytesRead = CFReadStreamRead(stream, buf, len);
		if (stream == torrentListUpdateStream) {
			[torrentListUpdateData appendData:
			 [NSData dataWithBytes:buf length:bytesRead]];
		} else if ((params = [torrentMethodDict objectForKey:[(id)stream description]]) != nil) {
			[[params objectForKey:@"response"] appendData:
			 [NSData dataWithBytes:buf length:bytesRead]];
		} else if (stream == torrentAddStream) {
			[torrentAddData appendData:
			 [NSData dataWithBytes:buf length:bytesRead]];
		}
	} while (bytesRead == len);
}

- (void)handleEventEndEncounteredForStream:(CFReadStreamRef)stream {	
	NSDictionary *params = nil;
	if (stream == torrentListUpdateStream) {
		float delay = fmaxf([self frequency] + [torrentListUpdateTime						// delay until next request
												timeIntervalSinceNow], 0.);
		CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
		CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(response);
		if (statusCode == 409) {															// session id not found
			[self setSessionId:[[NSString alloc] initWithString:(NSString *)
								CFHTTPMessageCopyHeaderFieldValue(response, (CFStringRef)
																  @"X-Transmission-Session-Id")]];
			NSLog(@"[%@:%i]: torrent-get: received session (id=%@)",
				  [self daemonAddress], [self daemonPort], [self sessionId]);
			delay = 0.;
		} else if (statusCode == 200) {
			NSLog(@"[%@:%i]: torrent-get: received data (length=%i)",
				  [self daemonAddress], [self daemonPort], [torrentListUpdateData length]);
			
			// TODO decode response for deflate encoding
			
			json_t *root = NULL;															// parse JSON document
			NSString *body = [NSString stringWithCString:[torrentListUpdateData bytes]
												  length:[torrentListUpdateData length]];
			if (json_parse_document(&root, (char *)[body UTF8String]) == JSON_OK) {
				[self updateTorrentsWithDataReceived:root];									// do update
				json_free_value(&root);
			}
		} else {
			NSLog(@"[%@:%i]: torrent-get: received unidentified code (status=%u)",
				  [self daemonAddress], [self daemonPort], statusCode);

			// TODO handle error
		}
		CFRelease(response);																// release response
		[self releaseDaemonUpdateProcess];													// release everything
		[self performSelector:@selector(startDaemonUpdateProcess)							// repeat the request
				   withObject:nil afterDelay:delay];
	} else if ((params = [torrentMethodDict objectForKey:[(id)stream description]]) != nil) {
		// check for response code and response result
		CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
		CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(response);
		if (statusCode == 200) {
			NSMutableData *data = [params objectForKey:@"response"];						// get data

			// TODO decode response for deflate encoding
			
			NSString *body = [NSString stringWithCString:[data bytes]						//	and convert it into string
												  length:[data length]];
			BOOL success = ([body rangeOfString:@"success"].location != NSNotFound);
			NSLog(@"[%@:%i]: %@: received data (success=%i)",
				  [self daemonAddress], [self daemonPort],
				  [params objectForKey:@"method"], success);
			if (success) {																	// get information about all torrents
				[self releaseDaemonUpdateProcess];											//	as fast as we can
				[self performSelector:@selector(startDaemonUpdateProcess)
						   withObject:nil afterDelay:0];
			} else {
				// TODO handle error
			}
		} else {
			NSLog(@"[%@:%i]: %@: received unidentified code (status=%u)",
				  [self daemonAddress], [self daemonPort],
				  [params objectForKey:@"method"],
				  statusCode);
			
			// TODO handle error
		}
		[self releaseMethodForStream:stream];												// release data
	} else if (stream == torrentAddStream) {
		// check for response code and response result
		CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
		CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(response);
		if (statusCode == 200) {
			// TODO decode response for deflate encoding
			
			NSString *body = [NSString stringWithCString:[torrentAddData bytes]				//	convert data into string
												  length:[torrentAddData length]];
			BOOL success = ([body rangeOfString:@"success"].location != NSNotFound);
			NSLog(@"[%@:%i]: %@: received data (success=%i)",
				  [self daemonAddress], [self daemonPort],
				  [params objectForKey:@"method"], success);
			if (success) {																	// get information about all torrents
				[self releaseDaemonUpdateProcess];											//	as fast as we can
				[self performSelector:@selector(startDaemonUpdateProcess)
						   withObject:nil afterDelay:0];
				[torrentAddDelegate performSelector:torrentAddEndSelector					// end with success result
										 withObject:TORRENT_ADD_SUCCESS
										 withObject:nil];
			} else {
				// TODO handle error
				
				[torrentAddDelegate performSelector:torrentAddEndSelector
										 withObject:(id)TORRENT_ADD_ERROR
										 withObject:nil];
			}
		} else {
			NSLog(@"[%@:%i]: %@: received unidentified code (status=%u)",
				  [self daemonAddress], [self daemonPort],
				  [params objectForKey:@"method"],
				  statusCode);
			
			// TODO handle error

			[torrentAddDelegate performSelector:torrentAddEndSelector
									 withObject:(id)TORRENT_ADD_ERROR
									 withObject:nil];
		}
		[self releaseAddTorrent];
	}
}

- (void)handleEventErrorOccurredForStream:(CFReadStreamRef)stream {
	NSDictionary *params = nil;
	if (stream == torrentListUpdateStream) {
		float delay = fmaxf([self frequency] + [torrentListUpdateTime
												timeIntervalSinceNow], 0.);
		CFStreamError error = CFReadStreamGetError(stream);
		NSLog(@"[%@:%i]: torrent-get: error occured (%i, %i)",
			  [self daemonAddress], [self daemonPort],
			  error.domain, error.error);
		
		// TODO handle error	
		
		[self releaseDaemonUpdateProcess];													// release everything
		[self performSelector:@selector(startDaemonUpdateProcess)							// repeat the request
				   withObject:nil afterDelay:delay];
	} else if ((params = [torrentMethodDict objectForKey:[(id)stream description]]) != nil) {
		CFStreamError error = CFReadStreamGetError(stream);
		NSLog(@"[%@:%i]: %@: error occured (%i, %i)",
			  [self daemonAddress], [self daemonPort],
			  [params objectForKey:@"method"],
			  error.domain, error.error);

		// TODO handle error	
		
		[self releaseMethodForStream:stream];												// release data
	} else if (stream == torrentAddStream) {
		CFStreamError error = CFReadStreamGetError(stream);
		NSLog(@"[%@:%i]: torrent-add: error occured (%i, %i)",
			  [self daemonAddress], [self daemonPort],
			  error.domain, error.error);
		
		// TODO handle error	

		[torrentAddDelegate performSelector:torrentAddEndSelector
								 withObject:(id)TORRENT_ADD_ERROR
								 withObject:nil];
		[self releaseAddTorrent];
	}
}

- (void)handleEventTimeoutOccurredForStream:(id)streamObject {
	NSDictionary *params = nil;
	CFReadStreamRef stream = (CFReadStreamRef)streamObject;
	if (stream == torrentListUpdateStream) {
		float delay = fmaxf([self frequency] + [torrentListUpdateTime
												timeIntervalSinceNow], 0.);
		NSLog(@"[%@:%i]: torrent-get: timeout occured",
			  [self daemonAddress], [self daemonPort]);
		
		// TODO handle error
		
		[self releaseDaemonUpdateProcess];													// release everything
		[self performSelector:@selector(startDaemonUpdateProcess)							// repeat the request
				   withObject:nil afterDelay:delay];
	} else if ((params = [torrentMethodDict objectForKey:[(id)stream description]]) != nil) {
		NSLog(@"[%@:%i]: %@: timeout occured",
			  [self daemonAddress], [self daemonPort],
			  [params objectForKey:@"method"]);

		// TODO handle error	
		
		[self releaseMethodForStream:stream];												// release data
	} else if (stream == torrentAddStream) {
		NSLog(@"[%@:%i]: torrent-add: timeout occured",
			  [self daemonAddress], [self daemonPort]);
		
		// TODO handle error	

		[torrentAddDelegate performSelector:torrentAddEndSelector
								 withObject:(id)TORRENT_ADD_ERROR
								 withObject:nil];
		[self releaseAddTorrent];
	}
}

#pragma mark Update torrents info.

- (void)updateTorrentsWithDataReceived:(void *)jsonRoot {
	for (json_t *json = (json_t *)jsonRoot; json != 0; json = json->next) {
		if (json->type == JSON_STRING && strcmp(json->text, "torrents") == 0) {			// found node with torrents
			json_t *jsonTorrentsArray = json->child;									// found array with torrents
			[self daemonDataWillChange];												// daemon data will be changed

			NSMutableSet *foundTorrents = [NSMutableSet set];							// found torrents in request
			for (json_t *jsonTorrentObject = jsonTorrentsArray->child;					// go through every torrent
				 jsonTorrentObject != 0; jsonTorrentObject = jsonTorrentObject->next) {
				
				NSString *uniqueId = nil;
				for (json_t *jsonTorrentData = jsonTorrentObject->child;				// get torrent identifier
					 jsonTorrentData != 0; jsonTorrentData = jsonTorrentData->next) {
					if (strcmp(jsonTorrentData->text, "id") == 0)
						uniqueId = [NSString stringWithCString:jsonTorrentData->child->text];
				}
				
				TorrentData *torrent = [torrentsDict objectForKey:uniqueId];
				if (torrent == nil) {														// if unable to find torrent, have to create new one
					torrent = [[TorrentData alloc] initWithDaemon:self uniqueId:uniqueId];	// new torrent creation
					[self insertTorrent:torrent];
					[torrent release];
				}
				
				for (json_t *jsonTorrentData = jsonTorrentObject->child;				// updating internals of torrent
					 jsonTorrentData != 0; jsonTorrentData = jsonTorrentData->next) {
					if (strcmp(jsonTorrentData->text, "name") == 0) {
						const char *unescaped = convert_from_escape(jsonTorrentData->child->text);
						[torrent setTitle:[NSString stringWithUTF8String:unescaped]];
						free((void *)unescaped);
					} else if (strcmp(jsonTorrentData->text, "totalSize") == 0)
						[torrent setTotalSize:[NSNumber numberWithUnsignedLongLong:
											   strtoull(jsonTorrentData->child->text, NULL, 10)]];
					else if (strcmp(jsonTorrentData->text, "haveValid") == 0)
						[torrent setHaveValid:[NSNumber numberWithUnsignedLongLong:
											   strtoull(jsonTorrentData->child->text, NULL, 10)]];
					else if (strcmp(jsonTorrentData->text, "haveUnchecked") == 0)
						[torrent setHaveUnchecked:[NSNumber numberWithUnsignedLongLong:
												   strtoull(jsonTorrentData->child->text, NULL, 10)]];
					else if (strcmp(jsonTorrentData->text, "status") == 0) {
						NSUInteger oldFilterType = [torrent filterType];
						[torrent setStatus:strtoul(jsonTorrentData->child->text, NULL, 10)];
						if ([torrent filterType] != oldFilterType)
							[self changedFilterTypeOfTorrent:torrent from:oldFilterType];
					}  else if (strcmp(jsonTorrentData->text, "peersSendingToUs") == 0)
						[torrent setSeedsActive:strtoul(jsonTorrentData->child->text, NULL, 10)];
					else if (strcmp(jsonTorrentData->text, "peersGettingFromUs") == 0)
						[torrent setPeersActive:strtoul(jsonTorrentData->child->text, NULL, 10)];
					else if (strcmp(jsonTorrentData->text, "rateDownload") == 0)
						[torrent setDownloadSpeed:strtoul(jsonTorrentData->child->text, NULL, 10)];
					else if (strcmp(jsonTorrentData->text, "rateUpload") == 0)
						[torrent setUploadSpeed:strtoul(jsonTorrentData->child->text, NULL, 10)];
					else if (strcmp(jsonTorrentData->text, "eta") == 0)
						[torrent setEta:strtol(jsonTorrentData->child->text, NULL, 10)];
					else if (strcmp(jsonTorrentData->text, "uploadedEver") == 0)
						[torrent setUploaded:[NSNumber numberWithUnsignedLongLong:
											  strtoull(jsonTorrentData->child->text, NULL, 10)]];
				}
				[foundTorrents addObject:uniqueId];										// adding to found torrents
			}
			
			NSMutableArray *removedTorrents = [NSMutableArray array];					// torrent ids to remove
			for (TorrentData *torrent in filteredTorrents[FILTER_TYPE_ALL])
				if (![foundTorrents containsObject:[torrent uniqueId]])					// found torrent not in set, so
					[removedTorrents addObject:[torrent uniqueId]];						//	add key to remove array
			[self removeTorrentsWithKeys:removedTorrents];								// removing torrent
			[self daemonDataDidChange];
			break;
		}
		
		// go childs
		if (json->child != 0)
			[self updateTorrentsWithDataReceived:json->child];
	}
}

#pragma mark Deallocation.

- (void)dealloc {
	NSLog(@"dealloc: %@", self);
	
	[self stopAllDaemonOperations];
	[sessionId release];

	[daemonAddress release];
	[daemonUsername release];
	[daemonPassword release];
	[proxyAddress release];
	[proxyUsername release];
	[proxyPassword release];

	[torrentMethodDict release];
	[super dealloc];
}

@end

void responseLoadCallback(CFReadStreamRef stream, CFStreamEventType type, void *info) {
	DaemonTransmission *self = (DaemonTransmission *)info;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];								// create autorelease pool
	switch (type) {																			//	due to memory leaks
		case kCFStreamEventHasBytesAvailable:
			[self handleEventHasBytesAvailableForStream:stream];
			break;
		case kCFStreamEventEndEncountered:
			[self handleEventEndEncounteredForStream:stream];
			break;
		case kCFStreamEventErrorOccurred:
			[self handleEventErrorOccurredForStream:stream];
			break;
		default:
			break;
	}
	[pool drain];
}
