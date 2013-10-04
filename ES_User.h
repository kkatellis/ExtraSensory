//
//  ES_User.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/4/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Activity, ES_ActivityStatistic, ES_SettingsModel;

@interface ES_User : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) ES_Activity *sampleBatches;
@property (nonatomic, retain) ES_SettingsModel *settings;
@property (nonatomic, retain) NSSet *activityStatistics;
@end

@interface ES_User (CoreDataGeneratedAccessors)

- (void)addActivityStatisticsObject:(ES_ActivityStatistic *)value;
- (void)removeActivityStatisticsObject:(ES_ActivityStatistic *)value;
- (void)addActivityStatistics:(NSSet *)values;
- (void)removeActivityStatistics:(NSSet *)values;

@end
