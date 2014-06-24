//
//  EWMyFriendsViewController.m
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWMyFriendsViewController.h"
#import "UINavigationController+Blur.h"
#import "EWPerson.h" 
#import "EWCollectionPersonCell.h"
#import "EWFriendsCollectionCell.h"
#import "EWUIUtil.h"
NSString * const tableViewCellId =@"MyFriendsTableViewCellId";
NSString * const collectViewCellId = @"friendsCollectionViewCellId";

@interface EWMyFriendsViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDataSource>
{
    NSArray *_friendsArray;
}

@end

@implementation EWMyFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(id)initWithPerson:(EWPerson *)person
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.person = person;
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
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - init

-(void)initData
{
    if (_person) {
        
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        _friendsArray = [_person.friends sortedArrayUsingDescriptors:sortDescriptors];
        _friendsTableView.delegate = self;
        _friendsTableView.dataSource = self;
//        _friendsCollectionView.delegate = self;
//        _friendsCollectionView.dataSource = self;
    }
}
-(void)initView
{
   
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.navigationItem.title = @"Friends";
    self.view.backgroundColor = [UIColor clearColor];
    _friendsCollectionView.backgroundColor = [UIColor clearColor];
    _friendsTableView.backgroundView = nil;
    _friendsTableView.backgroundColor = [UIColor clearColor];
    _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _friendsTableView.allowsSelection = NO;
    _friendsTableView.hidden = YES;
    _friendsCollectionView.hidden = NO;
    _tabView.selectedSegmentIndex = 0;
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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_friendsTableView dequeueReusableCellWithIdentifier:tableViewCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCellId];
    }
    EWPerson * myFriend = [_friendsArray objectAtIndex:indexPath.row];
    cell.imageView.image = myFriend.profilePic;
//    [EWUIUtil applyHexagonMaskForView:cell.imageView];
    cell.backgroundColor = [UIColor clearColor];
    cell.textColor = [UIColor whiteColor];
    cell.textLabel.text = myFriend.name;
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    cell.backgroundColor = [UIColor clearColor];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_friendsArray count];
}

#pragma mark - CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_friendsArray count]/3+1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EWFriendsCollectionCell * cell = [_friendsCollectionView dequeueReusableCellWithReuseIdentifier:collectViewCellId forIndexPath:indexPath];
    if (!cell) {
        cell = [[EWFriendsCollectionCell alloc] init];
        
    }
    
    EWPerson * myFriend = [_friendsArray objectAtIndex:indexPath.section*3+indexPath.row];
    
    [cell setupCellWithInfo:myFriend];
//    cell.
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
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
@end
