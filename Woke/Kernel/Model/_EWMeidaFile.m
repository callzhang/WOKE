// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMeidaFile.m instead.

#import "_EWMeidaFile.h"

const struct EWMeidaFileAttributes EWMeidaFileAttributes = {
	.audio = @"audio",
	.image = @"image",
	.thumbnail = @"thumbnail",
	.video = @"video",
};

const struct EWMeidaFileRelationships EWMeidaFileRelationships = {
	.medias = @"medias",
};

@implementation EWMeidaFileID
@end

@implementation _EWMeidaFile

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWMeidaFile" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWMeidaFile";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWMeidaFile" inManagedObjectContext:moc_];
}

- (EWMeidaFileID*)objectID {
	return (EWMeidaFileID*)[super objectID];
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

