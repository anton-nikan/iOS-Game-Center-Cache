//
//  PlayerListViewController.m
//  GCCacheSample
//
//  Created by nikan on 3/19/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "PlayerListViewController.h"


@implementation PlayerListViewController

@synthesize delegate;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        localPlayers = [[NSMutableArray alloc] init];
        onlinePlayers = [[NSMutableArray alloc] init];
        
        NSArray *allProfiles = [GCCache cachedProfiles];
        for (NSDictionary *profile in allProfiles) {
            BOOL isLocal = [[profile valueForKey:@"IsLocal"] boolValue];
            if (isLocal) {
                [localPlayers addObject:profile];
            } else {
                [onlinePlayers addObject:profile];
            }
        }
        
        authenticating = NO;
    }
    return self;
}

- (void)dealloc
{
    [onlinePlayers release];
    [localPlayers release];
    
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && localPlayers.count) {
        return @"Local Profiles";
    } else if (section == 1 && onlinePlayers.count) {
        return @"Online Profiles";
    }
    
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return localPlayers.count;
    } else if (section == 1) {
        if (![GCCache authenticatedCache]) {
            return onlinePlayers.count + 1;
        } else {
            return onlinePlayers.count;
        }
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CancelButtonCellIdentifier = @"CancelButtonCell";
    static NSString *AuthButtonCellIdentifier = @"AuthButtonCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:CancelButtonCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CancelButtonCellIdentifier] autorelease];
            cell.textLabel.text = @"Cancel";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
    } else if (indexPath.section == 1 && indexPath.row == onlinePlayers.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:AuthButtonCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AuthButtonCellIdentifier] autorelease];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
        
        if (authenticating) {
            cell.textLabel.text = @"Authenticating...";
            cell.textLabel.enabled = NO;
        } else {
            cell.textLabel.text = @"Authenticate";
            cell.textLabel.enabled = YES;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // Configure the cell
        NSDictionary *profile = nil;
        if (indexPath.section == 0) {
            profile = [localPlayers objectAtIndex:indexPath.row];
        } else if (indexPath.section == 1) {
            profile = [onlinePlayers objectAtIndex:indexPath.row];
            if ([[GCCache authenticatedCache] isEqualToProfile:profile]) {
                cell.textLabel.enabled = YES;
            } else {
                cell.textLabel.enabled = NO;
            }
        }
        
        if (profile) {
            cell.textLabel.text = [profile valueForKey:@"Name"];
            if ([[GCCache activeCache] isEqualToProfile:profile]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -

- (void)doneAuthenticatingWithError:(NSError*)error
{
    authenticating = NO;
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == onlinePlayers.count) {     // auth button
            if (!authenticating) {
                return indexPath;
            }
        } else if ([[GCCache authenticatedCache] isEqualToProfile:[onlinePlayers objectAtIndex:indexPath.row]])
        {
            return indexPath;
        }

        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2) {
        [self.delegate playerListViewControllerDidCancel:self];
    } else if (indexPath.section == 0) {
        NSDictionary *profile = [localPlayers objectAtIndex:indexPath.row];
        [self.delegate playerListViewController:self didSelectProfile:profile];
    } else if (indexPath.section == 1 && indexPath.row < onlinePlayers.count) {
        NSDictionary *profile = [onlinePlayers objectAtIndex:indexPath.row];
        [self.delegate playerListViewController:self didSelectProfile:profile];
    } else if (indexPath.section == 1 && indexPath.row == onlinePlayers.count) {
        authenticating = YES;
        [self.tableView reloadData];
        [GCCache launchGameCenterWithCompletionTarget:self action:@selector(doneAuthenticatingWithError:)];
    }
}

@end
