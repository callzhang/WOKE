//  EWPostWakeUpViewController.h
//  EarlyWorm
//
//  Created by letv on 14-2-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWTaskItem;

@interface EWPostWakeUpViewController : UIViewController<UICollectionViewDelegate,UICollectionViewDataSource>
{
    
    NSArray * personArray;
    EWTaskItem * taskItem;
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
@property(nonatomic,strong)EWTaskItem * taskItem;

@end
