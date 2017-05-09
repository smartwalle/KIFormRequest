//
//  KIFormRequest.m
//  KIFormRequest
//
//  Created by apple on 17/5/9.
//  Copyright © 2017年 smartwalle. All rights reserved.
//

#import "KIFormRequest.h"

@protocol AFHTTPManager <NSObject>
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(void (^)(NSProgress *uploadProgress))uploadProgress
                                downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
@end

@interface KIRequestFile : NSObject
@property (nonatomic, strong) NSData   *data;
@property (nonatomic, copy)   NSString *key;
@property (nonatomic, copy)   NSString *fileName;
@property (nonatomic, copy)   NSString *mimeType;
@end

@implementation KIRequestFile
@end

@interface KIFormRequest ()
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSURLSessionTask     *task;

@property (nonatomic, copy) KIFormRequestSuccessBlock          requestSuccessBlock;
@property (nonatomic, copy) KIFormRequestFailureBlock          requestFailureBlock;
@property (nonatomic, copy) KIFormRequestDownloadProgressBlock downloadProgressBlock;
@property (nonatomic, copy) KIFormRequestUploadProgressBlock   uploadProgressBlock;

@property (nonatomic, copy)   NSString            *method;
@property (nonatomic, copy)   NSString            *URLString;
@property (nonatomic, strong) NSMutableDictionary *headers;
@property (nonatomic, strong) NSMutableDictionary *params;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) id                  body;
@end

@implementation KIFormRequest

+ (NSMutableDictionary *)sharedRequestPool {
    static NSMutableDictionary *pool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[NSMutableDictionary alloc] init];
    });
    return pool;
}

+ (AFHTTPSessionManager *)sharedManager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        NSSet *acceptableContentType = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", @"text/html", @"application/json", @"text/plain", nil];
        manager.responseSerializer.acceptableContentTypes = acceptableContentType;
    });
    return manager;
}

#pragma mark - Lifecycle
- (void)dealloc {
}

- (instancetype)init {
    if (self = [super init]) {
        self.manager = [KIFormRequest sharedManager];
    }
    return self;
}

- (instancetype)initWithManager:(AFHTTPSessionManager *)manager {
    if (self = [super init]) {
        self.manager = manager;
    }
    return self;
}

#pragma mark - KVC
- (void)setValue:(id)value forKey:(NSString *)key {
    [self setValue:value forParam:key];
}

- (id)valueForKey:(NSString *)key {
    return [[self params] valueForKey:key];
}

#pragma mark - Public Methods
- (void)setMethod:(NSString *)method {
    _method = [method copy];
}

- (void)setURLString:(NSString *)URLString {
    _URLString = [URLString copy];
}

- (void)setValue:(id)value forHeader:(NSString *)field {
    if (field == nil) {
        return;
    }
    if (value == nil) {
        [[self headers] removeObjectForKey:field];
        return ;
    }
    [[self headers] setValue:value forKey:field];
}

- (void)removeHeader:(NSString *)field {
    if (field == nil) {
        return ;
    }
    [[self headers] removeObjectForKey:field];
}

- (void)setValue:(id)value forParam:(NSString *)field {
    if (field == nil) {
        return ;
    }
    if (value == nil) {
        [[self params] removeObjectForKey:field];
        return ;
    }
    [[self params] setValue:value forKey:field];
}

- (void)removeParam:(NSString *)field {
    if (field == nil) {
        return ;
    }
    [[self params] removeObjectForKey:field];
}

- (void)setHttpBody:(id)body {
    self.body = body;
}

- (void)addFile:(NSData *)fileData forKey:(NSString *)key fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    if (fileData == nil || key == nil) {
        return ;
    }
    KIRequestFile *file = [[KIRequestFile alloc] init];
    [file setData:fileData];
    [file setFileName:fileName];
    [file setKey:key];
    [file setMimeType:mimeType];
    
    [self.files setObject:file forKey:key];
}

- (void)addPNGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName {
    [self addFile:UIImagePNGRepresentation(image) forKey:key fileName:fileName mimeType:@"image/png"];
}

- (void)addJPEGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName {
    [self addFile:UIImageJPEGRepresentation(image, 1.0) forKey:key fileName:fileName mimeType:@"image/jpeg"];
}

- (void)startRequest {
    AFHTTPSessionManager *manager = [self manager];
    
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    
    if (self.body != nil) {
        [self requestWithBody];
    } else if (self.files.allValues.count > 0) {
        self.task = [self requestWithFile];
    } else {
        self.task = [self defaultRequest];
    }
    
    if (self.task != nil) {
        [[KIFormRequest sharedRequestPool] setObject:self forKey:@(self.task.taskIdentifier)];
        [self.task resume];
    }
}

- (void)cancel {
    if (self.task != nil) {
        [self.task cancel];
    }
}

