//  EWPostWakeUpViewController.h
//  EarlyWorm
//
//  Created by letv on 14-2-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWActivity.h"

@interface EWPostWakeUpViewController : UIViewController<UICollectionViewDelegate,UICollectionViewDataSource>
{
    
    NSArray * personArray;
    __weak IBOutlet UICollectionView *collectionView;
    IBOutlet UIButton *buzzButton;
    IBOutlet UIButton *voiceMessageButton;
}

/**
 * @brief personArray : save friend
 */
@property(nonatomic,strong)NSArray * personArray;

/**
 * @brief taskItem : save task item
 */
@property(nonatomic,strong)EWActivity * activity;

@end
