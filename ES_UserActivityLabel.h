//
//  ES_UserActivityLabel.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/6/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_Activity;

@interface ES_UserActivityLabel : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) ES_Activity *activity;

@end

@interface ES_UserActivityLabel (CoreDataGeneratedAccessors)

- (void)addActivityObject:(ES_Activity *)value;
- (void)removeActivityObject:(ES_Activity *)value;
- (void)addActivity:(NSSet *)values;
- (void)removeActivity:(NSSet *)values;

@end