//
//  FluffcornStickerBrowserViewController.h
//  Fluffcorn
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import <Messages/Messages.h>

@interface FluffcornStickerBrowserViewController : MSStickerBrowserViewController

@property (nonatomic) NSString *currentPack;

- (instancetype)initWithStickerSize:(MSStickerSize)stickerSize withPackInfo:(NSDictionary *)packInfo;

- (void)loadStickersInPack:(NSString *)packName;
- (void)loadStickerPackAtIndex:(NSInteger)index;

- (void)setNewStickerSize:(MSStickerSize)stickerSize;

@end
