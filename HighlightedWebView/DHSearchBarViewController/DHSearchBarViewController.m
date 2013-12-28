//
//  DHSearchBarViewController.m
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/28/13.
//
//

#import "DHSearchBarViewController.h"

@interface DHSearchBarViewController () <NSTextFieldDelegate>

@property (weak) IBOutlet NSSearchField *searchField;

@property (weak) IBOutlet NSButton *findPrev;
@property (weak) IBOutlet NSButton *findNext;

@property (weak) IBOutlet NSButton *done;

@end

@implementation DHSearchBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"DHSearchBarViewController" bundle:nibBundleOrNil];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.searchField.delegate = self;
}

- (IBAction)findPrevAction:(NSButton *)sender
{
    
}

- (IBAction)findNextAction:(NSButton *)sender
{
    
}

- (IBAction)doneAction:(NSButton *)sender
{
    
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    
}
@end
