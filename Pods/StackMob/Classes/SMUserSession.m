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

#import "StackMob.h"
#import "AFJSONRequestOperation.h"
#import "SMVersion.h"
#import "SystemInformation.h"

#define ACCESS_TOKEN @"access_token"
#define EXPIRES_IN @"expires_in"
#define MAC_KEY @"mac_key"
#define REFRESH_TOKEN @"refresh_token"
#define HTTP @"http"
#define HTTPS @"https"

@interface SMUserSession ()

@property (nonatomic, copy) NSString *oauthStorageKey;
@property (readwrite, nonatomic, copy) SMTokenRefreshFailureBlock tokenRefreshFailureBlock;
@property(nonatomic, readwrite, copy) NSString *publicKey;
@property(nonatomic, readwrite, copy) NSString *version;

- (NSURL *)SM_getStoreURLForUserIdentifierTable;
- (void)SM_createStoreURLPathIfNeeded:(NSURL *)storeURL;

@end


@implementation SMUserSession


@synthesize regularOAuthClient = _SM_regularOAuthClient;
@synthesize secureOAuthClient = _SM_secureOAuthClient;
@synthesize tokenClient = _SM_tokenClient;
@synthesize userSchema = _SM_userSchema;
@synthesize userPrimaryKeyField = _userPrimaryKeyField;
@synthesize userPasswordField = _SM_userPasswordField;
@synthesize expiration = _SM_expiration;
@synthesize refreshToken = _SM_refreshToken;
@synthesize refreshing = _SM_refreshing;
@synthesize oauthStorageKey = _SM_oauthStorageKey;
@synthesize networkMonitor = _SM_networkMonitor;
@synthesize userIdentifierMap = _SM_userIdentifierMap;
@synthesize tokenRefreshFailureBlock = _tokenRefreshFailureBlock;
@synthesize publicKey = _publicKey;
@synthesize version = _version;

- (id)initWithAPIVersion:(NSString *)version
                httpHost:(NSString *)httpHost
               httpsHost:(NSString *)httpsHost
               publicKey:(NSString *)publicKey
              userSchema:(NSString *)userSchema
     userPrimaryKeyField:(NSString *)userPrimaryKeyField
       userPasswordField:(NSString *)userPasswordField
{
    self = [super init];
    if (self) {
        self.regularOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:version scheme:HTTP apiHost:httpHost publicKey:publicKey];
        self.secureOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:version scheme:HTTPS apiHost:httpsHost publicKey:publicKey];
        self.tokenClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", HTTPS, httpsHost]]];
        
        NSString *acceptHeader = [NSString stringWithFormat:@"application/vnd.stackmob+json; version=%@", version];
        [self.tokenClient setDefaultHeader:@"Accept" value:acceptHeader];
        [self.tokenClient setDefaultHeader:@"X-StackMob-API-Key" value:publicKey];
        [self.tokenClient setDefaultHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
        [self.tokenClient setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"StackMob/%@ (%@/%@; %@;)", SDK_VERSION, smDeviceModel(), smSystemVersion(), [[NSLocale currentLocale] localeIdentifier]]];
        self.networkMonitor = [[SMNetworkReachability alloc] init];
        self.userSchema = userSchema;
        self.userPrimaryKeyField = userPrimaryKeyField;
        self.userPasswordField = userPasswordField;
        self.refreshing = NO;
        self.tokenRefreshFailureBlock = nil;
        self.publicKey = publicKey;
        self.version = version;
        
        NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
        
        if (!applicationName) {
            applicationName = @"nil";
        }
        self.oauthStorageKey = [NSString stringWithFormat:@"%@.%@.oauth", applicationName, publicKey];
        [self saveAccessTokenInfo:[[NSUserDefaults standardUserDefaults] dictionaryForKey:self.oauthStorageKey]];
        
        [self SMReadUserIdentifierMap];
        
    }
    
    return self;
}

