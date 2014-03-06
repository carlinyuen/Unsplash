//
//  USImageDatasource.m
//  Unsplash
//
//  Created by . Carlin on 2/27/14.
//  Copyright (c) 2014 Carlin Creations. All rights reserved.
//
//  This class uses the actual Tumblr api to get images

#import "USImageDatasource.h"

#import "Keys.h"

    #define URL_API_TUMBLR_GET_POSTS @"https://api.tumblr.com/v2/blog/%@/posts/photo?api_key=%@&offset=%@"

    #define KEY_CONNECTION_DOWNLOAD_SIZE @"size"
    #define KEY_CONNECTION_DOWNLOAD_DATA @"data"

    #define SIZE_CACHE_BUFFER 4

    #define TIME_CONNECTION_TIMEOUT 6

@interface USImageDatasource () <
    NSURLConnectionDelegate
    , NSURLConnectionDataDelegate
>

    /** Cached array of image urls */
    @property (nonatomic, strong, readwrite) NSMutableArray *imageURLCache;
    @property (nonatomic, strong, readwrite) NSMutableArray *imageCache;

    /** Managing connections for images */
    @property (nonatomic, strong) NSURLConnection *apiConnection;
    @property (nonatomic, strong) NSMutableData *apiConnectionData;
    @property (nonatomic, strong) NSMutableDictionary *connectionMap;

    /** Timer for timeouts */
    @property (nonatomic, strong) NSTimer *connectionTimeout;

@end

@implementation USImageDatasource

/** @brief Convenience constructor for urlString */
- (id)initWithURLString:(NSString *)urlString
{
    self = [self init];
    if (self) {
        _blogURLString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    }
    return self;
}

/** @brief Overridden init */
- (id)init
{
    self = [super init];
    if (self)
    {
        _imageCache = [NSMutableArray new];
        _imageURLCache = [NSMutableArray new];
        _connectionMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [_imageCache removeAllObjects];
    [_imageURLCache removeAllObjects];
    [_connectionMap removeAllObjects];
}


#pragma mark - Class Methods

/** @brief Asynchronously download image and store into imageCache.
    @param index Index of */
- (void)downloadImageAtIndex:(NSInteger)index
{
    [self downloadImageWithNSURLConnectionAtIndex:index];
}

/** @brief Download image at index using NSURLConnection */
- (void)downloadImageWithNSURLConnectionAtIndex:(NSInteger)index
{
    // Only make request if not already downloading
    NSString *imageURL = [self.imageURLCache objectAtIndex:index];
    if ([self.connectionMap objectForKey:imageURL]) {
        debugLog(@"Already downloading image at index: %i!", index);
        return;
    }

    // Make download request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL
        URLWithString:imageURL]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:true];

    // Store connection data into map
    NSMutableDictionary *info = [NSMutableDictionary new];
    [info setObject:@(index) forKey:KEY_CONNECTION_DOWNLOAD_INDEX];
    [self.connectionMap setObject:info
        forKey:[self keyForConnection:connection]];
}

/** @brief Download image at index using GCD */
- (void)downloadImageWithGCDAtIndex:(NSInteger)index
{
    __block USImageDatasource *this = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        // Download image data
        if (this)
        {
            NSString *urlString = [this.imageURLCache objectAtIndex:index];
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            if (data)
            {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        if (this)
                        {
                            // Replace spot in cache
                            [this.imageCache replaceObjectAtIndex:index withObject:image];
                            
                            // Notify that image was downloaded
                            [[NSNotificationCenter defaultCenter]
                                postNotificationName:NOTIFICATION_IMAGE_LOADED
                                object:self userInfo:@{
                                    KEY_CONNECTION_DOWNLOAD_INDEX : @(index)
                                }];
                        }
                    });
                } else {
                    NSLog(@"Could not create image from data.");
                }
            } else {
                NSLog(@"Could not download image data from url: %@", urlString);
            }
        }
    });
}

/** @brief Call to request more images from the datasource */
- (void)fetchMoreImages
{
    debugLog(@"fetchMoreImages");

    // Only fetch if connection is not still running
    if (self.apiConnection) {
        debugLog(@"fetch still going");
        return;
    }

    // Build request string
    NSString *urlString = [NSString stringWithFormat:URL_API_TUMBLR_GET_POSTS,
        self.blogURLString, KEY_API_TUMBLR, @(self.imageURLCache.count)];
    debugLog(@"urlString: %@", urlString);

    // Make API call
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    self.apiConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:true];
    self.apiConnectionData = [NSMutableData new];

    // Fire off timeout timer
    self.connectionTimeout = [NSTimer
        scheduledTimerWithTimeInterval:TIME_CONNECTION_TIMEOUT
        target:self selector:@selector(connectionTimeoutTriggered:)
        userInfo:nil repeats:false];

    // Show activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
}

/** @brief Cleans up and removes connection data */
- (void)cleanConnection:(NSURLConnection *)connection
{
    // Clear related connection info out if needed
    if (connection == self.apiConnection) {
        [self.apiConnection cancel];
        self.apiConnection = nil;
    } else {
        [self.connectionMap removeObjectForKey:[self
            keyForConnection:connection]];
    }
}

