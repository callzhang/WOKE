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

#import "SMDataStore.h"
#import "SMDataStore+Protected.h"
#import "SMQuery.h"
#import "AFNetworking.h"
#import "SMJSONRequestOperation.h"
#import "SMError.h"
#import "SMOAuth2Client.h"
#import "NSDictionary+AtomicCounter.h"
#import "SMRequestOptions.h"
#import "SMClient.h"
#import "SMUserSession.h"
#import "SMCustomCodeRequest.h"
#import "SMResponseBlocks.h"

@interface SMDataStore ()

@property(nonatomic, readwrite, copy) NSString *apiVersion;

@end

@implementation SMDataStore

@synthesize apiVersion = _SM_apiVersion;
@synthesize session = _SM_session;

- (id)initWithAPIVersion:(NSString *)apiVersion session:(SMUserSession *)session
{
    self = [super init];
    if (self) {
        self.apiVersion = apiVersion;
		self.session = session;
    }
    return self;
}

- (void)createObject:(NSDictionary *)object inSchema:(NSString *)schema onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self createObject:object inSchema:schema options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)createObject:(NSDictionary *)object inSchema:(NSString *)schema options:(SMRequestOptions *)options onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self createObject:object inSchema:schema options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)createObject:(NSDictionary *)object
            inSchema:(NSString *)schema
             options:(SMRequestOptions *)options
successCallbackQueue:(dispatch_queue_t)successCallbackQueue
failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue
           onSuccess:(SMDataStoreSuccessBlock)successBlock
           onFailure:(SMDataStoreFailureBlock)failureBlock
{
     if (object == nil || schema == nil) {
         if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, object, schema);
         }
     } else {
         NSString *theSchema = schema;
         if ([schema rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]].location == NSNotFound) {
             // lowercase the schema for StackMob
             theSchema = [theSchema lowercaseString];
         }
     
         NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"POST" path:theSchema parameters:object];
         SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForSchema:schema withSuccessBlock:successBlock];
         SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObject:object ofSchema:schema withFailureBlock:failureBlock];
         [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
     }
}

- (void)createObjects:(NSArray *)objects
             inSchema:(NSString *)schema
            onSuccess:(SMDataStoreBulkSuccessBlock)successBlock
            onFailure:(SMDataStoreBulkFailureBlock)failureBlock
{
    [self createObjects:objects inSchema:schema options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)createObjects:(NSArray *)objects
             inSchema:(NSString *)schema
              options:(SMRequestOptions *)options
             onSuccess:(SMDataStoreBulkSuccessBlock)successBlock
            onFailure:(SMDataStoreBulkFailureBlock)failureBlock
{
    [self createObjects:objects inSchema:schema options:[SMRequestOptions options] successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)createObjects:(NSArray *)objects
             inSchema:(NSString *)schema
              options:(SMRequestOptions *)options
 successCallbackQueue:(dispatch_queue_t)successCallbackQueue
 failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue
            onSuccess:(SMDataStoreBulkSuccessBlock)successBlock
            onFailure:(SMDataStoreBulkFailureBlock)failureBlock
{
    if (objects == nil || schema == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, objects, schema);
        }
    } else {
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"POST" path:schema parameters:nil];
        
        if (![NSJSONSerialization isValidJSONObject:objects]) {
            NSError *jsonError = nil;
            if (jsonError) {
                if (failureBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                    failureBlock(error, objects, schema);
                }
            }
            return;
        }
        
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objects options:0 error:&jsonError];
        
        if (jsonError) {
            if (failureBlock) {
                NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                failureBlock(error, objects, schema);
            }
            return;
        }
        
        [request setHTTPBody:jsonData];
        
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForBulkObjectsOfSchema:schema successBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForBulkObjects:objects ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (void)readObjectWithId:(NSString *)objectId
                inSchema:(NSString *)schema
               onSuccess:(SMDataStoreSuccessBlock)successBlock
               onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self readObjectWithId:objectId inSchema:schema options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)readObjectWithId:(NSString *)objectId inSchema:(NSString *)schema options:(SMRequestOptions *)options onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self readObjectWithId:objectId inSchema:schema options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)readObjectWithId:(NSString *)objectId inSchema:(NSString *)schema options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self readObjectWithId:objectId inSchema:schema parameters:nil options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:successBlock onFailure:failureBlock];
}

