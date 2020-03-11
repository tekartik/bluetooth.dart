//
//  BfleClientPlugin.h
//  Pods
//
//  Created by Alexandre Roux on 12/10/2019.
//
#ifndef BfleClientPlugin_h
#define BfleClientPlugin_h

#import "BflePlugin.h"

@interface BfleClientPlugin : NSObject
- (bool)isScanning;

- (id)initWithPlugin:(BflePlugin*)bflePlugin;
@end

#endif
