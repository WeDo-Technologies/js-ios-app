/*
 * JasperMobile for iOS
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
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
//  JSUIResourceViewController.h
//  Jaspersoft Corporation
//

#import <jaspersoft-sdk/JaspersoftSDK.h>

/**
 @author Giulio Toffoli giulio@jaspersoft.com
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 1.0
 */
@interface JSUIResourceViewController : UITableViewController <JSRequestDelegate, UIAlertViewDelegate> {
    BOOL resourceLoaded;
    BOOL deleting;
	UIToolbar *toolbar;
}

@property (nonatomic, retain) JSResourceDescriptor *descriptor;
@property (nonatomic, retain) JSRESTResource *resourceClient;
@property (nonatomic, retain) UITableViewCell *nameCell;
@property (nonatomic, retain) UITableViewCell *labelCell;
@property (nonatomic, retain) UITableViewCell *descriptionCell;
@property (nonatomic, retain) UITableViewCell *typeCell;
@property (nonatomic, retain) UITableViewCell *previewCell;
@property (nonatomic, retain) UITableViewCell *toolsCell;

- (IBAction)deleteButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (void)resourceDeleted;
- (void)clear;

@end