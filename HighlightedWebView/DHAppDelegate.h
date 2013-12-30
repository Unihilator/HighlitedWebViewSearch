#import <Cocoa/Cocoa.h>
#import "DHWebView.h"

@interface DHAppDelegate : NSObject <NSApplicationDelegate> {
}
@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet DHWebView *webView;

@end
