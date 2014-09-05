//
//  EWUtil.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  This class serves as the basic file input/output class that handles file namagement and memory management

#import "EWUtil.h"
#import <AdSupport/ASIdentifierManager.h>
#import <NSLogger/NSLogger.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <NSLogger/NSLogger.h>

@implementation EWUtil

+ (NSString *)UUID{
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    return uuid;
    
}
	
+ (NSString *)ADID{
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return adId;
}

+(void)clearMemory{
    //
}

+ (NSDictionary *)timeFromNumber:(double)number{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSInteger hour = floor(number);
    NSInteger minute = round((number - hour)*100);
    dic[@"hour"] = [NSNumber numberWithInteger:hour];
    dic[@"minute"] = [NSNumber numberWithInteger: minute];
    return dic;
}

+ (double)numberFromTime:(NSDictionary *)dic{
    double hour = [(NSNumber *)dic[@"hour"] doubleValue];
    double minute = [(NSNumber *)dic[@"minute"] doubleValue];
    double number = hour + minute/100;
    return number;
}


+ (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

+(BOOL) isFirstTimeLogin{
    
    NSDictionary *option = @{@"firstTime": @"YES"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:option];
    
    NSString *isString = [[NSUserDefaults standardUserDefaults] valueForKey:@"firstTime"];
    
    if ([isString isEqualToString:@"YES"]) {
        
        return YES;
        
    }
    else{
        
        return NO;
    }

}
+(void)setFirstTimeLoginOver{
    
    [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"firstTime"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)uploadImageToParseREST:(UIImage *)uploadImage
{
    
    NSMutableString *urlString = [NSMutableString string];
    [urlString appendString:kParseUploadUrl];
    [urlString appendFormat:@"files/imagefile.jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [request addValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:UIImagePNGRepresentation(uploadImage)];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSString *fileUrl = [httpResponse allHeaderFields][@"Location"];
    
    NSLog(@"%@",fileUrl);
    return fileUrl;

}


#pragma mark - Logging
void EWLog(NSString *format, ...){
    
    
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    

    
#ifdef DEBUG
    //dispatch to NSLOG
    NSString *symbol = [str substringToIndex:3];
    static const NSArray *symbolList;
    symbolList = @[@"***", @"!!!"];//error, warning
    NSInteger level = [symbolList indexOfObject:symbol];
    level = level != NSNotFound ? level : 3;
    if (level <= EW_DEBUG_LEVEL) {
        //LogMessageF(__FILE__,__LINE__,__FUNCTION__, @"Woke", level, @"%@", str);
        LogMessage(@"WOKE", level, str);
    }
#else
    //only send to TestFlight on release version
    TFLog(@"%@", str);
#endif
}

void EWLogInit(){
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    
	NSString *documentsDirectory = [paths objectAtIndex:0];
    
	NSString *fileName =[NSString stringWithFormat:@"%@.log",[NSDate date]];
    
	NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    Logger *logger = LoggerGetDefaultLogger();
    LoggerSetBufferFile(logger, (__bridge CFStringRef)logFilePath);
}


+(NSArray *)readContactsEmailsFromAddressBooks
{
    
    NSMutableArray * friendsEmails = [[NSMutableArray alloc] init];
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBook);
    for(int i = 0; i < CFArrayGetCount(results); i++)
    {
        ABRecordRef person = CFArrayGetValueAtIndex(results, i);
        //读取firstname
//        NSString *personName = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
//        //读取lastname
//        NSString *lastname = (__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
//       
//        //读取middlename
//        NSString *middlename = (__bridge NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);

        
        //获取email多值
        ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
        long emailcount = ABMultiValueGetCount(email);
        for (int x = 0; x < emailcount; x++)
        {
            //获取email Label
//            NSString* emailLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(email, x));
            //获取email值
            NSString* emailContent = (__bridge NSString*)ABMultiValueCopyValueAtIndex(email, x);
            [friendsEmails addObject:emailContent];

        }
    }
//
    CFRelease(results);
    CFRelease(addressBook);
    
    return [friendsEmails copy];
    
}



    
@end
