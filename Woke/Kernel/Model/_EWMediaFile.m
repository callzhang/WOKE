// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaFile.m instead.

#import "_EWMediaFile.h"

const struct EWMediaFileAttributes EWMediaFileAttributes = {
	.audio = @"audio",
	.image = @"image",
	.thumbnail = @"thumbnail",
	.video = @"video",
};

const struct EWMediaFileRelationships EWMediaFileRelationships = {
	.medias = @"medias",
};

@implementation EWMediaFileID
@end

@implementation _EWMediaFile

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWMediaFile" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWMediaFile";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWMediaFile" inManagedObjectContext:moc_];
}

- (EWMediaFileID*)objectID {
	return (EWMediaFileID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic audio;

@dynamic image;

@dynamic thumbnail;

@dynamic video;

@dynamic medias;

- (NSMutableSet*)mediasSet {
	[self willAccessValueForKey:@"medias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"medias"];

	[self didAccessValueForKey:@"medias"];
	return result;
}

@end

