//
//  EWMyProfileViewController.m
//  Woke
//
//  Created by mq on 14-6-28.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWMyProfileViewController.h"
#import "EWPersonStore.h"
@interface EWMyProfileViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@end

@implementation EWMyProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    [self initView];
    [self initData];
    // Do any additional setup after loading the view from its nib.
}

-(void)initView
{
    [self.view setBackgroundColor:[UIColor clearColor]];
    self.myTableView.backgroundColor = [UIColor clearColor];
    self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
       self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Confirm Button"] style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
}

-(void)initData
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@",indexPath);
   
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"profileCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.backgroundColor = kCustomLightGray;
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    switch (indexPath.row){
            
        case 0: {
            cell.textLabel.text = LOCALSTR(@"Profile Picture");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = me.profilePic;
        }
                  break;
        case 1: {
            cell.textLabel.text = LOCALSTR(@"Name");
            cell.detailTextLabel.text = me.name;
        }
            break;
            
        case 2: {
            cell.textLabel.text = LOCALSTR(@"ID");
            cell.detailTextLabel.text = me.username;
        }
            break;
        case 3: {
            cell.textLabel.text = LOCALSTR(@"Facebook ID");
            cell.detailTextLabel.text = me.facebook;
        }
            break;
        case 4:{
            cell.textLabel.text = LOCALSTR(@"Weibo ID");
            cell.detailTextLabel.text = me.weibo;
        }
            break;
        case 5:{
            cell.textLabel.text = LOCALSTR(@"City");
            cell.detailTextLabel.text = me.city;
        }
            break;
        case 6: {
            cell.textLabel.text = LOCALSTR(@"Region");
            cell.detailTextLabel.text = me.region;
        }
            break;
        case 7:{
            cell.textLabel.text = LOCALSTR(@"Log out");
        }
            break;
        default:
            break;
    }

    return cell;


}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

#pragma mark  - additional method
-(void)close:(id)sender
{
    if (self.navigationController) {
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }else{
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}
@end
