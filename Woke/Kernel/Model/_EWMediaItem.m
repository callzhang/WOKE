// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.m instead.

#import "_EWMediaItem.h"

const struct EWMediaItemAttributes EWMediaItemAttributes = {
	.audioKey = @"audioKey",
	.buzzKey = @"buzzKey",
	.createdAt = @"createdAt",
	.fixedDate = @"fixedDate",
	.imageKey = @"imageKey",
	.message = @"message",
	.objectId = @"objectId",
	.played = @"played",
	.priority = @"priority",
	.readTime = @"readTime",
	.type = @"type",
	.updatedAt = @"updatedAt",
	.videoKey = @"videoKey",
};

const struct EWMediaItemRelationships EWMediaItemRelationships = {
	.author = @"author",
	.groupTask = @"groupTask",
	.receiver = @"receiver",
	.task = @"task",
};

const struct EWMediaItemFetchedProperties EWMediaItemFetchedProperties = {
};

@implementation EWMediaItemID
@end

@implementation _EWMediaItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWMediaItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWMediaItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWMediaItem" inManagedObjectContext:moc_];
}

- (EWMediaItemID*)objectID {
	return (EWMediaItemID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"playedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"played"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"priorityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"priority"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic audioKey;






@dynamic buzzKey;






@dynamic createdAt;






@dynamic fixedDate;






@dynamic imageKey;






@dynamic message;






@dynamic objectId;






@dynamic played;



- (BOOL)playedValue {
	NSNumber *result = [self played];
	return [result boolValue];
}

- (void)setPlayedValue:(BOOL)value_ {
	[self setPlayed:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitivePlayedValue {
	NSNumber *result = [self primitivePlayed];
	return [result boolValue];
}

- (void)setPrimitivePlayedValue:(BOOL)value_ {
	[self setPrimitivePlayed:[NSNumber numberWithBool:value_]];
}





@dynamic priority;



- (int64_t)priorityValue {
	NSNumber *result = [self priority];
	return [result longLongValue];
}

- (void)setPriorityValue:(int64_t)value_ {
	[self setPriority:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitivePriorityValue {
	NSNumber *result = [self primitivePriority];
	return [result longLongValue];
}

- (void)setPrimitivePriorityValue:(int64_t)value_ {
	[self setPrimitivePriority:[NSNumber numberWithLongLong:value_]];
}





@dynamic readTime;






@dynamic type;






@dynamic updatedAt;






@dynamic videoKey;






@dynamic author;

	

@dynamic groupTask;

	

@dynamic receiver;

	

@dynamic task;

	






@end
