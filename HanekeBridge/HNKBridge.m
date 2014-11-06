//
//  HNKBridge.m
//  Haneke
//
//  Created by Hermes Pique on 10/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

#import "HNKBridge.h"
#import <sys/xattr.h>

@implementation NSString(Haneke)

- (BOOL)hnk_setValue:(NSString*)value forExtendedFileAttribute:(NSString*)attribute
{
    const char *attributeC = [attribute UTF8String];
    const char *path = [self fileSystemRepresentation];
    const char *valueC = [value UTF8String];
    const int result = setxattr(path, attributeC, valueC, strlen(valueC), 0, 0);
    return result == 0;
}

- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute
{
    const char *attributeC = [attribute UTF8String];
    const char *path = [self fileSystemRepresentation];
    
    const ssize_t length = getxattr(path, attributeC, NULL, 0, 0, 0);
    
    if (length <= 0) return nil;
    
    char *buffer = malloc(length);
    getxattr(path, attributeC, buffer, length, 0, 0);
    
    NSString *value = [[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding];
    
    free(buffer);
    
    return value;
}

@end
