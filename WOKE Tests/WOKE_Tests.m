//
//  WOKE_Tests.m
//  WOKE Tests
//
//  Created by Zitao Xiong on 17/09/2014.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#define EXP_SHORTHAND YES
#import "Expecta.h"
#import "OCMock.h"

@interface WOKE_Tests : XCTestCase

@end

@implementation WOKE_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    expect(2).equal(2);
    
//    [[MakeSpaceSessionManager shared] loginWithEmail:@"false@xxx.com" password:@"faslse" completion:^(NSDictionary *dictioanry, NSError *aError) {
//        response = dictioanry;
//        error = aError;
//    }];
//    
//    expect(response).will.beNil();
//    expect(error).willNot.beNil();
//    expect(error).will.beKindOf([NSError class]);
}

@end
