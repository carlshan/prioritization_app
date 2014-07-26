//
//  XYZToDoListTableViewController.h
//  Prioritization App
//
//  Created by Carl Shan on 7/24/14.
//  Copyright (c) 2014 Carl Shan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZToDoListTableViewController : UITableViewController

@property NSArray *filteredToDoItems;
- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

@end
