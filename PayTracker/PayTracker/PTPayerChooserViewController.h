//
//  PTPayerChooserViewController.h
//  PayTracker
//
//  Created by Sam Bodanis on 30/05/2014.
//  Copyright (c) 2014 Sam Bodanis. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PTPayerChooserViewController <NSObject>

- (void)userDidChoosePayer:(NSDictionary *)payer;

@end

@interface PTPayerChooserViewController : UITableViewController

@property (nonatomic, strong) NSArray *userArray;

@property (nonatomic, assign) id <PTPayerChooserViewController> delegate;

@end
