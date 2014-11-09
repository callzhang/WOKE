// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWNotification.m instead.

#import "_EWNotification.h"

const struct EWNotificationAttributes EWNotificationAttributes = {
	.completed = @"completed",
	.importance = @"importance",
	.receiver = @"receiver",
	.sender = @"sender",
	.type = @"type",
	.userInfo = @"userInfo",
};

const struct EWNotificationRelationships EWNotificationRelationships = {
	.owner = @"owner",
};

const struct EWNotificationFetchedProperties EWNotificationFetchedProperties = {
};

@implementation EWNotificationID
@end

@implementation _EWNotification

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWNotification" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWNotification";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWNotification" inManagedObjectContext:moc_];
}

- (EWNotificationID*)objectID {
	return (EWNotificationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"importanceValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"importance"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic completed;






@dynamic importance;



- (int64_t)importanceValue {
	NSNumber *result = [self importance];
	return [result longLongValue];
}

- (void)setImportanceValue:(int64_t)value_ {
	[self setImportance:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveImportanceValue {
	NSNumber *result = [self primitiveImportance];
	return [result longLongValue];
}

- (void)setPrimitiveImportanceValue:(int64_t)value_ {
	[self setPrimitiveImportance:[NSNumber numberWithLongLong:value_]];
}





@dynamic receiver;






@dynamic sender;






@dynamic type;






@dynamic userInfo;






@dynamic owner;

	






@end
