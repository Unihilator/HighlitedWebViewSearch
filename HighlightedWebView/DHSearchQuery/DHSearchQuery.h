#import <Foundation/Foundation.h>

@interface DHSearchQuery : NSObject {
    NSString *query;
    BOOL isCaseSensitive;
    NSMutableDictionary *selectionAfterHighlight;
    NSMutableDictionary *selectionAfterClear;
}

@property (strong) NSString *query;
@property (assign) BOOL isCaseSensitive;
@property (strong) NSMutableDictionary *selectionAfterHighlight;
@property (strong) NSMutableDictionary *selectionAfterClear;

+ (DHSearchQuery *)searchQueryWithQuery:(NSString *)aQuery caseSensitive:(BOOL)caseSensitive;
- (id)initWithQuery:(NSString *)aQuery caseSensitive:(BOOL)caseSensitive;
- (BOOL)isEqualTo:(DHSearchQuery *)object;

@end
