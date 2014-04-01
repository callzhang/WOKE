/*
 * Copyright 2012-2013 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SMHTTPRequestOperation.h"
#import "SMClient.h"
#import "SMUserSession.h"
#import "SMError.h"

@implementation SMHTTPRequestOperation

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response) {
        NSString *host = [[request URL] host];
        NSString *apiHost = nil;
        if ([[[request URL] scheme] isEqualToString:@"http"]) {
            apiHost = [[[SMClient defaultClient] session] getHttpHost];
        } else {
            apiHost = [[[SMClient defaultClient] session] getHttpsHost];
        }
        if (![apiHost isEqualToString:host]) {
            BOOL permanent = [(NSHTTPURLResponse *)response statusCode] == SMErrorMovedPermanently ? YES : NO;
            [[SMClient defaultClient] setRedirectedAPIHost:host port:[[request URL] port] scheme:[[request URL] scheme] permanent:permanent];
        }
    }
    return [super connection:connection willSendRequest:request redirectResponse:response];
}

+ (instancetype)SMHTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
										success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
										failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    SMHTTPRequestOperation *requestOperation = [(SMHTTPRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:success failure:failure];
    
    return requestOperation;
}

@end
