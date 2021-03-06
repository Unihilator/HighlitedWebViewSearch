#import "DHWebView.h"
#import "DHMatchedText.h"
#import "DHSearchBarViewController.h"
#import "DHSearchTextField.h"

@interface DHWebView () <DHSearchBarViewDelegate>
@property (nonatomic, weak) NSBox *shadowBox;
@property (nonatomic, strong) DHSearchBarViewController *sbVC;
@end

@implementation DHWebView

@synthesize currentQuery;
@synthesize workerTimer;
@synthesize highlightedMatches;
@synthesize matchedTexts;
@synthesize entirePageContent;
@synthesize scrollHighlighter;

- (void)dealloc
{
    [self invalidateTimers];
}

- (void)awakeFromNib
{
    float textSizeMultiplier = [[NSUserDefaults standardUserDefaults] floatForKey:@"DHHighlightedWebViewTextSizeMultiplier"];
    if(textSizeMultiplier > 0)
    {
        [self setTextSizeMultiplier:textSizeMultiplier];
    }
    [self initializeShadowView];
    [self initializeSearchBar];
}

- (void)initializeShadowView
{
    NSBox *shadowBox = [[NSBox alloc] initWithFrame:self.frame];
    shadowBox.titlePosition = NSNoTitle;
    shadowBox.boxType = NSBoxCustom;
    shadowBox.borderType = NSNoBorder;
    shadowBox.fillColor = [NSColor colorWithCalibratedWhite:0.000 alpha:0.410];
    shadowBox.alphaValue = .0f;
    shadowBox.autoresizingMask = (NSViewMinXMargin |
                                NSViewWidthSizable |
                                  NSViewMaxXMargin |
                                  NSViewMinYMargin |
                                  NSViewHeightSizable);
    [self.superview addSubview:shadowBox];
    self.shadowBox = shadowBox;
}

- (void)initializeSearchBar
{
    self.sbVC = [[DHSearchBarViewController alloc] init];
    self.sbVC.delegate = self;
    NSBox *box = (NSBox *)self.sbVC.view;
    NSRect rect = NSMakeRect(0, self.frame.size.height, self.frame.size.width, box.frame.size.height);
    [box setFrame:rect];
    [self addSubview:box];
    
    box.autoresizingMask = (NSViewMinXMargin |
                                  NSViewWidthSizable |
                                  NSViewMaxXMargin |
                                  NSViewMinYMargin
                                  );
}

- (BOOL)searchFor:(NSString *)string direction:(BOOL)forward caseSensitive:(BOOL)caseFlag wrap:(BOOL)wrapFlag
{
    if(!string.length)
    {
        self.currentQuery = nil;
        [self startClearingHighlights];
        return NO;
    }
    DHSearchQuery *query = [DHSearchQuery searchQueryWithQuery:string caseSensitive:caseFlag];
    BOOL result = [super searchFor:string direction:forward caseSensitive:caseFlag wrap:wrapFlag];
    if(result)
    {
        [self highlightSelection];
        [self highlightQuery:query];
    }
    else
    {
        self.currentQuery = nil;
        [self startClearingHighlights];
    }
    return result;
}

- (void)performFindPanelAction:(id)sender
{
    [super performFindPanelAction:sender];
}

- (void)highlightQuery:(NSString *)aQuery caseSensitive:(BOOL)isCaseSensitive
{
    DHSearchQuery *query = [DHSearchQuery searchQueryWithQuery:aQuery caseSensitive:isCaseSensitive];
    [self highlightQuery:query];
}

- (void)highlightQuery:(DHSearchQuery *)query
{
    if([currentQuery isEqualTo:query])
    {
        return;
    }
    self.currentQuery = query;
    [self startClearingHighlights];
}