- (id)initWithAPIVersion:(NSString *)version
                 apiHost:(NSString *)apiHost
               publicKey:(NSString *)publicKey
              userSchema:(NSString *)userSchema
     userPrimaryKeyField:(NSString *)userPrimaryKeyField
       userPasswordField:(NSString *)userPasswordField
{
    return [self initWithAPIVersion:version httpHost:apiHost httpsHost:apiHost publicKey:publicKey userSchema:userSchema userPrimaryKeyField:userPrimaryKeyField userPasswordField:userPasswordField];
}

- (NSString *)getHttpHost
{
    NSNumber *port = self.regularOAuthClient.baseURL.port;
    if (port) {
        return [NSString stringWithFormat:@"%@:%@", self.regularOAuthClient.baseURL.host, port];
    } else {
        return self.regularOAuthClient.baseURL.host;
    }
}

- (NSString *)getHttpsHost
{
    NSNumber *port = self.secureOAuthClient.baseURL.port;
    if (port) {
        return [NSString stringWithFormat:@"%@:%@", self.secureOAuthClient.baseURL.host, port];
    } else {
        return self.secureOAuthClient.baseURL.host;
    }
}

- (BOOL)accessTokenHasExpired
{
    return ![[self.expiration laterDate:[NSDate date]] isEqualToDate:self.expiration];
}

- (void)clearSessionInfo
{
    [self saveAccessTokenInfo:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.oauthStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)oauthClientWithHTTPS:(BOOL)https
{
    return https ? self.secureOAuthClient : self.regularOAuthClient;
}

- (void)refreshTokenOnSuccess:(void (^)(NSDictionary *userObject))successBlock
                    onFailure:(void (^)(NSError *error))failureBlock
{
    
    [self refreshTokenWithSuccessCallbackQueue:nil failureCallbackQueue:nil onSuccess:successBlock onFailure:failureBlock];
}

- (void)refreshTokenWithSuccessCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(void (^)(NSDictionary *userObject))successBlock onFailure:(void (^)(NSError *error))failureBlock
{
    if (!successCallbackQueue) {
        successCallbackQueue = dispatch_get_main_queue();
    }
    if (!failureCallbackQueue) {
        failureCallbackQueue = dispatch_get_main_queue();
    }
    
    if (self.refreshToken == nil) {
        if (failureBlock) {
            NSError *refreshError = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Refresh Token is nil", NSLocalizedDescriptionKey, nil]];
            dispatch_async(failureCallbackQueue, ^{
                failureBlock(refreshError);
            });
        }
    } else if (self.refreshing) {
        if (failureBlock) {
            NSError *refreshError = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorRefreshTokenInProgress userInfo:nil];
            dispatch_async(failureCallbackQueue, ^{
                failureBlock(refreshError);
            });
        }
    } else {
        self.refreshing = YES;//Don't ever trigger two refreshToken calls
        [self doTokenRequestWithEndpoint:@"refreshToken" credentials:[NSDictionary dictionaryWithObjectsAndKeys:self.refreshToken, @"refresh_token", nil] options:[SMRequestOptions options] successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:successBlock onFailure:failureBlock];
    }
    
}

