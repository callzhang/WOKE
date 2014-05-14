// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWGroupTask.m instead.

#import "_EWGroupTask.h"

const struct EWGroupTaskAttributes EWGroupTaskAttributes = {
	.added = @"added",
	.city = @"city",
	.createdAt = @"createdAt",
	.objectId = @"objectId",
	.region = @"region",
	.time = @"time",
	.updatedId = @"updatedId",
};

const struct EWGroupTaskRelationships EWGroupTaskRelationships = {
	.medias = @"medias",
	.messages = @"messages",
	.participents = @"participents",
};

const struct EWGroupTaskFetchedProperties EWGroupTaskFetchedProperties = {
};

@implementation EWGroupTaskID
@end

@implementation _EWGroupTask

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWGroupTask" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWGroupTask";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWGroupTask" inManagedObjectContext:moc_];
}

- (EWGroupTaskID*)objectID {
	return (EWGroupTaskID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic added;






@dynamic city;






@dynamic createdAt;






@dynamic objectId;






@dynamic region;






@dynamic time;






@dynamic updatedId;






@dynamic medias;

	
- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];
  
	[self didAccessValueForKey:@"medias"];
	return result;
}
	

@dynamic messages;

	

@dynamic participents;

	
- (NSMutableSet*)participentsSet {
	[self willAccessValueForKey:@"participents"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"participents"];
  
	[self didAccessValueForKey:@"participents"];
	return result;
}
	






@end
