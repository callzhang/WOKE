//
//  EWFriendsCollectionCell.h
//  Woke
//
//  Created by mq on 14-6-24.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWPerson;

@interface EWFriendsCollectionCell : UICollectionViewCell
@property UIImageView *headImageView;
@property UILabel *nameLabel;

-(void)setupCellWithInfo:(EWPerson *)person;
@end
