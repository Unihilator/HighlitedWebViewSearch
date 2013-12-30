//
//  DHSearchBarViewController.h
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/28/13.
//
//

#import <Cocoa/Cocoa.h>
@class DHSearchTextField;

@protocol DHSearchBarViewDelegate <NSObject>
@required;

- (void)findPrevButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField;
- (void)findNextButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField;
- (void)doneButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField;
- (void)searchField:(NSSearchField *)searchField didChangeText:(NSNotification *)notif;

@end

@interface DHSearchBarViewController : NSViewController

@property (weak, readonly) DHSearchTextField *searchField;

@property (weak) id <DHSearchBarViewDelegate> delegate;

@end
