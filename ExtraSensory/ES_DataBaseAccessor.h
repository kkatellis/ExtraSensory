//
//  ES_DataBaseAccessor.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/27/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ES_DataBaseAccessor : NSObject

+ (NSArray *) read: (NSString *)entityDescription;
+ (NSManagedObject *) write: (NSString *)data;
+ (void) save;

@end