// Derkach Roman
- (void)highlightSelection
{
    
    NSNumber *left = @([[self stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).getBoundingClientRect().left.toString()"] floatValue]);
    NSNumber *bottom = @([[self stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).getBoundingClientRect().bottom.toString()"] floatValue]);
    NSNumber *width = @([[self stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).getBoundingClientRect().width.toString()"] floatValue]);
    NSNumber *height = @([[self stringByEvaluatingJavaScriptFromString:@"window.getSelection().getRangeAt(0).getBoundingClientRect().height.toString()"] floatValue]);
    NSImage *sc = [self takeScreenshotFromRect:left bottom:bottom width:width height:height];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, sc.size.width, sc.size.height)];
    [sc drawInRect:view.frame];
}

- (NSImage *)takeScreenshotFromRect:(NSNumber *)left bottom:(NSNumber *)bottom width:(NSNumber *)width height:(NSNumber *)height
{
    NSData *d = [self dataWithPDFInsideRect:NSMakeRect(left.floatValue, bottom.floatValue, width.floatValue, height.floatValue)];
    NSImage *i = [[NSImage alloc] initWithData:d];
    return i;
}

//+ (NSImage*) processImage :(NSImage*) image
//{
//    const float colorMasking[6]={222,255,222,255,222,255};
//    CGImageRef imageRef = CGImageCreateWithMaskingColors(image.CGImage, colorMasking);
//    NSImage* imageB = [NSImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    return imageB;
//}

- (void)startClearingHighlights
{
    [self.scrollHighlighter removeFromSuperview];
    self.scrollHighlighter = nil;
    [self invalidateTimers];
    [self clearHighlights];
}

- (void)clearHighlights
{
    DOMRange *range = [self selectedDOMRange];
    for(int i = 0; i < 100; i++)
    {
        if(!highlightedMatches.count)
        {
            self.highlightedMatches = [NSMutableArray array];
            self.matchedTexts = [NSMutableArray array];
            self.entirePageContent = [NSMutableString string];
            if(!currentQuery.query.length)
            {
                return;
            }
            DOMDocument *document = [self mainFrameDocument];
            DOMHTMLElement *body = [document body];
            if(!body)
            {
                return;
            }
            [self tryToGuessSelection:currentQuery.selectionAfterClear];
            [self traverseNodes:[NSMutableArray arrayWithObject:body]];
            return;
        }
        DHMatchedText *match = [highlightedMatches objectAtIndex:0];
        [highlightedMatches removeObjectAtIndex:0];
        if(![currentQuery.selectionAfterClear objectForKey:@"startContainer"] || ![currentQuery.selectionAfterClear objectForKey:@"endContainer"])
        { 
            DOMNode *expectedStart = [currentQuery.selectionAfterClear objectForKey:@"expectedStart"];
            DOMNode *expectedEnd = [currentQuery.selectionAfterClear objectForKey:@"expectedEnd"];
            if(range || expectedStart || expectedEnd)
            {
                if(range)
                {
                    [currentQuery.selectionAfterClear setObject:[range startContainer] forKey:@"expectedStart"];
                    [currentQuery.selectionAfterClear setObject:[NSNumber numberWithInt:[range startOffset]] forKey:@"expectedStartOffset"];
                    [currentQuery.selectionAfterClear setObject:[range endContainer] forKey:@"expectedEnd"];
                    [currentQuery.selectionAfterClear setObject:[NSNumber numberWithInt:[range endOffset]] forKey:@"expectedEndOffset"];
                }
                int rangeStartOffset = (!range) ? [[currentQuery.selectionAfterClear objectForKey:@"expectedStartOffset"] intValue] : [range startOffset];
                int rangeEndOffset = (!range) ? [[currentQuery.selectionAfterClear objectForKey:@"expectedEndOffset"] intValue] : [range endOffset];
                DOMNode *startContainer = (range) ? [range startContainer] : expectedStart;
                DOMNode *endContainer = (range) ? [range endContainer] : expectedEnd;
                int startOffset = -1;
                int endOffset = -1;
                int offset = 0;
                for(int i = 0; i < match.highlightedSpan.childNodes.length; i++)
                {
                    DOMNode *child = [match.highlightedSpan.childNodes item:i];
                    if(child.nodeType == DOM_ELEMENT_NODE)
                    {
                        for(int j = 0; j < child.childNodes.length; j++)
                        {
                            DOMNode *anotherChild = [child.childNodes item:j];
                            if(anotherChild == startContainer)
                            {
                                [currentQuery.selectionAfterClear removeObjectForKey:@"expectedStart"];
                                startOffset = offset + rangeStartOffset;
                            }
                            if(anotherChild == endContainer)
                            {
                                [currentQuery.selectionAfterClear removeObjectForKey:@"expectedEnd"];
                                endOffset = offset + rangeEndOffset;
                            }
                            offset += anotherChild.nodeValue.length;
                        }
                    }
                    else
                    {
                        if(child == startContainer)
                        {
                            [currentQuery.selectionAfterClear removeObjectForKey:@"expectedStart"];
                            startOffset = offset + rangeStartOffset;
                        }
                        if(child == endContainer)
                        {
                            [currentQuery.selectionAfterClear removeObjectForKey:@"expectedEnd"];
                            endOffset = offset + rangeEndOffset;
                        }
                        offset += child.nodeValue.length;
                    }
                }
                [match clearHighlight];
                if(startOffset != -1)
                {
                    [currentQuery.selectionAfterClear setObject:match.text forKey:@"startContainer"];
                    [currentQuery.selectionAfterClear setObject:[NSNumber numberWithInt:startOffset] forKey:@"startOffset"];
                }
                if(endOffset != -1)
                {
                    [currentQuery.selectionAfterClear setObject:match.text forKey:@"endContainer"];
                    [currentQuery.selectionAfterClear setObject:[NSNumber numberWithInt:endOffset] forKey:@"endOffset"];
                }
                if([currentQuery.selectionAfterClear objectForKey:@"startContainer"] && [currentQuery.selectionAfterClear objectForKey:@"endContainer"])
                {
                    @try {
                        DOMRange *range = [[self mainFrameDocument] createRange];
                        [range setStart:[currentQuery.selectionAfterClear objectForKey:@"startContainer"] offset:[[currentQuery.selectionAfterClear objectForKey:@"startOffset"] intValue]];
                        [range setEnd:[currentQuery.selectionAfterClear objectForKey:@"endContainer"] offset:[[currentQuery.selectionAfterClear objectForKey:@"endOffset"] intValue]];
                        [self setSelectedDOMRange:range affinity:NSSelectionAffinityUpstream];
                    }
                    @catch (NSException *exception) {
                    }
                    @finally {
                    }
                }
            }
            else
            {
                [match clearHighlight];
            }
        }
        else
        {
            [match clearHighlight];
        }
    }
    self.workerTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(clearHighlights) userInfo:nil repeats:NO];
}

- (void)traverseNodes:(NSMutableArray *)nodes
{
    for(int i = 0; i < 500; i++)
    {
        if(!nodes.count)
        {
            [self highlightMatches];
            return;
        }
        DOMNode *node = [nodes objectAtIndex:0];
        [nodes removeObjectAtIndex:0];
        if(node.nodeType == DOM_TEXT_NODE || node.nodeType == DOM_CDATA_SECTION_NODE)
        {
            DOMText *textNode = (DOMText *)node;
  
            NSString *content = [self normalizeWhitespaces:[textNode nodeValue]];
            if(content.length)
            {
                DHMatchedText *matchedText = [DHMatchedText matchedTextWithDOMText:textNode andRange:NSMakeRange(entirePageContent.length, content.length)];
                [entirePageContent appendString:content];
                [matchedTexts addObject:matchedText];
            }
        }
        if(node.nodeType == DOM_ELEMENT_NODE)
        {
            NSString *tagName = [(DOMElement*)node tagName];
            if(![tagName isCaseInsensitiveLike:@"style"] && ![tagName isCaseInsensitiveLike:@"script"])
            {
                DOMNodeList *childNodes = [node childNodes];
                for(int i = 0; i < childNodes.length; i++)
                {
                    [nodes insertObject:[childNodes item:i] atIndex:i];
                }
            }
        }
    }
    self.workerTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(traverseWithTimer:) userInfo:nodes repeats:NO];
}

- (void)traverseWithTimer:(NSTimer *)timer
{
    NSMutableArray *userInfo = [timer userInfo];
    [self traverseNodes:userInfo];
}

- (void)highlightMatches
{
    NSMutableArray *foundRanges = [NSMutableArray array];
    NSRange foundRange;
    NSInteger scanLocation = 0;
    do 
    {
        NSStringCompareOptions options = ([currentQuery isCaseSensitive]) ? NSLiteralSearch : NSCaseInsensitiveSearch;
        foundRange = [entirePageContent rangeOfString:[currentQuery query] options:options range:NSMakeRange(scanLocation, entirePageContent.length-scanLocation)];
        if(foundRange.location != NSNotFound)
        {
            scanLocation = foundRange.location+foundRange.length;
            [foundRanges addObject:[NSValue valueWithRange:foundRange]];
        }
    } 
    while (foundRange.location != NSNotFound);

    NSEnumerator *matchesEnumerator = [matchedTexts objectEnumerator];
    DHMatchedText *currentMatch = [matchesEnumerator nextObject];
    NSMutableSet *foundMatches = [NSMutableSet set];
    for(NSValue *foundRange in foundRanges)
    {
        NSRange actualRange = [foundRange rangeValue];
        do 
        {
            NSRange intersectionRange = NSIntersectionRange([currentMatch effectiveRange], actualRange);
            if(intersectionRange.length > 0)
            {
                //
                [foundMatches addObject:currentMatch];
                [[currentMatch foundRanges] addObject:[NSValue valueWithRange:intersectionRange]];
                if(intersectionRange.location+intersectionRange.length >= actualRange.location+actualRange.length)
                {
                    break;
                }
                else
                {
                    currentMatch = [matchesEnumerator nextObject];
                }
            }
            else
            {
                currentMatch = [matchesEnumerator nextObject];
            }
        } while (currentMatch);
    }
    if(foundMatches.count)
    {
        [self timeredHighlightOfMatches:[NSMutableArray arrayWithArray:[foundMatches allObjects]]];
    }
}

- (void)timeredHighlightOfMatches:(NSMutableArray *)matches
{
    DOMRange *range = [self selectedDOMRange];
    if([matches isKindOfClass:[NSTimer class]])
    {
        matches = [(NSTimer*)matches userInfo];
    }
    for(int i = 0; i < 100; i++)
    {
        if(!matches.count)
        {
            [self tryToGuessSelection:currentQuery.selectionAfterHighlight];
            self.scrollHighlighter = [DHScrollbarHighlighter highlighterWithWebView:self andMatches:highlightedMatches];
            return;
        }
        DHMatchedText *last = [matches lastObject];
        [highlightedMatches addObject:last];
        [matches removeLastObject];
        
        if(![currentQuery.selectionAfterHighlight objectForKey:@"startContainer"] || ![currentQuery.selectionAfterHighlight objectForKey:@"endContainer"])
        {
            DOMNode *expectedStart = [currentQuery.selectionAfterHighlight objectForKey:@"expectedStart"];
            DOMNode *expectedEnd = [currentQuery.selectionAfterHighlight objectForKey:@"expectedEnd"];
            if(range || expectedStart || expectedEnd)
            {
                if(range)
                {
                    [currentQuery.selectionAfterHighlight setObject:[range startContainer] forKey:@"expectedStart"];
                    [currentQuery.selectionAfterHighlight setObject:[NSNumber numberWithInt:[range startOffset]] forKey:@"expectedStartOffset"];
                    [currentQuery.selectionAfterHighlight setObject:[range endContainer] forKey:@"expectedEnd"];
                    [currentQuery.selectionAfterHighlight setObject:[NSNumber numberWithInt:[range endOffset]] forKey:@"expectedEndOffset"];
                }
                int startOffset = (!range) ? [[currentQuery.selectionAfterHighlight objectForKey:@"expectedStartOffset"] intValue] : [range startOffset];
                int endOffset = (!range) ? [[currentQuery.selectionAfterHighlight objectForKey:@"expectedEndOffset"] intValue] : [range endOffset];
                BOOL isStart = (range) ? [range startContainer] == last.text : expectedStart == last.text;
                BOOL isEnd = (range) ? [range endContainer] == last.text : expectedEnd == last.text;
                
                [last highlightDOMNode];
                if(isStart)
                {
                    [currentQuery.selectionAfterHighlight removeObjectForKey:@"expectedStart"];
                    [currentQuery.selectionAfterHighlight setObject:last.highlightedSpan forKey:@"startContainer"];
                    [currentQuery.selectionAfterHighlight setObject:[NSNumber numberWithInt:startOffset] forKey:@"startOffset"];
                }
                if(isEnd)
                {
                    [currentQuery.selectionAfterHighlight removeObjectForKey:@"expectedEnd"];
                    [currentQuery.selectionAfterHighlight setObject:last.highlightedSpan forKey:@"endContainer"];
                    [currentQuery.selectionAfterHighlight setObject:[NSNumber numberWithInt:endOffset] forKey:@"endOffset"];
                }
                if([currentQuery.selectionAfterHighlight objectForKey:@"startContainer"] && [currentQuery.selectionAfterHighlight objectForKey:@"endContainer"])
                {
                    [self selectRangeUsingEncodedDictionary:currentQuery.selectionAfterHighlight];
                }
            }
            else
            {
                [last highlightDOMNode];
            }
        }
        else
        {
            [last highlightDOMNode];
        }
    }
    self.workerTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(timeredHighlightOfMatches:) userInfo:matches repeats:NO];
}

- (void)invalidateTimers
{
    if([self.workerTimer isValid])
    {
        [workerTimer invalidate];
    }
    self.workerTimer = nil;
}

- (NSString *)normalizeWhitespaces:(NSString *)aString
{
    // Normalize the whitespaces so we can avoid characters like "thin whitespace" (U+2009).
    // Yes, I tried using NSWidthInsensitiveSearch, but it only works for comparisons, not searching, hence the name (GG Apple!)
    NSRange foundRange;
    NSInteger scanLocation = 0;
    NSMutableString *string = [NSMutableString stringWithString:aString];
    do
    {
        foundRange = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSLiteralSearch range:NSMakeRange(scanLocation, string.length-scanLocation)];
        if(foundRange.location != NSNotFound)
        {
            scanLocation = foundRange.location+foundRange.length;
            [string replaceCharactersInRange:foundRange withString:@" "];
        }
    } while (foundRange.location != NSNotFound);
    return string;
}

