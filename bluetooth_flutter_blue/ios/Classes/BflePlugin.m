#import "BfleClientPlugin.h"

static NSString *const _channelName = @"com.tekartik.sqflite";

static const NSString* _logTag = @"Bfle";
static const int logLevelNone = 0;
static const int logLevelVerbose = 2;
static int _logLevel = logLevelNone;

static bool hasVerboseLogLevel() {
    return _logLevel >= logLevelVerbose;
}

@interface BflePlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, retain) CBCentralManager *centralManager;
@property(nonatomic, retain) BfleClientPlugin *clientPlugin;
@end

@implementation BflePlugin

@synthesize channel, centralManager, clientPlugin;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"tekartik_bluetooth_flutter"
                                     binaryMessenger:[registrar messenger]];
    BflePlugin* instance = [[BflePlugin alloc] init];
    instance.channel = channel;
    // Force on start
    instance.centralManager = [[CBCentralManager alloc] initWithDelegate:instance queue:nil];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (CBCentralManager*)getCentralManager {
    if (!self.centralManager) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        NSLog(@"%@: init centralManager.state %d", _logTag, (int)self.centralManager.state);
    }
    return self.centralManager;
}
- (BfleClientPlugin*)getClientPlugin {
    if (!self.clientPlugin) {
        self.clientPlugin = [[BfleClientPlugin alloc] initWithPlugin:self];
    }
    return self.clientPlugin;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"setOptions" isEqualToString:call.method]) {
        [self handleOptionsCall:call result:result];
    } else if ([@"getInfo" isEqualToString:call.method]) {
        [self handleGetInfoCall:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

//
// Options
//
- (void)handleOptionsCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* logLevelNumber = call.arguments[@"logLevel"];
    
    if (logLevelNumber) {
        _logLevel = [logLevelNumber intValue];
        NSLog(@"%@: logLevel %d", _logTag, _logLevel);
    }
    result(nil);
}

//
// GetInfo
//
- (void)handleGetInfoCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSMutableDictionary* map = [NSMutableDictionary new];
    bool hasBluetooth;
    CBCentralManager* centralManager = [self getCentralManager];
    
    if (@available(iOS 10.0, *)) {
        if (hasVerboseLogLevel()) {
            NSLog(@"%@: centralManager.state %d", _logTag, (int)centralManager.state);
        }
        hasBluetooth = centralManager.state != CBManagerStateUnsupported;
        if (hasBluetooth) {
            [map setValue:[NSNumber numberWithBool:hasBluetooth] forKey:@"hasBluetoothBle"];
            
            bool isBluetoothEnabled = (centralManager.state != CBManagerStateUnauthorized && self.centralManager.state != CBManagerStatePoweredOff);
            
            [map setValue:[NSNumber numberWithBool:isBluetoothEnabled] forKey:@"isBluetoothEnabled"];
            if (isBluetoothEnabled) {
                [map setValue:[NSNumber numberWithBool:[self getClientPlugin].isScanning] forKey:@"isScanning"];
            }
            
            
        }
    } else {
        if (hasVerboseLogLevel()) {
            NSLog(@"%@: Invalid IOS version %@", _logTag, [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
        }
        hasBluetooth = false;  // Fallback on earlier versions
    }
    [map setValue:[NSNumber numberWithBool:hasBluetooth] forKey:@"hasBluetooth"];
    
    
    result(map);
}

//
// CBCentralManagerDelegate methods
//
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    /*
     TODO
     if(_stateStreamHandler.sink != nil) {
     FlutterStandardTypedData *data = [self toFlutterData:[self toBluetoothStateProto:self->_centralManager.state]];
     self.stateStreamHandler.sink(data);
     }
     */
}

@end


