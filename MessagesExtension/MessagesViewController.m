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

#import "Firebase.h"
/*
 //Old Fabric integration
 #import <Fabric/Fabric.h>
 #import <Crashlytics/Crashlytics.h>
 #import <Answers/Answers.h>
 */

#import "MessagesExtension-Swift.h"

@interface MessagesViewController ()

@property (nonatomic) NSArray<NSLayoutConstraint *> *permanentConstraints;
@property (nonatomic) BOOL constraintsReapplied;

@property (nonatomic) NSDictionary *packInfo;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) FluffcornStickerBrowserViewController *browserViewController;
@property (nonatomic) UIButton *infoButton;
@property (nonatomic) UISlider *sizeSlider;

@property (nonatomic) UIButton *waStickerButton;

@property (nonatomic) FeedbackTextFieldDelegate *feedbackTextFieldDelegate;
@property (nonatomic) UIAlertController *sendingAlertController;

@end

@implementation MessagesViewController

//Keep track if Firebase SDK has been configured already due to how app extensions are initialized
//https://stackoverflow.com/a/40390083/761902
static BOOL firAppConfigured = NO;

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
  NSString *aboutText = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSString *creditText = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"openSourceCredit" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  
  
  UIAlertController *infoAlert = [UIAlertController
                                  alertControllerWithTitle:[NSString stringWithFormat:@"%@ v%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]
                                  message:error ? error.localizedDescription : [NSString stringWithFormat:@"%@\n\n%@", aboutText, creditText]
                                  preferredStyle:UIAlertControllerStyleAlert];
  
  @try {
    UIResponder *responder = self;
    SEL canOpenSel = @selector(canOpenURL:);
    SEL openSel = @selector(openURL:);
    NSURL *reviewStoreURL = [NSURL URLWithString:@"itms-apps://apps.apple.com/gb/app/id1171532447?action=write-review"];
    while (responder) {
      if ([responder respondsToSelector:canOpenSel] && [responder respondsToSelector:openSel]) {
        IMP imp = [responder methodForSelector:canOpenSel];
        BOOL (*func)(id, SEL, NSURL *) = (void *)imp;
        if(func(responder, canOpenSel, reviewStoreURL)) {
          UIAlertAction *reviewStoreAction = [UIAlertAction
                                              actionWithTitle:@"Rate Fluffcorn"
                                              style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction * action)
                                              {
            IMP imp = [responder methodForSelector:openSel];
            BOOL (*func)(id, SEL, NSURL *) = (void *)imp;
            BOOL openResult = func(responder, openSel, reviewStoreURL);
            
            if (!openResult) {
              UIAlertController *errorAlert = [UIAlertController
                                               alertControllerWithTitle:@"Unable to launch App Store."
                                               message:@"Please find Fluffcorn on the App Store! Thank you!"
                                               preferredStyle:UIAlertControllerStyleAlert];
              UIAlertAction *dismissAction = [UIAlertAction
                                              actionWithTitle:NSLocalizedString(@"alert.action.dismiss", nil)
                                              style:UIAlertActionStyleCancel
                                              handler:nil];
              [infoAlert addAction:dismissAction];
              [self presentViewController:errorAlert animated:YES completion:nil];
            }
          }];
          
          [infoAlert addAction:reviewStoreAction];
        }
        //[responder performSelector:openSel withObject:waStickerLaunchURL];
        break;
      } else {
        responder = [responder nextResponder];
      }
    }
    
  }
  @catch (NSException *exception) {
    NSLog(@"%@", exception.reason);
  }
  @finally {
  }
  
  UIAlertAction *sendFeedbackAction = [UIAlertAction
                                       actionWithTitle:@"Idea and Suggestion Box"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action)
                                       {
    [self displayFeedbackAlert];
    
    /*
     //Whatsapp In development
     NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"wa_fluffcorn2" withExtension:@"txt"];
     NSString*stringPath = [imgPath absoluteString]; //this is correct
     NSData *waf = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
     [UIPasteboard.generalPasteboard setData:waf forPasteboardType:@"net.whatsapp.third-party.sticker-pack"];
     //[UIPasteboard.generalPasteboard setURL:[NSURL URLWithString:@"whatsapp://stickerPack"]];
     */
    
    /*
     UIResponder *responder = self;
     SEL canOpenSel = @selector(canOpenURL:);
     SEL openSel = @selector(openURL:);
     NSURL *waStickerLaunchURL = [NSURL URLWithString:@"whatsapp://stickerPack"];
     //NSDictionary *openURLOptions = @{};
     //void (^completion)(BOOL success) = ^void(BOOL success) {};
     while (responder) {
     if ([responder respondsToSelector:openSel]) {
     
     //https://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
     if ([responder respondsToSelector:canOpenSel]) {
     IMP imp = [responder methodForSelector:canOpenSel];
     BOOL (*func)(id, SEL, NSURL *) = (void *)imp;
     BOOL canOpenResult = func(responder, canOpenSel, waStickerLaunchURL);
     }
     
     
     IMP imp = [responder methodForSelector:openSel];
     BOOL (*func)(id, SEL, NSURL *) = (void *)imp;
     BOOL openResult = func(responder, openSel, waStickerLaunchURL);
     
     //[responder performSelector:openSel withObject:waStickerLaunchURL];
     return;
     } else {
     responder = [responder nextResponder];
     }
     }
     */
  }];
  
  UIAlertAction *dismissAction = [UIAlertAction
                                  actionWithTitle:NSLocalizedString(@"alert.action.dismiss", nil)
                                  style:UIAlertActionStyleCancel
                                  handler:nil];
  
  
  
  //If developer has enabled feedback
  if (kFeedbackAction)
    [infoAlert addAction:sendFeedbackAction];
  
  [infoAlert addAction:dismissAction];
  [self presentViewController:infoAlert animated:YES completion:nil];
  
}

