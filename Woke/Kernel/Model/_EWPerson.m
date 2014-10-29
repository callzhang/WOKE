// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.m instead.

#import "_EWPerson.h"

const struct EWPersonAttributes EWPersonAttributes = {
	.bgImage = @"bgImage",
	.birthday = @"birthday",
	.cachedInfo = @"cachedInfo",
	.city = @"city",
	.email = @"email",
	.facebook = @"facebook",
	.gender = @"gender",
	.history = @"history",
	.images = @"images",
	.lastLocation = @"lastLocation",
	.name = @"name",
	.preference = @"preference",
	.profilePic = @"profilePic",
	.region = @"region",
	.score = @"score",
	.statement = @"statement",
	.username = @"username",
	.weibo = @"weibo",
};

const struct EWPersonRelationships EWPersonRelationships = {
	.achievements = @"achievements",
	.activities = @"activities",
	.alarms = @"alarms",
	.friends = @"friends",
	.medias = @"medias",
	.notifications = @"notifications",
	.socialGraph = @"socialGraph",
	.unreadMedias = @"unreadMedias",
};

@implementation EWPersonID
@end

@implementation _EWPerson

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWPerson" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWPerson";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWPerson" inManagedObjectContext:moc_];
}

- (EWPersonID*)objectID {
	return (EWPersonID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"scoreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"score"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic bgImage;

@dynamic birthday;

@dynamic cachedInfo;

@dynamic city;

@dynamic email;

@dynamic facebook;

@dynamic gender;

@dynamic history;

@dynamic images;

@dynamic lastLocation;

@dynamic name;

@dynamic preference;

@dynamic profilePic;

@dynamic region;

@dynamic score;

- (float)scoreValue {
	NSNumber *result = [self score];
	return [result floatValue];
}

- (void)setScoreValue:(float)value_ {
	[self setScore:[NSNumber numberWithFloat:value_]];
}

- (float)primitiveScoreValue {
	NSNumber *result = [self primitiveScore];
	return [result floatValue];
}

- (void)setPrimitiveScoreValue:(float)value_ {
	[self setPrimitiveScore:[NSNumber numberWithFloat:value_]];
}

@dynamic statement;

@dynamic username;

@dynamic weibo;

@dynamic achievements;

- (NSMutableSet*)achievementsSet {
	[self willAccessValueForKey:@"achievements"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"achievements"];

	[self didAccessValueForKey:@"achievements"];
	return result;
}

@dynamic activities;

- (NSMutableSet*)activitiesSet {
	[self willAccessValueForKey:@"activities"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"activities"];

	[self didAccessValueForKey:@"activities"];
	return result;
}

@dynamic alarms;

- (NSMutableSet*)alarmsSet {
	[self willAccessValueForKey:@"alarms"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"alarms"];

	[self didAccessValueForKey:@"alarms"];
	return result;
}

@dynamic friends;

- (NSMutableSet*)friendsSet {
	[self willAccessValueForKey:@"friends"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friends"];

	[self didAccessValueForKey:@"friends"];
	return result;
}

@dynamic medias;

- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];

	[self didAccessValueForKey:@"medias"];
	return result;
}

@dynamic notifications;

- (NSMutableSet*)notificationsSet {
	[self willAccessValueForKey:@"notifications"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"notifications"];

	[self didAccessValueForKey:@"notifications"];
	return result;
}

@dynamic socialGraph;

@dynamic unreadMedias;

- (NSMutableSet*)unreadMediasSet {
	[self willAccessValueForKey:@"unreadMedias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"unreadMedias"];

	[self didAccessValueForKey:@"unreadMedias"];
	return result;
}

@end

