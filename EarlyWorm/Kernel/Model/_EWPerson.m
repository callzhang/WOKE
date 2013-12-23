// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.m instead.

#import "_EWPerson.h"

const struct EWPersonAttributes EWPersonAttributes = {
	.bgImageKey = @"bgImageKey",
	.birthday = @"birthday",
	.city = @"city",
	.createddate = @"createddate",
	.email = @"email",
	.facebook = @"facebook",
	.gender = @"gender",
	.lastLocation = @"lastLocation",
	.lastSeenDate = @"lastSeenDate",
	.lastmoddate = @"lastmoddate",
	.name = @"name",
	.preferenceString = @"preferenceString",
	.profilePicKey = @"profilePicKey",
	.region = @"region",
	.statement = @"statement",
	.username = @"username",
	.weibo = @"weibo",
};

const struct EWPersonRelationships EWPersonRelationships = {
	.alarms = @"alarms",
	.friended = @"friended",
	.friends = @"friends",
	.groupTasks = @"groupTasks",
	.groups = @"groups",
	.groupsManaging = @"groupsManaging",
	.medias = @"medias",
	.pastTasks = @"pastTasks",
	.receivedMessages = @"receivedMessages",
	.sentMessages = @"sentMessages",
	.tasks = @"tasks",
	.tasksHelped = @"tasksHelped",
};

const struct EWPersonFetchedProperties EWPersonFetchedProperties = {
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
	

	return keyPaths;
}




@dynamic bgImageKey;






@dynamic birthday;






@dynamic city;






@dynamic createddate;






@dynamic email;






@dynamic facebook;






@dynamic gender;






@dynamic lastLocation;






@dynamic lastSeenDate;






@dynamic lastmoddate;






@dynamic name;






@dynamic preferenceString;






@dynamic profilePicKey;






@dynamic region;






@dynamic statement;






@dynamic username;






@dynamic weibo;






@dynamic alarms;

	
- (NSMutableSet*)alarmsSet {
	[self willAccessValueForKey:@"alarms"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"alarms"];
  
	[self didAccessValueForKey:@"alarms"];
	return result;
}
	

@dynamic friended;

	
- (NSMutableSet*)friendedSet {
	[self willAccessValueForKey:@"friended"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friended"];
  
	[self didAccessValueForKey:@"friended"];
	return result;
}
	

@dynamic friends;

	
- (NSMutableSet*)friendsSet {
	[self willAccessValueForKey:@"friends"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friends"];
  
	[self didAccessValueForKey:@"friends"];
	return result;
}
	

@dynamic groupTasks;

	
- (NSMutableSet*)groupTasksSet {
	[self willAccessValueForKey:@"groupTasks"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"groupTasks"];
  
	[self didAccessValueForKey:@"groupTasks"];
	return result;
}
	

@dynamic groups;

	
- (NSMutableSet*)groupsSet {
	[self willAccessValueForKey:@"groups"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"groups"];
  
	[self didAccessValueForKey:@"groups"];
	return result;
}
	

@dynamic groupsManaging;

	
- (NSMutableSet*)groupsManagingSet {
	[self willAccessValueForKey:@"groupsManaging"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"groupsManaging"];
  
	[self didAccessValueForKey:@"groupsManaging"];
	return result;
}
	

@dynamic medias;

	
- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];
  
	[self didAccessValueForKey:@"medias"];
	return result;
}
	

@dynamic pastTasks;

	
- (NSMutableSet*)pastTasksSet {
	[self willAccessValueForKey:@"pastTasks"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"pastTasks"];
  
	[self didAccessValueForKey:@"pastTasks"];
	return result;
}
	

@dynamic receivedMessages;

	
- (NSMutableSet*)receivedMessagesSet {
	[self willAccessValueForKey:@"receivedMessages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"receivedMessages"];
  
	[self didAccessValueForKey:@"receivedMessages"];
	return result;
}
	

@dynamic sentMessages;

	
- (NSMutableSet*)sentMessagesSet {
	[self willAccessValueForKey:@"sentMessages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"sentMessages"];
  
	[self didAccessValueForKey:@"sentMessages"];
	return result;
}
	

@dynamic tasks;

	
- (NSMutableSet*)tasksSet {
	[self willAccessValueForKey:@"tasks"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tasks"];
  
	[self didAccessValueForKey:@"tasks"];
	return result;
}
	

@dynamic tasksHelped;

	
- (NSMutableSet*)tasksHelpedSet {
	[self willAccessValueForKey:@"tasksHelped"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tasksHelped"];
  
	[self didAccessValueForKey:@"tasksHelped"];
	return result;
}
	






@end
