// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWTaskItem.m instead.

#import "_EWTaskItem.h"

const struct EWTaskItemAttributes EWTaskItemAttributes = {
	.added = @"added",
	.completed = @"completed",
	.createddate = @"createddate",
	.ewtaskitem_id = @"ewtaskitem_id",
	.lastmoddate = @"lastmoddate",
	.length = @"length",
	.state = @"state",
	.statement = @"statement",
	.success = @"success",
	.time = @"time",
};

const struct EWTaskItemRelationships EWTaskItemRelationships = {
	.alarm = @"alarm",
	.medias = @"medias",
	.messages = @"messages",
	.owner = @"owner",
	.pastOwner = @"pastOwner",
	.waker = @"waker",
};

const struct EWTaskItemFetchedProperties EWTaskItemFetchedProperties = {
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
	
	if ([key isEqualToString:@"lengthValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"length"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"stateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"state"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"successValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"success"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic added;






@dynamic completed;






@dynamic createddate;






@dynamic ewtaskitem_id;






@dynamic lastmoddate;






@dynamic length;



- (int16_t)lengthValue {
	NSNumber *result = [self length];
	return [result shortValue];
}

- (void)setLengthValue:(int16_t)value_ {
	[self setLength:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveLengthValue {
	NSNumber *result = [self primitiveLength];
	return [result shortValue];
}

- (void)setPrimitiveLengthValue:(int16_t)value_ {
	[self setPrimitiveLength:[NSNumber numberWithShort:value_]];
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






@dynamic success;



- (BOOL)successValue {
	NSNumber *result = [self success];
	return [result boolValue];
}

- (void)setSuccessValue:(BOOL)value_ {
	[self setSuccess:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSuccessValue {
	NSNumber *result = [self primitiveSuccess];
	return [result boolValue];
}

- (void)setPrimitiveSuccessValue:(BOOL)value_ {
	[self setPrimitiveSuccess:[NSNumber numberWithBool:value_]];
}





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

	

@dynamic owner;

	

@dynamic pastOwner;

	

@dynamic waker;

	
- (NSMutableSet*)wakerSet {
	[self willAccessValueForKey:@"waker"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"waker"];
  
	[self didAccessValueForKey:@"waker"];
	return result;
}
	






@end
