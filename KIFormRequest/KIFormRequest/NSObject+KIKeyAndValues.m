//
//  NSObject+KIKeyAndValues.m
//  KIFormRequest
//
//  Created by apple on 15/11/2.
//  Copyright (c) 2015年 smartwalle. All rights reserved.
//

#import "NSObject+KIKeyAndValues.h"
#import <objc/runtime.h>

NSString * const kPropertyList = @"kPropertyList";

@implementation NSObject (KIKeyAndValues)

- (NSMutableArray *)attributeList {
    static NSMutableDictionary *classDictionary = nil;
    if (classDictionary == nil) {
        classDictionary = [[NSMutableDictionary alloc] init];
    }
    
    NSString *className = NSStringFromClass(self.class);
    
    NSMutableArray *propertyList = [classDictionary objectForKey:className];
    
    if (propertyList != nil) {
        return propertyList;
    }
    
    
    //    NSMutableArray *propertyList = objc_getAssociatedObject(self, kPropertyList);
    //
    //    if (propertyList != nil) {
    //        return propertyList;
    //    }
    
    propertyList = [[NSMutableArray alloc] init];
    
    id theClass = object_getClass(self);
    [self getPropertyList:theClass forList:&propertyList];
    
    [classDictionary setObject:propertyList forKey:className];
    
    
    //    objc_setAssociatedObject(self, kPropertyList, propertyList, OBJC_ASSOCIATION_ASSIGN);
    
    return propertyList;
}

- (void)getPropertyList:(id)theClass forList:(NSMutableArray **)propertyList {
    id superClass = class_getSuperclass(theClass);
    unsigned int count, i;
    objc_property_t *properties = class_copyPropertyList(theClass, &count);
    for (i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)
                                                          encoding:NSUTF8StringEncoding];
        if (propertyName != nil) {
            [*propertyList addObject:propertyName];
            propertyName = nil;
        }
    }
    free(properties);
    
    if (superClass != [NSObject class]) {
        [self getPropertyList:superClass forList:propertyList];
    }
}

- (NSMutableDictionary *)keyAndValues {
    return [NSObject objectKeyValues:self];
}

+ (NSMutableDictionary *)objectKeyValues:(id)object {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    NSArray *propertyList = [object attributeList];
    NSUInteger count = propertyList.count;
    
    NSString *propertyName = nil;
    
    for (int i=0; i<count; i++) {
        propertyName = [propertyList objectAtIndex:i];
        
        id propertyValue =[object valueForKey:propertyName];
        
        if (propertyValue == object) {
            continue;
        }
        
        if (propertyValue == nil) {
            propertyValue = @"";
        }
        
        if (![propertyValue isKindOfClass:[NSDictionary class]]
            && ![propertyValue isKindOfClass:[NSArray class]]
            && ![propertyValue isKindOfClass:[NSNumber class]]
            && ![propertyValue isKindOfClass:[NSString class]]
            && ![propertyValue isKindOfClass:[NSNull class]]) {
            
            [dictionary setObject:[NSObject objectKeyValues:propertyValue]
                           forKey:propertyName];
        } else {
            [dictionary setObject:propertyValue forKey:propertyName];
        }
    }
    return dictionary;
}

@end
