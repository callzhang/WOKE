// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWActivity.m instead.

#import "_EWActivity.h"

const struct EWActivityAttributes EWActivityAttributes = {
	.completed = @"completed",
	.friendID = @"friendID",
	.friended = @"friended",
	.sleepTime = @"sleepTime",
	.statement = @"statement",
	.time = @"time",
	.type = @"type",
};

const struct EWActivityRelationships EWActivityRelationships = {
	.medias = @"medias",
	.owner = @"owner",
};

@implementation EWActivityID
@end

@implementation _EWActivity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWActivity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWActivity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWActivity" inManagedObjectContext:moc_];
}

- (EWActivityID*)objectID {
	return (EWActivityID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"friendedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"friended"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic completed;

@dynamic friendID;

@dynamic friended;

- (BOOL)friendedValue {
	NSNumber *result = [self friended];
	return [result boolValue];
}

- (void)setFriendedValue:(BOOL)value_ {
	[self setFriended:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveFriendedValue {
	NSNumber *result = [self primitiveFriended];
	return [result boolValue];
}

- (void)setPrimitiveFriendedValue:(BOOL)value_ {
	[self setPrimitiveFriended:[NSNumber numberWithBool:value_]];
}

@dynamic sleepTime;

@dynamic statement;

@dynamic time;

@dynamic type;

@dynamic medias;

- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];

	[self didAccessValueForKey:@"medias"];
	return result;
}

@dynamic owner;

@end

