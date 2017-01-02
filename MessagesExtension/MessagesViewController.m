//
//  MessagesViewController.m
//  MessagesExtension
//
//  Created by Anson Liu on 12/4/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "MessagesViewController.h"

#import "Constants.h"

#import "StickerPackInfo.h"
#import "FluffcornStickerBrowserViewController.h"
#import "FeedbackTextFieldDelegate.h"

@interface MessagesViewController ()

@property (nonatomic) NSArray<NSLayoutConstraint *> *permanentConstraints;
@property (nonatomic) BOOL constraintsReapplied;

@property (nonatomic) NSDictionary *packInfo;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) FluffcornStickerBrowserViewController *browserViewController;
@property (nonatomic) UIButton *infoButton;
@property (nonatomic) UISlider *sizeSlider;

@property (nonatomic) FeedbackTextFieldDelegate *feedbackTextFieldDelegate;
@property (nonatomic) UIAlertController *sendingAlertController;

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
        //CGPoint velocity = [gesture velocityInView:_browserViewController.stickerBrowserView];
        //NSLog(@"pan translation %@",NSStringFromCGPoint(translation));
        //NSLog(@"pan velocity %@",NSStringFromCGPoint(velocity));
        
        if (self.presentationStyle == MSMessagesAppPresentationStyleCompact)
            if (translation.y > 0) //if pan down by 0pixels or more, it's a net "up" scroll
                [self showSegmentedControl];
    }
}

#pragma mark - Logic/Model methods

/*
 //Unneeded because MSSticker is already typedef enum of NSInteger
- (MSStickerSize)stickerSizeForIntValue:(NSInteger)value {
    MSStickerSize stickerSize;
    switch ((int)value) {
        case 0:
            stickerSize = MSStickerSizeSmall;
            break;
        case 1:
            stickerSize = MSStickerSizeRegular;
            break;
        case 2:
            stickerSize = MSStickerSizeLarge;
            break;
            
        default:
            NSLog(@"Unknown slider value %ld", (long)value);
            stickerSize = MSStickerSizeRegular;
            break;
    }
    return stickerSize;
}
 */

#pragma mark - UI action methods

- (IBAction)segmentSwitch:(UISegmentedControl *)sender {
    NSInteger selectedSegment = sender.selectedSegmentIndex;
    
    [_browserViewController loadStickerPackAtIndex:selectedSegment];
    [_browserViewController.stickerBrowserView reloadData];
}

- (IBAction)infoButtonTapped:(id)sender {
    NSError *error;
    NSString *aboutText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    NSString *creditText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"openSourceCredit" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];

    
    UIAlertController *infoAlert = [UIAlertController
                                alertControllerWithTitle:[NSString stringWithFormat:@"Fluffcorn v%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                    message:error ? error.localizedDescription : [NSString stringWithFormat:@"%@\n\n%@", aboutText, creditText]
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *sendFeedbackAction = [UIAlertAction
                              actionWithTitle:@"Idea and Suggestion Box"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [self displayFeedbackAlert];
                                  
                              }];
    
    UIAlertAction *dismissAction = [UIAlertAction
                                         actionWithTitle:@"Dismiss"
                                         style:UIAlertActionStyleCancel
                                         handler:nil];
    
    //If developer has enabled feedback
    if (kFeedbackAction)
        [infoAlert addAction:sendFeedbackAction];
    
    [infoAlert addAction:dismissAction];
    [self presentViewController:infoAlert animated:YES completion:nil];

}

- (IBAction)sizeSliderValueChanged:(UISlider *)sender {
    //Remove existing browserViewController view from view
    MSStickerBrowserViewController *oldStickerBrowserViewController = _browserViewController;
    
    MSStickerSize stickerSize = (NSInteger)lroundf(sender.value);
    
    _browserViewController = [[FluffcornStickerBrowserViewController alloc] initWithStickerSize:stickerSize withPackInfo:_packInfo];
    
    _browserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:_browserViewController.view belowSubview:oldStickerBrowserViewController.view];
    [oldStickerBrowserViewController.view removeFromSuperview];
    
    [self applyPermanentConstraints];
    _constraintsReapplied = YES;
    
    [self setupStickerBrowserView];
    
    //Set browserViewController to currently selected segment
    [_browserViewController loadStickerPackAtIndex:_segmentedControl.selectedSegmentIndex];
    [_browserViewController.stickerBrowserView reloadData];
    
    //Save last selected sticker size to disk
    [self saveStickerSize];
}

- (IBAction)sliderSnapToIntValue:(UISlider *)sender {
    //http://stackoverflow.com/a/9695118
    [sender setValue:lroundf(sender.value) animated:YES];
}

