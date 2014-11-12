//
//  EWDefines.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

//#ifndef EarlyWorm_Defines_h
//#define EarlyWorm_Defines_h

//System
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iOS7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)

#define kAppName                        @"Woke"
#define kAppVersion                     @"0.8.0"
#define BACKGROUND_TEST                 YES


#define kCustomWhite                    EWSTR2COLOR(@"#F5F5F5")
#define kCustomGray                     EWSTR2COLOR(@"48494B")
#define kColorMediumGray                EWSTR2COLOR(@"7e7e7e")
#define kCustomLightGray                EWSTR2COLOR(@"#DDDDDD")


// Keys
#define kParseKeyDevelopment            @"4757c535-5583-46f9-8a55-3b8276d96f06"
#define kParseKeyProduction             @""
#define kParsePushUrl                   @"https://api.parse.com/1/push"
#define kParseUploadUrl                 @"https://api.parse.com/1/"
#define kParseApplicationId             @"p1OPo3q9bY2ANh8KpE4TOxCHeB6rZ8oR7SrbZn6Z"
#define kParseClientKey                 @"9yfUenOzHJYOTVLIFfiPCt8QOo5Ca8fhU8Yqw9yb"
#define kParseRestAPIId                 @"lGJTP5XCAq0O3gDyjjRjYtWui6pAJxdyDSTPXzkL"
#define kParseMasterKey                 @"yTKxNzkIm79nLPyNSycVY3lz32b434bZUu0koGSD"
#define AWS_ACCESS_KEY_ID               @"AKIAIB2BXKRPL3FCWJYA"
#define AWS_SECRET_KEY                  @"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"
#define AWS_SNS_APP_ARN                 @"arn:aws:sns:us-west-2:260520558889:app/APNS_SANDBOX/Woke_Dev"
#define TESTFLIGHT_ACCESS_KEY           @"e1ffe70a-26bf-4db0-91c8-eb2d1d362cb3"
#define WokeUserID                      @"CvCaWauseD"
#define KATConnectKey                   @"61c58f4a6f819d0f209606bdf5e9eeadabfc73529dba358cd079df0dc6dd1102"



// 任务宏
#define EW_DEBUG_LEVEL                  3//defined logging level
#define LOCALSTR(x)                     NSLocalizedString(x,nil)
#define EWAlert(str)                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

#define UIColorFromHex(rgbValue)        [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define TICK                            NSDate *startTime = [NSDate date];
#define TOCK                            NSLog(@"Time: %f", -[startTime timeIntervalSinceNow]);

//Logging
#define NSLog                           EWLog

//Global parameters
#define nWeeksToSchedule				1
#define nLocalNotifPerTask              5
#define kAlarmTimerCheckInterval        90 //10 min
#define alarmInterval                   600 //10 min
#define kMaxWakeTime                    3600 // 60min
#define kMediaPlayInterval              5 //5s
#define kBackgroundFetchInterval        600.0 //TODO: possible conflict with serverUpdateInterval
#define kSocialGraphUpdateInterval      3600*24*7
#define kMaxVoicePerTask                3
#define kLoopMediaPlayCount             100
#define kServerUpdateInterval			7200

//DEFAULT DATA
#define ringtoneNameList                @[@"Autumn Spring.caf", @"Daybreak.caf", @"Drive.caf", @"Parisian Dream.caf", @"Sunny Afternoon.caf", @"Tropical Delight.caf"]
#define weekdays                        @[@"Sunday", @"Monday",@"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"]
#define weekdayshort                    @[@"Sun", @"Mon",@"Tue", @"Wed", @"Thur", @"Fri", @"Sat"]
#define monthShort                      @[@"Jan.",@"Feb.",@"Mar.",@"Apr.",@"May.",@"Jun.",@"Jul.",@"Aug.",@"Sept.",@"Oct.",@"Nov.",@"Dec."]
#define defaultAlarmTimes               @[@8.00, @8.00, @8.00, @8.00, @8.00, @8.00, @8.00]
#define kUserDefaults                   @{@"DefaultTone": @"Autumn Spring.caf", @"SleepDuration":@8.0, kSocialLevel:kSocialLevelEveryone, @"FirstTime":@YES, @"SkipTutorial":@NO, @"buzzSound":@"default", @"BedTimeNotification":@YES}
#define kSocialLevel                    @"SocialLevel"
#define kSocialLevelFriends             @"Friends_only"
#define kSocialLevelFriendCircle        @"Friend_Circle"
#define kSocialLevelEveryone            @"Everyone"

