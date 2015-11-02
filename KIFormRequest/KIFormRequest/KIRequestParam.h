//
//  KIRequestParam.h
//  Kitalker
//
//  Created by 杨 烽 on 12-10-18.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSObject+KIKeyAndValues.h"

extern NSString * const KIHttpGet;
extern NSString * const KIHttpPost;
extern NSString * const KIHttpDelete;
extern NSString * const KIHttpPut;
extern NSString * const KIHttpPatch;
extern NSString * const KIHttpHead;

typedef enum {
    KIRequestTypeOfRemote = 1,
    KIRequestTypeOfLocal,
    KIRequestTypeOfAll
} KIRequestType;

@interface KIPostData : NSObject

@property (nonatomic, strong) NSData    *data;
@property (nonatomic, strong) NSString  *key;
@property (nonatomic, strong) NSString  *fileName;
@property (nonatomic, strong) NSString  *mineType;

@end

@interface KIRequestParam : NSObject {
    NSString            *_urlString;
    NSString            *_method;
    NSTimeInterval      _timeout;
    KIRequestType       _requestType;
    
    /*datas*/
    NSMutableDictionary *_param;
    
    /*动态添加的字段*/
    NSMutableDictionary *_dynamicParam;
    
    /*reuqest headers*/
    NSMutableDictionary *_headers;
    
    /*request body*/
    id  _httpBody;
    
    /*上传二进制数据或文件*/
    NSMutableDictionary *_postDatas;
}

@property (nonatomic, strong) NSString              *urlString;
@property (nonatomic, strong) NSString              *method;
@property (nonatomic, assign) NSTimeInterval        timeout;
@property (nonatomic, assign) KIRequestType         requestType;
@property (nonatomic, readonly) NSDictionary        *param;

- (void)addParam:(id)value forKey:(NSString *)key;

- (NSDictionary *)headers;

- (void)addHeader:(id)value forKey:(NSString *)key;

- (id)httpBody;

- (void)setHttpBody:(id)body;

- (NSDictionary *)postDatas;

- (void)addData:(NSData *)data forKey:(NSString *)key;

- (void)removePostDataWithKey:(NSString *)key;

- (void)removeAllPostData;

- (void)addFile:(NSData *)fileData forKey:(NSString *)key fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (void)addPNGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName;

- (void)addJPEGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName;

@end
