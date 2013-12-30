//
//  DHTextField.m
//  HighlightedWebView
//
//  Created by Roman Derkach on 12/27/13.
//
//

#import "DHSearchTextField.h"

@implementation DHSearchTextField

-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    if (theEvent.keyCode == 53) {
        [self didPressEscKeyWithEvent:theEvent];
    }
    else
    {
        [super keyUp:theEvent];
    }
}

- (void)didPressEscKeyWithEvent:(NSEvent *)theEvent
{
    if ([self.keyPressDelegate respondsToSelector:@selector(searchFieldDidpressEsc:)]) {
        [self.keyPressDelegate searchFieldDidpressEsc:self];
    }
}

@end