#pragma mark - Private Methods
#pragma mark - 自定义 HTTP Body 的请求
- (NSURLSessionDataTask *)requestWithBody {
    AFHTTPSessionManager *manager = [self manager];
    __weak KIFormRequest *weakSelf = self;
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST"
                                                                             URLString:self.URLString
                                                                            parameters:nil error:nil];
    
    req.timeoutInterval= manager.requestSerializer.timeoutInterval;
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [req setValue:obj forHTTPHeaderField:key];
    }];
    [req setHTTPBody:self.body];
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:req
                                            completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                if (error != nil) {
                                                    [weakSelf dispatchFailureMsg:response error:error];
                                                } else {
                                                    [weakSelf dispatchSuccessMsg:response responseObject:responseObject];
                                                }
                                            }];
    return task;
}

#pragma mark - 上传文件
- (NSURLSessionDataTask *)requestWithFile {
    AFHTTPSessionManager *manager = [self manager];
    __weak KIFormRequest *weakSelf = self;
    
    NSURLSessionDataTask *task = [manager POST:self.URLString
                                    parameters:self.params
                     constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                         for (KIRequestFile *file in weakSelf.files.allValues) {
                             [formData appendPartWithFileData:file.data name:file.key fileName:file.fileName mimeType:file.mimeType];
                         }
                     } progress:^(NSProgress *uploadProgress) {
                         [weakSelf dispatchUploadProgressMsg:uploadProgress];
                     } success:^(NSURLSessionDataTask *task, id responseObject) {
                         [weakSelf dispatchSuccessMsg:task.response responseObject:responseObject];
                     } failure:^(NSURLSessionDataTask *task, NSError *error) {
                         [weakSelf dispatchFailureMsg:task.response error:error];
                     }];
    return task;
}

#pragma mark - 普通的 HTTP 请求
- (NSURLSessionDataTask *)defaultRequest {
    AFHTTPSessionManager *manager = [self manager];
    __weak KIFormRequest *weakSelf = self;
    
    NSURLSessionDataTask *task = [(id<AFHTTPManager>)manager dataTaskWithHTTPMethod:self.method
                                                                          URLString:self.URLString
                                                                         parameters:self.params
                                                                     uploadProgress:^(NSProgress *uploadProgress) {
                                                                         [weakSelf dispatchUploadProgressMsg:uploadProgress];
                                                                     } downloadProgress:^(NSProgress *downloadProgress) {
                                                                         [weakSelf dispatchDownloadProgressMsg:downloadProgress];
                                                                     } success:^(NSURLSessionDataTask *task, id responseObject) {
                                                                         [weakSelf dispatchSuccessMsg:task.response responseObject:responseObject];
                                                                     } failure:^(NSURLSessionDataTask *task, NSError * error) {
                                                                         [weakSelf dispatchFailureMsg:task.response error:error];
                                                                     }];
    
#if DEBUG
    NSLog(@"============================================================");
    NSLog(@"发起网络请求[%@]：%@", self.method, self.URLString);
    NSLog(@"网络请求参数：%@", self.params);
    NSLog(@"网络请求头：%@", task.currentRequest.allHTTPHeaderFields);
    NSLog(@"============================================================");
#endif
    return task;
}

- (void)dispatchSuccessMsg:(NSURLResponse *)task responseObject:(id)responseObject {
    if (self.requestSuccessBlock != nil) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task;
        self.requestSuccessBlock(response.statusCode, responseObject);
    }
    [[KIFormRequest sharedRequestPool] removeObjectForKey:@(self.task.taskIdentifier)];
}

- (void)dispatchFailureMsg:(NSURLResponse *)task error:(NSError *)error {
#if DEBUG
    NSLog(@"网络请求错误：%@", error);
#endif
    if (self.requestFailureBlock != nil) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task;
        NSData *responseData = (NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        self.requestFailureBlock(response.statusCode, error, responseData);
    }
    [[KIFormRequest sharedRequestPool] removeObjectForKey:@(self.task.taskIdentifier)];
}

- (void)dispatchDownloadProgressMsg:(NSProgress *)downloadProgress {
    if (self.downloadProgressBlock != nil) {
        self.downloadProgressBlock(downloadProgress);
    }
}

- (void)dispatchUploadProgressMsg:(NSProgress *)uploadProgress {
    if (self.uploadProgressBlock != nil) {
        self.uploadProgressBlock(uploadProgress);
    }
}

#pragma mark - Getters & Setters
- (NSMutableDictionary *)headers {
    if (_headers == nil) {
        _headers = [[NSMutableDictionary alloc] init];
    }
    return _headers;
}

- (NSMutableDictionary *)params {
    if (_params == nil) {
        _params = [[NSMutableDictionary alloc] init];
    }
    return _params;
}

- (NSMutableDictionary *)files {
    if (_files == nil) {
        _files = [[NSMutableDictionary alloc] init];
    }
    return _files;
}

- (void)successBlock:(KIFormRequestSuccessBlock)block {
    [self setRequestSuccessBlock:block];
}

- (void)failureBlock:(KIFormRequestFailureBlock)block {
    [self setRequestFailureBlock:block];
}

- (void)downloadProgressBlock:(KIFormRequestDownloadProgressBlock)block {
    [self setDownloadProgressBlock:block];
}

- (void)uploadProgressBlock:(KIFormRequestUploadProgressBlock)block {
    [self setUploadProgressBlock:block];
}

@end