- (void)doTokenRequestWithEndpoint:(NSString *)endpoint
                       credentials:(NSDictionary *)credentials
                           options:(SMRequestOptions *)options
              successCallbackQueue:(dispatch_queue_t)successCallbackQueue
              failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue
                         onSuccess:(void (^)(NSDictionary *userObject))successBlock
                         onFailure:(void (^)(NSError *error))failureBlock
{
    NSMutableDictionary *args = [credentials mutableCopy];
    [args setValue:@"mac" forKey:@"token_type"];
    [args setValue:@"hmac-sha-1" forKey:@"mac_algorithm"];
    NSMutableURLRequest *request = [self.tokenClient requestWithMethod:@"POST" path:[self.userSchema stringByAppendingPathComponent:endpoint] parameters:args];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [options.headers enumerateKeysAndObjectsUsingBlock:^(id headerField, id headerValue, BOOL *stop) {
        [request setValue:headerValue forHTTPHeaderField:headerField];
    }];
    SMFullResponseSuccessBlock successHandler = ^void(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
        if (successBlock) {
            successBlock([self parseTokenResults:JSON]);
        }
    };
    SMFullResponseFailureBlock failureHandler = ^void(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
        self.refreshing = NO;
        if (failureBlock) {
            if (response == nil) {
                // May need to check for code -1009
                NSError *networkNotReachableError = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorNetworkNotReachable userInfo:[error userInfo]];
                failureBlock(networkNotReachableError);
            } else {
                int statusCode = (int)response.statusCode;
                NSString *domain = HTTPErrorDomain;
                if ([[JSON valueForKey:@"error_description"] isEqualToString:@"Temporary password reset required."]) {
                    statusCode = SMErrorTemporaryPasswordResetRequired;
                    domain = SMErrorDomain;
                }
                failureBlock([NSError errorWithDomain:domain code:statusCode userInfo:JSON]);
            }
        }
    };
    AFJSONRequestOperation * op = [SMJSONRequestOperation JSONRequestOperationWithRequest:request success:successHandler failure:failureHandler];
    if (successCallbackQueue) {
        [op setSuccessCallbackQueue:successCallbackQueue];
    }
    if (failureCallbackQueue) {
        [op setFailureCallbackQueue:failureCallbackQueue];
    }
    [self.tokenClient enqueueHTTPRequestOperation:op];
}

- (NSDictionary *) parseTokenResults:(NSDictionary *)result
{
    NSMutableDictionary *resultsToSave = [result mutableCopy];
    NSNumber *expires = [result valueForKey:EXPIRES_IN];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:[expires doubleValue]];
    [resultsToSave setObject:expirationDate forKey:EXPIRES_IN];
    [self saveAccessTokenInfo:resultsToSave];
    [[NSUserDefaults standardUserDefaults] setObject:resultsToSave forKey:self.oauthStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return [[result valueForKey:@"stackmob"] valueForKey:@"user"];
}

- (void)saveAccessTokenInfo:(NSDictionary *)result
{
    NSString *accessToken = [result valueForKey:ACCESS_TOKEN];
    NSString *refreshToken = [result valueForKey:REFRESH_TOKEN];
    NSDate *expiration = [result valueForKey:EXPIRES_IN];
    NSString *macKey = [result valueForKey:MAC_KEY];
    self.expiration = expiration;
    self.refreshToken = refreshToken;
    self.regularOAuthClient.accessToken = accessToken;
    self.regularOAuthClient.macKey = macKey;
    self.secureOAuthClient.accessToken = accessToken;
    self.secureOAuthClient.macKey = macKey;
    self.refreshing = NO;
}

- (NSURLRequest *) signRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *newRequest = [request mutableCopy];
    // Both requests have the same credentials so it doesn't matter which we use here
    [self.regularOAuthClient signRequest:newRequest path:[[request URL] path]];
    return newRequest;
}

- (BOOL)eligibleForTokenRefresh:(SMRequestOptions *)options
{
    return options.tryRefreshToken && self.refreshToken != nil && [self accessTokenHasExpired];
}

- (NSURL *)SM_getStoreURLForUserIdentifierTable
{
    
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationStorageDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:applicationName];
    
    NSString *userIDMapName = nil;
    if (applicationName != nil)
    {
        userIDMapName = [NSString stringWithFormat:@"%@-%@-UserIdentifierMap.plist", applicationName, self.regularOAuthClient.publicKey];
    } else {
        userIDMapName = [NSString stringWithFormat:@"%@-UserIdentifierMap.plist", self.regularOAuthClient.publicKey];
    }
    
    NSArray *paths = [NSArray arrayWithObjects:applicationDocumentsDirectory, applicationStorageDirectory, nil];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    for (NSString *path in paths)
    {
        NSString *filepath = [path stringByAppendingPathComponent:userIDMapName];
        if ([fm fileExistsAtPath:filepath])
        {
            return [NSURL fileURLWithPath:filepath];
        }
        
    }
    
    NSURL *aURL = [NSURL fileURLWithPath:[applicationStorageDirectory stringByAppendingPathComponent:userIDMapName]];
    return aURL;
}

