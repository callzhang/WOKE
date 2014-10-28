// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMessage.m instead.

#import "_EWMessage.h"

const struct EWMessageAttributes EWMessageAttributes = {
	.read = @"read",
	.text = @"text",
	.thumbnail = @"thumbnail",
	.time = @"time",
	.type = @"type",
};

const struct EWMessageRelationships EWMessageRelationships = {
	.media = @"media",
	.recipient = @"recipient",
	.sender = @"sender",
};

@implementation EWMessageID
@end

@implementation _EWMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWMessage" inManagedObjectContext:moc_];
}

- (EWMessageID*)objectID {
	return (EWMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic read;

@dynamic text;

@dynamic thumbnail;

@dynamic time;

@dynamic type;

@dynamic media;

@dynamic recipient;

@dynamic sender;

@end

