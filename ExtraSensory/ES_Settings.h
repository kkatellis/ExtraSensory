//
//  ES_Settings.h
//  
//
//  Created by yonatan vaizman on 7/22/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_Settings : NSManagedObject

@property (nonatomic, retain) NSNumber * hideHome;
@property (nonatomic, retain) NSNumber * homeLat;
@property (nonatomic, retain) NSNumber * homeLon;
@property (nonatomic, retain) NSNumber * homeSensingParticipant;
@property (nonatomic, retain) NSNumber * maxZipFilesStored;
@property (nonatomic, retain) NSNumber * recentTimePeriod;
@property (nonatomic, retain) NSNumber * sampleDuration;
@property (nonatomic, retain) NSNumber * sampleRate;
@property (nonatomic, retain) NSNumber * storedSamplesBeforeSend;
@property (nonatomic, retain) NSNumber * timeBetweenSampling;
@property (nonatomic, retain) NSNumber * timeBetweenUserNags;
@property (nonatomic, retain) NSNumber * allowCellular;
@property (nonatomic, retain) ES_User *user;

@end
