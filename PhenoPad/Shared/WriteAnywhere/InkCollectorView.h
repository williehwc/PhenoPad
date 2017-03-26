

#import <UIKit/UIKit.h>
#import "Shortcuts.h"

#define MAX_QUEUE_SIZE		512

@class SoundEffect;
@class InkCollectorView;

enum {
	WritePadPopoverNone = 0,
	WritePadPopoverKeyboard = 1,
	WritePadPopoverSpell = 2,
	WritePadPopoverRecognizer = 3
};

@interface InkCurrentStrokeView : UIView
{
}

@property(nonatomic, weak) InkCollectorView *		inkView;

@end

// dummy input view

@interface DummyInputView : UIView
{
    
}

+ (DummyInputView *) sharedDummyInputPanel;
+ (void) destroySharedDummyInputPanel;

@end

@class WPTextView;

@protocol InkCollectorViewDelegate;

@interface InkCollectorView : UIView <UIPopoverControllerDelegate>
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

@property(assign) id<InkCollectorViewDelegate> delegate;

@end

@protocol InkCollectorViewDelegate<NSObject>
@optional

- (void) InkCollectorResultReady:(InkCollectorView*)inkView theResult:(NSString*)string;
- (BOOL) InkCollectorRecognizedGesture:(InkCollectorView*)inkView withGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty;
- (void) InkCollectorAsyncResultReady:(InkCollectorView*)inkView theResult:(NSString*)string;

@end
