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

@interface MessagesViewController ()

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) FluffcornStickerBrowserViewController *browserViewController;

@end

@implementation MessagesViewController

- (void)viewDidLoad {
   
    _segmentedControl = [[UISegmentedControl alloc] init];
    [_segmentedControl addTarget:self
                         action:@selector(segmentSwitch:)
               forControlEvents:UIControlEventValueChanged];
    
    _browserViewController = [[FluffcornStickerBrowserViewController alloc] initWithStickerSize:MSStickerSizeRegular];

    NSDictionary *packInfo = [StickerPackInfo loadPackInfo];
    if (packInfo) {
        NSArray<NSString *> *packOrder = [packInfo objectForKey:@"packOrder"];
        for (NSString *pack in packOrder) {
            [_segmentedControl insertSegmentWithTitle:pack atIndex:_segmentedControl.numberOfSegments animated:YES];
        }
    }
    
    if (_segmentedControl.numberOfSegments > 0)
        _segmentedControl.selectedSegmentIndex = 0;
    
    [self.view addSubview:_segmentedControl];
    [self addChildViewController:_browserViewController];
    [_browserViewController didMoveToParentViewController:self];
    [self.view addSubview:_browserViewController.view];
    
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    _browserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    id topGuide = [self topLayoutGuide];
    id bottomGuide = [self bottomLayoutGuide];
    NSMutableArray *messageViewConstraints = [[NSMutableArray alloc] init];
    //@{@"topGuide": topGuide, @"bottomGuide": bottomGuide, @"segment": _segmentedControl, @"browser": _browserViewController.view};
    UIView *browserView = _browserViewController.view;
    NSDictionary *bindings = NSDictionaryOfVariableBindings(topGuide, bottomGuide, _segmentedControl, browserView);

    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide][_segmentedControl(==20)]-1-[browserView]-[bottomGuide]" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_segmentedControl]-|" options:0 metrics:nil views:bindings]];
    [messageViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[browserView]|" options:0 metrics:nil views:bindings]];
    [self.view addConstraints:messageViewConstraints];
    

    [_browserViewController loadStickers];
    [_browserViewController.stickerBrowserView reloadData];
}

- (IBAction)segmentSwitch:(UISegmentedControl *)sender {
    NSInteger selectedSegment = sender.selectedSegmentIndex;
    
    [_browserViewController loadStickerPackAtIndex:selectedSegment];
    [_browserViewController.stickerBrowserView reloadData];
}

@end
