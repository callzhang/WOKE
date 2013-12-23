// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaItem.m instead.

#import "_EWMediaItem.h"

const struct EWMediaItemAttributes EWMediaItemAttributes = {
	.audioKey = @"audioKey",
	.createddate = @"createddate",
	.ewmediaitem_id = @"ewmediaitem_id",
	.imageKey = @"imageKey",
	.lastmoddate = @"lastmoddate",
	.mediaType = @"mediaType",
	.message = @"message",
	.title = @"title",
	.videoKey = @"videoKey",
};

const struct EWMediaItemRelationships EWMediaItemRelationships = {
	.author = @"author",
	.groupTask = @"groupTask",
	.tasks = @"tasks",
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
	

	return keyPaths;
}




@dynamic audioKey;






@dynamic createddate;






@dynamic ewmediaitem_id;






@dynamic imageKey;






@dynamic lastmoddate;






@dynamic mediaType;






@dynamic message;






@dynamic title;






@dynamic videoKey;






@dynamic author;

	

@dynamic groupTask;

	
- (NSMutableSet*)groupTaskSet {
	[self willAccessValueForKey:@"groupTask"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"groupTask"];
  
	[self didAccessValueForKey:@"groupTask"];
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
