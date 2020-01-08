//
//  BfleClientPlugin.m
//  tekartik_bluetooth_flutter
//
//  Created by Alexandre Roux on 12/10/2019.
//

#import <Foundation/Foundation.h>
#import "BfleClientPlugin.h"

@interface BfleClientPlugin ()
@property (atomic, assign) bool _isScanning;
@property( nonatomic, retain) BflePlugin* _bflePlugin;
@end

@implementation BfleClientPlugin

@synthesize _isScanning, _bflePlugin;

- (id)initWithPlugin:(BflePlugin*)bflePlugin {
    self = [super init];
    if (self) {
        _bflePlugin = bflePlugin;
        _isScanning = false;
    }
    return self;
}

- (bool)isScanning {
    return _isScanning;
}

@end
