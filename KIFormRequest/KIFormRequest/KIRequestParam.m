//
//  KIRequestParam.m
//  Kitalker
//
//  Created by 杨 烽 on 12-10-18.
//
//

#import "KIRequestParam.h"
#import <objc/runtime.h>

NSString * const KIHttpGet      = @"GET";
NSString * const KIHttpPost     = @"POST";
NSString * const KIHttpDelete   = @"DELETE";
NSString * const KIHttpPut      = @"PUT";
NSString * const KIHttpPatch    = @"PATCH";
NSString * const KIHttpHead     = @"HEAD";

@implementation KIPostData

- (void)dealloc {
    _data = nil;
    _key = nil;
    _fileName = nil;
    _mineType = nil;
}

@end

@implementation KIRequestParam

@synthesize urlString           = _urlString;
@synthesize method              = _method;
@synthesize timeout             = _timeout;
@synthesize requestType         = _requestType;
@synthesize param               = _param;

- (void)dealloc {
    _param = nil;
    _dynamicParam = nil;
    _urlString = nil;
    _method = nil;
    _headers = nil;
    _httpBody = nil;
    _postDatas = nil;
}

- (id)init {
    if (self =[super init]) {
        _method = KIHttpPost;
        _timeout = 60.0f;
        _requestType = KIRequestTypeOfRemote;
    }
    return self;
}

- (NSDictionary *)param {
    if (_param == nil) {
        _param = [[NSMutableDictionary alloc] init];
    }
    
    [_param removeAllObjects];
    
    NSString *propertyName = nil;
    NSString *propertyValue = nil;
    
    NSArray *propertyList = [self attributeList];
    NSUInteger count = propertyList.count;
    
    for (int i=0; i<count; i++) {
        propertyName = [propertyList objectAtIndex:i];
        
        if ([propertyName isEqualToString:@"urlString"]
            || [propertyName isEqualToString:@"method"]
            || [propertyName isEqualToString:@"timeout"]
            || [propertyName isEqualToString:@"requestType"]
            || [propertyName isEqualToString:@"command"]
            || [propertyName isEqualToString:@"files"]
            || [propertyName isEqualToString:@"headers"]
            || [propertyName isEqualToString:@"param"]) {
            continue;
        }
        
        propertyValue =[self valueForKey:propertyName];
        
        [self setupParam:propertyName value:propertyValue];
    }
    
    if (_dynamicParam != nil) {
        for (NSString *key in [_dynamicParam allKeys]) {
            id value = [_dynamicParam objectForKey:key];
            
            [self setupParam:key value:value];
        }
    }
    
    return _param.count > 0 ? _param : nil;
}

- (void)setupParam:(NSString *)key value:(id)value {
    if (value == nil) {
        value = @"";
    }
    
    [_param setObject:value forKey:key];
}

- (void)addParam:(id)value forKey:(NSString *)key {
    if (_dynamicParam == nil) {
        _dynamicParam = [[NSMutableDictionary alloc] init];
    }
    
    if (value != nil && key != nil) {
        [_dynamicParam setObject:value forKey:key];
    }

}

- (NSDictionary *)headers {
    return _headers;
}

- (void)addHeader:(id)value forKey:(NSString *)key {
    if (value != nil && key != nil) {
        if (_headers == nil) {
            _headers = [[NSMutableDictionary alloc] init];
        }
        [_headers setObject:value forKey:key];
    }
}

- (id)httpBody {
    if (_httpBody == nil) {
        return nil;
    } else if ([_httpBody isKindOfClass:[NSArray class]]) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        NSUInteger count = ((NSArray *)_httpBody).count;
        for (int i=0; i<count; i++) {
            id item = [_httpBody objectAtIndex:i];
            if (item == nil) {
                item = @"";
                continue;
            }
            
            if (![item isKindOfClass:[NSDictionary class]]
                && ![item isKindOfClass:[NSArray class]]
                && ![item isKindOfClass:[NSNumber class]]
                && ![item isKindOfClass:[NSString class]]
                && ![item isKindOfClass:[NSNull class]]) {
                [items addObject:[item keyAndValues]];
            } else {
                [items addObject:item];
            }
        }
        
        return items;
    } else if ([_httpBody isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
        
        for (NSString *key in [_httpBody allKeys]) {
            id value = [_httpBody objectForKey:key];
            
            if (value == nil) {
                value = @"";
            }
            
            if (![value isKindOfClass:[NSDictionary class]]
                && ![value isKindOfClass:[NSArray class]]
                && ![value isKindOfClass:[NSNumber class]]
                && ![value isKindOfClass:[NSString class]]
                && ![value isKindOfClass:[NSNull class]]) {
                
                [items setObject:[value keyAndValues]
                          forKey:key];
            } else {
                [items setObject:value forKey:key];
            }
        }
        
        return items;
    } else if ([_httpBody isKindOfClass:[NSNumber class]]
               || [_httpBody isKindOfClass:[NSString class]]
               || [_httpBody isKindOfClass:[NSNull class]]) {
        return @[_httpBody];
    } else if ([_httpBody isKindOfClass:[NSObject class]]) {
        return [_httpBody keyAndValues];
    }
    
    return @[_httpBody];
}

- (void)setHttpBody:(id)body {
    _httpBody = body;
}

- (NSDictionary *)postDatas {
    return _postDatas;
}

- (void)addPostData:(KIPostData *)data {
    if (_postDatas == nil) {
        _postDatas = [[NSMutableDictionary alloc] init];
    }
    [_postDatas setObject:data forKey:data.key];
}

- (void)addData:(NSData *)data forKey:(NSString *)key {
    [self addFile:data forKey:key fileName:nil mimeType:nil];
}

- (void)removePostDataWithKey:(NSString *)key {
    [_postDatas removeObjectForKey:key];
}

- (void)removeAllPostData {
    [_postDatas removeAllObjects];
}

- (void)addFile:(NSData *)fileData forKey:(NSString *)key fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    if (fileData == nil || key == nil) {
        return ;
    }
    KIPostData *file = [[KIPostData alloc] init];
    [file setData:fileData];
    [file setFileName:fileName];
    [file setKey:key];
    [file setMineType:mimeType];
    [self addPostData:file];
}

- (void)addPNGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName {
    [self addFile:UIImagePNGRepresentation(image) forKey:key fileName:fileName mimeType:@"image/jpeg"];
}

- (void)addJPEGFile:(UIImage *)image forKey:(NSString *)key fileName:(NSString *)fileName {
    [self addFile:UIImageJPEGRepresentation(image, 1.0) forKey:key fileName:fileName mimeType:@"image/jpeg"];
}

@end
