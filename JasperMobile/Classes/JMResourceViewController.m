//
//  JMResourceViewController.m
//  JasperMobile
//
//  Created by Vlad Zavadskii on 6/7/13.
//  Copyright (c) 2013 com.jaspersoft. All rights reserved.
//

#import "JMResourceViewController.h"
#import "JMUtils.h"
#import "JMFilter.h"
#import "JMLocalization.h"
#import "JMCancelRequestPopup.h"
#import "JMBaseRepositoryTableViewController.h"
#import "UIAlertView+LocalizedAlert.h"
#import "UITableViewController+CellRelativeHeight.h"
#import <Objection-iOS/Objection.h>

#define kJMAttributesSection 0
#define kJMToolsSection 1
#define kJMResourcePropertiesSection 2

#define kJMDeleteButtonImage @"delete_button.png"
#define kJMDeleteButtonHighlightedImage @"delete_button_highlighted.png"
#define kJMAddFavoriteButtonImage @"add_favorite_button.png"
#define kJMAddFavoriteButtonHighlightedImage @"add_favorite_button_highlighted.png"
#define kJMRemoveFavoriteButtonImage @"remove_favorite_button.png"
#define kJMRemoveFavoriteButtonHighlightedImage @"remove_favorite_button_highlighted.png"

#define kJMConfirmButtonIndex 1

#define kJMTitleKey @"title"
#define kJMValueKey @"value"

#define kJMEditResourceDescriptorSegue @"EditResourceDescriptor"

typedef enum {
    JMGetResourceRequest,
    JMDeleteResourceRequest
} JMRequestType;

@interface JMResourceViewController ()
@property (nonatomic, strong, readonly) NSDictionary *numberOfRowsForSections;
@property (nonatomic, strong, readonly) NSDictionary *resourceDescriptorProperties;
@property (nonatomic, strong, readonly) NSDictionary *cellIdentifiers;
@property (nonatomic, assign) JMRequestType requestType;

- (void)fetchResourceDescriptor;
- (JSResourceProperty *)resourcePropertyForIndexPath:(NSIndexPath *)indexPath;
- (NSDictionary *)resourceDescriptorPropertyForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)localizedTextLabelTitleForProperty:(NSString *)property;
@end

@implementation JMResourceViewController
objection_requires(@"resourceClient");
inject_default_rotation();

#pragma mark - Accessors

@synthesize resourceClient = _resourceClient;
@synthesize resourceDescriptor = _resourceDescriptor;
@synthesize resourceDescriptorProperties = _resourceDescriptorProperties;
@synthesize numberOfRowsForSections = _numberOfRowsForSections;
@synthesize cellIdentifiers = _cellIdentifiers;
@synthesize needsToRefreshResourceDescriptorData = _needsToRefreshResourceDescriptorData;

- (NSDictionary *)resourceDescriptorProperties
{
    if (!_resourceDescriptorProperties) {
        _resourceDescriptorProperties = @{
            @0 : @{
              kJMTitleKey : @"name",
              kJMValueKey : self.resourceDescriptor.name ?: @""
            },
            @1 : @{
              kJMTitleKey : @"label",
              kJMValueKey : self.resourceDescriptor.label ?: @""
            },
            @2 : @{
              kJMTitleKey : @"resourceDescription",
              kJMValueKey : self.resourceDescriptor.resourceDescription ?: @""
            },
            @3 : @{
              kJMTitleKey : @"wsType",
              kJMValueKey : self.resourceDescriptor.wsType ?: @""
            }
        };
    }
    
    return _resourceDescriptorProperties;
}

- (NSDictionary *)numberOfRowsForSections
{
    if (!_numberOfRowsForSections) {
        _numberOfRowsForSections = @{
            @kJMAttributesSection : @4,
            @kJMToolsSection : @1,
            @kJMResourcePropertiesSection : [NSNumber numberWithInt:self.resourceDescriptor.resourceProperties.count]
        };
    }
    
    return _numberOfRowsForSections;
}

- (NSDictionary *)cellIdentifiers
{
    if (!_cellIdentifiers) {
        _cellIdentifiers = @{
            @kJMAttributesSection : @"ResourceAttributeCell",
            @kJMToolsSection : @"ToolsClearCell",
            @kJMResourcePropertiesSection : @"ResourcePropertyCell"
        };
    }
    
    return _cellIdentifiers;
}

