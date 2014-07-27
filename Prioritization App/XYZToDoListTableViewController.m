//
//  XYZToDoListTableViewController.m
//  Prioritization App
//
//  Created by Carl Shan on 7/24/14.
//  Copyright (c) 2014 Carl Shan. All rights reserved.
//

#import "XYZToDoListTableViewController.h"
#import "XYZToDoItem.h"
#import "XYZAddToDoItemViewController.h"
#import <sqlite3.h>
#import "MCSwipeTableViewCell.h"

@interface XYZToDoListTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *ImportantUrgentToggle;
@property BOOL displayImportant;
@property BOOL displayUrgent;
@property BOOL displayArchived;
@property NSMutableArray *toDoItems;
@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *contactDB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewToDo;


@end

@implementation XYZToDoListTableViewController

- (IBAction)toggleArchived:(id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if ([button.title isEqualToString: @"Archived"]) {
        button.title = @"Back";
    }
    else {
        button.title = @"Archived";
    }
    [_addNewToDo setEnabled: !_addNewToDo.enabled];
    _displayArchived = !_displayArchived;
    [self updateFilteredToDoItems];
    [self.tableView reloadData];
}

- (IBAction)toggleImportantUrgentView:(id)sender {
    
    switch ([sender selectedSegmentIndex]) {
        case 0:
            _displayImportant = YES;
            _displayUrgent = YES;
            break;
        case 1:
            _displayImportant = YES;
            _displayUrgent = NO;
            break;
        case 2:
            _displayImportant = NO;
            _displayUrgent = YES;
            break;
        case 3:
            _displayImportant = NO;
            _displayUrgent = NO;
            break;
    }
    [self updateFilteredToDoItems];
    [self.tableView reloadData];
}

- (void)loadInitialData{
    NSLog(@"called loadInitialData");
    _displayImportant = YES;
    _displayUrgent = YES;
    
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"SELECT itemname, completed, important, urgent, archived, id FROM todoitems;"];
        
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(_contactDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                XYZToDoItem *item = [[XYZToDoItem alloc] init];
                item.itemName = [[NSString alloc]
                                 initWithUTF8String:
                                 (const char *) sqlite3_column_text(statement, 0)];
                
                item.completed = sqlite3_column_int(statement,1);
                item.important = sqlite3_column_int(statement,2);
                item.urgent = sqlite3_column_int(statement,3);
                item.archived = sqlite3_column_int(statement,4);
                item.database_id = sqlite3_column_int(statement,5);
                [self.toDoItems addObject:item];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
}

-(NSString*) saveFilePath{
    NSString* path = [NSString stringWithFormat:@"%@%@",
                      [[NSBundle mainBundle] resourcePath],
                      @"data.plist"];
    return path;
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddToDoItemViewController *source = [segue sourceViewController];
    XYZToDoItem *item = source.toDoItem;
    if (item != nil) {
        [self.toDoItems addObject:item];
        [self saveItem:item];
        [self updateFilteredToDoItems];
        [self.tableView reloadData];
    }

}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    _databasePath = [[NSString alloc]
                     initWithString: [docsDir stringByAppendingPathComponent:
                                      @"todoitems.db"]];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        const char *dbpath = [_databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS todoitems\
                (id INTEGER PRIMARY KEY AUTOINCREMENT, \
                 itemname TEXT, \
                 completed INTEGER, \
                 important INTEGER, \
                 urgent INTEGER, \
                 archived INTEGER)";
            
            if (sqlite3_exec(_contactDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
            {
                NSLog(@"Failed to create table");
            } else {
                NSLog(@"Successfully created table");
            }
            sqlite3_close(_contactDB);
        } else {
            NSLog(@"Failed to open/create database");
        }
    }
    
    self.toDoItems = [[NSMutableArray alloc] init];
    [self loadInitialData];
    [self updateFilteredToDoItems];
}

- (void) saveItem:(XYZToDoItem *) item
{
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO todoitems (itemname, completed, important, urgent, archived)\
                                 VALUES (\"%@\", \"%d\", \"%d\",\"%d\", \"%d\")",
                               item.itemName, item.completed, item.important, item.urgent, item.archived];
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            item.database_id = (int) sqlite3_last_insert_rowid(_contactDB);
            NSLog(@"Item added");
        } else {
            NSLog(@"Failed to add contact");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

- (void) updateItem:(XYZToDoItem *) item
{
    NSLog(@"Completed(update)?%d", item.completed);
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE todoitems SET itemname=\"%@\", completed=\"%d\", important=\"%d\", urgent=\"%d\", archived=\"%d\" WHERE id = \"%d\"",
                               item.itemName, item.completed, item.important, item.urgent, item.archived, item.database_id];
        
        const char *update_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, update_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Item updated");
        } else {
            NSLog(@"Failed to update item");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

-(void) updateFilteredToDoItems
{
    NSPredicate * iuPredicate = [NSPredicate predicateWithFormat:@"important == %@ AND urgent == %@ AND archived == %@", [NSNumber numberWithBool:_displayImportant], [NSNumber numberWithBool:_displayUrgent], [NSNumber numberWithBool:_displayArchived]];
    self.filteredToDoItems = [self.toDoItems filteredArrayUsingPredicate: iuPredicate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.filteredToDoItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ListPrototypeCell";
    
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
        // Setting the background color of the cell.
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }

    // Configuring the views and colors.
//    UIView *checkView = [self viewWithImageName: @"check"];
//    UIColor *greenColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
    
//    UIView *crossView = [self viewWithImageName:@"cross"];
//    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
//    
//    UIView *clockView = [self viewWithImageName:@"clock"];
//    UIColor *yellowColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
//    
//    UIView *listView = [self viewWithImageName:@"list"];
//    UIColor *brownColor = [UIColor colorWithRed:206.0 / 255.0 green:149.0 / 255.0 blue:98.0 / 255.0 alpha:1.0];
    
    // Setting the default inactive state color to the tableView background color.
    // [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    // [cell.textLabel setText:@"Switch Mode Cell"];
    // [cell.detailTextLabel setText:@"Swipe to switch"];
    
    // Adding gestures per state basis.
//    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        NSLog(@"Did swipe \"Checkmark\" cell");
//    }];
//    
//    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState2 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        NSLog(@"Did swipe \"Cross\" cell");
//    }];
//    
//    [cell setSwipeGestureWithView:clockView color:yellowColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        NSLog(@"Did swipe \"Clock\" cell");
//    }];
//    
//    [cell setSwipeGestureWithView:listView color:brownColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState4 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        NSLog(@"Did swipe \"List\" cell");
//    }];
    
    XYZToDoItem *toDoItem = [self.filteredToDoItems objectAtIndex:indexPath.row];
    
    cell.textLabel.text = toDoItem.itemName;
    if (toDoItem.completed) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    XYZToDoItem *tappedItem = [self.filteredToDoItems objectAtIndex:indexPath.row];
    tappedItem.completed = !tappedItem.completed;
    NSLog(@"Completed?%d",tappedItem.completed);
    [self updateItem:tappedItem];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Utils

- (UIView *)viewWithImageName:(NSString *)imageName {
    NSLog(@"Hello!");
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

@end
