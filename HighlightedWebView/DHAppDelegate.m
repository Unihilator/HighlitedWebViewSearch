#import "DHAppDelegate.h"
#import "DHWebView.h"

@interface DHAppDelegate ()
@property (weak) IBOutlet NSView *rootView;

@end

@implementation DHAppDelegate

@synthesize webView;

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextView *field = [[obj userInfo] objectForKey:@"NSFieldEditor"];
    [webView highlightQuery:[field string] caseSensitive:NO];
}

- (IBAction)search:(id)sender
{
    NSString *query = [sender stringValue];
    [webView searchFor:query direction:YES caseSensitive:NO wrap:YES];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [webView setMainFrameURL:@"http://kapeli.com/dash"];
    [webView setEditable:YES];
}

@end