#pragma mark - UI display

- (void)applyPermanentConstraints {
    [self.view removeConstraints:_permanentConstraints];
    
    id topGuide = [self topLayoutGuide];
    id bottomGuide = [self bottomLayoutGuide];
    NSMutableArray<NSLayoutConstraint *> *messageViewConstraints = [[NSMutableArray alloc] init];
    //@{@"topGuide": topGuide, @"bottomGuide": bottomGuide, @"segment": _segmentedControl, @"browser": _browserViewController.view};
    UIView *browserView = _browserViewController.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(topGuide, bottomGuide, _segmentedControl, browserView, _infoButton, _sizeSlider);
    
    //Vertical constraints
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-[_segmentedControl(==20)]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[browserView]|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_infoButton]-[bottomGuide]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_sizeSlider]-[bottomGuide]" options:0 metrics:nil views:bindings]];
    
    //Horizontal constraints
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_segmentedControl]-|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[browserView]|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_sizeSlider]-16-[_infoButton]-|" options:0 metrics:nil views:bindings]];
    
    //Create global constraints array
    _permanentConstraints = [NSArray arrayWithArray:messageViewConstraints];
    [self.view addConstraints:messageViewConstraints];

}

- (void)loadLastSelectedCategoryToBrowserAndSegment {
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
                                  style:UIAlertActionStyleCancel
                                  handler:^(UIAlertAction * action)
                                  {
                                      [alert dismissViewControllerAnimated:YES completion:nil];
                                      
                                  }];
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    [_browserViewController.stickerBrowserView reloadData];
}

- (void)setupStickerBrowserView {
    
    //Multiply top inset by two when reapplying constraints due to new browserStickerView added to view. Autolayout places new browserViewController view too far up on reapplication of constraints.
    _browserViewController.stickerBrowserView.contentInset = UIEdgeInsetsMake(_segmentedControl.frame.size.height * (_constraintsReapplied ? 2 : 1), 0, 0, 0);
}

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

- (void)hideInfoButton {
    [UIView animateWithDuration:0.2 animations:^() {
        _infoButton.alpha = 0.0f;
    }];
}

- (void)showInfoButton {
    [UIView animateWithDuration:0.7 animations:^() {
        _infoButton.alpha = 1.0f;
    }];
}

- (void)hideStickerSizeSlider {
    [UIView animateWithDuration:0.2 animations:^() {
        _sizeSlider.alpha = 0.0f;
    }];
}

- (void)showStickerSizeSlider {
    if ([self readStickerSizeSliderVisibility]) {
        [UIView animateWithDuration:0.7 animations:^() {
            _sizeSlider.alpha = 1.0f;
        }];
    }
}

- (void)displayFeedbackAlert {
    UIAlertController *feedbackAlert = [UIAlertController
                                    alertControllerWithTitle:@"Ideas and Suggestion Box"
                                    message:nil
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *sendAction = [UIAlertAction
                                         actionWithTitle:@"Send"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             [self sendFeedbackAction:feedbackAlert.textFields.firstObject.text];
                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     [feedbackAlert dismissViewControllerAnimated:YES completion:nil];
                                 }];
    
    [feedbackAlert addTextFieldWithConfigurationHandler:^(UITextField *textfield) {
        _feedbackTextFieldDelegate = [[FeedbackTextFieldDelegate alloc] init];
        _feedbackTextFieldDelegate.createAction = sendAction;
        textfield.delegate = _feedbackTextFieldDelegate;
        textfield.placeholder = @"Your suggestion here.";
        textfield.autocorrectionType = UITextAutocorrectionTypeDefault;
        textfield.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textfield.keyboardAppearance = UIKeyboardAppearanceAlert;
        sendAction.enabled = NO;
    }];
    
    [feedbackAlert addAction:sendAction];
    [feedbackAlert addAction:cancelAction];
    
    [self presentViewController:feedbackAlert animated:YES completion:nil];
}

