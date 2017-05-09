//
//  KIFormRequest.h
//  KIFormRequest
//
//  Created by apple on 17/5/9.
//  Copyright © 2017年 smartwalle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@class KIFormRequest;
typedef void(^KIFormRequestSuccessBlock)          (NSInteger statusCode, id responseObject);
typedef void(^KIFormRequestFailureBlock)          (NSInteger statusCode, NSError *error, NSData *responseData);
typedef void(^KIFormRequestDownloadProgressBlock) (NSProgress *downloadProgress);
typedef void(^KIFormRequestUploadProgressBlock)   (NSProgress *uploadProgress);

@interface KIFormRequest : NSObject

+ (AFHTTPSessionManager *)sharedManager;

- (instancetype)init;
- (instancetype)initWithManager:(AFHTTPSessionManager *)manager;

- (void)successBlock:(KIFormRequestSuccessBlock)block;
- (void)failureBlock:(KIFormRequestFailureBlock)block;
- (void)downloadProgressBlock:(KIFormRequestDownloadProgressBlock)block;
- (void)uploadProgressBlock:(KIFormRequestUploadProgressBlock)block;

- (void)startRequest;
- (void)cancel;

// HTTP 请求方法
- (void)setMethod:(NSString *)method;

// HTTP 请求 URL 地址
- (void)setURLString:(NSString *)URLString;

// HTTP 请求头
- (void)setValue:(id)value forHeaderField:(NSString *)field;

- (void)removeHeaderWithField:(NSString *)field;

// HTTP 请求参数
- (void)setValue:(id)value forParamField:(NSString *)field;

- (void)removeParamWithField:(NSString *)field;

// HTTP Body
- (void)setHttpBody:(id)body;

// 上传文件
- (void)addFile:(NSData *)fileData forKey:(NSString *)key fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (void)addPNGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName;

- (void)addJPEGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName;

@end
