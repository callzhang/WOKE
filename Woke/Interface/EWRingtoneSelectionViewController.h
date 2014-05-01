//
//  EWRingtoneSelectionViewController.h
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWRingtoneSelectionViewController;

@protocol EWRingtoneSelectionDelegate <NSObject>
- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone;
@end

@interface EWRingtoneSelectionViewController : UITableViewController
@property NSArray *ringtoneList;
@property NSInteger selected;
//@property NSMutableArray *prefArray;
@property (nonatomic, weak) id <EWRingtoneSelectionDelegate> delegate;
@end
