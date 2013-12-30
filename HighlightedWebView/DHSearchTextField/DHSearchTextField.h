//
//  DHTextField.h
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/27/13.
//
//

#import <Cocoa/Cocoa.h>

@class DHSearchTextField;

@protocol DHTextFieldDelegate <NSObject>
@required;

- (void)searchFieldDidpressEsc:(DHSearchTextField *)sf;
- (void)searchFieldDidpressEnter:(DHSearchTextField *)sf;

@end

@interface DHSearchTextField : NSSearchField

@property (weak) id <DHTextFieldDelegate> keyPressDelegate;

@end
