//
//  KINetworkObserver.m
//  Kitalker
//
//  Created by 杨 烽 on 12-8-17.
//
//

#import "KINetworkObserver.h"

NSString * const KINetworkStatucChangedNotification = @"KINetworkStatucChangedNotification";

@interface KINetworkObserver () <UIAlertViewDelegate> {
}
@property (nonatomic, copy)   NSString              *hostName;
@property (nonatomic, strong) Reachability          *reachability;
@property (nonatomic, strong) UIAlertView           *alertView;
@property (nonatomic, strong) NSMutableDictionary   *observerList;
@property (nonatomic, assign) NetworkStatus         oldStatus;
@end

@implementation KINetworkObserver {
    
}

static KINetworkObserver *KINETWORK_OBSERVER;

+ (void)initialize {
    KINETWORK_OBSERVER = [[KINetworkObserver alloc] init];
}

+ (KINetworkObserver *)sharedInstance {
    if (KINETWORK_OBSERVER == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            KINETWORK_OBSERVER = [[KINetworkObserver alloc] init];
        });
    }
    return KINETWORK_OBSERVER;
}

+ (void)setHostName:(NSString *)hostName {
    [[KINetworkObserver sharedInstance] setHostName:hostName];
}

+ (void)startListenNetworkStatus {
    [[KINetworkObserver sharedInstance] startNotifier];
}

+ (void)addNetworkObserverBlock:(KINetworkStatusBlock)block forKey:(NSString *)key {
    [[KINetworkObserver sharedInstance] addNetworkObserverBlock:block forKey:key];
}

+ (void)removeNetworkObserver:(NSString *)key {
    [[KINetworkObserver sharedInstance] removeNetworkObserver:key];
}

+ (BOOL)isReachable {
    return [[[KINetworkObserver sharedInstance] reachability] isReachable];
}

+ (BOOL)isReachableViaWWAN {
    return [[[KINetworkObserver sharedInstance] reachability] isReachableViaWWAN];
}

+ (BOOL)isReachableViaWiFi {
    return [[[KINetworkObserver sharedInstance] reachability] isReachableViaWiFi];
}

- (id)init {
    if (KINETWORK_OBSERVER == nil) {
        if (self = [super init]) {
            self.observerList = [[NSMutableDictionary alloc] init];
            self.oldStatus = 255;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityChanaged:)
                                                         name:kReachabilityChangedNotification
                                                       object:nil];
            
            [self setHostName:@"www.baidu.com"];
            
            KINETWORK_OBSERVER = self;
        }
    }
    return KINETWORK_OBSERVER ;
}

- (void)addNetworkObserverBlock:(KINetworkStatusBlock)block forKey:(NSString *)key {
    [self.observerList setObject:block forKey:key];
}

- (void)removeNetworkObserver:(NSString *)key {
    [self.observerList removeObjectForKey:key];
}

- (Reachability *)reachability {
    if (_reachability == nil) {
        _reachability = [Reachability reachabilityWithHostName:self.hostName];
    }
    return _reachability;
}

- (void)startNotifier {
    [[self reachability] startNotifier];
}

- (void)reachabilityChanaged:(NSNotification *)noti {
    Reachability *reachability = [noti object];
    if ([reachability isKindOfClass:[Reachability class]]) {
        [self updateInterfaceWithReachability:reachability];
    }
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    
    __weak KINetworkObserver *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NetworkStatus status = [reachability currentReachabilityStatus];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:KINetworkStatucChangedNotification
                                                                object:[NSNumber numberWithInt:status]];
            BOOL customerMsg = NO;
            
            for (NSString *key in [weakSelf.observerList allKeys]) {
                KINetworkStatusBlock networkStatusBlcok = [weakSelf.observerList objectForKey:key];
                networkStatusBlcok(status);
                customerMsg = YES;
            }
            
            if (customerMsg == NO) {
                if (status == NotReachable && weakSelf.oldStatus != NotReachable) {
                    if (weakSelf.alertView == nil && ![weakSelf.alertView isVisible]) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"网络提示", nil)
                                                                            message:NSLocalizedString(@"系统检测到您当前的网络环境不可用，请查检", nil)
                                                                           delegate:weakSelf
                                                                  cancelButtonTitle:NSLocalizedString(@"好的", nil)
                                                                  otherButtonTitles:nil];
                        
                        [alertView show];
                        weakSelf.alertView = alertView;
                        alertView = nil;
                        
                    }
                } else {
                    if (weakSelf.alertView != nil && [weakSelf.alertView isVisible]) {
                        [weakSelf.alertView dismissWithClickedButtonIndex:0 animated:YES];
                    }
                }
            }
            
            weakSelf.oldStatus = status;
        });
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.alertView = nil;
}

- (void)dealloc {
    self.alertView = nil;
    self.hostName = nil;
    
    [self.observerList removeAllObjects];
    self.observerList = nil;
    
    [self.reachability stopNotifier];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
    self.reachability = nil;
}

@end
