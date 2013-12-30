//
//  DHSearchBarViewController.m
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/28/13.
//
//

#import "DHSearchBarViewController.h"
#import "DHSearchTextField.h"

@interface DHSearchBarViewController () <NSTextFieldDelegate, DHTextFieldDelegate>

@property (weak) IBOutlet DHSearchTextField *searchField;

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
    self.searchField.keyPressDelegate = self;
}

- (IBAction)findPrevAction:(NSButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(findPrevButtonPressed:withTextfield:)]) {
        [self.delegate findPrevButtonPressed:sender withTextfield:self.searchField];
    }
}

- (IBAction)findNextAction:(NSButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(findNextButtonPressed:withTextfield:)]) {
        [self.delegate findNextButtonPressed:sender withTextfield:self.searchField];
    }
}

- (IBAction)doneAction:(NSButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(doneButtonPressed:withTextfield:)]) {
        [self.delegate doneButtonPressed:sender withTextfield:self.searchField];
    }
}



- (void)controlTextDidChange:(NSNotification *)obj
{
    if ([self.delegate respondsToSelector:@selector(searchField:didChangeText:)]) {
        [self.delegate searchField:self.searchField didChangeText:obj];
    }
}

#pragma mark - DHTextFieldDelegate
- (void)searchFieldDidpressEsc:(DHSearchTextField *)sf
{
    if ([self.delegate respondsToSelector:@selector(doneButtonPressed:withTextfield:)]) {
        [self.delegate doneButtonPressed:self.done withTextfield:self.searchField];
    }
}

- (void)searchFieldDidpressEnter:(DHSearchTextField *)sf
{
    if ([self.delegate respondsToSelector:@selector(searchFieldDidPressEnterKey:)]) {
        [self.delegate searchFieldDidPressEnterKey:sf];
    }
}
@end
