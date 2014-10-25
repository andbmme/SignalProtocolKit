//
//  RatchetingSessionTest.m
//  AxolotlKit
//
//  Created by Frederic Jacobs on 24/10/14.
//  Copyright (c) 2014 Frederic Jacobs. All rights reserved.
//
#import <XCTest/XCTest.h>

#import <25519/Curve25519.h>
#import <25519/Ed25519.h>

#import "AxolotlInMemoryStore.h"
#import "AliceAxolotlParameters.h"
#import "BobAxolotlParameters.h"
#import "SessionCipher.h"
#import "SessionState.h"
#import "RatchetingSession.h"
#import "SessionRecord.h"
#import "ChainKey.h"

@implementation ECKeyPair (testing)

+(ECKeyPair*)keyPairWithPrivateKey:(NSData*)privateKey publicKey:(NSData*)publicKey{
    const Byte DJB_TYPE = 0x05;
    
    if ([privateKey length] == 33) {
        privateKey = [privateKey subdataWithRange:NSMakeRange(1, 32)];
    }
    
    if (([publicKey length]  == 33)) {
        if ([[publicKey subdataWithRange:NSMakeRange(0, 1)] isEqualToData:[NSData dataWithBytes:&DJB_TYPE length:1]]) {
            publicKey = [publicKey subdataWithRange:NSMakeRange(1, 32)];
        }
    }
    
    if ([privateKey length] != ECCKeyLength && [publicKey length] != ECCKeyLength) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Public or Private key is not required size" userInfo:@{@"PrivateKey":privateKey, @"Public Key":publicKey}];
    }
    
    ECKeyPair *keyPair  = [ECKeyPair new];
    memcpy(keyPair->publicKey,  [publicKey  bytes], ECCKeyLength);
    memcpy(keyPair->privateKey, [privateKey bytes], ECCKeyLength);
    
    return keyPair;
}

@end

@interface RatchetingSessionTest : XCTestCase

@end

