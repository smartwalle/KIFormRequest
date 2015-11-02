//
//  KIFormRequest.h
//  Kitalker
//
//  Created by 杨 烽 on 12-10-29.
//
//

#import "AFNetworking.h"
#import "KIRequestParam.h"

@class KIFormRequest;
typedef void(^KIFormRequestDidFinishedBlock)    (KIFormRequest *request, NSInteger statusCode, id responseObject);
typedef void(^KIFormRequestDidFailedBlock)      (KIFormRequest *request, NSInteger statusCode, NSError *error);

@interface KIFormRequest : AFHTTPRequestOperation {
    NSString                    *_identifier;
    KIRequestParam              *_requestParam;
    NSError                     *_error;
}

@property (nonatomic, strong, readonly) NSString        *identifier;
@property (nonatomic, strong, readonly) KIRequestParam  *requestParam;
@property (nonatomic, assign, readonly) NSInteger       responseStatusCode;
@property (nonatomic, readonly)         NSError         *error;

- (id)initWithParam:(KIRequestParam *)param;

- (void)startRequest:(NSString *)identifier
       finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
         failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)startRequest:(KIRequestParam *)param
                  finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                    failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)startRequest:(NSString *)urlString
                         method:(NSString *)method
                         params:(NSDictionary *)params
                  finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                    failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doGet:(NSString *)urlString
                  params:(NSDictionary *)params
           finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
             failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doPost:(NSString *)urlString
                   params:(NSDictionary *)params
            finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
              failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doDelete:(NSString *)urlString
                     params:(NSDictionary *)params
              finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
                failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doPut:(NSString *)urlString
                  params:(NSDictionary *)params
           finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
             failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doPatch:(NSString *)urlString
                    params:(NSDictionary *)params
             finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
               failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

+ (KIFormRequest *)doHead:(NSString *)urlString
                   params:(NSDictionary *)params
            finishedBlock:(KIFormRequestDidFinishedBlock)finishedBlock
              failedBlock:(KIFormRequestDidFailedBlock)failedBlock;

@end
