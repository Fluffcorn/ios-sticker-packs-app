//
//  MessagesViewController.m
//  MessagesExtension
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "MessagesViewController.h"
#import "StickerPackInfo.h"
#import "FluffcornStickerBrowserViewController.h"

#import "Constants.h"

@interface MessagesViewController ()

@property (nonatomic) NSDictionary *packInfo;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) FluffcornStickerBrowserViewController *browserViewController;

@end

@implementation MessagesViewController

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UIGestureRecognizer action methods

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSLog(@"swipe up");
    if (self.presentationStyle == MSMessagesAppPresentationStyleCompact)
        [self hideSegmentedControl];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSLog(@"swipe down");
    if (self.presentationStyle == MSMessagesAppPresentationStyleCompact)
        [self showSegmentedControl];
}

- (void)panGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint translation = [gesture translationInView:_browserViewController.stickerBrowserView];
        CGPoint velocity = [gesture velocityInView:_browserViewController.stickerBrowserView];
        NSLog(@"pan translation %@",NSStringFromCGPoint(translation));
        NSLog(@"pan velocity %@",NSStringFromCGPoint(velocity));
        
        if (self.presentationStyle == MSMessagesAppPresentationStyleCompact)
            if (translation.y > 0) //if pan down by 0pixels or more, it's a net "up" scroll
                [self showSegmentedControl];
    }
}

#pragma mark - Segmented category button action method

- (IBAction)segmentSwitch:(UISegmentedControl *)sender {
    NSInteger selectedSegment = sender.selectedSegmentIndex;
    
    [_browserViewController loadStickerPackAtIndex:selectedSegment];
    [_browserViewController.stickerBrowserView reloadData];
}

#pragma mark - UI display

- (void)hideSegmentedControl {
    [UIView animateWithDuration:0.2 animations:^() {
        _segmentedControl.alpha = 0.0f;
    }];
}

- (void)showSegmentedControl {
    [UIView animateWithDuration:0.7 animations:^() {
        _segmentedControl.alpha = 1.0f;
    }];
}

#pragma mark - Read/Save last selected category

- (NSString *)readLastSelectedCategory {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kLastSelectedCategory:@""}];
    NSString *lastSelectedCategory = [[NSUserDefaults standardUserDefaults] stringForKey:kLastSelectedCategory];
    return lastSelectedCategory;
}

- (void)saveSelectedCategory {
    if (_browserViewController.currentPack) {
        [[NSUserDefaults standardUserDefaults] setObject:_browserViewController.currentPack forKey:kLastSelectedCategory];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Read/Save new categories for version


#pragma mark - VC lifecycle

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    if (presentationStyle == MSMessagesAppPresentationStyleExpanded) {
        [UIView animateWithDuration:0.2 animations:^() {
            _segmentedControl.alpha = 1.0f;
        }];
    }
}

- (void)willBecomeActiveWithConversation:(MSConversation *)conversation {
    NSString *lastSelectedCategory = [self readLastSelectedCategory];
    if (lastSelectedCategory.length > 0) {
        [_browserViewController loadStickersInPack:lastSelectedCategory];
        [_segmentedControl setSelectedSegmentIndex:[((NSArray<NSString *> *)[_packInfo objectForKey:kPackOrderKey]) indexOfObject:lastSelectedCategory]];
    } else if (((NSArray<NSString *> *)[_packInfo objectForKey:kPackOrderKey]).count > 0) {
        [_browserViewController loadStickerPackAtIndex:0];
    } else {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"No stickers setup."
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
        
    }
    
    
    [_browserViewController.stickerBrowserView reloadData];
}


- (void)willResignActiveWithConversation:(MSConversation *)conversation {
    //Similar to viewWillDisappear
    //[self saveSelectedCategory];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveSelectedCategory];
}

- (void)viewDidLoad {
    //Load sticker pack info from bundle
    _packInfo = [StickerPackInfo loadPackInfo];
    
    //Alloc segmented control and load sticker packs into segment control
    _segmentedControl = [[UISegmentedControl alloc] init];
    [_segmentedControl setBackgroundColor:[UIColor whiteColor]];
    [_segmentedControl addTarget:self
                          action:@selector(segmentSwitch:)
                forControlEvents:UIControlEventValueChanged];
    if (_packInfo) {
        NSArray<NSString *> *packOrder = [_packInfo objectForKey:kPackOrderKey];
        for (NSString *pack in packOrder) {
            [_segmentedControl insertSegmentWithTitle:pack atIndex:_segmentedControl.numberOfSegments animated:YES];
        }
    }
    if (_segmentedControl.numberOfSegments > 0)
        _segmentedControl.selectedSegmentIndex = 0;

    
    //Alloc sticker browser view controller
    _browserViewController = [[FluffcornStickerBrowserViewController alloc] initWithStickerSize:MSStickerSizeRegular withPackInfo:_packInfo];
    
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    _browserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:_browserViewController.view];
    [self.view addSubview:_segmentedControl];
    [self addChildViewController:_browserViewController];
    [_browserViewController didMoveToParentViewController:self];
    
    id topGuide = [self topLayoutGuide];
    id bottomGuide = [self bottomLayoutGuide];
    NSMutableArray *messageViewConstraints = [[NSMutableArray alloc] init];
    //@{@"topGuide": topGuide, @"bottomGuide": bottomGuide, @"segment": _segmentedControl, @"browser": _browserViewController.view};
    UIView *browserView = _browserViewController.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(topGuide, bottomGuide, _segmentedControl, browserView);
    
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-[_segmentedControl(==20)]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[browserView]|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_segmentedControl]-|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[browserView]|" options:0 metrics:nil views:bindings]];
    [self.view addConstraints:messageViewConstraints];
    
    _browserViewController.stickerBrowserView.contentInset = UIEdgeInsetsMake(_segmentedControl.frame.size.height+25, 0, 0, 0);
    
    
    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    [swipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [_browserViewController.stickerBrowserView addGestureRecognizer:swipeUpRecognizer];
    swipeUpRecognizer.delegate = self;
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [_browserViewController.stickerBrowserView addGestureRecognizer:panRecognizer];
    panRecognizer.delegate = self;
    
    /*
     //Replaced by UIPanGestureRecognizer because we need to detect the second movement if user scrolls down and then up in one continuous movement.
     UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
     [swipeDownRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
     [_browserViewController.stickerBrowserView addGestureRecognizer:swipeDownRecognizer];
     swipeDownRecognizer.delegate = self;
     */
}

@end