- (void)selectRangeUsingEncodedDictionary:(NSMutableDictionary *)dictionary
{
    DOMNode *start = [dictionary objectForKey:@"startContainer"];
    DOMNode *end = [dictionary objectForKey:@"endContainer"];
    int startOffset = [[dictionary objectForKey:@"startOffset"] intValue];
    int endOffset = [[dictionary objectForKey:@"endOffset"] intValue];
    DOMRange *newRange = [[self mainFrameDocument] createRange];
    
    int offset = 0;
    for(int i = 0; i < [start childNodes].length; i++)
    {
        DOMNode *child = [[start childNodes] item:i];
        offset += (child.nodeType == DOM_ELEMENT_NODE) ? [(DOMHTMLElement*)child innerText].length : child.nodeValue.length;
        if(startOffset < offset)
        {
            @try {
                [newRange setStartBefore:child];
            }
            @catch (NSException *exception) {
            }
            break;
        }
    }
    offset = 0;
    for(int i = 0; i < [end childNodes].length; i++)
    {
        DOMNode *child = [[end childNodes] item:i];
        offset += (child.nodeType == DOM_ELEMENT_NODE) ? [(DOMHTMLElement*)child innerText].length : child.nodeValue.length;
        if(endOffset <= offset)
        {
            @try {
                [newRange setEndAfter:child];
            }
            @catch (NSException *exception) {
            }
            break;
        }
    }
    @try {
        [self setSelectedDOMRange:newRange affinity:NSSelectionAffinityUpstream];
    }
    @catch (NSException *exception) {
    }
}

