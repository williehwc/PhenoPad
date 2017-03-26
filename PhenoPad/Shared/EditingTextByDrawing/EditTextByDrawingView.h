

#import <UIKit/UIKit.h>
#import "Shortcuts.h"
#import "InkCollectorView.h"
#import "RichTextEditorChangeStrokeViewController.h"

#define MAX_QUEUE_SIZE		512

@class SoundEffect;
@class EditTextByDrawingView;
@class WPTextView;

@protocol EditTextByDrawingViewDelegate;

@interface EditTextByDrawingView : UIView <UIPopoverControllerDelegate,
    RichTextEditorChangeStrokeViewControllerDelegate,
    RichTextEditorChangeStrokeViewControllerDataSource>
{
@private
    CGStroke			ptStroke;
    int					strokeLen;
    int					strokeMemLen;
    Boolean				_firstTouch;
    CGPoint				_previousLocation;
    Boolean				autoRecognize;
    Boolean				backgroundReco;
    NSTimer *			_timerRecognizer;
    NSTimer *			_timerTouchAndHold;
    INK_DATA_PTR		inkData;
    NSTimeInterval		recognitionDelay;
    GESTURE_TYPE		gesturesEnabledIfEmpty;
    GESTURE_TYPE		gesturesEnabledIfData;
    UIColor *			strokeColor;
    float				strokeWidth;
    Shortcuts	*		shortcuts;
    
    Boolean				_bSelectionMode;
    Boolean				_bAddStroke;
    Boolean				_bSendTouchToEdit;
    NSInteger			CurrPopover;
    NSInteger			_nAdded;
    
    void *              cacheBitmap;
    CGContextRef        cacheContext;
    int                 countLines;
    
    InkCurrentStrokeView *  _currentStrokeView;
    
    CGPoint				_inkQueue[MAX_QUEUE_SIZE];
    int					_inkQueueGet, _inkQueuePut;
    NSCondition		*	_inkQueueCondition;
    Boolean				_runInkThread;
    Boolean				_bAsyncInkCollector;
    NSLock *			_inkLock;
    BOOL                _useAsyncRecognizer;
    
}

@property(nonatomic, readwrite) NSTimeInterval  recognitionDelay;
@property(nonatomic, readwrite) Boolean			autoRecognize;
@property(nonatomic, readwrite) float			strokeWidth;
@property(nonatomic, assign)    WPTextView * 	edit;
@property(nonatomic, retain)    UIColor *		strokeColor;
@property(nonatomic)			Boolean			backgroundReco;
@property(nonatomic)			NSInteger		CurrPopover;
@property(nonatomic, retain)    Shortcuts	*	shortcuts;
@property(nonatomic, readonly)  Boolean			asyncInkCollector;

@property(nonatomic, assign)    int				strokeLen;
@property(nonatomic, assign)    CGStroke		ptStroke;

@property(nonatomic, retain)    NSString *      placeholder1;
@property(nonatomic, retain)    NSString *      placeholder2;

@property(nonatomic, assign)    Boolean *      isStylus;


+ (void) ensureDefaultSettings:(Boolean)force;

- (void) reloadOptions;
- (void) empty;
- (BOOL) deleteLastStroke;
- (void) enableGestures:(GESTURE_TYPE)gestures whenEmpty:(BOOL)bEmpty;
- (BOOL) shortcutsEnable:(BOOL)bEnable delegate:(id)del uiDelegate:(id)uiDel;
- (void) enterSelectionMode;
- (void) endSelectionMode;
- (void) recognizeNow;
- (void) openStyle;

@property(assign) id<EditTextByDrawingViewDelegate> delegate;

@end

@protocol EditTextByDrawingViewDelegate<NSObject>
@optional

- (void) InkCollectorResultReady:(EditTextByDrawingView*)inkView theResult:(NSString*)string;
- (BOOL) InkCollectorRecognizedGesture:(EditTextByDrawingView*)inkView withGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty;
- (BOOL) InkCollectorRecognizedShape:(EditTextByDrawingView *)inkView withShape:(SHAPETYPE)gesture isEmpty:(BOOL)bEmptys;
- (void) InkCollectorAsyncResultReady:(EditTextByDrawingView*)inkView theResult:(NSString*)string;

@end