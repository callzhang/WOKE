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

#import "SMRequestOptions.h"
#import "SMError.h"

@interface SMRequestOptions ()

@property (nonatomic, readwrite) BOOL cachePolicySet __attribute__((deprecated("use fetchPolicySet. First deprecated in v2.2.0.")));
@property (nonatomic, readwrite) BOOL fetchPolicySet;
@property (nonatomic, readwrite) BOOL savePolicySet;

@end

@implementation SMRequestOptions

@synthesize headers = _SM_headers;
@synthesize isSecure = _SM_isSecure;
@synthesize tryRefreshToken = _SM_tryRefreshToken;
@synthesize numberOfRetries = _SM_numberOfRetries;
@synthesize retryBlock = _SM_retryBlock;
@synthesize cachePolicy = _cachePolicy;
@synthesize cachePolicySet = _cachePolicySet;
@synthesize fetchPolicy = _fetchPolicy;
@synthesize fetchPolicySet = _fetchPolicySet;
@synthesize savePolicy = _savePolicy;
@synthesize savePolicySet = _savePolicySet;
@synthesize cacheResults = _cacheResults;


+ (SMRequestOptions *)options
{
    SMRequestOptions *opts = [[SMRequestOptions alloc] init];
    opts.headers = nil;
    opts.isSecure = NO;
    opts.tryRefreshToken = YES;
    opts.numberOfRetries = 3;
    opts.retryBlock = nil;
    opts.fetchPolicy = SMFetchPolicyNetworkOnly;
    opts.fetchPolicySet = NO;
    opts.cacheResults = YES;
    opts.savePolicy = SMSavePolicyNetworkThenCache;
    opts.savePolicySet = NO;
    return opts;
}

+ (SMRequestOptions *)optionsWithHeaders:(NSDictionary *)headers
{
    SMRequestOptions *opt = [SMRequestOptions options];
    opt.headers = headers;
    return opt;
}


+ (SMRequestOptions *)optionsWithHTTPS
{
    SMRequestOptions *opt = [SMRequestOptions options];
    opt.isSecure = YES;
    return opt;
}

+ (SMRequestOptions *)optionsWithExpandDepth:(NSUInteger)depth
{
    SMRequestOptions *opt = [SMRequestOptions options];
    [opt setExpandDepth:depth];
    return opt;
}

+ (SMRequestOptions *)optionsWithReturnedFieldsRestrictedTo:(NSArray *)fields
{
    SMRequestOptions *opt = [SMRequestOptions options];
    [opt restrictReturnedFieldsTo:fields];
    return opt;
}


+ (SMRequestOptions *)optionsWithCachePolicy:(SMCachePolicy)cachePolicy
{
    switch (cachePolicy) {
        case 0:
            return [self optionsWithFetchPolicy:SMFetchPolicyNetworkOnly];
            break;
        case 1:
            return [self optionsWithFetchPolicy:SMFetchPolicyCacheOnly];
            break;
        case 2:
            return [self optionsWithFetchPolicy:SMFetchPolicyTryNetworkElseCache];
            break;
        case 3:
            return [self optionsWithFetchPolicy:SMFetchPolicyTryCacheElseNetwork];
            break;
        default:
            [NSException raise:SMExceptionInvalidArugments format:@"Attempting to set an invalid cache policy."];
            break;
    }
    
}

+ (SMRequestOptions *)optionsWithFetchPolicy:(SMFetchPolicy)fetchPolicy
{
    SMRequestOptions *opt = [SMRequestOptions options];
    opt.fetchPolicy = fetchPolicy;
    return opt;
}

+ (SMRequestOptions *)optionsWithSavePolicy:(SMSavePolicy)savePolicy
{
    SMRequestOptions *opt = [SMRequestOptions options];
    opt.savePolicy = savePolicy;
    return opt;
}

+ (SMRequestOptions *)optionsWithCacheResults:(BOOL)cacheResults
{
    SMRequestOptions *opt = [SMRequestOptions options];
    opt.cacheResults = cacheResults;
    return opt;
}

- (void)setCachePolicy:(SMCachePolicy)cachePolicy
{
    if (_cachePolicy != cachePolicy) {
        _cachePolicy = cachePolicy;
    }
    self.cachePolicySet = YES;
    
    switch (cachePolicy) {
        case 0:
            [self setFetchPolicy:SMFetchPolicyNetworkOnly];
            break;
        case 1:
            [self setFetchPolicy:SMFetchPolicyCacheOnly];
            break;
        case 2:
            [self setFetchPolicy:SMFetchPolicyTryNetworkElseCache];
            break;
        case 3:
            [self setFetchPolicy:SMFetchPolicyTryCacheElseNetwork];
            break;
        default:
            [NSException raise:SMExceptionInvalidArugments format:@"Attempting to set an invalid cache policy."];
            break;
    }
    
}

- (void)setFetchPolicy:(SMFetchPolicy)fetchPolicy
{
    if (_fetchPolicy != fetchPolicy) {
        _fetchPolicy = fetchPolicy;
    }
    self.fetchPolicySet = YES;
}

- (void)setSavePolicy:(SMSavePolicy)savePolicy
{
    if (_savePolicy != savePolicy) {
        _savePolicy = savePolicy;
    }
    self.savePolicySet = YES;
}

- (void)setExpandDepth:(NSUInteger)depth
{
    if (!self.headers) {
        self.headers = [NSDictionary dictionary];
    }
    NSMutableDictionary *tempHeadersDict = [self.headers mutableCopy];
    [tempHeadersDict setValue:[NSString stringWithFormat:@"%d", (int)depth] forKey:@"X-StackMob-Expand"];
    self.headers = tempHeadersDict;
}

- (void)restrictReturnedFieldsTo:(NSArray *)fields
{
    if (!self.headers) {
        self.headers = [NSDictionary dictionary];
    }
    NSMutableDictionary *tempHeadersDict = [self.headers mutableCopy];
    [tempHeadersDict setValue:[fields componentsJoinedByString:@","] forKey:@"X-StackMob-Select"];
    self.headers = tempHeadersDict;
}

- (void)addSMErrorServiceUnavailableRetryBlock:(SMFailureRetryBlock)retryBlock
{
    self.retryBlock = retryBlock;
}

- (void)associateKey:(NSString *)key withSchema:(NSString *)schema
{
    if (!self.headers) {
        self.headers = [NSDictionary dictionary];
    }
    NSMutableDictionary *tempHeadersDict = [self.headers mutableCopy];
    if ([tempHeadersDict objectForKey:@"X-StackMob-Relations"]) {
        NSString *newRelationsHeader = [NSString stringWithFormat:@"%@&%@=%@", [tempHeadersDict objectForKey:@"X-StackMob-Relations" ], key, schema];
        [tempHeadersDict setValue:newRelationsHeader forKey:@"X-StackMob-Relations"];
    } else {
        [tempHeadersDict setValue:[NSString stringWithFormat:@"%@=%@", key, schema] forKey:@"X-StackMob-Relations"];
    }
    self.headers = tempHeadersDict;
}

- (void)setValue:(NSString *)value forHeaderKey:(NSString *)key
{
    if (!self.headers) {
        self.headers = [NSDictionary dictionary];
    }
    NSMutableDictionary *tempHeadersDict = [self.headers mutableCopy];
    [tempHeadersDict setObject:value forKey:key];
    self.headers = tempHeadersDict;
}

@end
