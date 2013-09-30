//
//  ES_NetworkAccessor.m
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import "ES_NetworkAccessor.h"
#import "ES_DataBaseAccessor.h"
#import "ES_AppDelegate.h"

#define API_URL         @"http://137.110.112.50:8080/api/analyze?%@"
#define API_UPLOAD      @"http://137.110.112.50:8080/api/feedback_upload"
#define API_FEEDBACK    @"http://137.110.112.50:8080/api/feedback?%@"
#define BOUNDARY        @"0xKhTmLbOuNdArY"

@implementation ES_NetworkAccessor

@synthesize recievedData = _recievedData;

- (NSData *) recievedData
{
    if (!_recievedData)
    {
        _recievedData = [NSMutableData data];
    }
    return _recievedData;
}


/**
 
 Uploads the given file. The file is compressed before beign uploaded.
 The data is uploaded using an HTTP POST command.
 
 */
- (void) upload
{
    ES_AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *file = [appDelegate popOffNetworkStack];
    
    NSLog( @"upload: %@", file);
    
    if (!file)
    {
        NSLog( @"Nil file, not sending!");
        return;
    }
        
    NSString *storagePath = [ES_DataBaseAccessor dataDirectory];
    
    NSString *fullPath = [ storagePath stringByAppendingString: file ];
    
    NSLog( @"[DataUploader] Attempting to upload %@", fullPath );
    
    NSData *data = [NSData dataWithContentsOfFile: fullPath];
    
    if( !data || [data length] == 0 )
    {
        NSLog(@"no data!");
    }
    
    NSURL *url = [NSURL URLWithString: API_UPLOAD];
    
    NSURLRequest *urlRequest = [self postRequestWithURL: url
                                                boundry: BOUNDARY
                                                   data: data
                                               fileName: file];
    if( !urlRequest ) {
        NSLog( @"url request failed");
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: urlRequest
                                                                   delegate: appDelegate.networkAccessor];
    
    if (!connection) {
        NSLog( @"Connection Failed");
    }
    
    // Now wait for the URL connection to call us back.
}

/**
 
 Creates a HTML POST request.
 
 */
- (NSURLRequest *)postRequestWithURL: (NSURL *)url
                             boundry: (NSString *)boundry
                                data: (NSData *)data
                            fileName: (NSString *) fileName
{
    
    // From http://www.cocoadev.com/index.pl?HTTPFileUpload
    NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue: [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry]
      forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postData = [NSMutableData dataWithCapacity:[data length] + 512];
    
    [postData appendData: [[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding: NSUTF8StringEncoding]];
    
    [postData appendData: [[NSString stringWithFormat:
                            @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", @"file", fileName]
                           dataUsingEncoding:NSUTF8StringEncoding]];
    
    [postData appendData:data];
    
    [postData appendData:
     [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    
    NSLog( @"urlRequest = %@", urlRequest);
    
    return urlRequest;
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog( @"connection: %@ didReceiveResponse: %@", [connection description], [response description] );
    
    [self.recievedData setLength: 0];
    
}

- (void) connection: (NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog( @"connection: %@ didReceiveData: %@", connection, data);
    [self.recievedData appendData:data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError:(NSError *)error
{
    connection = nil;
    self.recievedData = nil;
    NSLog( @"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]);
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSError *error;
    
    NSString *reply = [[NSString alloc] initWithData: self.recievedData
                                            encoding: NSUTF8StringEncoding];
    NSLog( @" reply = %@", [reply description]);
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData: self.recievedData options:NSJSONReadingMutableContainers error: &error];
    
    NSLog( @"Data: %@", [response description]);
    
    //NSDictionary *response = [[reply dataUsingEncoding: NSUTF8StringEncoding] objectFromJSONData];
    
    [self.recievedData writeToFile: [[ES_DataBaseAccessor dataDirectory] stringByAppendingString: @"/JSONData" ] atomically:YES];
    
    NSLog(@"Succeeded! Received %d bytes of data.", [self.recievedData length]);
    
    connection = nil;
}



@end
