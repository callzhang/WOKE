//
//  EWDefines.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#ifndef EarlyWorm_Defines_h
#define EarlyWorm_Defines_h

//Judge System
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

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
#define kStackMobKeyProduction  @""

//background fetch
#define kBackgroundFetchInterval        600.0 //TODO: possible conflict with serverUpdateInterval

// 开关宏
/*
 *  在测试代码外包上 "ifndef CLEAR_TEST" 开关
 */

//#define CLEAR_TEST
//#define BACKGROUND_TEST

// 任务宏

#define LOCALSTR(x)     NSLocalizedString(x,nil)


//Global parameters
#define nWeeksToScheduleTask 1
#define serverUpdateInterval 60 //30 min
#define alarmInterval 600 //10min
#define autoGroupIndentifier @"wakeUpTogetherGroup"
#define autoGroupStatement @"Wake up together with people around you."

//DEFAULT DATA

#define ringtoneNameList @[@"Autumn Spring.caf", @"Daybreak.caf", @"Drive.caf", @"Parisian Dream.caf", @"Sunny Afternoon.caf", @"Tropical Delight.caf"];

#define weekdays @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];

#define userDefaults @{@"DefaultTone": @"Autumn Spring.caf", @"SocialLevel":@"Social Network Only", @"DownloadConnection":@"Cellular and Wifi", @"BedTimeNotification":@YES, @"SleepDuration":@8.0, @"PrivacyLevel":@"Privacy info", @"SystemID":@"0", @"FirstTime":@YES, @"SkipTutorial":@NO, @"Region":@"America", @"alarmTime":@"08:00"};


//notification
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

//Notification key
#define kLocalNotificationUserInfoKey   @"task_ID"  //store task id
#define kFinishedSync                   @"FinishedSync" //server has finished syncing (usually at startup)

//Audio & Video
#define kMaxRecordTime                  20.0;
#define kAudioPlayerDidFinishPlaying    @"audio_finished_playing"
#define kPushTokenKey                   @"push_token" //the key for local defaults to get the array of tokenByUser dict
#define kPushTokenUserKey               @"user" //the key for user in tokenByUser dict
#define kPushTokenByUserKey             @"token" //the key for token in tokenByUser dict
#define kPushTokenUserAvatarKey         @"current_user_avatar" //for username avator when token received but user not logged in
#define kUserLoggedInUserKey            @"user"





//Collection View Identifier

#define COLLECTION_VIEW_IDENTIFIER  @"CollectionViewIdentifier"


//Collection Cell Size

#define COLLECTION_CELL_WIDTH 54

#define COLLECTION_CELL_HEIGHT 54

#endif
