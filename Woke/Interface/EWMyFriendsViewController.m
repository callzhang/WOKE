//
//  EWMyFriendsViewController.m
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWMyFriendsViewController.h"
#import "EWPerson.h"
#import "EWCollectionPersonCell.h"
#import "EWFriendsCollectionCell.h"
#import "EWUIUtil.h"
#import "EWFriendsTableCell.h"
#import "EWPersonStore.h"
#import "EWPersonViewController.h"
NSString * const tableViewCellId =@"MyFriendsTableViewCellId";
NSString * const collectViewCellId = @"friendsCollectionViewCellId";

@interface EWMyFriendsViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    NSArray *friends;
    NSArray *mutualFriends;
}

@end

@implementation EWMyFriendsViewController

-(id)initWithPerson:(EWPerson *)person cellSelect:(BOOL)cellSelect
{
    self = [self initWithPerson:person];
    self.cellSelect = cellSelect;
    return self;
}
-(id)initWithPerson:(EWPerson *)person
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.person = person;
        self.cellSelect = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initData];
    [self initView];

    // Do any additional setup after loading the view from its nib.
}

#pragma mark - init

-(void)initData
{
    if (_person) {
        
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        friends = [_person.friends sortedArrayUsingDescriptors:@[sd]];
        NSMutableSet *myFriends = [me.friends mutableCopy];
        [myFriends intersectSet:[NSSet setWithArray:friends]];
        mutualFriends = [[myFriends allObjects] sortedArrayUsingDescriptors:@[sd]];
        _friendsTableView.delegate = self;
        _friendsTableView.dataSource = self;
        _friendsCollectionView.delegate = self;
        _friendsCollectionView.dataSource = self;
    }
}
-(void)initView
{
   
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.title = @"Friends";
    
    self.view.backgroundColor = [UIColor clearColor];
    _friendsCollectionView.backgroundColor = [UIColor clearColor];
    _friendsCollectionView.hidden = NO;
     UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [_friendsCollectionView registerNib:nib  forCellWithReuseIdentifier:collectViewCellId];
    _tabView.selectedSegmentIndex = 0;
    
    
    _friendsTableView.backgroundView = nil;
    _friendsTableView.backgroundColor = [UIColor clearColor];
    _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _friendsTableView.allowsSelection = _cellSelect;
    _friendsTableView.hidden = YES;
    [_friendsTableView registerNib:[UINib nibWithNibName:@"EWFriendsTableCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:tableViewCellId];
    
    //
    if ([friends count]==1&& friends[0]==me) {
        
        _tabView.hidden = YES;
    }
   
}

-(void)close:(id)sender
{
//    [self.navigationController popViewControllerWithBlur];
    [self.navigationController popViewControllerAnimated:YES];

}
#pragma mark - TableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [mutualFriends count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EWFriendsTableCell *cell = [_friendsTableView dequeueReusableCellWithIdentifier:tableViewCellId];
    EWPerson * myFriend = [friends objectAtIndex:indexPath.row];
    [cell setupCellWithPerson:myFriend];
    
    return cell;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    return;
    if (_cellSelect) {
        [self pushControllerWithArrayNumber:indexPath.row];

    }
   
}


#pragma mark - CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [friends count];
    
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    EWCollectionPersonCell * cell = [_friendsCollectionView dequeueReusableCellWithReuseIdentifier:collectViewCellId forIndexPath:indexPath];
    cell.showName = YES;
    EWPerson * friend = [friends objectAtIndex:indexPath.row];
    
    cell.person = friend;

//    cell.backgroundColor = [UIColor redColor];
   
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 100);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 20, 5, 10);
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _cellSelect;
//    return NO;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self pushControllerWithArrayNumber:indexPath.row];
    
}

- (IBAction)tabValueChange:(UISegmentedControl *)sender {
    NSUInteger value =  [sender selectedSegmentIndex];
    switch (value) {
        case 0:
        {
            _friendsCollectionView.hidden = NO;
            _friendsTableView.hidden = YES;
            break;
        }
            
        case 1:
        {
            _friendsTableView.hidden = NO;
            _friendsCollectionView.hidden  = YES;
            break;
        }
        default:
            break;
    }
}
#pragma mark - help method
-(void)pushControllerWithArrayNumber:(NSInteger)number
{
    if ([self.navigationController.viewControllers count] <kMaxPersonNavigationConnt) {
        
        EWPerson * friend = [friends objectAtIndex:number];
        EWPersonViewController *viewController = [[EWPersonViewController alloc] initWithPerson:friend ];
        viewController.canSeeFriendsDetail = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    }

}
   @end
