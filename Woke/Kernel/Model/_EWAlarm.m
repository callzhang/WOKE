// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAlarm.m instead.

#import "_EWAlarm.h"

const struct EWAlarmAttributes EWAlarmAttributes = {
	.important = @"important",
	.state = @"state",
	.statement = @"statement",
	.time = @"time",
	.todo = @"todo",
	.tone = @"tone",
};

const struct EWAlarmRelationships EWAlarmRelationships = {
	.owner = @"owner",
};

@implementation EWAlarmID
@end

@implementation _EWAlarm

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWAlarm" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWAlarm";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWAlarm" inManagedObjectContext:moc_];
}

- (EWAlarmID*)objectID {
	return (EWAlarmID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"importantValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"important"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"stateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"state"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic important;

- (BOOL)importantValue {
	NSNumber *result = [self important];
	return [result boolValue];
}

- (void)setImportantValue:(BOOL)value_ {
	[self setImportant:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveImportantValue {
	NSNumber *result = [self primitiveImportant];
	return [result boolValue];
}

- (void)setPrimitiveImportantValue:(BOOL)value_ {
	[self setPrimitiveImportant:[NSNumber numberWithBool:value_]];
}

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

@dynamic todo;

@dynamic tone;

@dynamic owner;

@end

