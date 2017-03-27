

#import <UIKit/UIKit.h>
#import "WritePadInputView.h"
#import "WritePadInputPanel.h"
#import "Shortcuts.h"
#import "NoteInkController.h"
#import "SuggestionsView.h"
#import "RichTextEditor.h"
#import "WPTextView.h"
#import "NotePopupController.h"
#import "NotePopover.h"
#import "NoteCustomPopover.h"
#import "FloatPanelView.h"

@protocol NoteTextViewDelegate<NSObject>
@optional

- (void) selectCameraOrPhoto;
- (void) selectPaint;
- (void) selectEdit;
- (void) selectKeyboard;
- (void) selectStylus;

@end

@interface NoteTextView : RichTextEditor <WritePadInputPanelDelegate, WritePadInputViewDelegate, ShortcutsDelegate, NoteInkControllerDelegate, SuggestionsViewDelegate, NotePopupControllerDelegate>
{
@private
    NoteInkController * inkCollector;
}

+ (NoteTextView *) createTextView:(CGRect)frame;

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
- (void) showPopMenu:(CGRect) fromRect inView:(UIView*)inView;
- (void) openStyle;
- (void) popupRect:(CGRect) rt;
- (void) showParagraphs;

-(void)initSubjective;
-(void)initObjective;
-(void)initAssessment;
-(void)initPlan;


@property (nonatomic, strong) UIColor *horizontalLineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *verticalLineColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, retain) NoteInkController * inkCollector;
@property (nonatomic, readonly ) InputSystem  inputSystem;
@property(nonatomic, retain)    UITextPosition *      startSelTextPos;
@property(nonatomic, retain)    UITextPosition *      endSelTextPos;
@property(nonatomic) CGFloat fontSize;
@property(nonatomic) CGFloat lineWidth;
@property(nonatomic) CGFloat lineSpace;
@property (nonatomic, weak) id <NoteTextViewDelegate> noteDelegate;
@property (nonatomic, strong) id <NotePopover> popover;
@property (nonatomic, retain) NSMutableArray* paragraphs;
@property (nonatomic, retain) FloatPanelView* floatPanel;
@property(nonatomic) CGRect insertPosi;
@end


