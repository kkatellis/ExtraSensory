//
//  ES_SettingsModel.h
//  ExtraSensory
//
//  Created by Bryan Grounds on 9/30/13.
//  Copyright (c) 2013 Bryan Grounds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ES_SettingsModel : NSManagedObject

@property (nonatomic, retain) NSNumber * sampleFrequency;

@end
