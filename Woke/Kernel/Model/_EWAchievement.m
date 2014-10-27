// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWAchievement.m instead.

#import "_EWAchievement.h"

const struct EWAchievementAttributes EWAchievementAttributes = {
	.body = @"body",
	.image = @"image",
	.name = @"name",
	.time = @"time",
	.type = @"type",
};

const struct EWAchievementRelationships EWAchievementRelationships = {
	.owner = @"owner",
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

@dynamic image;

@dynamic name;

@dynamic time;

@dynamic type;

@dynamic owner;

@end

