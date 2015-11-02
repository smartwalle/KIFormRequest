//
//  KINetworkObserver.h
//  Kitalker
//
//  Created by 杨 烽 on 12-8-17.
//
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

extern NSString * const KINetworkStatucChangedNotification;

typedef void(^KINetworkStatusBlock) (NetworkStatus status);

@interface KINetworkObserver : NSObject {
}

+ (void)setHostName:(NSString *)hostName;

+ (void)startListenNetworkStatus;

+ (void)addNetworkObserverBlock:(KINetworkStatusBlock)block forKey:(NSString *)key;

+ (void)removeNetworkObserver:(NSString *)key;

+ (BOOL)isReachable;

+ (BOOL)isReachableViaWWAN;

+ (BOOL)isReachableViaWiFi;

@end
