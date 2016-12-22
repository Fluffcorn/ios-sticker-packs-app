//
//  FluffcornStickerBrowserViewController.m
//  Fluffcorn
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "FluffcornStickerBrowserViewController.h"
#import "StickerPackInfo.h"

#import "Constants.h"

@interface FluffcornStickerBrowserViewController ()

@property (nonatomic) NSDictionary *packInfo;
@property (nonatomic) NSMutableArray<MSSticker *> *stickers;

@end

@implementation FluffcornStickerBrowserViewController

- (instancetype)initWithStickerSize:(MSStickerSize)stickerSize withPackInfo:(NSDictionary *)packInfo {
    self = [super initWithStickerSize:stickerSize];
    if (!self)
        return nil;
    _packInfo = packInfo;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadStickersInPack:(NSString *)packName {
    /*
     //Cannot access stickerpack in xcode assets
    NSString *packPath = [[NSBundle mainBundle] pathForResource:packName ofType:@"stickerpack"];
    
    NSError *error;
    NSArray<NSString *> *packStickers = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:packPath error:&error];
    if (error)
        NSLog(@"Error getting contentsOfDirectoryAtPath %@ %@", packPath, error.localizedDescription);
    
    for (NSString *stickerName in packStickers)
        [self createSticker:stickerName fromPack:packName localizedDescription:stickerName];
     */
    
    _stickers = [[NSMutableArray alloc] init];

    NSDictionary *allPacks = [_packInfo objectForKey:kAllPacksKey];
    NSDictionary *targetPack = [allPacks objectForKey:packName];
    
    if (!targetPack) {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Sticker pack unavailable."
                                    message:nil
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismiss = [UIAlertAction
                                  actionWithTitle:@"Dismiss"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action)
                                  {
                                      [alert dismissViewControllerAnimated:YES completion:nil];
                                      
                                  }];
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSArray<NSDictionary *> *stickerOrder = [targetPack objectForKey:@"order"];
    
    for (NSDictionary *sticker in stickerOrder)
        [self createSticker:[sticker valueForKey:kFilenameKey] fromPack:packName localizedDescription:[sticker valueForKey:kDescriptionKey]];
    
    _currentPack = packName;
}

- (void)loadStickerPackAtIndex:(NSInteger)index {
    NSArray<NSString *> *packOrder = [_packInfo objectForKey:kPackOrderKey];
    
    if (index < packOrder.count) {
        [self loadStickersInPack:[_packInfo objectForKey:kPackOrderKey][index]];
    } else {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Sticker pack unavailable."
                                    message:nil
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismiss = [UIAlertAction
                                  actionWithTitle:@"Dismiss"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action)
                                  {
                                      [alert dismissViewControllerAnimated:YES completion:nil];
                                      
                                  }];
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
}

- (void)createSticker:(NSString *)asset fromPack:(NSString *)packName localizedDescription:(NSString *)localizedDescription {
    /*
    NSString *stickerPath = [[NSBundle mainBundle] pathForResource:asset ofType:@"png" inDirectory:[NSString stringWithFormat:@"%@.stickerpack",packName]];
     */
    NSString *extension = @"png";
    
    NSString *stickerPath = [[NSBundle mainBundle] pathForResource:asset ofType:extension];
    //NSLog(@"%@", stickerPath);
    
    if (!stickerPath)
        NSLog(@"Couldn't create the sticker path for %@", asset);
    
    NSURL *stickerURL = [NSURL fileURLWithPath:stickerPath];
    
    MSSticker *sticker;
    NSError *error;
    sticker = [[MSSticker alloc] initWithContentsOfFileURL:stickerURL localizedDescription:localizedDescription error:&error];
    if (error)
        NSLog(@"Error init sticker %@", error.localizedDescription);
    else
        [_stickers addObject:sticker];
 
    //NSLog(@"processed %@", stickerURL);
}

- (NSInteger)numberOfStickersInStickerBrowserView:(MSStickerBrowserView *)stickerBrowserView {
    return _stickers.count;
}

- (MSSticker *)stickerBrowserView:(MSStickerBrowserView *)stickerBrowserView stickerAtIndex:(NSInteger)index {
    return [_stickers objectAtIndex:index];
}

- (void)setNewStickerSize:(MSStickerSize)stickerSize {

}

@end