- (void)SM_createStoreURLPathIfNeeded:(NSURL *)storeURL
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *pathToStore = [storeURL URLByDeletingLastPathComponent];
    
    NSError *error = nil;
    BOOL pathWasCreated = [fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (!pathWasCreated) {
        [NSException raise:SMExceptionAddPersistentStore format:@"Error creating user identifier map: %@", error];
    }
    
}

- (void)SMReadUserIdentifierMap
{
    
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSURL *mapPath = [self SM_getStoreURLForUserIdentifierTable];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[mapPath path]]) {
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:[mapPath path]];
        NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                              propertyListFromData:plistXML
                                              mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                              format:&format
                                              errorDescription:&errorDesc];
        
        if (!temp) {
            [NSException raise:SMExceptionCacheError format:@"Error reading user identifier: %@, format: %d", errorDesc, (int)format];
        } else {
            self.userIdentifierMap = [temp mutableCopy];
        }
    } else {
        self.userIdentifierMap = [NSMutableDictionary dictionary];
    }
    
}

- (void)SMSaveUserIdentifierMap
{
    NSString *errorDesc = nil;
    NSError *error = nil;
    NSURL *mapPath = [self SM_getStoreURLForUserIdentifierTable];
    [self SM_createStoreURLPathIfNeeded:mapPath];
    
    NSData *mapData = [NSPropertyListSerialization dataFromPropertyList:self.userIdentifierMap
                                                                 format:NSPropertyListXMLFormat_v1_0
                                                       errorDescription:&errorDesc];
    
    if (!mapData) {
        [NSException raise:SMExceptionCacheError format:@"Error serializing user identifier data with error description %@", errorDesc];
    }
    
    BOOL successfulWrite = [mapData writeToFile:[mapPath path] options:NSDataWritingAtomic error:&error];
    if (!successfulWrite) {
        [NSException raise:SMExceptionCacheError format:@"Error saving identifier data with error %@", error];
    }
    
}

- (void)setTokenRefreshFailureBlock:(void (^)(NSError *error, SMFailureBlock originalFailureBlock))block
{
    _tokenRefreshFailureBlock = block;
}

- (void)setNewAPIHost:(NSString *)apiHost port:(NSNumber *)port scheme:(NSString *)scheme
{
    __block BOOL resetTokenClientHeaders = NO;
    if (port) {
        if ([scheme isEqualToString:@"https"]) {
            self.secureOAuthClient = nil;
            self.tokenClient = nil;
            self.secureOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:self.version scheme:@"https" apiHost:[NSString stringWithFormat:@"%@:%@", apiHost, port] publicKey:self.publicKey];
            self.tokenClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@", apiHost, port]]];
            resetTokenClientHeaders = YES;
        } else {
            self.regularOAuthClient = nil;
            self.regularOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:self.version scheme:@"http" apiHost:[NSString stringWithFormat:@"%@:%@", apiHost, port] publicKey:self.publicKey];
        }
    } else if ([scheme isEqualToString:@"https"]) {
        self.secureOAuthClient = nil;
        self.tokenClient = nil;
        self.secureOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:self.version scheme:@"https" apiHost:apiHost publicKey:self.publicKey];
        self.tokenClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiHost]]];
        resetTokenClientHeaders = YES;
    } else {
        self.regularOAuthClient = nil;
        
        self.regularOAuthClient = [[SMOAuth2Client alloc] initWithAPIVersion:self.version scheme:@"http" apiHost:apiHost publicKey:self.publicKey];
    }
    
    if (resetTokenClientHeaders) {
        NSString *acceptHeader = [NSString stringWithFormat:@"application/vnd.stackmob+json; version=%@", self.version];
        [self.tokenClient setDefaultHeader:@"Accept" value:acceptHeader];
        [self.tokenClient setDefaultHeader:@"X-StackMob-API-Key" value:self.publicKey];
        [self.tokenClient setDefaultHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
        [self.tokenClient setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"StackMob/%@ (%@/%@; %@;)", SDK_VERSION, smDeviceModel(), smSystemVersion(), [[NSLocale currentLocale] localeIdentifier]]];
    }
}


@end