- (void)clearSelection
{
    DOMRange *range = [self selectedDOMRange];
    if(range)
    {
        [range setEnd:[range startContainer] offset:[range startOffset]];
        [self setSelectedDOMRange:range affinity:NSSelectionAffinityUpstream];
    }
}

- (void)tryToGuessSelection:(NSDictionary *)fromDict
{
    if([self selectedDOMRange])
    {
        return;
    }
    @try {
        DOMNode *expectedStart = [fromDict objectForKey:@"expectedStart"];
        DOMNode *expectedEnd = [fromDict objectForKey:@"expectedEnd"];
        int expectedStartOffset = [[fromDict objectForKey:@"expectedStartOffset"] intValue];
        int expectedEndOffset = [[fromDict objectForKey:@"expectedEndOffset"] intValue];
        DOMNode *start = [fromDict objectForKey:@"startContainer"];
        DOMNode *end = [fromDict objectForKey:@"endContainer"];
        int startOffset = (fromDict == currentQuery.selectionAfterHighlight) ? 0 : [[fromDict objectForKey:@"startOffset"] intValue];
        int endOffset = (fromDict == currentQuery.selectionAfterHighlight) ? 0 : [[fromDict objectForKey:@"endOffset"] intValue];
        DOMDocument *document = [self mainFrameDocument];
        if(expectedStart && end)
        {
            DOMRange *range = [document createRange];
            [range setStart:expectedStart offset:expectedStartOffset];
            [range setEnd:end offset:endOffset];
            [self setSelectedDOMRange:range affinity:NSSelectionAffinityUpstream];
        }
        else if(expectedEnd && start)
        {
            DOMRange *range = [document createRange];
            [range setStart:start offset:startOffset];
            [range setEnd:expectedEnd offset:expectedEndOffset];
            [self setSelectedDOMRange:range affinity:NSSelectionAffinityUpstream];
        }
        else if(expectedStart && expectedEnd)
        {
            DOMRange *range = [[self mainFrameDocument] createRange];
            [range setStart:expectedStart offset:expectedStartOffset];
            [range setEnd:expectedEnd offset:expectedEndOffset];
            [self setSelectedDOMRange:range affinity:NSSelectionAffinityUpstream];
        }
    }
    @catch (NSException *exception) {
    }
}

