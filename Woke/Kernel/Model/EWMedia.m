#import "EWMedia.h"
#import "EWMediaFile.h"

@interface EWMedia ()

// Private interface goes here.

@end

@implementation EWMedia


#pragma mark - create media
+ (EWMedia *)newMedia{
    NSParameterAssert([NSThread isMainThread]);
    EWMedia *m = [EWMedia createEntity];
    m.updatedAt = [NSDate date];
    m.author = [EWSession sharedSession].currentUser;
    return m;
}


#pragma mark - validate
- (BOOL)validate{
    BOOL good = YES;
    if(!self.type){
        good = NO;
    }
    
    if (!self.author) {
        good = NO;
    }
    
    if ([self.type isEqualToString:kMediaTypeVoice]) {
        if(!self.mediaFile){
            DDLogError(@"Media %@ type voice with no mediaFile.", self.serverID);
            good = NO;
        }
    }
    
    if (!self.receiver && !self.activity) {
        DDLogError(@"Found media %@ with no receiver and no activity.", self.serverID);
        good = NO;
    }
    
    return good;
}

- (void)createACL{
    PFObject *m = self.parseObject;
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    PFObject *PO = self.receiver.parseObject;
    [acl setReadAccess:YES forUser:(PFUser *)PO];
    [acl setReadAccess:YES forUser:(PFUser *)PO];
    m.ACL = acl;
    NSLog(@"ACL created for media(%@) with access for %@", self.objectId, self.receiver.serverID);
}

+ (EWMedia *)getMediaByID:(NSString *)mediaID{
    return [EWMedia findByAttribute:kParseObjectID withValue:mediaID].firstObject;
}


#pragma mark - DELETE
- (void)remove{
    [self deleteEntity];
    [EWSync save];
}


- (void)downloadMediaFile{
    //TODO;
}

#pragma mark - Underlying data
- (NSData *)audio{
    //TODO
    return nil;
}

- (NSString *)audioKey{
    //TODO
    return nil;
}
@end
