/*
 * JasperMobile for iOS
 * Copyright (C) 2011 - 2013 Jaspersoft Corporation. All rights reserved.
 * http://community.jaspersoft.com/project/jaspermobile-ios
 *
 * Unless you have purchased a commercial license agreement from Jaspersoft,
 * the following license terms apply:
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/lgpl>.
 */

//
//  JMCancelRequestPopup.m
//  Jaspersoft Corporation
//

#import "JMCancelRequestPopup.h"
#import "JMLocalization.h"
#import "JMUtils.h"
#import "UIViewController+MJPopupViewController.h"
#import "JMRequestDelegate.h"
#import <QuartzCore/QuartzCore.h>

static JMCancelRequestPopup *instance;

@interface JMCancelRequestPopup ()
@property (nonatomic, strong) JSRESTBase *restClient;
@property (nonatomic, copy) JMCancelRequestBlock cancelBlock;
@property (nonatomic, weak) UIViewController *delegate;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;
@end

@implementation JMCancelRequestPopup

#pragma mark - Class Methods

+ (void)presentInViewController:(UIViewController *)viewController message:(NSString *)message restClient:(JSRESTBase *)client cancelBlock:(JMCancelRequestBlock)cancelBlock
{
    instance = [[JMCancelRequestPopup alloc] initWithNibName:@"JMCancelRequestPopup" bundle:nil];
    instance.restClient = client;
    instance.delegate = viewController;
    instance.cancelBlock = cancelBlock;
    [instance.cancelButton setTitle:JMCustomLocalizedString(@"dialog.button.cancel", nil) forState:UIControlStateNormal];
    instance.progressLabel.text = JMCustomLocalizedString(message, nil);
    
    [viewController presentPopupViewController:instance animationType:MJPopupViewAnimationFade];
}

+ (void)dismiss
{
    [JMUtils hideNetworkActivityIndicator];
    [instance.delegate dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    instance = nil;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.cornerRadius = 5.0f;
}

#pragma mark - Actions

- (IBAction)cancelRequests:(id)sender
{
    [self.restClient cancelAllRequests];
    [JMRequestDelegate clearRequestPool];
    [self.delegate dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    
    [JMCancelRequestPopup dismiss];
}

#pragma mark - NSObject

- (void)dealloc
{
    self.view = nil;
}

@end
