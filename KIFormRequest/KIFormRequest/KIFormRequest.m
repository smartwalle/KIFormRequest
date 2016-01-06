//
//  KIFormRequest.m
//  Kitalker
//
//  Created by 杨 烽 on 12-10-29.
//
//

#import "KIFormRequest.h"

@implementation KIHTTPRequestOperationManager

+ (KIHTTPRequestOperationManager *)sharedManager {
    static dispatch_once_t onceToken;
    static KIHTTPRequestOperationManager *REQUEST_OPERATION_MANAGER = nil;
    dispatch_once(&onceToken, ^{
        REQUEST_OPERATION_MANAGER = [[KIHTTPRequestOperationManager alloc] init];
        
        NSMutableSet *contentTypes = [[NSMutableSet alloc] init];
        [contentTypes addObject:@"text/html"];
        [contentTypes addObject:@"text/javascript"];
        [contentTypes addObject:@"application/json"];
        [contentTypes addObject:@"text/json"];
        [contentTypes addObject:@"application/xml"];
        [contentTypes addObject:@"text/xml"];
        [contentTypes addObject:@"application/x-plist"];
        
        [REQUEST_OPERATION_MANAGER.responseSerializer setAcceptableContentTypes:contentTypes];

        NSOperationQueue *operationQueue = REQUEST_OPERATION_MANAGER.operationQueue;
        [REQUEST_OPERATION_MANAGER.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    [operationQueue setSuspended:NO];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                default:
                    [operationQueue setSuspended:YES];
                    break;
            }
        }];
        
        [REQUEST_OPERATION_MANAGER.reachabilityManager startMonitoring];
    });
    
    REQUEST_OPERATION_MANAGER.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    return REQUEST_OPERATION_MANAGER;
}
@end

@interface KIFormRequest ()
@property (nonatomic, weak) KIHTTPRequestOperationManager *requestManager;
@end

@implementation KIFormRequest

@synthesize identifier      = _identifier;
@synthesize requestParam    = _requestParam;
@synthesize error           = _error;

- (void)dealloc {
    _identifier = nil;
    _requestParam = nil;
    _error = nil;
}

- (id)initWithParam:(KIRequestParam *)param {
    
    self.requestManager = [KIHTTPRequestOperationManager sharedManager];
    
    [param.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.requestManager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    
    NSString *method = [param.method copy];
    NSString *URLString = [[NSURL URLWithString:param.urlString relativeToURL:self.requestManager.baseURL] absoluteString];
    NSMutableDictionary *parameters = (NSMutableDictionary *)[param param];
    
    NSMutableURLRequest *request = nil;
    
    BOOL hasData = NO;
    
    if (param.postDatas != nil && param.postDatas.allValues != nil && param.postDatas.allValues.count > 0) {
        hasData = YES;
    }
    
    if (hasData) {
        request = [self.requestManager.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                              URLString:URLString
                                                                             parameters:parameters
                                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                  NSArray *files = [[param postDatas] allValues];
                                                                  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                      KIPostData *postData = (KIPostData *)obj;
                                                                      if (postData != nil && [postData isKindOfClass:[KIPostData class]]) {
                                                                          if (postData.fileName) {
                                                                              [formData appendPartWithFileData:postData.data
                                                                                                          name:postData.key
                                                                                                      fileName:postData.fileName
                                                                                                      mimeType:postData.mineType];
                                                                          } else {
                                                                              [formData appendPartWithFormData:postData.data name:postData.key];
                                                                          }
                                                                      }
                                                                  }];
                                                              }
                                                                                  error:nil];
    } else {
        request = [self.requestManager.requestSerializer requestWithMethod:method
                                                                 URLString:URLString
                                                                parameters:parameters
                                                                     error:nil];
    }
    
    id httpBody = [param httpBody];
    
    if (httpBody) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:httpBody
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        [request setHTTPBody:data];
    }
    
    [request setTimeoutInterval:param.timeout];
    
    if (self = [super initWithRequest:request]) {
         _requestParam = param;
        self.responseSerializer = self.requestManager.responseSerializer;
        self.shouldUseCredentialStorage = self.requestManager.shouldUseCredentialStorage;
        self.credential = self.requestManager.credential;
        self.securityPolicy = self.requestManager.securityPolicy;
    }
    
    return self;
}

- (void)startRequest:(NSString *)identifier
       finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
         failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    
    _identifier = identifier;
    
#if DEBUG
    NSLog(@"发起网络请求[%@]：%@", self.request.HTTPMethod, self.request.URL.absoluteString);
    NSLog(@"网络请求参数：%@", self.requestParam.param);
    NSLog(@"网络请求头：%@", self.request.allHTTPHeaderFields);
    if (self.request.HTTPBody != nil) {
        NSLog(@"网络请求Body：%@", [[NSString alloc] initWithData:self.request.HTTPBody encoding:NSUTF8StringEncoding]);
    }
#endif
    
    __weak KIFormRequest *weakSelf = self;
    
    [self setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (finishedBlock) {
            KIFormRequest *request = (KIFormRequest *)operation;
            finishedBlock(request, request.responseStatusCode, operation.responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf setError:error];
        if (failedBlock) {
#if DEBUG
            NSLog(@"网络请求错误：%@", error);
#endif
            KIFormRequest *request = (KIFormRequest *)operation;
            failedBlock(request, request.responseStatusCode, error);
        }
    }];
    
    [self.requestManager.operationQueue addOperation:self];
}

- (void)setError:(NSError *)error {
    _error = error;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (id)responseObject {
    id object = [super responseObject];
    return object != nil ? object : self.responseString;
}

+ (KIFormRequest *)startRequest:(KIRequestParam *)param
                  finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                    failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    KIFormRequest *requeset = [[KIFormRequest alloc] initWithParam:param];
    [requeset startRequest:param.urlString
             finishedBlock:finishedBlock
               failedBlock:failedBlock];
    return requeset;
}

+ (KIFormRequest *)startRequest:(NSString *)urlString
                         method:(NSString *)method
                         params:(NSDictionary *)params
                  finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                    failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    KIRequestParam *param = [[KIRequestParam alloc] init];
    [param setUrlString:urlString];
    [param setMethod:method];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [param addParam:obj forKey:key];
    }];
    
    return [KIFormRequest startRequest:param
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doGet:(NSString *)urlString
                  params:(NSDictionary *)params
           finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
             failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpGet
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doPost:(NSString *)urlString
                   params:(NSDictionary *)params
            finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
              failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpPost
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doDelete:(NSString *)urlString
                     params:(NSDictionary *)params
              finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpDelete
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doPut:(NSString *)urlString
                  params:(NSDictionary *)params
           finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
             failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpPut
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doPatch:(NSString *)urlString
                    params:(NSDictionary *)params
             finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
               failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpPatch
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

+ (KIFormRequest *)doHead:(NSString *)urlString
                   params:(NSDictionary *)params
            finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
              failedBlock:(KIFormRequestDidFailedBlock)failedBlock {
    return [KIFormRequest startRequest:urlString
                                method:KIHttpHead
                                params:params
                         finishedBlock:finishedBlock
                           failedBlock:failedBlock];
}

@end
