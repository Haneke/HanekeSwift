//
//  HNKBridge.h
//  Haneke
//
//  Created by Hermes Pique on 10/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Haneke)

- (BOOL)hnk_setValue:(NSString*)value forExtendedFileAttribute:(NSString*)attribute;

- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute;

@end
