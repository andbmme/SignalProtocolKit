//
//  SessionState.h
//  AxolotlKit
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECKeyPair;
#import "RKCK.h"
#import "MessageKeys.h"
#import "Chain.h"
#import "RootKey.h"

@interface UnacknowledgedPreKeyMessageItems : NSObject

@property int preKeyId;
@property int signedPreKeyId;
@property (nonatomic, copy)NSData* baseKey;

@end

@interface SessionState : NSObject<NSCoding>

/**
 *  AxolotlSessions are either retreived from the database or initiated on new discussions. They are serialized before being stored to make storing abstractions significantly simpler. Because we propose no abstraction for a contact and TextSecure has multi-device (multiple sessions with same identity key) support, the identityKeys need to be added manually.
 */

@property(nonatomic, copy)NSData *aliceBaseKey;
@property(nonatomic)BOOL needsRefresh;
@property(nonatomic)int  version;
@property(nonatomic)NSData *remoteIdentityKey;
@property(nonatomic)NSData *localIdentityKey;
@property(nonatomic)int previousCounter;
@property(nonatomic)RootKey *rootKey;

- (NSData*)senderRatchetKey;
- (ECKeyPair*)senderRatchetKeyPair;

- (BOOL)hasReceiverChain:(NSData*)senderRatchet;
- (BOOL)hasSenderChain;

- (ChainKey*)receiverChainKey:(NSData*)senderRatchetKey;

- (void)setReceiverChainKey:(NSData*)senderEphemeral chainKey:(ChainKey*)chainKey;

- (void)addReceiverChain:(NSData*)senderRatchetKey chainKey:(ChainKey*)chainKey;

- (void)setSenderChain:(ECKeyPair*)senderRatcherKeyPair chainKey:(ChainKey*)chainKey;

- (ChainKey*)senderChainKey;

- (void)setSenderChainKey:(ChainKey*)nextChainKey;

- (BOOL)hasMessageKeys:(NSData*)senderRatchetKey counter:(int)counter;

- (MessageKeys*)removeMessageKeys:(NSData*)senderRatcherKey counter:(int)counter;

- (void)setMessageKeys:(NSData*)senderRatchetKey messageKeys:(MessageKeys*)messageKeys;

- (void)setPendingKeyExchange:(int)sequence ourBaseKey:(ECKeyPair*)ourBaseKey ourRatchetKey:(ECKeyPair*)ourRatchetKey identityKeyPair:(NSData*)ourIdentityKeyPair;

- (int)pendingKeyExchangeSequence;

- (ECKeyPair*)pendingKeyExchangeBaseKey;
- (ECKeyPair*)pendingKeyExchangeRatchetKey;
- (ECKeyPair*)pendingKeyExchangeIdentityKey;

- (BOOL) hasPendingKeyExchange;

- (void)setUnacknowledgedPreKeyMessage:(int)preKeyId signedPreKey:(int)signedPreKeyId baseKey:(NSData*)baseKey;
- (BOOL)hasUnacknowledgedPreKeyMessage;
- (UnacknowledgedPreKeyMessageItems*)unacknowledgedPreKeyMessageItems;
- (void)clearUnacknowledgedPreKeyMessage;

@property(nonatomic)long remoteRegistrationId;
@property(nonatomic)long localRegistrationId;

@end
