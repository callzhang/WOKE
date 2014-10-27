// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWTaskItem.m instead.

#import "_EWTaskItem.h"

const struct EWTaskItemAttributes EWTaskItemAttributes = {
	.completed = @"completed",
	.log = @"log",
	.state = @"state",
	.statement = @"statement",
	.time = @"time",
};

const struct EWTaskItemRelationships EWTaskItemRelationships = {
	.alarm = @"alarm",
	.medias = @"medias",
	.messages = @"messages",
	.owner = @"owner",
	.pastOwner = @"pastOwner",
};

@implementation EWTaskItemID
@end

@implementation _EWTaskItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWTaskItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWTaskItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWTaskItem" inManagedObjectContext:moc_];
}

- (EWTaskItemID*)objectID {
	return (EWTaskItemID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"stateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"state"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic completed;

@dynamic log;

@dynamic state;

- (BOOL)stateValue {
	NSNumber *result = [self state];
	return [result boolValue];
}

- (void)setStateValue:(BOOL)value_ {
	[self setState:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveStateValue {
	NSNumber *result = [self primitiveState];
	return [result boolValue];
}

- (void)setPrimitiveStateValue:(BOOL)value_ {
	[self setPrimitiveState:[NSNumber numberWithBool:value_]];
}

@dynamic statement;

@dynamic time;

@dynamic alarm;

@dynamic medias;

- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];

	[self didAccessValueForKey:@"medias"];
	return result;
}

@dynamic messages;

- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];

	[self didAccessValueForKey:@"messages"];
	return result;
}

@dynamic owner;

@dynamic pastOwner;

@end

