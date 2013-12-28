#import "DHAppDelegate.h"
#import "DHWebView.h"

@interface DHAppDelegate () <DHWebViewProtocol>
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
    [self.window makeFirstResponder:self.textSearchField];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [webView setMainFrameURL:@"file:///Users/bogdan/Library/Application%20Support/Dash/DocSets/Android/Android.docset/Contents/Resources/Documents/docs/reference/android/widget/AbsListView.html"];
    [webView setMainFrameURL:@"http://kapeli.com/dash"];
    [webView setEditable:YES];
    self.webView.delegate = self;
}

#pragma mark - <DHWebViewProtocol>

- (NSTextField *)textField
{
    return self.textSearchField;
}


@end
