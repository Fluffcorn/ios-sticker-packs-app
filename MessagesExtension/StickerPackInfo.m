//
//  StickerPackInfo.m
//  Fluffcorn
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "StickerPackInfo.h"

@implementation StickerPackInfo

+ (NSDictionary *)loadPackInfo {
    NSString *packInfoPath = [[NSBundle mainBundle] pathForResource:@"stickerPacks" ofType:@"json"];
    
    NSError *error;
    NSData *packInfoData = [NSData dataWithContentsOfFile:packInfoPath];
    if (error)
        NSLog(@"error init data with url %@ %@", packInfoPath, error.localizedDescription);
    
    NSObject *object = [NSJSONSerialization JSONObjectWithData:packInfoData options:0 error:&error];
    
    if ([object isKindOfClass:[NSDictionary class]]){
        return (NSDictionary *)object;
    } else {
        return nil;
    }
}

@end
