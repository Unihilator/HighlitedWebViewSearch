#import <Cocoa/Cocoa.h>
#import "DHWebView.h"

@interface DHAppDelegate : NSObject <NSApplicationDelegate> {
}
@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *textSearchField;

@property (weak) IBOutlet DHWebView *webView;

- (IBAction)search:(id)sender;

@end
