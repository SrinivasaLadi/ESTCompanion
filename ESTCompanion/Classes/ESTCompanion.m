//
//  ESTCompanion.m
//  ESTCompanion
//
//  Created by Jonathon Hibbard on 5/29/14.
//  Copyright (c) 2014 Jonathon Hibbard. All rights reserved.
//

#import "ESTCompanion.h"
#import "ESTBeacon.h"
#import "UIAlertView+ESTCompanion.h"

@interface ESTCompanion() <ESTBeaconDelegate>

@property (nonatomic, copy) NSArray *proximityStrings;
@property (nonatomic, copy) ESTCompletionBlock connectionBlock;

@end

@implementation ESTCompanion

+(instancetype)sharedInstance {
    static ESTCompanion *_sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedInstance = [ESTCompanion new];
    });

    return _sharedInstance;
}

-(instancetype)init {

    self = [super init];
    if( self ) {
        self.proximityStrings = @[ @"Unknown", @"Immediate", @"Near", @"Far" ];
    }

    return self;
}

-(void)setProximityStrings:(NSArray *)proximityStrings {
    _proximityStrings = [proximityStrings copy];
}

// Get the string representation of a given CLProximity
-(NSString *)stringFromProximity:(NSInteger)proximity {
    return self.proximityStrings[(NSUInteger)proximity];
}


/**
 * >>> WARNING <<<
 * Running resetFactorySettingsToBeacon will - well, reset your beacon's Settings ( ProximityUUID, Minor, Major, etc. ) to
 * the Factory Setting Defaults.  It should be treated like a rock - it has no eyes, heart or soul, so only use it if you mean to.
 *
 * >>> NOTE <<<
 * If another Controller is set as the ESTBeaconDelegate, then it would be wise to use resetFactorySettingsToBeacon:withCompletion: instead.
 * In the completion block, it will be necessary to reset the object that is desired to be ESTBeaconDelegate to the delegate.
 * The reason is because ESTCompanion will make itself the delegate to handle the connection crap - but once it is complete, it will
 * reset the delegate to nil.  The completion block is therefore the prime opportunity to reset the delegate to another object.
 *
 */

-(void)resetFactorySettingsToBeacon:(ESTBeacon *)beacon {
    [self resetFactorySettingsToBeacon:beacon withCompletion:nil];
}

-(void)resetFactorySettingsToBeacon:(ESTBeacon *)beacon withCompletion:(ESTCompletionBlock)block {

    beacon.delegate = self;

    if( block != nil ) {
        self.connectionBlock = block;
    }
    
    NSLog( @"Attempting to connnect to beacon.." );
    [beacon connect];
}

/**
 *  Currently, this will actually be what is returned by any attempt to actually "conntect" to an estimote.
 *  It apperas as though the new SDK requires an App ID and an App Token.  This will be updated once
 *  it is formally announced as to how these two values are obtained.
 */
-(void)beaconConnectionDidFail:(ESTBeacon *)beacon withError:(NSError *)error {
    beacon.delegate = nil;
    self.connectionBlock = nil;

    [self alertWithError:error];
}

-(void)beaconConnectionDidSucceeded:(ESTBeacon *)beacon {

    beacon.delegate = nil;

    NSLog( @"Connected to beacon.." );

    __weak typeof( self ) weakSelf = self;
    [beacon resetToFactorySettingsWithCompletion:^(NSError *error) {

        if( error ) {

            dispatch_async(dispatch_get_main_queue(), ^{
                [self alertWithError:error];
            });

        } else {
            NSLog( @"Complete!" );

            if( weakSelf.connectionBlock != nil ) {
                weakSelf.connectionBlock( error );
            }
        }

        weakSelf.connectionBlock = nil;
    }];
}

//- (void)postLocalNotification:(BWLocalNotificationMessage)localNotificationMessage {
//
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.userInfo = @{@"identifier": self.beaconRegion.identifier};
//    notification.soundName = @"Default";
//
//    if (localNotificationMessage == BWLocalNotificationMessageBeaconApproached) {
//        notification.alertBody = @"Welcome home. Do you need to open your door?";
//    } else if (localNotificationMessage == BWLocalNotificationMessageBeaconDistanced) {
//        notification.alertBody = @"Don't forget to close your door!";
//    }
//
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//
//}

-(void)alertWithError:(NSError *)error {
    [UIAlertView showAlertWithError:error
                           delegate:nil
                  cancelButtonTitle:@"OK"
                  otherButtonTitles:nil];
}

@end
