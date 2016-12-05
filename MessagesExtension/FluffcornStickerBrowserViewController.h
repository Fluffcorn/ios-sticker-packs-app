//
//  FluffcornStickerBrowserViewController.h
//  Fluffcorn
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import <Messages/Messages.h>

@interface FluffcornStickerBrowserViewController : MSStickerBrowserViewController

- (instancetype)initWithStickerSize:(MSStickerSize)stickerSize withView:(UIView *)view;

- (void)loadStickers;

- (void)loadStickerPackAtIndex:(NSInteger)index;

@end
