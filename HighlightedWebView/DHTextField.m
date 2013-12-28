//
//  DHTextField.m
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/27/13.
//
//

#import "DHTextField.h"

@implementation DHTextField

-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    [super keyUp:theEvent];
    if (theEvent.keyCode == 53) {
        [self setHidden:YES];
        [self resignFirstResponder];
    }
}
@end