- (void)setResourceDescriptor:(JSResourceDescriptor *)resourceDescriptor
{
    if (_resourceDescriptor != resourceDescriptor) {
        _resourceDescriptor = resourceDescriptor;
        // Update the number of rows for resource properties section by re-creating
        // numberOfRowsForSections variable
        _numberOfRowsForSections = nil;
        // Also update properties for resource descriptor
        _resourceDescriptorProperties = nil;
    }
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [JMUtils awakeFromNibForResourceViewController:self];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchResourceDescriptor];
    self.resourceDescriptor = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id  destinationViewController = segue.destinationViewController;
    
    if ([destinationViewController conformsToProtocol:@protocol(JMResourceClientHolder)]) {
        [destinationViewController setResourceDescriptor:self.resourceDescriptor];
    }
    
    if ([segue.identifier isEqualToString:kJMEditResourceDescriptorSegue]) {
        [destinationViewController setDelegate:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.needsToRefreshResourceDescriptorData) {
        [self fetchResourceDescriptor];
        self.needsToRefreshResourceDescriptorData = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.numberOfRowsForSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == kJMResourcePropertiesSection ? JMCustomLocalizedString(@"resource.properties.title", nil) : @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.numberOfRowsForSections objectForKey:[NSNumber numberWithInt:section]] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSString *cellIdentifier = [self cellIdentifierForSection:section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];;
    
    if (section == kJMAttributesSection) {
        NSDictionary *propertyForIndexPath = [self resourceDescriptorPropertyForIndexPath:indexPath];
        NSString *title = [propertyForIndexPath objectForKey:kJMTitleKey];
        NSString *value = [propertyForIndexPath objectForKey:kJMValueKey];
        
        cell.textLabel.text = [self localizedTextLabelTitleForProperty:title];
        cell.detailTextLabel.text = value;
    } else if (section == kJMToolsSection) {
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    } else if (section == kJMResourcePropertiesSection) {
        JSResourceProperty *resourceProperty = [self resourcePropertyForIndexPath:indexPath];
        
        cell.textLabel.text = resourceProperty.name;
        cell.detailTextLabel.text = resourceProperty.value;
    }
    
    return cell;
}

// Calculate height for table view cell according to amount of text inside cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSString *cellIdentifier = [self cellIdentifierForSection:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (section == kJMToolsSection) {
        return cell.frame.size.height;
    }
    
    NSString *text,
             *detailText;    
    UITableViewCellStyle cellStyle = UITableViewCellStyleValue2;
    
    if (section == kJMAttributesSection) {
        NSDictionary *propertyForIndexPath = [self resourceDescriptorPropertyForIndexPath:indexPath];
        text = [self localizedTextLabelTitleForProperty:[propertyForIndexPath objectForKey:kJMTitleKey]];
        detailText = [propertyForIndexPath objectForKey:kJMValueKey];
    } else if (section == kJMResourcePropertiesSection) {
        JSResourceProperty *property = [self resourcePropertyForIndexPath:indexPath];
        text = property.name;
        detailText = property.value;
        cellStyle = UITableViewCellStyleSubtitle;
    }
        
    return [self relativeHeightForTableViewCell:cell text:text detailText:detailText cellStyle:cellStyle];
}

#pragma mark - Actions

- (IBAction)deleteResource:(id)sender
{
    [[UIAlertView localizedAlert:@"delete.dialog.title"
                         message:@"delete.dialog.msg"
                        delegate:self
               cancelButtonTitle:@"dialog.button.cancel"
               otherButtonTitles:@"dialog.button.yes", nil] show];
}

- (IBAction)favoriteClicked:(id)sender
{
#warning Needs Implementation For Favorite Button
    NSLog(@"Favorite Action Works");
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kJMConfirmButtonIndex) {
        [JMFilter checkNetworkReachabilityForBlock:^{
            self.requestType = JMDeleteResourceRequest;
            [self.resourceClient deleteResource:self.resourceDescriptor.uriString delegate:[JMFilter checkRequestResultForDelegate:self]];
        } viewControllerToDismiss:nil];
    }
}

#pragma mark - JSRequestDelegate

- (void)requestFinished:(JSOperationResult *)result
{
    if (self.requestType == JMGetResourceRequest) {
        self.resourceDescriptor = [result.objects objectAtIndex:0];
        [self.tableView reloadData];
    } else if (self.requestType == JMDeleteResourceRequest) {
#warning Finish Favorites Implementation
//        if ([[JasperMobileAppDelegate sharedInstance].favorites isResourceInFavorites:self.descriptor]) {
//            [[JasperMobileAppDelegate sharedInstance].favorites removeFromFavorites:self.descriptor];
//        }
        [self.delegate removeResource:self.resourceDescriptor];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Private

- (void)fetchResourceDescriptor {
    [JMCancelRequestPopup presentInViewController:self restClient:self.resourceClient cancelBlock:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    [JMFilter checkNetworkReachabilityForBlock:^{
        self.requestType = JMGetResourceRequest;
        [self.resourceClient resource:self.resourceDescriptor.uriString delegate:[JMFilter checkRequestResultForDelegate:self]];
    } viewControllerToDismiss:self];
}

- (JSResourceProperty *)resourcePropertyForIndexPath:(NSIndexPath *)indexPath
{
    return [self.resourceDescriptor.resourceProperties objectAtIndex:[indexPath indexAtPosition:1]];
}

- (NSDictionary *)resourceDescriptorPropertyForIndexPath:(NSIndexPath *)indexPath
{
    return [self.resourceDescriptorProperties objectForKey:[NSNumber numberWithInt:[indexPath indexAtPosition:1]]];
}

- (NSString *)cellIdentifierForSection:(NSInteger)section
{
    return [self.cellIdentifiers objectForKey:[NSNumber numberWithInt:section]];
}

- (NSString *)localizedTextLabelTitleForProperty:(NSString *)property
{
    return JMCustomLocalizedString([NSString stringWithFormat:@"resource.%@.title", property], nil);
}

@end