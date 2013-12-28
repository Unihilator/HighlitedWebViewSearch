#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface DHScrollbarHighlighter : NSView {
    WebView *parentView;
    NSArray *matches;
    NSMutableArray *highlightRects;
}

@property (strong) WebView *parentView;
@property (strong) NSArray *matches;
@property (strong) NSMutableArray *highlightRects;

+ (DHScrollbarHighlighter *)highlighterWithWebView:(WebView *)aWebView andMatches:(NSArray *)matches;
- (id)initWithWebView:(WebView *)aWebView andMatches:(NSArray *)matches;
- (void)calculatePositions;
- (int)topPositionForElement:(DOMHTMLElement *)element;

@end
