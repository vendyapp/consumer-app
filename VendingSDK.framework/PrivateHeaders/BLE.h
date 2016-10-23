/*
 * Copyright 2016 MasterCard International.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of the MasterCard International Incorporated nor the names of its
 * contributors may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

static NSString * const kManufacturerIdentifier     = @"2A29";
static NSString * const kModelNumberIdentifier      = @"2A24";
static NSString * const kSerialNumberIdentifier     = @"2A25";
static NSString * const kHardwareRevisionIdentifier = @"2A27";
static NSString * const kFirmwareRevisionIdentifier = @"2A26";
static NSString * const kSoftwareRevisionIdentifier = @"2A28";

@class BLEScan, BleObject;
@protocol BleComm;

@protocol ScanDelegate <NSObject>
- (void)onReady:(BLEScan *)bleScan;
- (void)onPoweredOff:(BLEScan *)bleScan;
- (void)onScanDone:(BLEScan *)bleScan peripherals:(NSArray<BleObject *> *)peripherals;

@end

@protocol CommDelegate <NSObject>
- (void)onConnect:(id<BleComm>)bleComm;
- (void)onDisconnect:(id<BleComm>)bleComm;
- (void)onData:(id<BleComm>)bleComm data:(NSString *)data;

@end

@protocol BleComm

@optional
- (void)connect;
- (void)send:(NSString *)data;
- (void)writeRawData:(NSData *)data;
- (void)disconnect;

@end

@interface DataHandler : NSObject

@property (nonatomic, weak) id <BleComm> bleComm;
@property (nonatomic, weak) id <CommDelegate> commDelegate;
@property (nonatomic, assign) NSInteger packetSize;

- (instancetype)initWith:(id <BleComm>)bleComm commDelegate:(id <CommDelegate>)commDelegate packetSize:(NSInteger)packetSize;
- (void)onConnectionFinalized;
- (void)onData:(NSData *)data;
- (void)writeRaw:(NSData *)data;
- (void)writeString:(NSString *)data;

@end

@interface ProtocolDataHandler : DataHandler

- (instancetype)initWith:(id <BleComm>)bleComm commDelegate:(id <CommDelegate>)commDelegate packetSize:(NSInteger)packetSize;
- (void)onConnectionFinalized;
- (void)writeString:(NSString *)data;
- (void)pingIn;
- (void)pingOut;
- (void)onDataPacket:(NSData *)data;

@end

@interface BleObject : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *manufacturerName;
@property (nonatomic, strong) NSString *modelNumber;
@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSString *hardwareRevision;
@property (nonatomic, strong) NSString *firmwareRevision;
@property (nonatomic, strong) NSString *softwareRevision;
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, assign) NSInteger connectionAttempts;

@end

@interface BLEScan : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) NSMutableArray<BleObject *> *peripherals;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBUUID *sUUID;
@property (nonatomic, strong) NSTimer *scanTimer;
@property (nonatomic, weak) id <ScanDelegate> delegate;
@property (nonatomic, strong) NSTimer *connectionTimer;
@property (nonatomic, assign) NSInteger connectionAttempts;
@property (nonatomic, strong) NSArray *characteristics;
@property (nonatomic, assign) BOOL withDeviceInfo;

- (NSInteger)startScan:(CGFloat)timeout withDeviceInfo:(BOOL)deviceInfo;

- (void)tearDown;

@end

@interface DeviceInfoBLEScan : BLEScan

@property (nonatomic, assign) BOOL haltUpdate;
@property (nonatomic, strong) NSString *modelNumber;
@property (nonatomic, strong) NSString *serialNumber;

- (instancetype)initWithDelegate:(id <ScanDelegate>)delegate andCharacteristics:(NSArray *)characteristics;

@end

@interface DefaultBLEComm : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, BleComm>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *currentPeripheral;
@property (nonatomic, strong) CBCharacteristic *txCharacteristic;
@property (nonatomic, strong) CBCharacteristic *rxCharacteristic;
@property (nonatomic, strong) CBUUID *sUUID;
@property (nonatomic, strong) CBUUID *tUUID;
@property (nonatomic, strong) CBUUID *rUUID;
@property (nonatomic, assign) NSInteger packetSize;
@property (nonatomic, strong) NSUUID *deviceId;
@property (nonatomic, weak) id <CommDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *features;
@property (nonatomic, strong) DataHandler *dataHandler;

@end
