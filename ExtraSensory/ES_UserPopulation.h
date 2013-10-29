//
//  ES_UserPopulation.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 10/25/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ES_User;

@interface ES_UserPopulation : NSManagedObject

@property (nonatomic, retain) NSSet *users;
@end

@interface ES_UserPopulation (CoreDataGeneratedAccessors)

- (void)addUsersObject:(ES_User *)value;
- (void)removeUsersObject:(ES_User *)value;
- (void)addUsers:(NSSet *)values;
- (void)removeUsers:(NSSet *)values;

@end
