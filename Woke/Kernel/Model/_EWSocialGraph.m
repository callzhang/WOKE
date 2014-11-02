// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWSocialGraph.m instead.

#import "_EWSocialGraph.h"

const struct EWSocialGraphAttributes EWSocialGraphAttributes = {
	.facebookFriends = @"facebookFriends",
	.facebookToken = @"facebookToken",
	.facebookUpdated = @"facebookUpdated",
	.weiboFriends = @"weiboFriends",
	.weiboToken = @"weiboToken",
	.weiboUpdated = @"weiboUpdated",
};

const struct EWSocialGraphRelationships EWSocialGraphRelationships = {
	.owner = @"owner",
};

@implementation EWSocialGraphID
@end

@implementation _EWSocialGraph

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWSocialGraph" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWSocialGraph";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWSocialGraph" inManagedObjectContext:moc_];
}

- (EWSocialGraphID*)objectID {
	return (EWSocialGraphID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic facebookFriends;

@dynamic facebookToken;

@dynamic facebookUpdated;

@dynamic weiboFriends;

@dynamic weiboToken;

@dynamic weiboUpdated;

@dynamic owner;

@end

