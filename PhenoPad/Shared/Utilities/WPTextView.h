

#import <UIKit/UIKit.h>
#import "WritePadInputView.h"
#import "WritePadInputPanel.h"
#import "Shortcuts.h"
#import "InkCollectorView.h"
#import "SuggestionsView.h"
#import "RichTextEditor.h"

typedef enum {
    InputSystem_Default = -1,
    InputSystem_InputPanel = 0,
    InputSystem_WriteAnywhere,
    InputSystem_Keyboard,
    InputSystem_NoKeyboard,
    InputSystem_Previous,
    InputSystem_Next
} InputSystem;

@interface WPTextView : RichTextEditor <WritePadInputPanelDelegate, WritePadInputViewDelegate, ShortcutsDelegate, InkCollectorViewDelegate, SuggestionsViewDelegate>
{
@private
    InkCollectorView * inkCollector;
}

+ (WPTextView *) createTextView:(CGRect)frame;

- (void) setInputMethod:(InputSystem)inputSystem;
- (void) processTouchAndHoldAtLocation:(CGPoint)location;
- (void) tapAtLocation:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) selectTextFromPosition:(CGPoint)from toPosition:(CGPoint)to;
- (void) hideSuggestions;
- (void) reloadOptions;
- (void) scrollToVisible;
- (void) doScroll:(Boolean)up yOffset:(NSInteger)y;
- (void) setTextLocation:(CGPoint) pointInTextView startOrEnd:(BOOL)startOrEnd;

////////////////jixuan
- (void) initTextViewWithoutFrame;
- (void) appendAttributedString:(NSString*) s;

@property (nonatomic, strong) UIColor *horizontalLineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *verticalLineColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, retain) InkCollectorView * inkCollector;
@property (nonatomic, readonly ) InputSystem  inputSystem;
@property(nonatomic, retain)    UITextPosition *      startSelTextPos;
@property(nonatomic, retain)    UITextPosition *      endSelTextPos;
@property(nonatomic) CGFloat fontSize;
@property(nonatomic) CGFloat lineWidth;
@property(nonatomic) CGFloat lineSpace;
@end
