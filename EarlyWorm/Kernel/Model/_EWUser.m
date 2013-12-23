// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWUser.m instead.

#import "_EWUser.h"

const struct EWUserAttributes EWUserAttributes = {
	.fbID = @"fbID",
	.fbToken = @"fbToken",
	.parseID = @"parseID",
	.password = @"password",
	.userName = @"userName",
	.uuid = @"uuid",
	.weiboID = @"weiboID",
	.weiboToken = @"weiboToken",
	.weixinID = @"weixinID",
	.weixinToken = @"weixinToken",
};

const struct EWUserRelationships EWUserRelationships = {
	.person = @"person",
};

const struct EWUserFetchedProperties EWUserFetchedProperties = {
};

@implementation EWUserID
@end

@implementation _EWUser

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWUser" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWUser";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWUser" inManagedObjectContext:moc_];
}

- (EWUserID*)objectID {
	return (EWUserID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic fbID;






@dynamic fbToken;






@dynamic parseID;






@dynamic password;






@dynamic userName;






@dynamic uuid;






@dynamic weiboID;






@dynamic weiboToken;






@dynamic weixinID;






@dynamic weixinToken;






@dynamic person;

	






@end
