/*
 * Copyright 2012-2013 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "NSEntityDescription+StackMobSerialization.h"
#import "SMUserManagedObject.h"
#import "SMError.h"

@implementation NSEntityDescription (StackMobSerialization)

+ (void)SM_throwExceptionNoPrimaryKey:(NSEntityDescription *)entity
{
    [NSException raise:SMExceptionIncompatibleObject format:@"Unable to locate a primary key field for %@.  If this is an Entity which describes user objects, and your managed object subclass inherits from SMUserManagedObject, make sure to include an attribute that matches the value returned by your SMClient's userPrimaryKeyField property.", [entity description]];
}

- (NSString *)SMSchema
{
    return [[self name] lowercaseString];
}

- (NSString *)primaryKeyField
{
    NSString *objectIdField = nil;
     
    // Search for schemanameId
    objectIdField = [NSString stringWithFormat:@"%@Id", [self SMSchema]];
    if ([[self propertiesByName] objectForKey:objectIdField] != nil) {
        return objectIdField;
    }
    
    objectIdField = nil;
    
    // Search for schemaname_id
    objectIdField = [NSString stringWithFormat:@"%@_id", [self SMSchema]];
    if ([[self propertiesByName] objectForKey:objectIdField] != nil) {
        return objectIdField;
    }
    
    return nil;
}

- (NSString *)SMPrimaryKeyField
{
    NSString *primaryKeyField = [self primaryKeyField];
    if (!primaryKeyField) {
        [NSEntityDescription SM_throwExceptionNoPrimaryKey:self];
    }
    return [self SMFieldNameForProperty:[[self propertiesByName] objectForKey:primaryKeyField]];
}

- (NSString *)SMFieldNameForProperty:(NSPropertyDescription *)property 
{
    NSCharacterSet *uppercaseSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSMutableString *stringToReturn = [[property name] mutableCopy];
    
    NSRange range = [stringToReturn rangeOfCharacterFromSet:uppercaseSet];
    if (range.location == 0) {
        [NSException raise:SMExceptionIncompatibleObject format:@"Property %@ cannot start with an uppercase letter.  Acceptable formats are camelCase or lowercase letters with optional underscores", [property name]];
    }
    while (range.location != NSNotFound) {
        
        unichar letter = [stringToReturn characterAtIndex:range.location] + 32;
        [stringToReturn replaceCharactersInRange:range withString:[NSString stringWithFormat:@"_%C", letter]];
        range = [stringToReturn rangeOfCharacterFromSet:uppercaseSet];
    }
    
    return stringToReturn;
}

- (NSPropertyDescription *)propertyForSMFieldName:(NSString *)fieldName
{
    // Look for matching names with all lowercase or underscores first
    NSPropertyDescription *propertyToReturn = [[self propertiesByName] objectForKey:fieldName];
    if (propertyToReturn) {
        return propertyToReturn;
    }
    
    // Then look for camelCase equivalents
    NSCharacterSet *underscoreSet = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    NSMutableString *convertedFieldName = [fieldName mutableCopy];
    
    NSRange range = [convertedFieldName rangeOfCharacterFromSet:underscoreSet];
    while (range.location != NSNotFound) {
        
        unichar letter = [convertedFieldName characterAtIndex:(range.location + 1)] - 32;
        [convertedFieldName replaceCharactersInRange:NSMakeRange(range.location, 2) withString:[NSString stringWithFormat:@"%C", letter]];
        range = [convertedFieldName rangeOfCharacterFromSet:underscoreSet];
    }
    
    propertyToReturn = [[self propertiesByName] objectForKey:convertedFieldName];
    if (propertyToReturn) {
        return propertyToReturn;
    }
    
    // No matching properties
    return nil;
}

@end
