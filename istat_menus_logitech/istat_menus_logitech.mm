//
//  istat_menus_logitech.m
//  istat_menus_logitech
//
//  Created by admin on 2022/2/28.
//

#import "CaptainHook.h"
#include <stdio.h>
#include <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <dlfcn.h>
#include <string>

#import "JFRSecurity.h"
#import "JFRWebSocket.h"

using namespace std;


static NSMutableArray<NSMutableDictionary *> *g_deviceInfos;

CHDeclareClass(BatteryStatCollectorMac)
CHOptimizedMethod(0, self, NSArray *, BatteryStatCollectorMac, batteriesLogitech) {
//    NSDictionary *item = @{
//        @"Serial Number": @"123456",
//        @"Battery Level": @"1",
//        @"Device Name": @"G Pro"
//    };
#ifdef DEBUG
    NSLog(@"ISTAT_LOGITECH batteriesLogitech");
#endif
//    return @[item];
    
    return g_deviceInfos;
}

@interface Client : NSObject<JFRWebSocketDelegate>

@property (nonatomic, retain) JFRWebSocket *socket;

- (void)start;

@end

@interface Client()
@property (atomic, assign) NSUInteger msgId;
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation Client
- (instancetype)init {
    if ([super init]) {
        self.msgId = 1;
        self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost:9010"] protocols:@[@"json"]];
        self.socket.delegate = self;
        
        self.timer = [NSTimer timerWithTimeInterval:20.0 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
        [NSRunLoop.currentRunLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
        
    }
    return self;
}

- (void)refresh {
    if (!self.socket.isConnected) {
        return;
    }
    
    // msg = "{\"msg_id\":\"516\",\"verb\":\"GET\",\"path\":\"/devices/list\"}"
    NSDictionary *data = @{
        @"msg_id": [self obtainMsgId],
        @"verb": @"GET",
        @"path": @"/devices/list"
    };
    
    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"JSON Output: %@", jsonString);
    [self.socket writeString:jsonString];
}

- (NSString *)obtainMsgId {
    return [NSString stringWithFormat:@"%lu", (unsigned long)self.msgId++];
}

- (void)start {
    [self.socket connect];
}

-(void)websocketDidConnect:(JFRWebSocket *)socket {
#ifdef DEBUG
    NSLog(@"ISTAT_LOGITECH websocket is connected");
#endif
    [self refresh];
}

-(void)websocket:(JFRWebSocket *)socket didReceiveData:(NSData *)data {
//    NSLog(@"got some binary data: %lu",(unsigned long)data.length);
}

-(void)websocket:(JFRWebSocket *)socket didReceiveMessage:(NSString *)string {
//    NSLog(@"received: %@", string);
    NSError *err = nil;
    
    // Get JSON data into a Foundation object
    id object = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&err];
    if ([object isKindOfClass:[NSDictionary class]] && err == nil) {
//        payload =     {
        NSString *payloadType = object[@"payload"][@"@type"];
        if ([payloadType isEqualToString:@"type.googleapis.com/logi.protocol.devices.Device.Info.List"]) {
//            NSLog(@"list retrived");
            NSArray *deviceInfos = object[@"payload"][@"deviceInfos"];
            
            [g_deviceInfos removeAllObjects];
            for (NSDictionary *info in deviceInfos) {
                NSArray *activeInterfaces = info[@"activeInterfaces"];
                if (activeInterfaces.count == 0) {
                    continue;
                }
                
                NSMutableDictionary *deviceItem = [NSMutableDictionary dictionaryWithDictionary: @{
                    @"__deviceId": info[@"id"],
                    @"Serial Number": activeInterfaces[0][@"serialNumber"],
                    @"Battery Level": @"100",
                    @"Device Name": info[@"displayName"],
                    @"HIDDefaultBehavior": @"mouse" // Hardcode here
                }];
                
                [g_deviceInfos addObject:deviceItem];
            }
            
            for (NSDictionary *info in deviceInfos) {
                // "{\"msg_id\":\"517\",\"verb\":\"GET\",\"path\":\"/battery/dev00000000/state\"}"
                NSDictionary *req = @{
                    @"msg_id": [self obtainMsgId],
                    @"verb": @"GET",
                    @"path": [NSString stringWithFormat:@"/battery/%@/state", info[@"id"]]
                };
                NSData *reqData = [NSJSONSerialization dataWithJSONObject:req options:NSJSONWritingPrettyPrinted error:&err];
                [self.socket writeData:reqData];
            }
            
        } else if ([payloadType isEqualToString:@"type.googleapis.com/logi.protocol.wireless.Battery"]) {
            for (NSMutableDictionary *deviceItem in g_deviceInfos) {
                if ([deviceItem[@"__deviceId"] isEqualToString: object[@"payload"][@"deviceId"]]) {
                    [deviceItem setObject:object[@"payload"][@"percentage"] forKey:@"Battery Level"];
                }
            }
#ifdef DEBUG
            NSLog(@"ISTAT_LOGITECH Devices: %@", g_deviceInfos);
#endif
        }
    }
}

-(void)websocketDidDisconnect:(JFRWebSocket *)socket error:(NSError *)error {
//    NSLog(@"websocket is disconnected: %@",[error localizedDescription]);
}
@end

static Client *g_client = nil;

__attribute__((constructor))
void hook_entry() {
    
    CHLoadLateClass(BatteryStatCollectorMac);
    CHHook(0, BatteryStatCollectorMac, batteriesLogitech);
    
    NSLog(@"ISTAT_LOGITECH Plugin loaded");
    
    @autoreleasepool {
        g_deviceInfos = [NSMutableArray new];
        g_client = [Client new];
        [g_client start];
    }
    
}