//sleep
#define kSleepDuration                  @"SleepDuration"
#define kBedTimeNotification            @"BedTimeNotification"

//user defaults key
#define kPushTokenDicKey                @"push_token_dic" //the key for local defaults to get the array of tokenByUser dict
#define kUserLoggedInUserKey            @"user"
#define kAWSEndPointDicKey              @"AWS_EndPoint_dic"
#define kAWSTopicDicKey                 @"AWS_Topic_dic"
#define kLastChecked                    @"last_checked"//stores the last checked task
#define kSavedAlarms                    @"saved_alarms"

#pragma mark - User / External events
//App wide events
#define kWokeNotification               @"woke"
#define kSleepNotification              @"Sleep"
#define kNewMediaNotification           @"media_event" //key: task & media
#define kNewTimerNotification           @"alarm_timer"

#pragma mark - Data event
//alarm store
#define kAlarmNew						@"EWAlarmNew" //key: alarm
#define kAlarmStateChanged				@"EWAlarmStateChanged"//key: alarm
#define kAlarmTimeChanged				@"EWAlarmTimeChanged"//key: alarm
#define kAlarmDelete					@"EWAlarmDelete" //key: tasks
#define kAlarmChanged					@"EWAlarmChanged" //key: alarm
#define kAlarmToneChanged				@"EWAlarmToneChanged" //key: alarm
#define kAlarmStatementChanged			@"EWAlarmStatementChanged" //key: alarm


//person store
#define kPersonLoggedIn                 @"PersonLoggedIn"
#define kPersonLoggedOut                @"PersonLoggedOut"

//media store
//#define kMediaNewNotification           @"EWMediaNew"

#define kADIDKey                        @"ADID" //key for ADID
#define kPushAPNSRegisteredNotification @"APNSRegistered"

//Notification key
#define kLocalNotificationTypeKey       @"type"
#define kLocalNotificationTypeAlarmTimer    @"alarm_timer"
#define kLocalNotificationTypeReactivate    @"reactivate"
#define kLocalNotificationTypeSleepTimer    @"sleep_timer"
//push
#define kPushType						@"type"
#define kPushTypeAlarmTimer				@"timer"
#define kPushTypeBroadcast				@"broadcast"
#define kPushTypeMedia					@"media"
#define kPushTypeNotification			@"notice"

//media
#define kPushMediaType					@"media_type"
#define kPushMediaTypeBuzz				@"buzz"
#define kPushMediaTypeVoice				@"voice"
#define kPushPersonID					@"person"
#define kPushAlarmID					@"alarm_server_ID"
#define kLocalAlarmID					@"alarm_local_ID"
#define kPushMediaID					@"media"
//notification
#define kPushNofiticationID				@"notificationID"

//Audio & Video
#define kMaxRecordTime                  30.0
#define kAudioPlayerDidFinishPlaying    @"audio_finished_playing"
#define kAudioPlayerWillStart           @"audio_will_start"
#define kAudioPlayerNextPath            @"audio_next_path"

//Collection View Identifier
#define kCollectionViewCellPersonIdenfifier  @"CollectionViewIdentifier"


//CollectionView Cell
#define kCollectionViewCellWidth        80
#define kCollectionViewCellHeight       80

//Notification types
#define kNotificationTypeFriendRequest      @"friendship_request"
#define kNotificationTypeFriendAccepted     @"friendship_accepted"
#define kNotificationTypeSystemNotice             @"notice"
#define kNotificationTypeNextTaskHasMedia   @"task_has_media"

//Navgation Controller
#define kMaxPersonNavigationConnt       6

//Cached Info
#define kCachedFriends                      @"friends"


// ATConnect
#define kLoginSuccess           @"login_success"
#define kWakeupSuccess          @"wake_success"
#define kRecordVoiceSuccess     @"record_success"

#define kCachedAlarmTimes                @"alarm_schedule"
#define kCachedStatements                @"statements"