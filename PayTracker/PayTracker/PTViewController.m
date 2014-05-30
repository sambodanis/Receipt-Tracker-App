//
//  PTViewController.m
//  PayTracker
//
//  Created by Sam Bodanis on 29/05/2014.
//  Copyright (c) 2014 Sam Bodanis. All rights reserved.
//

#import "PTViewController.h"

@interface PTViewController ()

@property (strong, nonatomic) IBOutlet UITableView *personTable;
@property (strong, nonatomic) IBOutlet UITextField *itemField;
@property (strong, nonatomic) IBOutlet UITextField *costField;
@property (strong, nonatomic) IBOutlet UIButton *choosePayerButton;

@property (strong, nonatomic) NSArray *userArray;

@property (strong, nonatomic) NSNumberFormatter *currencyFormatter;

@property (strong, nonatomic) NSDictionary *payer;

@property (strong, nonatomic) NSMutableSet *buyins;

@end

@implementation PTViewController

@synthesize userArray = _userArray;
@synthesize currencyFormatter = _currencyFormatter;
@synthesize payer = _payer;
@synthesize buyins = _buyins;

- (NSArray *)userArray {
    if (!_userArray) {
        _userArray = [[NSArray alloc] init];
    }
    return _userArray;
}

- (void)setUserArray:(NSArray *)userArray {
    _userArray = userArray;
}

- (NSNumberFormatter *)currencyFormatter {
    if (!_currencyFormatter) {
        _currencyFormatter = [NSNumberFormatter new];
        [_currencyFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        [_currencyFormatter setLenient:YES];
        [_currencyFormatter setGeneratesDecimalNumbers:YES];
    }
    return _currencyFormatter;
}

- (NSDictionary *)payer {
    if (!_payer) {
        _payer = [[NSDictionary alloc] init];
    }
    return _payer;
}

- (void)setPayer:(NSDictionary *)payer {
    _payer = payer;
}

- (NSMutableSet *)buyins {
    if (!_buyins) {
        _buyins = [[NSMutableSet alloc] init];
    }
    return _buyins;
}

- (void)setBuyins:(NSMutableSet *)buyins {
    _buyins = buyins;
}

- (void)userDidChoosePayer:(NSDictionary *)payer {
    [self setPayer:payer];
    NSLog(@"Payer chosen %@", self.payer);
    // reload payer thingy
    [self reloadPayerButtonText];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"payerChooseSegue"]) {
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setUserArray:self.userArray];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.userArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"personCell";
    
    UITableViewCell *cell = [self.personTable dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[[self.userArray objectAtIndex:(int)indexPath.row] objectForKey:@"name"] capitalizedString];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.buyins addObject:[self.userArray objectAtIndex:indexPath.row]];
}

- (IBAction)choosePayerButtonPressed {
    [self performSegueWithIdentifier:@"payerChooseSegue" sender:self];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.itemField) {
        return YES;
    }
    NSString *replaced = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSDecimalNumber *amount = (NSDecimalNumber*) [self.currencyFormatter numberFromString:replaced];
    if (amount == nil) {
        // Something screwed up the parsing. Probably an alpha character.
        return NO;
    }
    // If the field is empty (the initial case) the number should be shifted to
    // start in the right most decimal place.
    short powerOf10 = 0;
    if ([textField.text isEqualToString:@""]) {
        powerOf10 = -self.currencyFormatter.maximumFractionDigits;
    }
    // If the edit point is to the right of the decimal point we need to do
    // some shifting.
    else if (range.location + self.currencyFormatter.maximumFractionDigits >= textField.text.length) {
        // If there's a range of text selected, it'll delete part of the number
        // so shift it back to the right.
        if (range.length) {
            powerOf10 = -range.length;
        }
        // Otherwise they're adding this many characters so shift left.
        else {
            powerOf10 = [string length];
        }
    }
    amount = [amount decimalNumberByMultiplyingByPowerOf10:powerOf10];
    
    // Replace the value and then cancel this change.
    textField.text = [self.currencyFormatter stringFromNumber:amount];
    return NO;
}

- (IBAction)sendItemPayment {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableArray *buyinUsernames = [[NSMutableArray alloc] init];
    for (NSDictionary *d in [self.buyins allObjects]) {
        [buyinUsernames addObject:[d objectForKey:@"username"]];
    }
    
    NSDictionary *parameters = @{@"name": self.itemField.text,
                                 @"cost": [self.costField.text substringFromIndex:1],
                                 @"payer": [self.payer objectForKey:@"username"],
                                 @"buyins": buyinUsernames};
    
    [manager POST:@"http://ec2-54-194-186-121.eu-west-1.compute.amazonaws.com:9000/purchases/" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    self.itemField.text = @"";
    self.costField.text = @"";
    for (int i = 0; i < [self.personTable numberOfRowsInSection:0]; i++) {
        [self.personTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
    }
    [self.buyins removeAllObjects];
}

- (void)reloadPayerButtonText {
    if ([self.payer objectForKey:@"name"]) {
        NSString *title = [NSString stringWithFormat:@"%@ is paying", [[self.payer objectForKey:@"name"] capitalizedString]];
        [self.choosePayerButton setTitle:title forState: UIControlStateNormal];
    } else {
        [self.choosePayerButton setTitle:@"Choose someone to pay" forState: UIControlStateNormal];
    }
}

- (void)resignOnTap:(id)iSender {
    [[self view] endEditing:YES];
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    if (textField == self.itemField) {
        [self.costField becomeFirstResponder];
    }
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self reloadPayerButtonText];
    
    [self.costField setDelegate:self];
    [self.itemField setDelegate:self];
    
    [self.personTable setDelegate:self];
    [self.personTable setDataSource:self];
    [self.personTable setAllowsMultipleSelection:YES];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [singleTap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:singleTap];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://ec2-54-194-186-121.eu-west-1.compute.amazonaws.com:9000/users/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.userArray = [responseObject objectForKey:@"users"];
        [self.personTable reloadData];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