- (void)updateObjectWithId:(NSString *)objectId inSchema:(NSString *)schema update:(NSDictionary *)updatedFields onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self updateObjectWithId:objectId inSchema:schema update:updatedFields options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)updateObjectWithId:(NSString *)objectId inSchema:(NSString *)schema update:(NSDictionary *)updatedFields options:(SMRequestOptions *)options onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self updateObjectWithId:objectId inSchema:schema update:updatedFields options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)updateObjectWithId:(NSString *)objectId inSchema:(NSString *)schema update:(NSDictionary *)updatedFields options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    if (objectId == nil || schema == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, updatedFields, schema);
        }
    } else {
        NSString *path = [[schema lowercaseString] stringByAppendingPathComponent:[self URLEncodedStringFromValue:objectId]];
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"PUT" path:path parameters:updatedFields];
        
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForSchema:schema withSuccessBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObject:updatedFields ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (void)updateAtomicCounterWithId:(NSString *)objectId
                            field:(NSString *)field
                         inSchema:(NSString *)schema
                               by:(int)increment
                        onSuccess:(SMDataStoreSuccessBlock)successBlock
                        onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self updateAtomicCounterWithId:objectId field:field inSchema:schema by:increment options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)updateAtomicCounterWithId:(NSString *)objectId
                            field:(NSString *)field
                         inSchema:(NSString *)schema
                               by:(int)increment
                      options:(SMRequestOptions *)options
                        onSuccess:(SMDataStoreSuccessBlock)successBlock
                        onFailure:(SMDataStoreFailureBlock)failureBlock
{
    [self updateAtomicCounterWithId:objectId field:field inSchema:schema by:increment options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)updateAtomicCounterWithId:(NSString *)objectId field:(NSString *)field inSchema:(NSString *)schema by:(int)increment options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreFailureBlock)failureBlock
{
    NSDictionary *args = [[NSDictionary dictionary] dictionaryByAppendingCounterUpdateForField:field by:increment];
    [self updateObjectWithId:objectId inSchema:schema update:args options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:successBlock onFailure:failureBlock];
}