@implementation RatchetingSessionTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSessionInitializationAndFirstEncrypt {
    
    Byte aliceIdentityPrivateKey [] = {(Byte) 0xF0, (Byte) 0x74, (Byte) 0x93, (Byte) 0x5E,
        (Byte) 0xFB, (Byte) 0x9B, (Byte) 0x81, (Byte) 0x79,
        (Byte) 0xE4, (Byte) 0xEE, (Byte) 0x7D, (Byte) 0xD2,
        (Byte) 0xD3, (Byte) 0x4D, (Byte) 0x73, (Byte) 0x07,
        (Byte) 0x1C, (Byte) 0xC2, (Byte) 0x10, (Byte) 0xB8,
        (Byte) 0x49, (Byte) 0xBD, (Byte) 0x85, (Byte) 0x5E,
        (Byte) 0x82, (Byte) 0x53, (Byte) 0x1C, (Byte) 0x06,
        (Byte) 0x1C, (Byte) 0x06, (Byte) 0x1C, (Byte) 0x5F};
    NSData *aliceIdentityPrivateKeyData =  [NSData dataWithBytes:aliceIdentityPrivateKey length:32];
   
    Byte aliceIdentityPublicKey [] = {(Byte) 0x05, (Byte) 0xF2, (Byte) 0xEF, (Byte) 0x72,
        (Byte) 0xF2, (Byte) 0xF0, (Byte) 0xBD, (Byte) 0x31,
        (Byte) 0x9E, (Byte) 0xBD, (Byte) 0xC1, (Byte) 0x27,
        (Byte) 0x9F, (Byte) 0x96, (Byte) 0x78, (Byte) 0x79,
        (Byte) 0x78, (Byte) 0xA0, (Byte) 0x35, (Byte) 0xCF,
        (Byte) 0x1E, (Byte) 0xAA, (Byte) 0xDB, (Byte) 0xFE,
        (Byte) 0xCD, (Byte) 0xB5, (Byte) 0x0E, (Byte) 0x54,
        (Byte) 0xAB, (Byte) 0x21, (Byte) 0x7F, (Byte) 0xC2,
        (Byte) 0x6E};
    NSData *aliceIdentityPublicKeyData =  [NSData dataWithBytes:aliceIdentityPublicKey length:33];
   
    Byte aliceBasePublicKey [] = {(Byte) 0x05, (Byte) 0xA0, (Byte) 0x13, (Byte) 0x89,
        (Byte) 0x89, (Byte) 0xAE, (Byte) 0x98, (Byte) 0x82,
        (Byte) 0x6D, (Byte) 0xD7, (Byte) 0xAA, (Byte) 0xBF,
        (Byte) 0x97, (Byte) 0x0A, (Byte) 0x1C, (Byte) 0x82,
        (Byte) 0x4D, (Byte) 0x08, (Byte) 0x60, (Byte) 0x3C,
        (Byte) 0xF8, (Byte) 0x12, (Byte) 0x18, (Byte) 0x38,
        (Byte) 0x92, (Byte) 0x1F, (Byte) 0xF3, (Byte) 0x6F,
        (Byte) 0xF9, (Byte) 0x6A, (Byte) 0xC1, (Byte) 0xF2,
        (Byte) 0x6D};
    NSData *aliceBasePublicKeyData =  [NSData dataWithBytes:aliceBasePublicKey length:33];
  
    Byte aliceBasePrivateKey [] = {(Byte) 0x78, (Byte) 0xDE, (Byte) 0x94, (Byte) 0x38,
        (Byte) 0x7B, (Byte) 0x3A, (Byte) 0xC9, (Byte) 0x1A,
        (Byte) 0xE3, (Byte) 0x64, (Byte) 0xB8, (Byte) 0xB8,
        (Byte) 0x38, (Byte) 0xBC, (Byte) 0x92, (Byte) 0x77,
        (Byte) 0xEA, (Byte) 0x58, (Byte) 0x85, (Byte) 0xC8,
        (Byte) 0x34, (Byte) 0xE3, (Byte) 0x67, (Byte) 0x98,
        (Byte) 0xBE, (Byte) 0xCA, (Byte) 0xCA, (Byte) 0xA4,
        (Byte) 0xD1, (Byte) 0x03, (Byte) 0x9C, (Byte) 0x46};
    NSData *aliceBasePrivateKeyData =  [NSData dataWithBytes:aliceBasePrivateKey length:32];
    
    Byte bobIdentityPublicKey [] = {(Byte) 0x05, (Byte) 0x3C, (Byte) 0xAD, (Byte) 0xFF,
        (Byte) 0x55, (Byte) 0x2B, (Byte) 0x06, (Byte) 0x35,
        (Byte) 0x4B, (Byte) 0x25, (Byte) 0x84, (Byte) 0xC4,
        (Byte) 0x65, (Byte) 0x93, (Byte) 0x9A, (Byte) 0xF0,
        (Byte) 0xF3, (Byte) 0x92, (Byte) 0x44, (Byte) 0xE9,
        (Byte) 0x33, (Byte) 0xD9, (Byte) 0x7E, (Byte) 0x86,
        (Byte) 0x3B, (Byte) 0xFF, (Byte) 0x89, (Byte) 0x5B,
        (Byte) 0x75, (Byte) 0xBA, (Byte) 0x0C, (Byte) 0x03,
        (Byte) 0x7A};
    NSData *bobIdentityPublicKeyData =  [NSData dataWithBytes:bobIdentityPublicKey length:33];
    
    Byte bobIdentityPrivateKey [] = {(Byte) 0x90, (Byte) 0x0A, (Byte) 0x1A, (Byte) 0xFD,
        (Byte) 0xBB, (Byte) 0x02, (Byte) 0x02, (Byte) 0x0F,
        (Byte) 0xC2, (Byte) 0x6F, (Byte) 0xDC, (Byte) 0x48,
        (Byte) 0x45, (Byte) 0x4A, (Byte) 0x3D, (Byte) 0x1C,
        (Byte) 0x78, (Byte) 0x03, (Byte) 0x5D, (Byte) 0x45,
        (Byte) 0x28, (Byte) 0xCE, (Byte) 0x80, (Byte) 0x32,
        (Byte) 0x6B, (Byte) 0x96, (Byte) 0x64, (Byte) 0xE4,
        (Byte) 0x22, (Byte) 0xF4, (Byte) 0x35, (Byte) 0x61};
    NSData *bobIdentityPrivateKeyData =  [NSData dataWithBytes:bobIdentityPrivateKey length:32];
    
    Byte bobBasePrivateKey [] = {(Byte) 0x80, (Byte) 0xC5, (Byte) 0xC6, (Byte) 0x3F,
        (Byte) 0x5A, (Byte) 0xA2, (Byte) 0x20, (Byte) 0xD9,
        (Byte) 0xF4, (Byte) 0x9E, (Byte) 0xB3, (Byte) 0x85,
        (Byte) 0x19, (Byte) 0xF4, (Byte) 0xB6, (Byte) 0x2F,
        (Byte) 0x19, (Byte) 0x58, (Byte) 0xFE, (Byte) 0x8D,
        (Byte) 0xE7, (Byte) 0xEA, (Byte) 0x8E, (Byte) 0xBE,
        (Byte) 0x3B, (Byte) 0xAE, (Byte) 0x50, (Byte) 0x5E,
        (Byte) 0xC9, (Byte) 0x28, (Byte) 0x98, (Byte) 0x7B};
    NSData *bobBasePrivateKeyData =  [NSData dataWithBytes:bobBasePrivateKey length:32];

    Byte bobBasePublicKey [] = {(Byte) 0x05, (Byte) 0xB8, (Byte) 0xC2, (Byte) 0xDE,
        (Byte) 0x9B, (Byte) 0x06, (Byte) 0xF6, (Byte) 0x61,
        (Byte) 0x28, (Byte) 0x76, (Byte) 0x30, (Byte) 0xC7,
        (Byte) 0x2F, (Byte) 0x49, (Byte) 0xD6, (Byte) 0xA3,
        (Byte) 0x3A, (Byte) 0x40, (Byte) 0xA7, (Byte) 0xBE,
        (Byte) 0x89, (Byte) 0x97, (Byte) 0x2E, (Byte) 0x10,
        (Byte) 0x60, (Byte) 0x6B, (Byte) 0xB6, (Byte) 0xC3,
        (Byte) 0x95, (Byte) 0xA5, (Byte) 0x7F, (Byte) 0xB4,
        (Byte) 0x55};
    NSData *bobBasePublicKeyData =  [NSData dataWithBytes:bobBasePublicKey length:33];
    
    Byte bobPreKeyPrivateKey [] = {(Byte) 0x28, (Byte) 0x50, (Byte) 0xB8, (Byte) 0x99,
        (Byte) 0x60, (Byte) 0x58, (Byte) 0x56, (Byte) 0x39,
        (Byte) 0x84, (Byte) 0x80, (Byte) 0xCC, (Byte) 0x29,
        (Byte) 0x25, (Byte) 0x98, (Byte) 0x0A, (Byte) 0x9D,
        (Byte) 0x64, (Byte) 0xD4, (Byte) 0x5C, (Byte) 0x74,
        (Byte) 0x33, (Byte) 0x26, (Byte) 0x97, (Byte) 0xB7,
        (Byte) 0x15, (Byte) 0x38, (Byte) 0x0E, (Byte) 0x98,
        (Byte) 0x13, (Byte) 0x42, (Byte) 0xF0, (Byte) 0x68};
    NSData *bobPreKeyPrivateKeyData =  [NSData dataWithBytes:bobPreKeyPrivateKey length:32];
    
    Byte bobPreKeyPublicKey [] = {(Byte) 0x05, (Byte) 0x3B, (Byte) 0xC6, (Byte) 0x13,
        (Byte) 0xE1, (Byte) 0xE1, (Byte) 0xB5, (Byte) 0x6A,
        (Byte) 0x37, (Byte) 0xC6, (Byte) 0x1A, (Byte) 0x64,
        (Byte) 0xE3, (Byte) 0x25, (Byte) 0xF3, (Byte) 0x34,
        (Byte) 0x89, (Byte) 0x97, (Byte) 0x8C, (Byte) 0x02,
        (Byte) 0x63, (Byte) 0xB8, (Byte) 0x71, (Byte) 0x0C,
        (Byte) 0xB1, (Byte) 0x64, (Byte) 0x60, (Byte) 0x89,
        (Byte) 0xA8, (Byte) 0x45, (Byte) 0x9A, (Byte) 0xF0,
        (Byte) 0x54};
    NSData *bobPreKeyPublicKeyData =  [NSData dataWithBytes:bobPreKeyPublicKey length:33];
    
    Byte aliceSendingRatchetPrivate [] = {(Byte) 0x18, (Byte) 0x9B, (Byte) 0xCA, (Byte) 0xB5,
        (Byte) 0xBE, (Byte) 0x3B, (Byte) 0x31, (Byte) 0xF9,
        (Byte) 0x8C, (Byte) 0xA1, (Byte) 0xCC, (Byte) 0x22,
        (Byte) 0xB7, (Byte) 0x8A, (Byte) 0x7F, (Byte) 0x9D,
        (Byte) 0x0E, (Byte) 0x7A, (Byte) 0xC7, (Byte) 0x88,
        (Byte) 0xB6, (Byte) 0x23, (Byte) 0xA0, (Byte) 0xB8,
        (Byte) 0x76, (Byte) 0x82, (Byte) 0x65, (Byte) 0xEA,
        (Byte) 0x2C, (Byte) 0xDF, (Byte) 0x0C, (Byte) 0x7A};
    NSData *aliceSendingRatchetPrivateData =  [NSData dataWithBytes:aliceSendingRatchetPrivate length:32];
    
    
    Byte aliceSendingRatchetPublic [] = {(Byte) 0x05, (Byte) 0x28, (Byte) 0xC5, (Byte) 0xDA,
        (Byte) 0xEA, (Byte) 0x68, (Byte) 0xE5, (Byte) 0xEA,
        (Byte) 0x80, (Byte) 0xEB, (Byte) 0x85, (Byte) 0x74,
        (Byte) 0x0A, (Byte) 0x4F, (Byte) 0xBD, (Byte) 0xED,
        (Byte) 0xD7, (Byte) 0xA3, (Byte) 0x8A, (Byte) 0xB6,
        (Byte) 0x3C, (Byte) 0xCF, (Byte) 0x3A, (Byte) 0xCE,
        (Byte) 0xB7, (Byte) 0xA3, (Byte) 0x1D, (Byte) 0x74,
        (Byte) 0x12, (Byte) 0x7D, (Byte) 0xC8, (Byte) 0x35,
        (Byte) 0x10};
    NSData *aliceSendingRatchetPublicData =  [NSData dataWithBytes:aliceSendingRatchetPublic length:33];
    
    Byte masterKey [] = {(Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF, (Byte) 0xFF,
        (Byte) 0xAF, (Byte) 0xD1, (Byte) 0x23, (Byte) 0x78,
        (Byte) 0x5B, (Byte) 0x9D, (Byte) 0x5E, (Byte) 0x1C,
        (Byte) 0x9C, (Byte) 0x86, (Byte) 0xBB, (Byte) 0x67,
        (Byte) 0xF5, (Byte) 0xFE, (Byte) 0x89, (Byte) 0x3F,
        (Byte) 0x8E, (Byte) 0x65, (Byte) 0x0E, (Byte) 0x97,
        (Byte) 0x3D, (Byte) 0x52, (Byte) 0x88, (Byte) 0xB2,
        (Byte) 0x55, (Byte) 0x98, (Byte) 0xC0, (Byte) 0x67,
        (Byte) 0xE9, (Byte) 0xAD, (Byte) 0x6B, (Byte) 0x7B,
        (Byte) 0x63, (Byte) 0xE5, (Byte) 0xED, (Byte) 0x4C,
        (Byte) 0x1F, (Byte) 0xC9, (Byte) 0xBA, (Byte) 0xB3,
        (Byte) 0x60, (Byte) 0x77, (Byte) 0xFC, (Byte) 0x59,
        (Byte) 0xB2, (Byte) 0xF3, (Byte) 0x27, (Byte) 0xD4,
        (Byte) 0xDB, (Byte) 0xE0, (Byte) 0x3F, (Byte) 0xD4,
        (Byte) 0x6D, (Byte) 0x92, (Byte) 0x06, (Byte) 0xAA,
        (Byte) 0xA2, (Byte) 0x59, (Byte) 0x05, (Byte) 0x19,
        (Byte) 0xB8, (Byte) 0x3F, (Byte) 0x34, (Byte) 0x59,
        (Byte) 0xDA, (Byte) 0xCB, (Byte) 0xC6, (Byte) 0x3B,
        (Byte) 0x22, (Byte) 0xD6, (Byte) 0xE4, (Byte) 0xA2,
        (Byte) 0x17, (Byte) 0x98, (Byte) 0xA3, (Byte) 0x22,
        (Byte) 0xF3, (Byte) 0x53, (Byte) 0xF2, (Byte) 0xA9,
        (Byte) 0x58, (Byte) 0x30, (Byte) 0xAC, (Byte) 0xCC,
        (Byte) 0x33, (Byte) 0x69, (Byte) 0xBD, (Byte) 0x27,
        (Byte) 0xE5, (Byte) 0x91, (Byte) 0xC9, (Byte) 0x1D,
        (Byte) 0x11, (Byte) 0x88, (Byte) 0xBB, (Byte) 0x0C};
    NSData *masterKeyData =  [NSData dataWithBytes:masterKey length:128];
    
    Byte aliceRootKey [] = {(Byte) 0x56, (Byte) 0xA7, (Byte) 0xD8, (Byte) 0x52,
        (Byte) 0x5D, (Byte) 0xF8, (Byte) 0x27, (Byte) 0x85,
        (Byte) 0x37, (Byte) 0xFC, (Byte) 0x31, (Byte) 0xC1,
        (Byte) 0x6F, (Byte) 0x81, (Byte) 0xCF, (Byte) 0x0B,
        (Byte) 0x60, (Byte) 0xC6, (Byte) 0xF4, (Byte) 0x1A,
        (Byte) 0xFF, (Byte) 0x49, (Byte) 0x19, (Byte) 0x23,
        (Byte) 0xD6, (Byte) 0x3E, (Byte) 0xC4, (Byte) 0x9F,
        (Byte) 0xD6, (Byte) 0xAB, (Byte) 0xE4, (Byte) 0x3A};
    NSData *aliceRootKeyData =  [NSData dataWithBytes:aliceRootKey length:32];
    
    Byte aliceSendingChainKey [] = {(Byte) 0x80, (Byte) 0x9D, (Byte) 0x57, (Byte) 0xFA,
        (Byte) 0xB0, (Byte) 0xD9, (Byte) 0x94, (Byte) 0x9E,
        (Byte) 0xC2, (Byte) 0x7D, (Byte) 0x78, (Byte) 0x04,
        (Byte) 0xBA, (Byte) 0xA9, (Byte) 0x98, (Byte) 0x64,
        (Byte) 0xE5, (Byte) 0x58, (Byte) 0x6F, (Byte) 0xC7,
        (Byte) 0x6A, (Byte) 0x15, (Byte) 0x56, (Byte) 0x87,
        (Byte) 0xE4, (Byte) 0xD2, (Byte) 0x24, (Byte) 0xCB,
        (Byte) 0xE7, (Byte) 0x17, (Byte) 0xFC, (Byte) 0x6D};
    NSData *aliceSendingChainKeyData =  [NSData dataWithBytes:aliceSendingChainKey length:32];
    
    Byte aliceSendingCipherKey [] = {(Byte) 0xD9, (Byte) 0x2F, (Byte) 0x70, (Byte) 0xA5,
        (Byte) 0xBC, (Byte) 0x48, (Byte) 0x8D, (Byte) 0xAC,
        (Byte) 0x06, (Byte) 0xD1, (Byte) 0x8F, (Byte) 0xA7,
        (Byte) 0x5D, (Byte) 0x19, (Byte) 0x14, (Byte) 0x6B,
        (Byte) 0x9F, (Byte) 0xF8, (Byte) 0x4B, (Byte) 0x98,
        (Byte) 0x07, (Byte) 0xE8, (Byte) 0x11, (Byte) 0xDB,
        (Byte) 0x16, (Byte) 0xB8, (Byte) 0x3F, (Byte) 0xCA,
        (Byte) 0x26, (Byte) 0x32, (Byte) 0x4F, (Byte) 0x7D};
    NSData *aliceSendingCipherKeyData =  [NSData dataWithBytes:aliceSendingCipherKey length:32];
    
    Byte bobRootKey [] = {(Byte) 0x5E, (Byte) 0xA3, (Byte) 0xA7, (Byte) 0x4C,
        (Byte) 0xF9, (Byte) 0x60, (Byte) 0x44, (Byte) 0x38,
        (Byte) 0xA4, (Byte) 0xE8, (Byte) 0xF5, (Byte) 0x9D,
        (Byte) 0x13, (Byte) 0x8A, (Byte) 0x89, (Byte) 0xF8,
        (Byte) 0xBC, (Byte) 0xD9, (Byte) 0x86, (Byte) 0xA6,
        (Byte) 0x77, (Byte) 0x7F, (Byte) 0xE9, (Byte) 0x02,
        (Byte) 0xF2, (Byte) 0x6C, (Byte) 0xBA, (Byte) 0x4B,
        (Byte) 0xF1, (Byte) 0x55, (Byte) 0xC4, (Byte) 0x99};
    NSData *bobRootKeyData =  [NSData dataWithBytes:bobRootKey length:32];
    
    Byte aliceSessionRecordRootKey [] = {(Byte) 0x56, (Byte) 0xA7, (Byte) 0xD8, (Byte) 0x52,
        (Byte) 0x5D, (Byte) 0xF8, (Byte) 0x27, (Byte) 0x85,
        (Byte) 0x37, (Byte) 0xFC, (Byte) 0x31, (Byte) 0xC1,
        (Byte) 0x6F, (Byte) 0x81, (Byte) 0xCF, (Byte) 0x0B,
        (Byte) 0x60, (Byte) 0xC6, (Byte) 0xF4, (Byte) 0x1A,
        (Byte) 0xFF, (Byte) 0x49, (Byte) 0x19, (Byte) 0x23,
        (Byte) 0xD6, (Byte) 0x3E, (Byte) 0xC4, (Byte) 0x9F,
        (Byte) 0xD6, (Byte) 0xAB, (Byte) 0xE4, (Byte) 0x3A};
    NSData *aliceSessionRecordRootKeyData =  [NSData dataWithBytes:aliceSessionRecordRootKey length:32];
    
    Byte bobSessionRecordRootKey [] = {(Byte) 0x5E, (Byte) 0xA3, (Byte) 0xA7, (Byte) 0x4C,
        (Byte) 0xF9, (Byte) 0x60, (Byte) 0x44, (Byte) 0x38,
        (Byte) 0xA4, (Byte) 0xE8, (Byte) 0xF5, (Byte) 0x9D,
        (Byte) 0x13, (Byte) 0x8A, (Byte) 0x89, (Byte) 0xF8,
        (Byte) 0xBC, (Byte) 0xD9, (Byte) 0x86, (Byte) 0xA6,
        (Byte) 0x77, (Byte) 0x7F, (Byte) 0xE9, (Byte) 0x02,
        (Byte) 0xF2, (Byte) 0x6C, (Byte) 0xBA, (Byte) 0x4B,
        (Byte) 0xF1, (Byte) 0x55, (Byte) 0xC4, (Byte) 0x99};
    NSData *bobSessionRecordRootKeyData =  [NSData dataWithBytes:bobSessionRecordRootKey length:32];
    
    Byte alicePlaintext [] = {(Byte) 0x54, (Byte) 0x68, (Byte) 0x69, (Byte) 0x73,
        (Byte) 0x20, (Byte) 0x69, (Byte) 0x73, (Byte) 0x20,
        (Byte) 0x61, (Byte) 0x20, (Byte) 0x70, (Byte) 0x6C,
        (Byte) 0x61, (Byte) 0x69, (Byte) 0x6E, (Byte) 0x74,
        (Byte) 0x65, (Byte) 0x78, (Byte) 0x74, (Byte) 0x20,
        (Byte) 0x6D, (Byte) 0x65, (Byte) 0x73, (Byte) 0x73,
        (Byte) 0x61, (Byte) 0x67, (Byte) 0x65, (Byte) 0x2E};
    NSData *alicePlaintextData =  [NSData dataWithBytes:alicePlaintext length:28];

    Byte aliceCipherMessage [] = {(Byte) 0x33, (Byte) 0x0A, (Byte) 0x21, (Byte) 0x05,
        (Byte) 0x28, (Byte) 0xC5, (Byte) 0xDA, (Byte) 0xEA,
        (Byte) 0x68, (Byte) 0xE5, (Byte) 0xEA, (Byte) 0x80,
        (Byte) 0xEB, (Byte) 0x85, (Byte) 0x74, (Byte) 0x0A,
        (Byte) 0x4F, (Byte) 0xBD, (Byte) 0xED, (Byte) 0xD7,
        (Byte) 0xA3, (Byte) 0x8A, (Byte) 0xB6, (Byte) 0x3C,
        (Byte) 0xCF, (Byte) 0x3A, (Byte) 0xCE, (Byte) 0xB7,
        (Byte) 0xA3, (Byte) 0x1D, (Byte) 0x74, (Byte) 0x12,
        (Byte) 0x7D, (Byte) 0xC8, (Byte) 0x35, (Byte) 0x10,
        (Byte) 0x10, (Byte) 0x00, (Byte) 0x18, (Byte) 0x00,
        (Byte) 0x22, (Byte) 0x20, (Byte) 0x9C, (Byte) 0xE0,
        (Byte) 0x7A, (Byte) 0x38, (Byte) 0x2B, (Byte) 0xB1,
        (Byte) 0xA3, (Byte) 0x63, (Byte) 0x79, (Byte) 0xAB,
        (Byte) 0xBA, (Byte) 0x90, (Byte) 0x97, (Byte) 0xAE,
        (Byte) 0x7E, (Byte) 0x7B, (Byte) 0x8C, (Byte) 0x58,
        (Byte) 0x99, (Byte) 0x01, (Byte) 0x81, (Byte) 0xED,
        (Byte) 0xFB, (Byte) 0x57, (Byte) 0xFE, (Byte) 0xED,
        (Byte) 0xD7, (Byte) 0x22, (Byte) 0xB8, (Byte) 0xAE,
        (Byte) 0xD7, (Byte) 0x54, (Byte) 0x48, (Byte) 0xE4,
        (Byte) 0x8E, (Byte) 0xFC, (Byte) 0x76, (Byte) 0xDF,
        (Byte) 0x24, (Byte) 0x2F};
    NSData *aliceCipherMessageData =  [NSData dataWithBytes:aliceCipherMessage length:82];
    
    ECKeyPair *aliceIdentityKey = [ECKeyPair keyPairWithPrivateKey:aliceIdentityPrivateKeyData publicKey:aliceIdentityPublicKeyData];
    
    ECKeyPair *bobIdentityKey   = [ECKeyPair keyPairWithPrivateKey:bobIdentityPrivateKeyData publicKey:bobIdentityPublicKeyData];
    
    ECKeyPair *bobPrekey = [ECKeyPair keyPairWithPrivateKey:bobPreKeyPrivateKeyData publicKey:bobPreKeyPublicKeyData];
    
    ECKeyPair *aliceBaseKey = [ECKeyPair keyPairWithPrivateKey:aliceBasePrivateKeyData publicKey:aliceBasePublicKeyData];
    
    ECKeyPair *bobBaseKey   = [ECKeyPair keyPairWithPrivateKey:bobBasePrivateKeyData publicKey:bobBasePublicKeyData];
    
    ECKeyPair *aliceSendingRatchet = [ECKeyPair keyPairWithPrivateKey:aliceSendingRatchetPrivateData publicKey:aliceSendingRatchetPublicData];
    
    // ---
    
    AxolotlInMemoryStore *aliceStore = [AxolotlInMemoryStore new];
    AxolotlInMemoryStore *bobStore = [AxolotlInMemoryStore new];
    
    SessionRecord *aliceSessionRecord = [SessionRecord new];
    SessionRecord *bobSessionRecord   = [SessionRecord new];
    
    AliceAxolotlParameters *aliceAxolotlParams = [[AliceAxolotlParameters alloc] initWithIdentityKey:aliceIdentityKey theirIdentityKey:bobIdentityKey.publicKey ourBaseKey:aliceBaseKey theirSignedPreKey:bobBaseKey.publicKey theirOneTimePreKey:nil theirRatchetKey:bobBaseKey.publicKey];
    
    BobAxolotlParameters   *bobAxolotlParams   = [[BobAxolotlParameters alloc] initWithMyIdentityKeyPair:bobIdentityKey theirIdentityKey:aliceIdentityKey.publicKey ourSignedPrekey:bobBaseKey ourRatchetKey:bobBaseKey ourOneTimePrekey:nil theirBaseKey:aliceBaseKey.publicKey];
    
    [RatchetingSession initializeSession:aliceSessionRecord.sessionState sessionVersion:3 AliceParameters:aliceAxolotlParams senderRatchet:aliceSendingRatchet];
    
    [RatchetingSession initializeSession:bobSessionRecord.sessionState sessionVersion:3 BobParameters:bobAxolotlParams];
    

    
    XCTAssert([[@"This is a plaintext message." dataUsingEncoding:NSUTF8StringEncoding] isEqualToData:alicePlaintextData], @"Encoding is not correct");
    XCTAssert([aliceSessionRecord.sessionState.rootKey.keyData isEqualToData:aliceSessionRecordRootKeyData]);
    XCTAssert([aliceSessionRecord.sessionState.senderChainKey.key isEqualToData:aliceSendingChainKeyData]);
    XCTAssert([aliceSendingCipherKeyData isEqualToData:aliceSessionRecord.sessionState.senderChainKey.messageKeys.cipherKey]);
   // bobStore.identityKeyPair = bobIdentityKey;
    
    XCTAssert([bobRootKeyData isEqualToData:bobSessionRecord.sessionState.rootKey.keyData]);
    
    [aliceStore storeSession:5L deviceId:1 session:aliceSessionRecord];
    [bobStore storeSession:5L deviceId:1 session:bobSessionRecord];
    
    SessionCipher *aliceSessionCipher = [[SessionCipher alloc] initWithAxolotlStore:aliceStore recipientId:5L deviceId:1];
    SessionCipher *bobSessionCipher = [[SessionCipher alloc] initWithAxolotlStore:bobStore recipientId:5L deviceId:1];
    
    WhisperMessage *message = [aliceSessionCipher encryptMessage:alicePlaintextData];
    
    XCTAssert([message.cipherText isEqualToData:aliceCipherMessageData]);

    
    //NSData *plaintext = [bobSessionCipher decrypt:[[PreKeyWhisperMessage alloc] initWithData:aliceCipherMessageData]];
    
    //XCTAssert([plaintext isEqualToData:alicePlaintextData]);
}

//- (void)testRatchetingSessionAsBob {
//    Byte bobPublic [] = {(Byte) 0x05, (Byte) 0x2c, (Byte) 0xb4, (Byte) 0x97,
//        (Byte) 0x76, (Byte) 0xb8, (Byte) 0x77, (Byte) 0x02,
//        (Byte) 0x05, (Byte) 0x74, (Byte) 0x5a, (Byte) 0x3a,
//        (Byte) 0x6e, (Byte) 0x24, (Byte) 0xf5, (Byte) 0x79,
//        (Byte) 0xcd, (Byte) 0xb4, (Byte) 0xba, (Byte) 0x7a,
//        (Byte) 0x89, (Byte) 0x04, (Byte) 0x10, (Byte) 0x05,
//        (Byte) 0x92, (Byte) 0x8e, (Byte) 0xbb, (Byte) 0xad,
//        (Byte) 0xc9, (Byte) 0xc0, (Byte) 0x5a, (Byte) 0xd4,
//        (Byte) 0x58};
//    
//    Byte bobPrivate [] = {(Byte) 0xa1, (Byte) 0xca, (Byte) 0xb4, (Byte) 0x8f,
//        (Byte) 0x7c, (Byte) 0x89, (Byte) 0x3f, (Byte) 0xaf,
//        (Byte) 0xa9, (Byte) 0x88, (Byte) 0x0a, (Byte) 0x28,
//        (Byte) 0xc3, (Byte) 0xb4, (Byte) 0x99, (Byte) 0x9d,
//        (Byte) 0x28, (Byte) 0xd6, (Byte) 0x32, (Byte) 0x95,
//        (Byte) 0x62, (Byte) 0xd2, (Byte) 0x7a, (Byte) 0x4e,
//        (Byte) 0xa4, (Byte) 0xe2, (Byte) 0x2e, (Byte) 0x9f,
//        (Byte) 0xf1, (Byte) 0xbd, (Byte) 0xd6, (Byte) 0x5a};
//    
//    Byte bobIdentityPublic []   = {(Byte) 0x05, (Byte) 0xf1, (Byte) 0xf4, (Byte) 0x38,
//        (Byte) 0x74, (Byte) 0xf6, (Byte) 0x96, (Byte) 0x69,
//        (Byte) 0x56, (Byte) 0xc2, (Byte) 0xdd, (Byte) 0x47,
//        (Byte) 0x3f, (Byte) 0x8f, (Byte) 0xa1, (Byte) 0x5a,
//        (Byte) 0xde, (Byte) 0xb7, (Byte) 0x1d, (Byte) 0x1c,
//        (Byte) 0xb9, (Byte) 0x91, (Byte) 0xb2, (Byte) 0x34,
//        (Byte) 0x16, (Byte) 0x92, (Byte) 0x32, (Byte) 0x4c,
//        (Byte) 0xef, (Byte) 0xb1, (Byte) 0xc5, (Byte) 0xe6,
//        (Byte) 0x26};
//    
//    Byte bobIdentityPrivate []   = {(Byte) 0x48, (Byte) 0x75, (Byte) 0xcc, (Byte) 0x69,
//        (Byte) 0xdd, (Byte) 0xf8, (Byte) 0xea, (Byte) 0x07,
//        (Byte) 0x19, (Byte) 0xec, (Byte) 0x94, (Byte) 0x7d,
//        (Byte) 0x61, (Byte) 0x08, (Byte) 0x11, (Byte) 0x35,
//        (Byte) 0x86, (Byte) 0x8d, (Byte) 0x5f, (Byte) 0xd8,
//        (Byte) 0x01, (Byte) 0xf0, (Byte) 0x2c, (Byte) 0x02,
//        (Byte) 0x25, (Byte) 0xe5, (Byte) 0x16, (Byte) 0xdf,
//        (Byte) 0x21, (Byte) 0x56, (Byte) 0x60, (Byte) 0x5e};
//    
//    Byte aliceBasePublic [] = {(Byte) 0x05, (Byte) 0x47, (Byte) 0x2d, (Byte) 0x1f,
//        (Byte) 0xb1, (Byte) 0xa9, (Byte) 0x86, (Byte) 0x2c,
//        (Byte) 0x3a, (Byte) 0xf6, (Byte) 0xbe, (Byte) 0xac,
//        (Byte) 0xa8, (Byte) 0x92, (Byte) 0x02, (Byte) 0x77,
//        (Byte) 0xe2, (Byte) 0xb2, (Byte) 0x6f, (Byte) 0x4a,
//        (Byte) 0x79, (Byte) 0x21, (Byte) 0x3e, (Byte) 0xc7,
//        (Byte) 0xc9, (Byte) 0x06, (Byte) 0xae, (Byte) 0xb3,
//        (Byte) 0x5e, (Byte) 0x03, (Byte) 0xcf, (Byte) 0x89,
//        (Byte) 0x50};
//    
//    Byte aliceEphemeralPublic [] = {(Byte) 0x05, (Byte) 0x6c, (Byte) 0x3e, (Byte) 0x0d,
//        (Byte) 0x1f, (Byte) 0x52, (Byte) 0x02, (Byte) 0x83,
//        (Byte) 0xef, (Byte) 0xcc, (Byte) 0x55, (Byte) 0xfc,
//        (Byte) 0xa5, (Byte) 0xe6, (Byte) 0x70, (Byte) 0x75,
//        (Byte) 0xb9, (Byte) 0x04, (Byte) 0x00, (Byte) 0x7f,
//        (Byte) 0x18, (Byte) 0x81, (Byte) 0xd1, (Byte) 0x51,
//        (Byte) 0xaf, (Byte) 0x76, (Byte) 0xdf, (Byte) 0x18,
//        (Byte) 0xc5, (Byte) 0x1d, (Byte) 0x29, (Byte) 0xd3,
//        (Byte) 0x4b};
//    
//    Byte aliceIdentityPublic [] = {(Byte) 0x05, (Byte) 0xb4, (Byte) 0xa8, (Byte) 0x45,
//        (Byte) 0x56, (Byte) 0x60, (Byte) 0xad, (Byte) 0xa6,
//        (Byte) 0x5b, (Byte) 0x40, (Byte) 0x10, (Byte) 0x07,
//        (Byte) 0xf6, (Byte) 0x15, (Byte) 0xe6, (Byte) 0x54,
//        (Byte) 0x04, (Byte) 0x17, (Byte) 0x46, (Byte) 0x43,
//        (Byte) 0x2e, (Byte) 0x33, (Byte) 0x39, (Byte) 0xc6,
//        (Byte) 0x87, (Byte) 0x51, (Byte) 0x49, (Byte) 0xbc,
//        (Byte) 0xee, (Byte) 0xfc, (Byte) 0xb4, (Byte) 0x2b,
//        (Byte) 0x4a};
//    
//    Byte senderChain [] = {(Byte)0xd2, (Byte)0x2f, (Byte)0xd5, (Byte)0x6d, (Byte)0x3f,
//        (Byte)0xec, (Byte)0x81, (Byte)0x9c, (Byte)0xf4, (Byte)0xc3,
//        (Byte)0xd5, (Byte)0x0c, (Byte)0x56, (Byte)0xed, (Byte)0xfb,
//        (Byte)0x1c, (Byte)0x28, (Byte)0x0a, (Byte)0x1b, (Byte)0x31,
//        (Byte)0x96, (Byte)0x45, (Byte)0x37, (Byte)0xf1, (Byte)0xd1,
//        (Byte)0x61, (Byte)0xe1, (Byte)0xc9, (Byte)0x31, (Byte)0x48,
//        (Byte)0xe3, (Byte)0x6b};
//    
//    NSData *bobPublicKey  = [NSData dataWithBytes:bobIdentityPublic  length:33];
//    NSData *bobPrivateKey = [NSData dataWithBytes:bobIdentityPrivate length:32];
//    ECKeyPair *bobIdentityKey = [ECKeyPair keyPairWithPrivateKey:bobPrivateKey publicKey:bobPublicKey];
//    
//    NSData *bobEphemeralPublicKey  = [NSData dataWithBytes:bobPublic length:33];
//    NSData *bobEphemeralPrivateKey = [NSData dataWithBytes:bobPrivate length:32];
//    ECKeyPair *bobEphemeral = [ECKeyPair keyPairWithPrivateKey:bobEphemeralPrivateKey publicKey:bobEphemeralPublicKey];
//    
//    NSData *aliceIdentityPublicKey = [[NSData dataWithBytes:aliceIdentityPublic length:33] subdataWithRange:NSMakeRange(1, 32)];
//    NSData *aliceBasePublicKey = [[NSData dataWithBytes:aliceBasePublic length:33] subdataWithRange:NSMakeRange(1, 32)];
//    NSData *aliceEphemeralKey = [[NSData dataWithBytes:aliceEphemeralPublic length:33] subdataWithRange:NSMakeRange(1, 32)];
//    
//    BobAxolotlParameters *bobAxolotlParameters = [[BobAxolotlParameters alloc] initWithMyIdentityKeyPair:bobIdentityKey theirIdentityKey:aliceIdentityPublicKey ourSignedPrekey:bobEphemeral ourRatchetKey:bobEphemeral ourOneTimePrekey:nil theirBaseKey:aliceBasePublicKey];
//    
//    SessionState *session = [SessionState new];
//    
//    [RatchetingSession initializeSession:session sessionVersion:3 BobParameters:<#(BobAxolotlParameters *)#>]
//    
//    
//        IdentityKey     bobIdentityKeyPublic   = new IdentityKey(bobIdentityPublic, 0);
//        ECPrivateKey    bobIdentityKeyPrivate  = Curve.decodePrivatePoint(bobIdentityPrivate);
//        IdentityKeyPair bobIdentityKey         = new IdentityKeyPair(bobIdentityKeyPublic, bobIdentityKeyPrivate);
//        ECPublicKey     bobEphemeralPublicKey  = Curve.decodePoint(bobPublic, 0);
//        ECPrivateKey    bobEphemeralPrivateKey = Curve.decodePrivatePoint(bobPrivate);
//        ECKeyPair       bobEphemeralKey        = new ECKeyPair(bobEphemeralPublicKey, bobEphemeralPrivateKey);
//        ECKeyPair       bobBaseKey             = bobEphemeralKey;
//        
//        ECPublicKey     aliceBasePublicKey       = Curve.decodePoint(aliceBasePublic, 0);
//        ECPublicKey     aliceEphemeralPublicKey  = Curve.decodePoint(aliceEphemeralPublic, 0);
//        IdentityKey     aliceIdentityPublicKey   = new IdentityKey(aliceIdentityPublic, 0);
//        
//        BobAxolotlParameters parameters = BobAxolotlParameters.newBuilder()
//        .setOurIdentityKey(bobIdentityKey)
//        .setOurSignedPreKey(bobBaseKey)
//        .setOurRatchetKey(bobEphemeralKey)
//        .setOurOneTimePreKey(Optional.<ECKeyPair>absent())
//        .setTheirIdentityKey(aliceIdentityPublicKey)
//        .setTheirBaseKey(aliceBasePublicKey)
//        .create();
//        
//        SessionState session = new SessionState();
//        
//        RatchetingSession.initializeSession(session, 2, parameters);
//        
//        assertTrue(session.getLocalIdentityKey().equals(bobIdentityKey.getPublicKey()));
//        assertTrue(session.getRemoteIdentityKey().equals(aliceIdentityPublicKey));
//        assertTrue(Arrays.equals(session.getSenderChainKey().getKey(), senderChain));
//}

@end