- (BOOL)maintainsInactiveSelection
{
    return YES;
}

// You should call this from your delegate, I couldn't find a way of knowing when a new page is loaded
- (void)didStartProvisionalLoad
{
    [self invalidateTimers];
    [scrollHighlighter removeFromSuperview];
    self.scrollHighlighter = nil;
    self.currentQuery = nil;
    self.highlightedMatches = [NSMutableArray array];
    self.matchedTexts = [NSMutableArray array];
    self.entirePageContent = [NSMutableString string];
}

- (void)makeTextLarger:(id)sender
{
    [super makeTextLarger:sender];
    [[NSUserDefaults standardUserDefaults] setFloat:[self textSizeMultiplier] forKey:@"DHHighlightedWebViewTextSizeMultiplier"];
}

- (void)makeTextSmaller:(id)sender
{
    [super makeTextSmaller:sender];
    [[NSUserDefaults standardUserDefaults] setFloat:[self textSizeMultiplier] forKey:@"DHHighlightedWebViewTextSizeMultiplier"];
}



- (void)keyDown:(NSEvent *)theEvent
{
    if (( [theEvent modifierFlags] & NSCommandKeyMask ) && ([theEvent.characters isEqualToString:@"f"])) {
//        [self showTextField];
        [self showSearchField];
    }
    else if ([theEvent.characters isEqualToString:@""])
    {
        [self hideSearchField];
    }
    else
    {
        [super keyDown:theEvent];
    }
}