- (void)createAndAppendRelatedObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema relatedField:(NSString *)field onSuccess:(SMDataStoreBulkSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self createAndAppendRelatedObjects:objects toObjectWithId:objectId inSchema:schema relatedField:field options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)createAndAppendRelatedObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema relatedField:(NSString *)field options:(SMRequestOptions *)options onSuccess:(SMDataStoreBulkSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self createAndAppendRelatedObjects:objects toObjectWithId:objectId inSchema:schema relatedField:field options:[SMRequestOptions options] successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)createAndAppendRelatedObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema relatedField:(NSString *)field options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreBulkSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    if (objectId == nil || schema == nil || field == nil || objects == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, objectId, schema);
        }
    } else {
        NSString *path = [[[schema lowercaseString] stringByAppendingPathComponent:[self URLEncodedStringFromValue:objectId]] stringByAppendingPathComponent:field];
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"POST" path:path parameters:nil];
        
        if (![NSJSONSerialization isValidJSONObject:objects]) {
            NSError *jsonError = nil;
            if (jsonError) {
                if (failureBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                    failureBlock(error, objectId, schema);
                }
            }
            return;
        }
        
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objects options:0 error:&jsonError];
        
        if (jsonError) {
            if (failureBlock) {
                NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                failureBlock(error, objectId, schema);
            }
            return;
        }

        
        [request setHTTPBody:jsonData];
        
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForBulkObjectsOfSchema:schema successBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObjectId:objectId ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (void)appendObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self appendObjects:objects toObjectWithId:objectId inSchema:schema field:field options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)appendObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field options:(SMRequestOptions *)options onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self appendObjects:objects toObjectWithId:objectId inSchema:schema field:field options:[SMRequestOptions options] successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)appendObjects:(NSArray *)objects toObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    if (objectId == nil || schema == nil || field == nil || objects == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, objectId, schema);
        }
    } else {
        NSString *path = [[[schema lowercaseString] stringByAppendingPathComponent:[self URLEncodedStringFromValue:objectId]] stringByAppendingPathComponent:field];
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"PUT" path:path parameters:nil];
        
        if (![NSJSONSerialization isValidJSONObject:objects]) {
            NSError *jsonError = nil;
            if (jsonError) {
                if (failureBlock) {
                    NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                    failureBlock(error, objectId, schema);
                }
            }
            return;
        }
        
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objects options:0 error:&jsonError];
        
        if (jsonError) {
            if (failureBlock) {
                NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
                failureBlock(error, objectId, schema);
            }
            return;
        }
        
        
        [request setHTTPBody:jsonData];
        
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForSchema:schema withSuccessBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObjectId:objectId ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (void)deleteObjects:(NSArray *)objects fromObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field cascadeDelete:(BOOL)cascadeDelete onSuccess:(SMSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self deleteObjects:objects fromObjectWithId:objectId inSchema:schema field:field cascadeDelete:cascadeDelete options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)deleteObjects:(NSArray *)objects fromObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field cascadeDelete:(BOOL)cascadeDelete options:(SMRequestOptions *)options onSuccess:(SMSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self deleteObjects:objects fromObjectWithId:objectId inSchema:schema field:field cascadeDelete:cascadeDelete options:[SMRequestOptions options] successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)deleteObjects:(NSArray *)objects fromObjectWithId:(NSString *)objectId inSchema:(NSString *)schema field:(NSString *)field cascadeDelete:(BOOL)cascadeDelete options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    if (objectId == nil || schema == nil || field == nil || objects == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, objectId, schema);
        }
    } else {
        NSString *objectsString = [objects componentsJoinedByString:@","];
        NSString *path = [[[[schema lowercaseString] stringByAppendingPathComponent:[self URLEncodedStringFromValue:objectId]] stringByAppendingPathComponent:field] stringByAppendingPathComponent:objectsString];
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"DELETE" path:path parameters:nil];
        
        if (cascadeDelete) {
            [options setValue:@"true" forHeaderKey:@"X-StackMob-CascadeDelete"];
        } else {
            [options setValue:@"false" forHeaderKey:@"X-StackMob-CascadeDelete"];
        }
        
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForSuccessBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObjectId:objectId ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (void)deleteObjectId:(NSString *)objectId inSchema:(NSString *)schema onSuccess:(SMDataStoreObjectIdSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self deleteObjectId:objectId inSchema:schema options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)deleteObjectId:(NSString *)objectId inSchema:(NSString *)schema options:(SMRequestOptions *)options onSuccess:(SMDataStoreObjectIdSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    [self deleteObjectId:objectId inSchema:schema options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)deleteObjectId:(NSString *)objectId inSchema:(NSString *)schema options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMDataStoreObjectIdSuccessBlock)successBlock onFailure:(SMDataStoreObjectIdFailureBlock)failureBlock
{
    if (objectId == nil || schema == nil) {
        if (failureBlock) {
            NSError *error = [[NSError alloc] initWithDomain:SMErrorDomain code:SMErrorInvalidArguments userInfo:nil];
            failureBlock(error, objectId, schema);
        }
    } else {
        NSString *path = [[schema lowercaseString] stringByAppendingPathComponent:[self URLEncodedStringFromValue:objectId]];
        
        NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"DELETE" path:path parameters:nil];
        SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForObjectId:objectId ofSchema:schema withSuccessBlock:successBlock];
        SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForObjectId:objectId ofSchema:schema withFailureBlock:failureBlock];
        [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
    }
}

- (NSMutableURLRequest *)requestFromQuery:(SMQuery *)query options:(SMRequestOptions *)options
{
    NSDictionary *requestHeaders    = [query requestHeaders];
    NSDictionary *requestParameters = [query requestParameters];
    NSString *requestPath           = [query schemaName];
    
    NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] requestWithMethod:@"GET" path:requestPath parameters:requestParameters];
    [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:(NSString *)obj forHTTPHeaderField:(NSString *)key];
    }];
    return request;
}

