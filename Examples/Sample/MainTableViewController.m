//
//  MainTableViewController.m
//  Sample
//
//  Created by null_ptr on 03/05/14.
//  Copyright (c) 2014 Epic Peaks GmbH. All rights reserved.
//

#import "MainTableViewController.h"
#import "DZNSegmentedControl.h"

@interface MainTableViewController () <DZNSegmentedControlDelegate> {
    NSArray* titles;
}

- (IBAction)addSegmentClicked:(UIBarButtonItem *)sender;
- (IBAction)deleteSegmentClicked:(UIBarButtonItem *)sender;
- (IBAction)selectedSegmentChanged:(DZNSegmentedControl *)sender;

@property (strong, nonatomic) IBOutlet DZNSegmentedControl *segmentedControl;

@end

@implementation MainTableViewController

static NSString * const dummyCellIdentifier = @"dummy_cell";

- (void)viewDidLoad {
    [super viewDidLoad];

    titles = @[@"tweets", @"following", @"followers"];

    self.segmentedControl.items = [titles copy];

    titles = [titles arrayByAddingObject:@"favorites"];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:dummyCellIdentifier];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 32;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:dummyCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = nil;
    cell.textLabel.textColor = [UIColor lightGrayColor];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ #%@", [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex], @(indexPath.row)];

    return cell;
}

- (void)selectedSegment:(DZNSegmentedControl *)control {

}

- (IBAction)addSegmentClicked:(UIBarButtonItem *)sender {
    [self.segmentedControl insertSegmentWithTitle:@"new" atIndex:self.segmentedControl.selectedSegmentIndex];
    [self.segmentedControl setCount:@(arc4random() % 400) forSegmentAtIndex:self.segmentedControl.selectedSegmentIndex == 0 ? 0 : self.segmentedControl.selectedSegmentIndex - 1];
}

- (IBAction)deleteSegmentClicked:(UIBarButtonItem *)sender {
    [self.segmentedControl removeSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
}

- (IBAction)selectedSegmentChanged:(DZNSegmentedControl *)sender {
    [self.tableView reloadData];
}

@end
