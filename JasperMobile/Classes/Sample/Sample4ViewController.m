/*
 * Jaspersoft Mobile SDK
 * Copyright (C) 2001 - 2011 Jaspersoft Corporation. All rights reserved.
 * http://www.jasperforge.org/projects/mobile
 *
 * Unless you have purchased a commercial license agreement from Jaspersoft,
 * the following license terms apply:
 *
 * This program is part of Jaspersoft Mobile SDK.
 *
 * Jaspersoft Mobile SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Jaspersoft Mobile SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Jaspersoft Mobile SDK. If not, see <http://www.gnu.org/licenses/>.
 */

//
//  Sample4ViewController.m
//  Jaspersoft
//
//  Created by Giulio Toffoli on 9/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sample4ViewController.h"
#import <jasperserver-mobile-sdk-ios/JSUIResourcePicker.h>

@implementation Sample4ViewController
@synthesize parentController;
@synthesize client;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)pickFolderClicked:(id)sender
{
    // 1. Create a new resource picker
    JSUIResourcePicker *folderPicker = [[JSUIResourcePicker alloc] initWithResourceType:JSUIResourcePickerTypeFolderOnly];
    
    // 2. Set the client (the class which contains the server settings)
    [folderPicker setClient: client];
    
    // 3. Set the delegated
    [folderPicker setDelegate:self];
    
    UINavigationController *picker = [[UINavigationController alloc] initWithRootViewController:folderPicker];
    
    // Push the new view
    [[self.parentController navigationController] presentModalViewController:picker animated: TRUE];
    
    // Force an update.
    [folderPicker updateTableContent];
    
    [folderPicker release];
    [picker release];
    
}

-(void)resourcePicked:(JSResourceDescriptor *)rd
{
    
    if (rd != nil)
    {
        [parentFolderTextfield setText: [rd uri]];
    }
    
}


-(IBAction)createFolderClicked:(id)sender
{
    NSString *parentFolder = [[parentFolderTextfield text] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([parentFolder isEqualToString:@"/"])
    {
        parentFolder = @"";
    }
    
    
    NSString *folderName = [[folderTextfield text] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 1. Prepare the descriptor for the folder...
    
    JSResourceDescriptor *rd = [[JSResourceDescriptor alloc] init];
    [rd setName: folderName];
    [rd setUri: [NSString stringWithFormat: @"%@/%@", parentFolder, folderName]];
    [rd setWsType: JS_TYPE_FOLDER];
    [rd setLabel: folderName];
    
    [self.client resourceCreate: parentFolder resourceDescriptor:rd data: nil responseDelegate:self];
    [rd release];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
    
}

-(void)requestFinished:(JSOperationResult *)op
{
    NSString *msg = nil;
    
    if (op != nil)
    {
        
       msg = [NSString stringWithFormat:@"Return code: %d\n%@", [op returnCode], [op message]];
        
       if ([op returnCode] == 201)
       {
           msg = @"Folder created!";
       }
        
    }
    else
    {
        msg = @"Operation failed...";
    }
    UIAlertView *uiView =[[[UIAlertView alloc] initWithTitle:@"" message: msg  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] autorelease];
    [uiView show];
    
}



        
        



@end