/** @brief Returns key used in map for connection */
- (NSString *)keyForConnection:(NSURLConnection *)connection
{
    return [[[connection currentRequest] URL] absoluteString];
//    return [NSString stringWithFormat:@"%i", [connection hash]];
}

/** @brief Trims down cache to save on memory */
- (void)trimCacheAroundIndex:(NSInteger)index
{
    for (NSInteger i = 0; i < self.imageCache.count; ++i)
    {
        // If not within cache buffer bounds, clear
        if (i < index - SIZE_CACHE_BUFFER || i > index + SIZE_CACHE_BUFFER) {
            [self.imageCache replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}


#pragma mark - Event Handlers

/** @brief When connection timeout happens */
- (void)connectionTimeoutTriggered:(NSTimer *)timer
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:NOTIFICATION_CONNECTION_TIMEOUT
        object:self userInfo:nil];
}


#pragma mark - Protocols
#pragma mark - NSURLConnectionDelegate, NSURLConnectionDownloadDelegate , NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // If for api connection, do nothing
    if (connection == self.apiConnection) {
        return;
    }

    // Get connection info, create new mutable data storage
    NSMutableDictionary *connectionInfo
        = self.connectionMap[[self keyForConnection:connection]];
    [connectionInfo setObject:[NSMutableData new]
        forKey:KEY_CONNECTION_DOWNLOAD_DATA];
    [connectionInfo setObject:@([response expectedContentLength])
        forKey:KEY_CONNECTION_DOWNLOAD_SIZE];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // If for api connection, just append data simply
    if (connection == self.apiConnection) {
        [self.apiConnectionData appendData:data];
        return;
    }

    // Get connection info and update data / size
    NSMutableDictionary *connectionInfo = self.connectionMap[[self keyForConnection:connection]];

    NSMutableData *totalData = connectionInfo[KEY_CONNECTION_DOWNLOAD_DATA];
    [totalData appendData: data];

    // Broadcast a notification with the progress change
    NSNumber *totalSize = connectionInfo[KEY_CONNECTION_DOWNLOAD_SIZE];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:NOTIFICATION_IMAGE_DOWNLOAD_PROGRESS
        object:self userInfo:@{
            KEY_CONNECTION_DOWNLOAD_INDEX : connectionInfo[KEY_CONNECTION_DOWNLOAD_INDEX],
            KEY_CONNECTION_DOWNLOAD_PROGRESS :
               @((float)[data length] / [totalSize floatValue])
        }];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"Connection Error: %@", error);

    // Delete connection info
    [self cleanConnection:connection];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    debugLog(@"Connection Finished");

    // If from api response
    if (connection == self.apiConnection)
    {
        // Create dictionary from api response
        NSError *error;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.apiConnectionData options:kNilOptions error:&error];
        if (error) {
            NSLog(@"Error Parsing API Response: %@", self.apiConnectionData);
            return;
        }

        // Collect image urls and store into cache
        NSArray *posts = [[response objectForKey:@"response"] objectForKey:@"posts"];
        if (posts) {
            for (NSInteger i = 0; i < posts.count; ++i) {
                NSArray *photos = [posts[i] objectForKey:@"photos"];
                if (photos) {
                    for (NSInteger j = 0; j < photos.count; ++j) {
                        NSArray *sizes = [photos[j] objectForKey:@"alt_sizes"];
                        if (sizes)
                        {
                            NSDictionary *imageInfo = sizes[0];
                            [self.imageURLCache addObject:[imageInfo objectForKey:@"url"]];

                            // Add NSNull to fill in image cache
                            [self.imageCache addObject:[NSNull null]];
                        }
                    }
                }
            }
            debugLog(@"Collected urls: %@", self.imageURLCache);
            
            // Notify that cache is updated
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NOTIFICATION_IMAGE_URL_CACHE_UPDATED
                object:self userInfo:nil];
        }
        else {
            NSLog(@"No posts returned!");
        }

        // Hide status bar activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
    }
    else    // Store in cache and notify
    {
        // Get connection info
        NSMutableDictionary *connectionInfo = self.connectionMap[[self keyForConnection:connection]];
        NSInteger index = [connectionInfo[KEY_CONNECTION_DOWNLOAD_INDEX] integerValue];

        // Create image
        UIImage *image = [UIImage imageWithData:connectionInfo[KEY_CONNECTION_DOWNLOAD_DATA]];
        if (image)
        {
            // Replace spot in cache
            [self.imageCache replaceObjectAtIndex:index withObject:image];

            // Notify that image was downloaded
            [[NSNotificationCenter defaultCenter]
                postNotificationName:NOTIFICATION_IMAGE_LOADED
                object:self userInfo:@{
                    KEY_CONNECTION_DOWNLOAD_INDEX : @(index)
                }];
        }
        else {
            NSLog(@"Could not create image with data from connection: %@", connection);
        }
    }

    // Delete connection info
    [self cleanConnection:connection];
}


@end
