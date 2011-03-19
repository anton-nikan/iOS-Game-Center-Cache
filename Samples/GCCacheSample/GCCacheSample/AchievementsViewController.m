//
//  AchievementsViewController.m
//  GCCacheSample
//
//  Created by nikan on 3/19/11.
//  Copyright 2011 Anton Nikolaienko. All rights reserved.
//

#import "AchievementsViewController.h"


@implementation AchievementsViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        achievements = [[NSMutableArray alloc] init];
        
        NSArray *allAchievements = [GCCache registeredAchievements];
        NSDictionary *playerAchievements = [[GCCache activeCache] allAchievements];
        for (NSDictionary *achieve in allAchievements) {
            NSString *name = [achieve valueForKey:@"Name"];
            NSNumber *isHidden = [achieve valueForKey:@"IsHidden"];
            NSNumber *playerProgress = [playerAchievements valueForKey:name];
            if (playerProgress) {
                [achievements addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         name, @"Name",
                                         isHidden, @"IsHidden",
                                         playerProgress, @"Progress",
                                         nil]];
            } else if (![isHidden boolValue]) {
                [achievements addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         name, @"Name",
                                         isHidden, @"IsHidden",
                                         [NSNumber numberWithDouble:0.0], @"Progress",
                                         nil]];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [achievements release];
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
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && achievements.count) {
        return [NSString stringWithFormat:@"Achievements for %@:", [GCCache activeCache].profileName];
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return achievements.count;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *CancelButtonCellIdentifier = @"CancelButtonCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.section == 1) {
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
        NSDictionary *profile = [achievements objectAtIndex:indexPath.row];        
        cell.textLabel.text = [profile valueForKey:@"Name"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f%%",
                                     [[profile valueForKey:@"Progress"] doubleValue]];
        
        if ([[profile valueForKey:@"IsHidden"] boolValue]) {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
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
    if (indexPath.section == 1) {
        return indexPath;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end
