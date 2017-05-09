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
    [r setURLString:@""];
    [r setMethod:@"GET"];
    [r setValue:@"" forKey:@"key1"];
    [r setValue:@"" forParamField:@"key2"];
    
    [r successBlock:^(NSInteger statusCode, id responseObject) {
        NSLog(@"%d--%@", statusCode, responseObject);
    }];
    [r startRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
