// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMedia.m instead.

#import "_EWMedia.h"

const struct EWMediaAttributes EWMediaAttributes = {
	.liked = @"liked",
	.message = @"message",
	.played = @"played",
	.priority = @"priority",
	.response = @"response",
	.targetDate = @"targetDate",
	.type = @"type",
};

const struct EWMediaRelationships EWMediaRelationships = {
	.activity = @"activity",
	.author = @"author",
	.mediaFile = @"mediaFile",
	.messages = @"messages",
	.receiver = @"receiver",
};

@implementation EWMediaID
@end

@implementation _EWMedia

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWMedia" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWMedia";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWMedia" inManagedObjectContext:moc_];
}

- (EWMediaID*)objectID {
	return (EWMediaID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"likedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"liked"];
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

@dynamic liked;

- (BOOL)likedValue {
	NSNumber *result = [self liked];
	return [result boolValue];
}

- (void)setLikedValue:(BOOL)value_ {
	[self setLiked:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveLikedValue {
	NSNumber *result = [self primitiveLiked];
	return [result boolValue];
}

- (void)setPrimitiveLikedValue:(BOOL)value_ {
	[self setPrimitiveLiked:[NSNumber numberWithBool:value_]];
}

@dynamic message;

@dynamic played;

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

@dynamic response;

@dynamic targetDate;

@dynamic type;

@dynamic activity;

@dynamic author;

@dynamic mediaFile;

@dynamic messages;

- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];

	[self didAccessValueForKey:@"messages"];
	return result;
}

@dynamic receiver;

@end