- (IBAction)waStickerButtonTapped:(id)sender {
  __block NSError *generateStickerPackError;
  
  //Get currently selected sticker pack non-localized name
  NSString *packName = [[_packInfo objectForKey:kPackOrderKey] objectAtIndex:_segmentedControl.selectedSegmentIndex];
  NSDictionary *allPacks = [_packInfo objectForKey:kAllPacksKey];
  NSDictionary *targetPack = [allPacks objectForKey:packName];
  NSArray<NSDictionary *> *stickerOrder = [targetPack objectForKey:kPackStickerOrderKey];
  
  NSString *packIdentifier = [NSString stringWithFormat:@"com.ansonliu.fluffcorn.%@", [packName stringByReplacingOccurrencesOfString:@" " withString:@""]];
  
  NSString *packTitle = [NSString stringWithFormat:@"Fluffcorn %@", NSLocalizedString(packName, @"Sticker Pack title")];
  
  //Get the WA tray icon image file for the selected sticker pack
  NSString *packTrayIcon = [targetPack objectForKey:kFilenameKey];
  packTrayIcon = [NSString stringWithFormat:@"%@%@.png", kWAStickerFilenamePrefix, packTrayIcon ? packTrayIcon : kWADefaultTrayLogo];
  
  StickerPack *waStickerPack = [[StickerPack alloc] initWithIdentifier:packIdentifier name:packTitle publisher:kWAStickerPackPublisher trayImageFileName:packTrayIcon publisherWebsite:kWAStickerPackPublisherWebsite privacyPolicyWebsite:kWAStickerPackPrivacyWebsite licenseAgreementWebsite:kWAStickerPackPrivacyWebsite error:&generateStickerPackError];
  
  for (NSDictionary *sticker in stickerOrder) {
    NSString *waStickerFilename = [NSString stringWithFormat:@"%@%@.png", kWAStickerFilenamePrefix, [sticker valueForKey:kFilenameKey]];
    
    NSArray<NSString *> *allWAStickerEmojis = [sticker valueForKey:kWAStickerEmojisKey];
    [waStickerPack addStickerWithContentsOfFile:waStickerFilename emojis:allWAStickerEmojis error:&generateStickerPackError];
    
    //Non-localized method
    //Use description key value in stickerPacks.json.
    //[self createSticker:[sticker valueForKey:kFilenameKey] fromPack:packName localizedDescription:[sticker valueForKey:kDescriptionKey]];
    
    if (generateStickerPackError) {
      NSLog(@"Error adding to WASticker %@ %@", waStickerFilename, generateStickerPackError);
      generateStickerPackError = nil;
    } else {
      NSLog(@"Added to WASticker %@", waStickerFilename);
    }
  }
  
  NSURL *waStickerLaunchURL = [NSURL URLWithString:@"whatsapp://stickerPack"];
  //Prefill user accessible general pasteboard with whatsapp launch URL
  //setter method for pasteboard URL replacees all current items in pasteboard
  [UIPasteboard.generalPasteboard setURL:waStickerLaunchURL];
  
  [waStickerPack sendToWhatsAppWithCompletionHandler:^(BOOL success, NSData *dataToSend) {
    BOOL openResult;
    NSString *exceptionReason;
    @try {
      //Open URL method of WAStickers code has been commented out.
      //If the WAStickers code was unable to create the sticker pack data successfully, continue to @finally block of code.
      if (!success) {
        generateStickerPackError = [NSError errorWithDomain:@"WAStickerError"
                                                       code:-1
                                                   userInfo:@{
                                                     NSLocalizedDescriptionKey: @"WASticker framework error."
                                                   }] ;
        return;
      }
      
      
      UIResponder *responder = self;
      SEL openSel = @selector(openURL:);
      //NSDictionary *openURLOptions = @{};
      //void (^completion)(BOOL success) = ^void(BOOL success) {};
      while (responder) {
        if ([responder respondsToSelector:openSel]) {
          //https://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
          IMP imp = [responder methodForSelector:openSel];
          BOOL (*func)(id, SEL, NSURL *) = (void *)imp;
          openResult = func(responder, openSel, waStickerLaunchURL);
          break;
        } else {
          responder = [responder nextResponder];
        }
      }
    }
    @catch (NSException *exception) {
      NSLog(@"%@", exception.reason);
      exceptionReason = exceptionReason;
    }
    @finally {
      if (openResult)
        return;
      [UIPasteboard.generalPasteboard setItems:@[
        @{@"net.whatsapp.third-party.sticker-pack": dataToSend, @"public.url": waStickerLaunchURL}]];
      
      NSString *waInstructions = [NSString stringWithFormat:@"We did not detect WhatsApp on your device.\nInstall WhatsApp and come back!\nIf you do have it, paste the exact URL\n\n%@\n\nin Safari to launch WhatsApp and finish sticker pack installation.\nWe've copied the URL to your device clipboard for you.", waStickerLaunchURL.absoluteString];
      NSString *generateStickerPackErrorInstructions = [NSString stringWithFormat:@"Unable to generate WhatsApp Sticker Pack\n%@\nPlease let us know at support@ansonliu.com", generateStickerPackError.localizedDescription];
      
      UIAlertController *waAlert = [UIAlertController
                                    alertControllerWithTitle:[NSString stringWithFormat:@"%@ WhatsApp Stickers", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]]
                                    message:generateStickerPackError ? generateStickerPackErrorInstructions : [NSString stringWithFormat:@"%@%@", waInstructions, exceptionReason ? [NSString stringWithFormat:@"\n\n%@", exceptionReason] : [NSString new]]
                                    preferredStyle:UIAlertControllerStyleAlert];
      
      UIAlertAction *dismissAction = [UIAlertAction
                                      actionWithTitle:generateStickerPackError ? @"Dismiss" : @"OK"
                                      style:UIAlertActionStyleDefault
                                      handler:nil];
      [waAlert addAction:dismissAction];
      [self presentViewController:waAlert animated:YES completion:nil];
    }
  }];
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
  NSDictionary *bindings = NSDictionaryOfVariableBindings(topGuide, bottomGuide, _segmentedControl, browserView, _infoButton, _waStickerButton, _sizeSlider);
  
  //Vertical constraints
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-[_segmentedControl(==20)]" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[browserView]|" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_infoButton]-[bottomGuide]" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_waStickerButton]-[_infoButton]" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_sizeSlider]-[bottomGuide]" options:0 metrics:nil views:bindings]];
  
  //Horizontal constraints
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_segmentedControl]-|" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[browserView]|" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_sizeSlider]-16-[_infoButton]-|" options:0 metrics:nil views:bindings]];
  [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_waStickerButton]-|" options:0 metrics:nil views:bindings]];
  
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
                              actionWithTitle:NSLocalizedString(@"alert.action.dismiss", nil)
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
    self->_segmentedControl.alpha = 0.0f;
  }];
}