- (void)performQuery:(SMQuery *)query onSuccess:(SMResultsSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    [self performQuery:query options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)performQuery:(SMQuery *)query options:(SMRequestOptions *)options onSuccess:(SMResultsSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    [self performQuery:query options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)performQuery:(SMQuery *)query options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMResultsSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    NSMutableURLRequest *request = [self requestFromQuery:query options:options];
    
    SMFullResponseSuccessBlock urlSuccessBlock = [self SMFullResponseSuccessBlockForQuerySuccessBlock:successBlock];
    SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForFailureBlock:failureBlock];
    
    [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
}

- (void)performCount:(SMQuery *)query onSuccess:(SMCountSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    [self performCount:query options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];    
}

- (void)performCount:(SMQuery *)query options:(SMRequestOptions *)options onSuccess:(SMCountSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    [self performCount:query options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)performCount:(SMQuery *)query options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMCountSuccessBlock)successBlock onFailure:(SMFailureBlock)failureBlock
{
    SMQuery *countQuery = [[SMQuery alloc] initWithSchema:query.schemaName];
    countQuery.requestParameters = query.requestParameters;
    countQuery.requestHeaders = [query.requestHeaders copy];
    [countQuery fromIndex:0 toIndex:0];
    NSMutableURLRequest *request = [self requestFromQuery:countQuery options:options];
    SMFullResponseSuccessBlock urlSuccessBlock = ^(NSURLRequest *successRequest, NSHTTPURLResponse *response, id JSON) {
        NSString *rangeHeader = [response.allHeaderFields valueForKey:@"Content-Range"];
        //No range header means we've got all the results right here (1 or 0)
        int count = [self countFromRangeHeader:rangeHeader results:JSON];
        if (count < 0) {
            if (failureBlock) {
                failureBlock([NSError errorWithDomain:SMErrorDomain code:SMErrorNoCountAvailable userInfo:nil]);
            }
        } else {
            if (successBlock) {
                successBlock([NSNumber numberWithInt:count]);
            }
        }
    };
    
    SMFullResponseFailureBlock urlFailureBlock = [self SMFullResponseFailureBlockForFailureBlock:failureBlock];
    [self queueRequest:request options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:urlSuccessBlock onFailure:urlFailureBlock];
}

- (void)performCustomCodeRequest:(SMCustomCodeRequest *)customCodeRequest onSuccess:(SMFullResponseSuccessBlock)successBlock onFailure:(SMFullResponseFailureBlock)failureBlock
{
    [self performCustomCodeRequest:customCodeRequest options:[SMRequestOptions options] onSuccess:successBlock onFailure:failureBlock];
}

- (void)performCustomCodeRequest:(SMCustomCodeRequest *)customCodeRequest options:(SMRequestOptions *)options onSuccess:(SMFullResponseSuccessBlock)successBlock onFailure:(SMFullResponseFailureBlock)failureBlock
{
    [self performCustomCodeRequest:customCodeRequest options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)performCustomCodeRequest:(SMCustomCodeRequest *)customCodeRequest options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMFullResponseSuccessBlock)successBlock onFailure:(SMFullResponseFailureBlock)failureBlock
{
    NSMutableURLRequest *request = [[self.session oauthClientWithHTTPS:options.isSecure] customCodeRequest:customCodeRequest options:options];
    
    [self queueCustomCodeRequest:request customCodeRequestInstance:customCodeRequest options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:successBlock onFailure:failureBlock];
}

- (void)retryCustomCodeRequest:(NSURLRequest *)request options:(SMRequestOptions *)options onSuccess:(SMFullResponseSuccessBlock)successBlock onFailure:(SMFullResponseFailureBlock)failureBlock
{
    [self retryCustomCodeRequest:request options:options successCallbackQueue:dispatch_get_main_queue() failureCallbackQueue:dispatch_get_main_queue() onSuccess:successBlock onFailure:failureBlock];
}

- (void)retryCustomCodeRequest:(NSURLRequest *)request options:(SMRequestOptions *)options successCallbackQueue:(dispatch_queue_t)successCallbackQueue failureCallbackQueue:(dispatch_queue_t)failureCallbackQueue onSuccess:(SMFullResponseSuccessBlock)successBlock onFailure:(SMFullResponseFailureBlock)failureBlock
{
    [self queueRequest:[self.session signRequest:request] options:options successCallbackQueue:successCallbackQueue failureCallbackQueue:failureCallbackQueue onSuccess:successBlock onFailure:failureBlock];
}

@end

