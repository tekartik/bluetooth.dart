#ifndef BflePlugin_h
#define BflePlugin_h

#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BflePlugin : NSObject<FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate>
@end

#endif
