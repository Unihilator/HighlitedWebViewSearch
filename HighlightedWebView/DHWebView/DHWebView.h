#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "DHSearchQuery.h"
#import "DHScrollbarHighlighter.h"

@class DHSearchTextField;

@interface DHWebView : WebView {
    NSTimer *workerTimer;
    DHSearchQuery *currentQuery;
    NSMutableArray *highlightedMatches;
    NSMutableArray *matchedTexts;
    NSMutableString *entirePageContent;
    DHScrollbarHighlighter *scrollHighlighter;
}

@property (strong) NSTimer *workerTimer;
@property (strong) DHSearchQuery *currentQuery;
@property (strong) NSMutableArray *highlightedMatches;
@property (strong) NSMutableArray *matchedTexts;
@property (strong) NSMutableString *entirePageContent;
@property (strong) DHScrollbarHighlighter *scrollHighlighter;

- (void)highlightQuery:(NSString *)aQuery caseSensitive:(BOOL)isCaseSensitive;
- (void)highlightQuery:(DHSearchQuery *)query;
- (void)startClearingHighlights;
- (void)clearHighlights;
- (void)traverseNodes:(NSMutableArray *)nodes;
- (void)highlightMatches;
- (void)timeredHighlightOfMatches:(NSMutableArray *)matches;
- (void)invalidateTimers;
- (NSString *)normalizeWhitespaces:(NSString *)aString;
- (void)selectRangeUsingEncodedDictionary:(NSMutableDictionary *)dictionary;
- (void)clearSelection;
- (void)tryToGuessSelection:(NSDictionary *)fromDict;
- (void)didStartProvisionalLoad;

@end