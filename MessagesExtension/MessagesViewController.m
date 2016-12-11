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

@property (nonatomic) NSDictionary *packInfo;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) FluffcornStickerBrowserViewController *browserViewController;
@property (nonatomic) UIButton *infoButton;

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
        CGPoint velocity = [gesture velocityInView:_browserViewController.stickerBrowserView];
        NSLog(@"pan translation %@",NSStringFromCGPoint(translation));
        NSLog(@"pan velocity %@",NSStringFromCGPoint(velocity));
        
        if (self.presentationStyle == MSMessagesAppPresentationStyleCompact)
            if (translation.y > 0) //if pan down by 0pixels or more, it's a net "up" scroll
                [self showSegmentedControl];
    }
}

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
    
    [infoAlert addAction:sendFeedbackAction];
    [infoAlert addAction:dismissAction];
    [self presentViewController:infoAlert animated:YES completion:nil];

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
        [self showSegmentedControl];
        [self showInfoButton];
    } else {
        [self hideInfoButton];
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
    
    //Alloc and hide info button
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    _infoButton.alpha = 0.0f;
    [_infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //Remove auto resizing masks
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    _browserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _infoButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:_browserViewController.view];
    [self.view addSubview:_segmentedControl];
    [self.view addSubview:_infoButton];
    [self addChildViewController:_browserViewController];
    [_browserViewController didMoveToParentViewController:self];
    
    id topGuide = [self topLayoutGuide];
    id bottomGuide = [self bottomLayoutGuide];
    NSMutableArray *messageViewConstraints = [[NSMutableArray alloc] init];
    //@{@"topGuide": topGuide, @"bottomGuide": bottomGuide, @"segment": _segmentedControl, @"browser": _browserViewController.view};
    UIView *browserView = _browserViewController.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(topGuide, bottomGuide, _segmentedControl, browserView, _infoButton);
    
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-[_segmentedControl(==20)]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[browserView]|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_infoButton]-[bottomGuide]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_segmentedControl]-|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[browserView]|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_infoButton]-|" options:0 metrics:nil views:bindings]];
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
