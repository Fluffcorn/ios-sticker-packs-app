//
//  CreateNoteTextFieldDelegate.m
//  Peer
//
//  Created by Anson Liu on 9/28/16.
//  Copyright © 2016 Anson Liu. All rights reserved.
//

#import "FeedbackTextFieldDelegate.h"

@implementation FeedbackTextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.text.length - range.length > 0 || string.length > 0) {
        _createAction.enabled = YES;
    } else {
        _createAction.enabled = NO;
    }
    return YES;
}

@end
