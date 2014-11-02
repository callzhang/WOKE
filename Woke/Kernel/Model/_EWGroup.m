// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWGroup.m instead.

#import "_EWGroup.h"

const struct EWGroupAttributes EWGroupAttributes = {
	.imageKey = @"imageKey",
	.name = @"name",
	.statement = @"statement",
	.topic = @"topic",
	.wakeupTime = @"wakeupTime",
};

const struct EWGroupRelationships EWGroupRelationships = {
	.admin = @"admin",
	.member = @"member",
};

@implementation EWGroupID
@end

@implementation _EWGroup

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWGroup" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWGroup";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWGroup" inManagedObjectContext:moc_];
}

- (EWGroupID*)objectID {
	return (EWGroupID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic imageKey;

@dynamic name;

@dynamic statement;

@dynamic topic;

@dynamic wakeupTime;

@dynamic admin;

- (NSMutableSet*)adminSet {
	[self willAccessValueForKey:@"admin"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"admin"];

	[self didAccessValueForKey:@"admin"];
	return result;
}

@dynamic member;

- (NSMutableSet*)memberSet {
	[self willAccessValueForKey:@"member"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"member"];

	[self didAccessValueForKey:@"member"];
	return result;
}

@end

