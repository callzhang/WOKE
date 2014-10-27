// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.m instead.

#import "_EWMediaItem.h"

const struct EWMediaItemAttributes EWMediaItemAttributes = {
	.audio = @"audio",
	.buzzKey = @"buzzKey",
	.image = @"image",
	.message = @"message",
	.played = @"played",
	.priority = @"priority",
	.readTime = @"readTime",
	.targetDate = @"targetDate",
	.thumbnail = @"thumbnail",
	.type = @"type",
	.video = @"video",
};

const struct EWMediaItemRelationships EWMediaItemRelationships = {
	.author = @"author",
	.groupTask = @"groupTask",
	.receivers = @"receivers",
	.tasks = @"tasks",
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

@dynamic audio;

@dynamic buzzKey;

@dynamic image;

@dynamic message;

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

@dynamic targetDate;

@dynamic thumbnail;

@dynamic type;

@dynamic video;

@dynamic author;

@dynamic groupTask;

@dynamic receivers;

- (NSMutableSet*)receiversSet {
	[self willAccessValueForKey:@"receivers"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"receivers"];

	[self didAccessValueForKey:@"receivers"];
	return result;
}

@dynamic tasks;

- (NSMutableSet*)tasksSet {
	[self willAccessValueForKey:@"tasks"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tasks"];

	[self didAccessValueForKey:@"tasks"];
	return result;
}

@end

