//
//  ViewController.m
//  KIFormRequest
//
//  Created by apple on 15/11/2.
//  Copyright (c) 2015年 smartwalle. All rights reserved.
//

#import "ViewController.h"
#import "KIFormRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KIFormRequest *r = [[KIFormRequest alloc] init];
    [r setURLString:@"https://api.github.com/repos/vmg/redcarpet/issues"];
    [r setMethod:@"GET"];
    [r setValue:@"closed" forKey:@"state"];
//    [r setValue:@"closed" forParam:@"state"];
    
    [r successBlock:^(NSInteger statusCode, id responseObject) {
        NSLog(@"%ld--%@", (long)statusCode, responseObject);
    }];
    [r failureBlock:^(NSInteger statusCode, NSError *error, NSData *responseData) {
        NSLog(@"%@", error);
    }];
    [r startRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
