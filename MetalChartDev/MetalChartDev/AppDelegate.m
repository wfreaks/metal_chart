//
//  AppDelegate.m
//  MetalChartDev
//
//  Created by Keisuke Mori on 2016/08/05.
//  Copyright © 2016年 freaks. All rights reserved.
//

#import "AppDelegate.h"

#import <HealthKit/HealthKit.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	HKHealthStore *store = [[HKHealthStore alloc] init];
	HKQuantityType *step = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
	HKQuantityType *weight = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKQuantityType *systolic = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
	HKQuantityType *diastolic = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
	[store requestAuthorizationToShareTypes:nil
								  readTypes:[NSSet setWithArray:@[step, weight, systolic, diastolic]]
								 completion:^(BOOL success, NSError * _Nullable error) {
									 
								 }];
}

@end
