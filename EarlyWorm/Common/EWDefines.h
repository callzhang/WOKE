//
//  EWDefines.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#ifndef EarlyWorm_Defines_h
#define EarlyWorm_Defines_h

#define kAppName            @"EarlyWorm"
#define kAppVersion         @"0.0.3.0"

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
#define serverUpdateInterval 1800 //30 min
#define alarmInterval 600 //10min
#define autoGroupIndentifier @"wakeUpTogetherGroup"
#define autoGroupStatement @"Wake up together with people around you."

#pragma mark - DATA

#define ringtoneNameList @[@"Autumn Spring.mp3", @"Daybreak.mp3", @"Drive.mp3", @"Morning Dew.mp3", @"Nature at night.mp3", @"Ocean Breeze.mp3", @"Ocean tides.mp3", @"Overture.mp3", @"Parisian Dream.mp3", @"Robots in Love.mp3", @"Sunny Afternoon.mp3", @"Tropical Delight.mp3", @"Walk the Dog.mp3", @"Wind in the trees.mp3"];

#define weekdays @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];


//notification
#define kAlarmsAllNewNotification       @"EWAlarmsNew" //key: alarms
#define kAlarmNewNotification           @"EWAlarmNew" //key: alarm
#define kAlarmStateChangedNotification  @"EWAlarmStateChanged"//key: alarm
#define kAlarmTimeChangedNotification   @"EWAlarmTimeChanged"//key: alarm
#define kAlarmDeleteNotification        @"EWAlarmDelete" //key: alarm
#define kAlarmChangedNotification       @"EWAlarmChanged" //key: alarm
#define kAlarmToneChangedNotification   @"EWAlarmToneChanged" //key: alarm

#define kTasksAllNewNotification        @"EWTasksNew"  //key: tasks
#define kTaskNewNotification            @"EWTaskNew"  //key: task
#define kTaskStateChangedNotification   @"EWTasksStateChanged"  //key: task
#define kTaskDeleteNotification         @"EWTaskDelete"  //key: task
#define kTaskTimeChangedNotification    @"EWTaskTimeChanged"  //key: task
#define kTaskChangedNotification        @"EWTaskChanged" //key: task

#define kPersonLoggedIn                 @"PersonLoggedIn"

#define kMediaNewNotification           @"EWMediaNew" //key: task & media

//Notification key
#define kLocalNotificationUserInfoKey   @"task_ID"  //store task id

//Audio & Video
#define kMaxRecordTime                  20.0;

#endif