- (void)keyUp:(NSEvent *)theEvent
{
    if (YES) {
        
    }
    else
    {
        [super keyUp:theEvent];
    }
}

- (void)showSearchField
{
    [self animateSearchBarAndHide:NO];
    
    [self highlightQuery:self.sbVC.searchField.stringValue caseSensitive:NO];
}

- (void)hideSearchField
{
    [self animateSearchBarAndHide:YES];

    [self highlightQuery:@"" caseSensitive:NO];
}

- (void)animateSearchBarAndHide:(BOOL)hides
{
    BBlockWeakSelf weakself = self;
    NSBox *box = (NSBox *)weakself.sbVC.view;
    NSRect searchBarRect = hides ? NSMakeRect(0, weakself.frame.size.height, weakself.frame.size.width, box.frame.size.height)
    : NSMakeRect(0, weakself.frame.size.height - box.frame.size.height, weakself.frame.size.width, box.frame.size.height);
    
//    NSRect webViewRect = self.frame;
//    if (hides) {
//        webViewRect.size.height += box.frame.size.height;
//    }
//    else
//    {
//        webViewRect.size.height -= box.frame.size.height;
//    }
//    
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
    {
        [context setDuration:.25f];
        [weakself.sbVC.view.animator setFrame:searchBarRect];
//        [weakself.animator setFrame:webViewRect];
    } completionHandler:^
    {
        if (hides) {
            [weakself.window makeFirstResponder:self];
        }
        else
        {
            [weakself.window makeFirstResponder:weakself.sbVC.searchField];
        }
    }];
}

#pragma mark - DHSearchBarViewDelegate

- (void)findPrevButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField
{
    NSString *query = [textField stringValue];
    [self searchFor:query direction:NO caseSensitive:NO wrap:YES];
    [self.window makeFirstResponder:textField];
}

- (void)findNextButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField
{
    NSString *query = [textField stringValue];
    [self searchFor:query direction:YES caseSensitive:NO wrap:YES];
    [self.window makeFirstResponder:textField];
}

- (void)doneButtonPressed:(NSButton *)button withTextfield:(NSTextField *)textField
{
    // Hides shadowView
    [self animateSearchBarAndHide:YES];
    
    [self highlightQuery:@"" caseSensitive:NO];
}

- (void)searchField:(NSSearchField *)searchField didChangeText:(NSNotification *)notif
{
    NSTextView *field = [[notif userInfo] objectForKey:@"NSFieldEditor"];
    [self highlightQuery:[field string] caseSensitive:NO];
}

- (void)searchFieldDidPressEnterKey:(NSSearchField *)searchField
{
    NSString *query = [searchField stringValue];
    [self searchFor:query direction:YES caseSensitive:NO wrap:YES];
    [self.window makeFirstResponder:searchField];
}




@end