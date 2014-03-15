//
//  EWDefines.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#ifndef EarlyWorm_Defines_h
#define EarlyWorm_Defines_h

//System
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iOS7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)

#define kAppName            @"EarlyWorm"
#define kAppVersion         @"0.5.0"

#define UserInfo           @"userInfo"

#define kCustomWhite        EWSTR2COLOR(@"#F5F5F5")
#define kCustomGray         EWSTR2COLOR(@"48494B")
#define kColorMediumGray    EWSTR2COLOR(@"7e7e7e")
#define kCustomLightGray    EWSTR2COLOR(@"#DDDDDD")

// Keys
#define kStackMobKeyDevelopment         @"4757c535-5583-46f9-8a55-3b8276d96f06"
#define kStackMobKeyDevelopmentPrivate  @"63be438d-9a8a-428c-9d64-e1df9844da7d"
#define kStackMobKeyProduction          @""
#define AWS_ACCESS_KEY_ID               @"AKIAIB2BXKRPL3FCWJYA"
#define AWS_SECRET_KEY                  @"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"
#define AWS_SNS_APP_ARN                 @"arn:aws:sns:us-west-2:260520558889:app/APNS_SANDBOX/Woke_Dev"
#define TESTFLIGHT_ACCESS_KEY           @"e1ffe70a-26bf-4db0-91c8-eb2d1d362cb3"

#define AWS_SNS_EndPoint_test_id_1      @"2:260520558889:endpoint/APNS_SANDBOX/Woke_Dev/3b46d55e-0da2-397c-8116-603a9acf02be"

//background fetch
#define kBackgroundFetchInterval        600.0 //TODO: possible conflict with serverUpdateInterval


// 开关宏
/*
 *  在测试代码外包上 "ifndef DEV_TEST" 开关
 */

#define DEV_TEST                        1
#define BACKGROUND_TEST                 1

// 任务宏

#define LOCALSTR(x)     NSLocalizedString(x,nil)
#define EWAlert(str)    [[[UIAlertView alloc] initWithTitle:@"Alert" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

//Global parameters
#define nWeeksToScheduleTask            1
#define nLocalNotifPerTask              10
#define serverUpdateInterval            1800 //30 min
#define alarmInterval                   600 //10min
#define kMaxWakeTime                    600 // 10min
#define autoGroupIndentifier @"wakeUpTogetherGroup"
#define autoGroupStatement @"Wake up together with people around you."

//DEFAULT DATA

#define ringtoneNameList @[@"Autumn Spring.caf", @"Daybreak.caf", @"Drive.caf", @"Parisian Dream.caf", @"Sunny Afternoon.caf", @"Tropical Delight.caf"];

#define weekdays @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];

#define userDefaults @{@"DefaultTone": @"Autumn Spring.caf", @"SocialLevel":@"Social Network Only", @"DownloadConnection":@"Cellular and Wifi", @"BedTimeNotification":@YES, @"SleepDuration":@8.0, @"PrivacyLevel":@"Privacy info", @"SystemID":@"0", @"FirstTime":@YES, @"SkipTutorial":@NO, @"Region":@"America", @"alarmTime":@"08:00"};


//event
#define kAlarmsAllNewNotification       @"EWAlarmsNew" //key: alarms
#define kAlarmNewNotification           @"EWAlarmNew" //key: alarm
#define kAlarmStateChangedNotification  @"EWAlarmStateChanged"//key: alarm
#define kAlarmTimeChangedNotification   @"EWAlarmTimeChanged"//key: alarm
#define kAlarmDeleteNotification        @"EWAlarmDelete" //key: tasks
#define kAlarmChangedNotification       @"EWAlarmChanged" //key: alarm
#define kAlarmToneChangedNotification   @"EWAlarmToneChanged" //key: alarm

#define kTasksAllNewNotification        @"EWTasksNew"  //key: tasks
#define kTaskNewNotification            @"EWTaskNew"  //key: task
#define kTaskStateChangedNotification   @"EWTasksStateChanged"  //key: task
#define kTaskDeleteNotification         @"EWTaskDelete"  //key: task
#define kTaskTimeChangedNotification    @"EWTaskTimeChanged"  //key: task
#define kTaskChangedNotification        @"EWTaskChanged" //key: task

#define kPersonLoggedIn                 @"PersonLoggedIn"
#define kPersonLoggedOut                @"PersonLoggedOut"
#define kPersonProfilePicDownloaded     @"PersonPicDownloaded"

#define kMediaNewNotification           @"EWMediaNew" //key: task & media

#define kPushAPNSRegisteredNotification @"APNSRegistered"

#define kNewBuzzNotification            @"buzz_event"
#define kNewMediaNotification           @"media_event"
#define kNewTimerNotification           @"alarm_timer"

//Notification key
#define kLocalNotificationUserInfoKey   @"task_ID"  //store task id
#define kPushPersonKey                  @"person"
#define kPushTaskKey                    @"task"
#define kPushMediaKey                   @"media"
#define kPushTypeBuzzKey                @"buzz"
#define kPushTypeMediaKey               @"media"
#define kPushTypeTimerKey               @"timer"
#define kFinishedSync                   @"FinishedSync" //server has finished syncing (usually at startup)
#define kADIDKey                        @"ADID" //key for ADID

//Audio & Video
#define kMaxRecordTime                  20.0;
#define kAudioPlayerDidFinishPlaying    @"audio_finished_playing"

//User Defaults
#define kPushTokenDicKey                @"push_token_dic" //the key for local defaults to get the array of tokenByUser dict
#define kUserLoggedInUserKey            @"user"
#define kAWSEndPointDicKey              @"AWS_EndPoint_dic"
#define kAWSTopicDicKey                 @"AWS_Topic_dic"



//Collection View Identifier

#define kCollectionViewCellPersonIdenfifier  @"CollectionViewIdentifier"


//Collection Cell Size

#define kCollectionViewCellWidth      60
#define kCollectionViewCellHeight     68
#define kCollectionViewCellPersonRadius   30

#endif
