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

    #define URL_API_TUMBLR_GET_POSTS @"api.tumblr.com/v2/blog/%@/posts/photo?api_key=%@&offset=%@"

    #define KEY_CONNECTION_DOWNLOAD_SIZE @"size"
    #define KEY_CONNECTION_DOWNLOAD_DATA @"data"

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
    // Make download request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL
        URLWithString:[self.imageURLCache objectAtIndex:index]]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:true];

    // Store connection data into map
    [self.connectionMap setObject:[NSMutableDictionary new]
        forKey:@([connection hash])];
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
}

/** @brief Cleans up and removes connection data */
- (void)cleanConnection:(NSURLConnection *)connection
{
    // Clear it out
    [self.connectionMap removeObjectForKey:@([connection hash])];
}


#pragma mark - Event Handlers


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
        = self.connectionMap[@([connection hash])];
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
    NSMutableDictionary *connectionInfo = self.connectionMap[@([connection hash])];

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
        debugLog(@"API Response: %@", response);

        // Collect image urls and store into cache
        NSArray *posts = [[response objectForKey:@"response"] objectForKey:@"posts"];
        if (posts) {
            for (NSInteger i = 0; i < posts.count; ++i) {
                NSArray *sizes = [posts[i] objectForKey:@"alt_sizes"];
                if (sizes) {
                    NSDictionary *imageInfo = sizes[0];
                    [self.imageURLCache addObject:[imageInfo objectForKey:@"url"]];
                }
            }
            debugLog(@"Collected urls: %@", self.imageURLCache);
        }
        else {
            NSLog(@"No posts returned!");
        }
    }
    else    // Store in cache and notify
    {
        // Get connection info
        NSMutableDictionary *connectionInfo = self.connectionMap[@([connection hash])];
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

        // Delete connection info
        [self cleanConnection:connection];
    }
}


@end
