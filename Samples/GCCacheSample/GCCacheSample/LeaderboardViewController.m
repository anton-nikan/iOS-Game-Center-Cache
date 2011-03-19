//
//  LeaderboardViewController.m
//  GCCacheSample
//
//  Created by nikan on 3/19/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "LeaderboardViewController.h"


@implementation LeaderboardViewController

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
        return onlinePlayers.count;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CancelButtonCellIdentifier = @"CancelButtonCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:CancelButtonCellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CancelButtonCellIdentifier] autorelease];
            cell.textLabel.text = @"Done";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        }
        
        // Configure the cell
        NSDictionary *profile = nil;
        if (indexPath.section == 0) {
            profile = [localPlayers objectAtIndex:indexPath.row];
        } else if (indexPath.section == 1) {
            profile = [onlinePlayers objectAtIndex:indexPath.row];
        }
        
        if (profile) {
            cell.textLabel.text = [profile valueForKey:@"Name"];
            
            NSDictionary *scores = [profile valueForKey:@"Scores"];
            if (scores) {
                // TODO: make score tables for all leaderboards
                NSString *leaderboard = [[scores allKeys] objectAtIndex:0];
                NSNumber *score = [scores valueForKey:leaderboard];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", score];
            } else {
                cell.detailTextLabel.text = @"0";
            }
            
            if ([[GCCache activeCache] isEqualToProfile:profile]) {
                cell.textLabel.textColor = [UIColor blueColor];
            } else {
                cell.textLabel.textColor = [UIColor blackColor];
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

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        return indexPath;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end