- (void)showSegmentedControl {
  [UIView animateWithDuration:0.7 animations:^() {
    self->_segmentedControl.alpha = 1.0f;
  }];
}

- (void)hideInfoButton {
  [UIView animateWithDuration:0.2 animations:^() {
    self->_infoButton.alpha = 0.0f;
  }];
}

- (void)showInfoButton {
  [UIView animateWithDuration:0.7 animations:^() {
    self->_infoButton.alpha = 1.0f;
  }];
}

- (void)hideWAStickerButton {
  [UIView animateWithDuration:0.2 animations:^() {
    self->_waStickerButton.alpha = 0.0f;
  }];
}

- (void)showWAStickerButton {
  [UIView animateWithDuration:0.7 animations:^() {
    self->_waStickerButton.alpha = 1.0f;
  }];
}

- (void)hideStickerSizeSlider {
  [UIView animateWithDuration:0.2 animations:^() {
    self->_sizeSlider.alpha = 0.0f;
  }];
}

- (void)showStickerSizeSlider {
  if ([self readStickerSizeSliderVisibility]) {
    [UIView animateWithDuration:0.7 animations:^() {
      self->_sizeSlider.alpha = 1.0f;
    }];
  }
}

- (void)displayFeedbackAlert {
  UIAlertController *feedbackAlert = [UIAlertController
                                      alertControllerWithTitle:NSLocalizedString(@"feedback.alert.title", @"Ideas and Suggestion Box")
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *sendAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"alert.action.send", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
    [self sendFeedbackAction:feedbackAlert.textFields.firstObject.text];
  }];
  
  UIAlertAction *cancelAction = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"alert.action.cancel", nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
    [feedbackAlert dismissViewControllerAnimated:YES completion:nil];
  }];
  
  [feedbackAlert addTextFieldWithConfigurationHandler:^(UITextField *textfield) {
    self->_feedbackTextFieldDelegate = [[FeedbackTextFieldDelegate alloc] init];
    self->_feedbackTextFieldDelegate.createAction = sendAction;
    textfield.delegate = self->_feedbackTextFieldDelegate;
    textfield.placeholder = NSLocalizedString(@"feedback.textfield.placeholder", @"Your suggestion here.");
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
                             alertControllerWithTitle:NSLocalizedString(@"feedback.alert.sending", @"Sending")
                             message:nil
                             preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:_sendingAlertController animated:YES completion:nil];
  
  NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    [self->_sendingAlertController dismissViewControllerAnimated:YES completion:^() {
      UIAlertController *sentAlert = [UIAlertController
                                      alertControllerWithTitle:error ? NSLocalizedString(@"feedback.alert.send-result-fail", @"Unable to send. Please try later.") : NSLocalizedString(@"feedback.alert.send-result-success", @"Sent successfully!")
                                      message:error ? error.localizedDescription : nil
                                      preferredStyle:UIAlertControllerStyleAlert];
      [sentAlert addAction:[UIAlertAction
                            actionWithTitle:NSLocalizedString(@"alert.action.dismiss", nil)
                            style:UIAlertActionStyleCancel
                            handler:nil]
       ];
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
    [self showWAStickerButton];
    [self showStickerSizeSlider];
  } else {
    [self hideInfoButton];
    [self hideWAStickerButton];
    [self hideStickerSizeSlider];
  }
  
  if (kFirebaseEnabled && [FIRApp defaultApp]) {
    NSString *presentationStyleTitle;
    switch (presentationStyle) {
      case MSMessagesAppPresentationStyleCompact:
        presentationStyleTitle = @"Compact";
        break;
      case MSMessagesAppPresentationStyleExpanded:
        presentationStyleTitle = @"Expanded";
        break;
      default:
        presentationStyleTitle = @"Unknown";
        break;
    }
    if ([FIRApp defaultApp])
      [FIRAnalytics logEventWithName:@"ChangedPresentationStyle"
                          parameters:@{@"PresentationStyle" : presentationStyleTitle}];
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
  [super viewWillDisappear:animated];
  [self saveSelectedCategory];
}

- (id)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];
  if (!self) {
    return nil;
  }
  
  if (kFirebaseEnabled && !firAppConfigured) {
    //Firebase initialization
    [FIRApp configure];
    [[FIRConfiguration sharedInstance] setLoggerLevel:FIRLoggerLevelMin];
    firAppConfigured = YES;
    
    /*
     //From http://herzbube.ch/blog/2016/08/how-hide-fabric-api-key-and-build-secret-open-source-project and https://twittercommunity.com/t/should-apikey-be-kept-secret/52644/6
     //Get API key from fabric.apikey file in mainBundle
     NSURL* resourceURL = [[NSBundle mainBundle] URLForResource:@"fabric.apikey" withExtension:nil];
     NSStringEncoding usedEncoding;
     NSString* fabricAPIKey = [NSString stringWithContentsOfURL:resourceURL usedEncoding:&usedEncoding error:NULL];
     
     // The string that results from reading the bundle resource contains a trailing
     // newline character, which we must remove now because Fabric/Crashlytics
     // can't handle extraneous whitespace.
     NSCharacterSet* whitespaceToTrim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
     NSString* fabricAPIKeyTrimmed = [fabricAPIKey stringByTrimmingCharactersInSet:whitespaceToTrim];
     
     [Crashlytics startWithAPIKey:fabricAPIKeyTrimmed];
     */
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
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
      [_segmentedControl insertSegmentWithTitle:NSLocalizedString(pack, @"Sticker Pack title") atIndex:_segmentedControl.numberOfSegments animated:YES];
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
  
  //Alloc and hide WASticker install button
  _waStickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *waLogo = [UIImage imageNamed:@"WALogoIconColor"];
  //UIImage *waLogo = [[UIImage imageNamed:@"WALogoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [_waStickerButton setImage:waLogo forState:UIControlStateNormal];
  _waStickerButton.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
  [_waStickerButton addTarget:self action:@selector(waStickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  
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
  _waStickerButton.translatesAutoresizingMaskIntoConstraints = NO;
  _sizeSlider.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self.view addSubview:_browserViewController.view];
  [self.view addSubview:_segmentedControl];
  [self.view addSubview:_infoButton];
  [self.view addSubview:_waStickerButton];
  [self.view addSubview:_sizeSlider];
  [self addChildViewController:_browserViewController];
  [_browserViewController didMoveToParentViewController:self];
  
  //Apply constraints for autolayout
  [self applyPermanentConstraints];
  
  //Only show the segmented control if number of categories is > 1
  if (_segmentedControl.numberOfSegments > 1) {
    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    [swipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [_browserViewController.stickerBrowserView addGestureRecognizer:swipeUpRecognizer];
    swipeUpRecognizer.delegate = self;
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [_browserViewController.stickerBrowserView addGestureRecognizer:panRecognizer];
    panRecognizer.delegate = self;
  } else {
    _segmentedControl.hidden = YES;
  }
  
  //Set background color to named color asset with light/dark colors for iOS 13
  if (@available(iOS 13.0, *)) {
    self.view.backgroundColor = [UIColor colorNamed:@"backgroundColor"];
    self.segmentedControl.backgroundColor = [UIColor systemBackgroundColor];
  }
  
  /*
   //Replaced by UIPanGestureRecognizer because we need to detect the second movement if user scrolls down and then up in one continuous movement.
   UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
   [swipeDownRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
   [_browserViewController.stickerBrowserView addGestureRecognizer:swipeDownRecognizer];
   swipeDownRecognizer.delegate = self;
   */
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  //iOS currently returns the wrong presentationStyle when switching from another expanded app to fluffcorn
  _infoButton.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
  _waStickerButton.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
  _sizeSlider.alpha = self.presentationStyle == MSMessagesAppPresentationStyleCompact ? 0.0f : 1.0f;
}

@end