- (void)sendFeedbackAction:(NSString *)feedback {
    //NSURLSession version of
    //http://stackoverflow.com/questions/12358002/submit-data-to-google-spreadsheet-form-from-objective-c
    
    //initialize url that is going to be fetched.
    NSURL *url = [NSURL URLWithString:@"https://docs.google.com/forms/d/e/1FAIpQLSe9ONAbDW-HbaYqtAAl3iBtDThtddFHM5sXCpRequrxi2esmg/formResponse"];
    
    //initialize a request from url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
    
    //set http method
    [request setHTTPMethod:@"POST"];
    //initialize a post data
    NSString *postData = [NSString stringWithFormat:@"entry.262066721=%@", feedback];
    //set request content type we MUST set this value.
    
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    //set post data of request
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    
    //initialize a connection from request
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    
    _sendingAlertController = [UIAlertController
                               alertControllerWithTitle:@"Sending"
                               message:nil
                               preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:_sendingAlertController animated:YES completion:nil];
    
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [_sendingAlertController dismissViewControllerAnimated:YES completion:^() {
            UIAlertController *sentAlert = [UIAlertController
                                            alertControllerWithTitle:error ? @"Unable to send. Please try later." : @"Sent successfully!"
                                            message:error ? error.localizedDescription : nil
                                            preferredStyle:UIAlertControllerStyleAlert];
            [sentAlert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:sentAlert animated:YES completion:nil];
        }];
    }];
    
    [uploadTask resume];
}

#pragma mark - Read/Save last selected category

- (NSString *)readLastSelectedCategory {
    NSString *lastSelectedCategory = [[NSUserDefaults standardUserDefaults] stringForKey:kLastSelectedCategoryKey];
    return lastSelectedCategory;
}

- (void)saveSelectedCategory {
    if (_browserViewController.currentPack) {
        [[NSUserDefaults standardUserDefaults] setObject:_browserViewController.currentPack forKey:kLastSelectedCategoryKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Read/Save sticker size

- (NSInteger)readSavedStickerSize {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kStickerSizeSliderPreferenceKey];
}

- (void)saveStickerSize {
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)lroundf(_sizeSlider.value) forKey:kStickerSizeSliderPreferenceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Read/Save sticker size

- (BOOL)readStickerSizeSliderVisibility {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kStickerSizeSliderVisibilityPreferenceKey];
}

#pragma mark - VC lifecycle

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    if (presentationStyle == MSMessagesAppPresentationStyleExpanded) {
        [self showSegmentedControl];
        [self showInfoButton];
        [self showStickerSizeSlider];
    } else {
        [self hideInfoButton];
        [self hideStickerSizeSlider];
    }
}

- (void)willBecomeActiveWithConversation:(MSConversation *)conversation {
    [self setupStickerBrowserView];
    [self loadLastSelectedCategoryToBrowserAndSegment];
}


- (void)willResignActiveWithConversation:(MSConversation *)conversation {
    //Called less frequently than viewWillDisappear, called after the user has switched a few apps away
    //[self saveSelectedCategory];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveSelectedCategory];
}

- (void)viewDidLoad {
    //Register settings defaults
    BOOL stickerSizeVisibility = kStickerSizeSliderVisibility;
    MSStickerSize defaultStickerSize = kDefaultStickerSize;
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kLastSelectedCategoryKey:@"",kStickerSizeSliderPreferenceKey:[NSNumber numberWithInteger:defaultStickerSize],kStickerSizeSliderVisibilityPreferenceKey:[NSNumber numberWithBool:stickerSizeVisibility]}];
    
    //Read saved sticker size for use in alloc sticker browser view controller and sticker size slider
    NSInteger savedStickerSize = [self readSavedStickerSize];
    
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
    _browserViewController = [[FluffcornStickerBrowserViewController alloc] initWithStickerSize:savedStickerSize withPackInfo:_packInfo];
    
    //Alloc and hide info button
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    _infoButton.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
    [_infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //Alloc slider and set min/max values and actions
    _sizeSlider = [[UISlider alloc] init];
    _sizeSlider.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
    _sizeSlider.minimumValue = 0;
    _sizeSlider.maximumValue = 2;
    _sizeSlider.value = savedStickerSize;
    _sizeSlider.minimumTrackTintColor = [UIColor lightGrayColor];
    [_sizeSlider addTarget:self action:@selector(sizeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_sizeSlider addTarget:self action:@selector(sliderSnapToIntValue:) forControlEvents:UIControlEventTouchUpInside];
    [_sizeSlider addTarget:self action:@selector(sliderSnapToIntValue:) forControlEvents:UIControlEventTouchUpOutside];
    
    //Remove auto resizing masks
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    _browserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _infoButton.translatesAutoresizingMaskIntoConstraints = NO;
    _sizeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:_browserViewController.view];
    [self.view addSubview:_segmentedControl];
    [self.view addSubview:_infoButton];
    [self.view addSubview:_sizeSlider];
    [self addChildViewController:_browserViewController];
    [_browserViewController didMoveToParentViewController:self];
    
    //Apply constraints for autolayout
    [self applyPermanentConstraints];
    
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

- (void)viewWillAppear:(BOOL)animated {
    //iOS currently returns the wrong presentationStyle when switching from another expanded app to fluffcorn
    _infoButton.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
    _sizeSlider.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;

}

@end
