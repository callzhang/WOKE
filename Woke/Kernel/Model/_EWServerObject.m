// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWServerObject.m instead.

#import "_EWServerObject.h"

const struct EWServerObjectAttributes EWServerObjectAttributes = {
	.createdAt = @"createdAt",
	.objectId = @"objectId",
	.updatedAt = @"updatedAt",
};

@implementation EWServerObjectID
@end

@implementation _EWServerObject

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWServerObject" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWServerObject";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWServerObject" inManagedObjectContext:moc_];
}

- (EWServerObjectID*)objectID {
	return (EWServerObjectID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic createdAt;

@dynamic objectId;

@dynamic updatedAt;

@end

