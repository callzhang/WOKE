// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAchievement.m instead.

#import "_EWAchievement.h"

const struct EWAchievementAttributes EWAchievementAttributes = {
	.body = @"body",
	.createdAt = @"createdAt",
	.image = @"image",
	.name = @"name",
	.objectId = @"objectId",
	.time = @"time",
	.type = @"type",
	.updatedAt = @"updatedAt",
};

const struct EWAchievementRelationships EWAchievementRelationships = {
	.owner = @"owner",
};

const struct EWAchievementFetchedProperties EWAchievementFetchedProperties = {
};

@implementation EWAchievementID
@end

@implementation _EWAchievement

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWAchievement" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWAchievement";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWAchievement" inManagedObjectContext:moc_];
}

- (EWAchievementID*)objectID {
	return (EWAchievementID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic body;






@dynamic createdAt;






@dynamic image;






@dynamic name;






@dynamic objectId;






@dynamic time;






@dynamic type;






@dynamic updatedAt;






@dynamic owner;

	






@end
