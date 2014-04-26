//
//  EWAlarmMenuViewController.m
//  Woke
//
//  Created by apple on 14-4-17.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWAlarmMenuViewController.h"

@interface EWAlarmMenuViewController ()

@end

@implementation EWAlarmMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoadWithCell:(EWCollectionPersonCell*)cell;
{
    UIView *view=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 568)];
    view.backgroundColor=[UIColor whiteColor];
    view.alpha=0.7;
    _alphaview=view;
    
    UIButton *abutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x-30 ,cell.frame.origin.y-30 , 30, 30)];
    //    abutton.center=cell.center;
    _profilebutton=abutton;
    UIImage *aimge=[UIImage imageNamed:@"button_p.png"];
    [_profilebutton setImage:aimge forState:UIControlStateNormal];
    [_profilebutton addTarget:self action:@selector(toperson) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width ,cell.frame.origin.y-30 , 30, 30)];
    //    bbutton.center=cell.center;
    _buzzbutton=bbutton;
    UIImage *bimge=[UIImage imageNamed:@"button_b.png"];
    [_buzzbutton setImage:bimge forState:UIControlStateNormal];
    [_buzzbutton addTarget:self action:@selector(tobuzz) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width/2-15 ,cell.frame.origin.y-45 , 30, 30)];
    //    cbutton.center=cell.center;
    _voicebutton=cbutton;
    UIImage *cimge=[UIImage imageNamed:@"button_v.png"];
    [_voicebutton setImage:cimge forState:UIControlStateNormal];
    [_voicebutton addTarget:self action:@selector(tovoice) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *dbutton=[[UIButton alloc]initWithFrame:CGRectMake(cell.frame.origin.x+cell.frame.size.width/2-15, cell.frame.origin.y+cell.frame.size.height+15 , 30, 30)];
    //    dbutton.center=cell.center;
    _closebutton=dbutton;
    [_closebutton addTarget:self action:@selector(closemeun) forControlEvents:UIControlEventTouchUpInside];
    UIImage *dimge=[UIImage imageNamed:@"button_x.png"];
    [_closebutton setImage:dimge forState:UIControlStateNormal];
    
    _personcellview=cell;
    //    UIImageView *imageview=[[UIImageView alloc]initWithFrame:cell.frame];
    //    imageview.image=cell.profilePic.image;
    //    personcell.profilePic.image =imageview.image;
    //  _personcellview=personcell;
    
    
    [self.view addSubview:_alphaview];
    [self.view addSubview:_profilebutton];
    [self.view addSubview:_buzzbutton];
    [self.view addSubview:_voicebutton];
    [self.view addSubview:_closebutton];
    [self.view addSubview:_personcellview];

    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
