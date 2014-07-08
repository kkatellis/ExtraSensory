//
//  ES_UserActivityLabels.h
//  ExtraSensory
//
//  Created by Kat Ellis on 3/17/14.
//  Copyright (c) 2014 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Activity;

@interface ES_UserActivityLabels : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *activity;

+ (NSMutableArray *) createStringArrayFromUserActivityLabelsAraay:(NSArray *)userActivityLabelsArray;
@end

@interface ES_UserActivityLabels (CoreDataGeneratedAccessors)

- (void)addActivityObject:(ES_Activity *)value;
- (void)removeActivityObject:(ES_Activity *)value;
- (void)addActivity:(NSSet *)values;
- (void)removeActivity:(NSSet *)values;

@end
