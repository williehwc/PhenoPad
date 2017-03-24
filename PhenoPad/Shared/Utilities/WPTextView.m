/* ************************************************************************************* */
/* *    PhatWare WritePad SDK                                                          * */
/* *    Copyright (c) 2008-2015 PhatWare(r) Corp. All rights reserved.                 * */
/* ************************************************************************************* */

/* ************************************************************************************* *
 *
 * WritePad SDK Sample
 *
 * Unauthorized distribution of this code is prohibited. For more information
 * refer to the End User Software License Agreement provided with this
 * software.
 *
 * This source code is distributed and supported by PhatWare Corp.
 * http://www.phatware.com
 *
 * THIS SAMPLE CODE CAN BE USED  AS A REFERENCE AND, IN ITS BINARY FORM,
 * IN THE USER'S PROJECT WHICH IS INTEGRATED WITH THE WRITEPAD SDK.
 * ANY OTHER USE OF THIS CODE IS PROHIBITED.
 *
 * THE MATERIAL EMBODIED ON THIS SOFTWARE IS PROVIDED TO YOU "AS-IS"
 * AND WITHOUT WARRANTY OF ANY KIND, EXPRESS, IMPLIED OR OTHERWISE,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY OR
 * FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL PHATWARE CORP.
 * BE LIABLE TO YOU OR ANYONE ELSE FOR ANY DIRECT, SPECIAL, INCIDENTAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER,
 * INCLUDING WITHOUT LIMITATION, LOSS OF PROFIT, LOSS OF USE, SAVINGS
 * OR REVENUE, OR THE CLAIMS OF THIRD PARTIES, WHETHER OR NOT PHATWARE CORP.
 * HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH LOSS, HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE
 * POSSESSION, USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * US Government Users Restricted Rights
 * Use, duplication, or disclosure by the Government is subject to
 * restrictions set forth in EULA and in FAR 52.227.19(c)(2) or subparagraph
 * (c)(1)(ii) of the Rights in Technical Data and Computer Software
 * clause at DFARS 252.227-7013 and/or in similar or successor
 * clauses in the FAR or the DOD or NASA FAR Supplement.
 * Unpublished-- rights reserved under the copyright laws of the
 * United States.  Contractor/manufacturer is PhatWare Corp.
 * 1314 S. Grand Blvd. Ste. 2-175 Spokane, WA 99202
 *
 * ************************************************************************************* */

#import "WPTextView.h"
#import "UIConst.h"
#import "OptionKeys.h"
#import "AsyncResultView.h"

////Jixuan
#define DEFAULT_HORIZONTAL_COLOR    [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1.0f]
#define DEFAULT_VERTICAL_COLOR      [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
static CGFloat const fontSize = 25.0;
static CGFloat lineWidth = 3.0f;
static CGFloat lineSpace = 60.0f;

@implementation WPTextView

@synthesize inkCollector;
@synthesize inputSystem;

+ (WPTextView *) createTextView:(CGRect)frame
{
    WPTextView * textView = [[WPTextView alloc] initWithFrame:frame];

    textView.opaque = NO;
    textView.font = [UIFont fontWithName:@"Arial" size:fontSize];
    textView.backgroundColor = [UIColor clearColor];
    textView.returnKeyType = UIReturnKeyDefault;
    textView.autoresizesSubviews = YES;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)

    
    return textView;
}
////////////////////////////////////////////////////jixuan
+ (void)initialize
{
    if (self == [WPTextView class]) {
        id appearance = [self appearance];
        [appearance setContentMode:UIViewContentModeRedraw];
        [appearance setHorizontalLineColor:DEFAULT_HORIZONTAL_COLOR];
        [appearance setVerticalLineColor:DEFAULT_VERTICAL_COLOR];
    }
}


#pragma mark - Superclass overrides

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, lineWidth);
    
    if (self.horizontalLineColor) {
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context, self.horizontalLineColor.CGColor);
        // CGFloat dash[] = {0, lineWidth*2};
        // CGContextSetLineDash(context, 0, dash, 2);
        
        // Create un-mutated floats outside of the for loop.
        // Reduces memory access.
        CGFloat baseOffset = 7.0f + self.textContainerInset.top + self.font.descender;
        CGFloat screenScale = [UIScreen mainScreen].scale;
        CGFloat boundsX = self.bounds.origin.x;
        CGFloat boundsWidth = self.bounds.size.width;
        
        CGFloat kFactor = 0.0;
        CGFloat lFactor = 0.0;
        BOOL isAtLeast7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
        if(isAtLeast7) {
            kFactor = self.font.pointSize * 0.03268;  // ArialMT  0.03267857143
            lFactor = self.font.pointSize * 0.03268;
            //kFactor = self.font.pointSize * 0.0;  // Helvetica
            //kFactor = self.font.pointSize * 0.028;  // Helvetica Neue (Regular)
            //kFactor = self.font.pointSize * 0.029;  // Helvetica Neue Thin
            //kFactor = self.font.pointSize * 0.029;  // Helvetica Neue Light
            //kFactor = self.font.pointSize * 0.0424;  // Times New Roman
        }
        
        // Only draw lines that are visible on the screen.
        // (As opposed to throughout the entire view's contents)
        NSInteger firstVisibleLine = MAX(1, (self.contentOffset.y / (self.font.lineHeight+lineSpace)));
        NSInteger lastVisibleLine = ceilf((self.contentOffset.y + self.bounds.size.height) / self.font.lineHeight);

        for (NSInteger line = firstVisibleLine; line <= lastVisibleLine; line++) {
            CGFloat linePointY = (baseOffset + ((self.font.lineHeight + kFactor ) * line) + (lineSpace-lFactor)*(line-1));
            // Rounding the point to the nearest pixel.
            // Greatly reduces drawing time.
            CGFloat roundedLinePointY = roundf(linePointY * screenScale) / screenScale;
            roundedLinePointY = roundedLinePointY + self.font.descender;
            CGContextMoveToPoint(context, boundsX, roundedLinePointY);
            CGContextAddLineToPoint(context, boundsWidth, roundedLinePointY);
        }
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }

    if (self.verticalLineColor) {
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context, self.verticalLineColor.CGColor);
        CGContextMoveToPoint(context, -lineWidth + self.textContainerInset.left, self.contentOffset.y);
        CGContextAddLineToPoint(context, -lineWidth + self.textContainerInset.left, self.contentOffset.y + self.bounds.size.height);
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    CGRect originalRect = [super caretRectForPosition:position];
    originalRect.size.height = fontSize;
    return originalRect;
}


- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    [super setTextContainerInset:textContainerInset];
    [self setNeedsDisplay];
}


#pragma mark - Property methods

- (void)setHorizontalLineColor:(UIColor *)horizontalLineColor
{
    _horizontalLineColor = horizontalLineColor;
    [self setNeedsDisplay];
}

- (void)setVerticalLineColor:(UIColor *)verticalLineColor
{
    _verticalLineColor = verticalLineColor;
    [self setNeedsDisplay];
}
////////////////////////////////////////////////////////////////////

- (void) initTextViewWithoutFrame
{
    WPTextView * textView = self;
    inputSystem = InputSystem_Default;
    
    // create full screen ink collector
    // create ink collector control
    // Create a Quartz View to embed later with a dummy rect for now.
    inkCollector = [[InkCollectorView alloc] initWithFrame:self.frame];
    inkCollector.backgroundColor = [UIColor clearColor];
    inkCollector.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    inkCollector.contentMode = UIViewContentModeRedraw;
    inkCollector.autoRecognize = YES;
    inkCollector.backgroundReco = YES;
    inkCollector.edit = self;
    inkCollector.delegate = self;
    inkCollector.hidden = NO;
    
    // these gestures should be recognized when control is emply
    [inkCollector enableGestures:(GEST_ALL & ~GEST_LOOP) whenEmpty:YES];
    
    // only these gestures should be recognized when control is not empty
    // loop for shortcuts... Shortcuts is a simplified version of PenCommander
    // Return - to enter text, Cut to delete ink, Loop for shortcut
    [inkCollector enableGestures:(GEST_RETURN | GEST_CUT | GEST_LOOP | GEST_BACK) whenEmpty:NO];
    
    [inkCollector shortcutsEnable:YES delegate:self uiDelegate:nil];
    
    textView.opaque = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.returnKeyType = UIReturnKeyDefault;
    textView.autoresizesSubviews = YES;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
    
    /////jixuan
    /// for background lines
    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    lineWidth = lineWidth / screen.scale;
    lineSpace = lineSpace / screen.scale;
    /// style
    textView.textContainerInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = lineSpace;
    self.attributedText = [[NSAttributedString alloc]
                           initWithString:@""
                           attributes:@{NSParagraphStyleAttributeName : style}];
    
    [self setFont: [UIFont fontWithName:@"Arial" size:fontSize]];
    UIFont *font = self.font;
    self.font = nil;
    self.font = font;
    
    self.textContainerInset = UIEdgeInsetsMake(40.0f, 0.0f, 0.0f, 0.0f);
    //self.editable = NO;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
	{
		inputSystem = InputSystem_Default;
        
        // create full screen ink collector
		// create ink collector control
		// Create a Quartz View to embed later with a dummy rect for now.
		inkCollector = [[InkCollectorView alloc] initWithFrame:self.frame];
		inkCollector.backgroundColor = [UIColor clearColor];
		inkCollector.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		inkCollector.contentMode = UIViewContentModeRedraw;
		inkCollector.autoRecognize = YES;
		inkCollector.backgroundReco = YES;
		inkCollector.edit = self;
		inkCollector.delegate = self;
        inkCollector.hidden = NO;
        
        // these gestures should be recognized when control is emply
		[inkCollector enableGestures:(GEST_ALL & ~GEST_LOOP) whenEmpty:YES];
        		
		// only these gestures should be recognized when control is not empty
		// loop for shortcuts... Shortcuts is a simplified version of PenCommander
		// Return - to enter text, Cut to delete ink, Loop for shortcut
		[inkCollector enableGestures:(GEST_RETURN | GEST_CUT | GEST_LOOP | GEST_BACK) whenEmpty:NO];
        
        [inkCollector shortcutsEnable:YES delegate:self uiDelegate:nil];
        
        
        /////jixuan
        self.font = [UIFont fontWithName:@"Arial" size:fontSize];
        UIFont *font = self.font;
        self.font = nil;
        self.font = font;
        /**
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = 50;
        self.font = [UIFont fontWithName:@"Arial" size:50.0];
        self.attributedText = [[NSAttributedString alloc]
                                   initWithString:@"Predefinedxxx Text"
                                   attributes:@{NSParagraphStyleAttributeName : style}];
         **/
            
    }
    return self;
}

- (void) reloadOptions
{
    [inkCollector reloadOptions];
    [[WritePadInputView sharedInputPanel].inkCollector reloadOptions];
}

- (void)dealloc
{
    if ( [[SuggestionsView sharedSuggestionsView].suggestions_delegate isEqual:self] )
        [SuggestionsView sharedSuggestionsView].suggestions_delegate = nil;
	self.inputView = nil;
}

#pragma mark -- Alternative Input method support

- (void) setInputMethod:(InputSystem)is
{
    if ( is == inputSystem )
        return;
    
    //if ( inputSystem == InputSystem_WriteAnywhere )
    {
        [inkCollector removeFromSuperview];
    }
    
    [self resignFirstResponder];
    inputSystem = is;
    switch( inputSystem )
    {
        case InputSystem_InputPanel :
            self.inputView = [WritePadInputView sharedInputPanel];
            break;
            
        case InputSystem_WriteAnywhere :
            // set Ink Collector as the top most view and assign the dummy input panle to input view
            self.inputView = [DummyInputView sharedDummyInputPanel];
            // TODO: you should add ink view to the supervierw of the text editor and resize it based on the desired writing area
            inkCollector.frame = self.frame;
            [self.superview insertSubview:inkCollector belowSubview:[SuggestionsView sharedSuggestionsView]];
            break;
            
        case InputSystem_Keyboard :
        default :
            self.inputView = nil;
            break;
    }
    //[self becomeFirstResponder];
}

- (BOOL) becomeFirstResponder
{
    if ( inputSystem == InputSystem_InputPanel )
    {
        [[WritePadInputView sharedInputPanel].inkCollector shortcutsEnable:YES
                                                                  delegate:self uiDelegate:self.delegate];
        [WritePadInputView sharedInputPanel].delegate = self;
    }
    [SuggestionsView sharedSuggestionsView].suggestions_delegate = self;
	return [super becomeFirstResponder];
}

- (BOOL) resignFirstResponder
{
    [self hideSuggestions];
	if ( [super resignFirstResponder] )
	{
        if ( [self isEqual:[WritePadInputView sharedInputPanel].delegate] )
        {
            [WritePadInputView sharedInputPanel].delegate = nil;
            [[WritePadInputView sharedInputPanel].inkCollector shortcutsEnable:NO delegate:nil uiDelegate:nil];
        }
        if ( [self isEqual:[SuggestionsView sharedSuggestionsView].suggestions_delegate] )
            [SuggestionsView sharedSuggestionsView].suggestions_delegate = nil;
		return YES;
	}
	return NO;
}

#pragma mark -- Functions to add/delete/select text

- (void) appendEditorString:(NSString *)string
{
    if ( [string length] > 0 )
    {
        UITextRange * range = [self selectedTextRange];
        [self replaceRange:range withText:string];
        [self scrollRangeToVisible:self.selectedRange];
    }
	[[WritePadInputView sharedInputPanel] empty];
}

- (UITextRange *)frameOfTextRange:(NSRange)range
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *start = [self positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [self positionFromPosition:start offset:range.length];
    UITextRange *textRange = [self textRangeFromPosition:start toPosition:end];
    return textRange;
}

- (void) backspaceEditor
{
    UITextRange * selRange = self.selectedTextRange;
    
	UITextPosition * minusOnePosition = [self positionFromPosition:selRange.start offset:(-1)];
	selRange = [self textRangeFromPosition:minusOnePosition toPosition:selRange.start];
    
    [self replaceRange:selRange withText:@""];
}

- (void) WritePadInputPanelResultReady:(WritePadInputPanel*)inkView theResult:(NSString*)string
{
    [self unmarkText];
    [self setMarkedText:string selectedRange:NSMakeRange( 0, [string length]-1 )];
    [self scrollRangeToVisible:self.selectedRange];
    self.selectedRange = NSMakeRange( self.selectedRange.location + [string length], 0 );
    [inkView.inputPanel empty];
}

- (UIView *) writePadInputPanelPositionAltPopover:(CGRect *)pRect
{
	CGRect rText = *pRect;
	UIView * view = ((UIViewController *)self.delegate).view;
	CGRect svr = view.superview.frame;
	rText.origin.y += (svr.size.height + svr.origin.y) - kInputPanelHeight;
	rText.origin.x -= svr.origin.x;
	*pRect = rText;
	return (UIView *)view.superview;
}

- (void) selectTextFromPosition:(CGPoint)from toPosition:(CGPoint)to
{
    // TODO: select text from X1:Y1 to X2:Y2 or do something else
    UITextPosition * pf = [self closestPositionToPoint:from];
    UITextPosition * pt = [self closestPositionToPoint:to];
    UITextRange * range = [self textRangeFromPosition:pf toPosition:pt];
    self.selectedTextRange = range;
}

#pragma mark -- Shortcut Delegate Functions

- (BOOL) ShortcutsRecognizedShortcut:(Shortcut*)sc withGesture:(GESTURE_TYPE)gesture offset:(NSInteger)offset
{
	NSLog( @"ShortcutsRecognizedShortcut:%@ withGesture:0x%08X", sc.name, gesture );
	if ( gesture == GEST_NONE )
	{
		[self appendEditorString:sc.text];
		if ( sc.offset < 0 && (int)self.selectedRange.location + sc.offset >= 0 )
		{
            NSRange range = self.selectedRange;
            range.length = 0;
			range.location += sc.offset;
			self.selectedRange = range;
		}
		return TRUE;
	}
	return [self WritePadInputPanelRecognizedGesture:[WritePadInputView sharedInputPanel].inkCollector withGesture:gesture isEmpty:YES];
}

- (NSString *) ShortcutGetSelectedText:(Shortcut *)sc withGesture:(GESTURE_TYPE)gesture offset:(NSInteger)offset
{
    UITextRange * tr = self.selectedTextRange;
    sc.text = @"";
    if ( tr != nil )
    {
        NSString * str = [self textInRange:tr];
        if ( str != nil )
            sc.text = str;
    }
	return sc.text;
}

#pragma mark -- Function to Position cursor and Select text using screen coordinates

- (void) processTouchAndHoldAtLocation:(CGPoint)location
{
    // TODO: optinal: show popup menu or do something else
    location.y += self.contentOffset.y;
    UITextPosition * pos = [self closestPositionToPoint:location];
    UITextRange * range = [self textRangeFromPosition:pos toPosition:pos];
    self.selectedTextRange = range;

	UIMenuController * menu = [UIMenuController sharedMenuController];
    CGRect rect = CGRectMake(location.x, location.y, 0, 0);
	[menu setTargetRect:rect inView:self];
	menu.arrowDirection = UIMenuControllerArrowDefault;
    [menu setMenuVisible:YES animated:YES];
    [self hideSuggestions];
}

- (void)tapAtLocation:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Places cursor at location coordinates or do something else
    UITouch  *	touch =  [touches anyObject];
    UITextPosition * pos = [self closestPositionToPoint:[touch locationInView:self]];
    UITextRange * range = [self textRangeFromPosition:pos toPosition:pos];
    self.selectedTextRange = range;
    [self hideSuggestions];
}


#pragma mark -- Scroll text Up and Down

-(void) doScroll:(Boolean)up yOffset:(NSInteger)y
{
	CGRect bounds = [self bounds];
	
	CGPoint offset = self.contentOffset;
    CGFloat t = offset.y;
    
	if ( y == 0 )
		offset.y += ((up) ? (3*bounds.size.height)/4 : (-(3*bounds.size.height)/4));
	else
		offset.y += y;
	if ( offset.y < 0 || (self.contentSize.height <= bounds.size.height) )
	{
		offset.y = 0;
	}
	else
	{
		bounds.size.height -= kBottomOffset;
		if ( offset.y > (self.contentSize.height - bounds.size.height) )
			offset.y = (self.contentSize.height - bounds.size.height);
	}
    if ( fabs( t-offset.y) <= 1.0 )
        return;
	[self setContentOffset:offset animated:YES];
   
}

- (void) scrollToVisible
{
    [self scrollRangeToVisible:self.selectedRange];
}


#pragma mark -- WriteAnywhere Delegate Functions

- (void) InkCollectorResultReady:(InkCollectorView*)inkView theResult:(NSString*)string
{
    [self unmarkText];
    NSString * text = string;
    if ( text && [text rangeOfString:@kEmptyWord].location == NSNotFound )
    {
        [self setMarkedText:text selectedRange:NSMakeRange( 0, [text length] )];
        self.selectedRange = NSMakeRange( self.selectedRange.location + [text length], 0 );
        
        NSLog( @"%@", self.markedTextRange );
        [self scrollRangeToVisible:self.selectedRange];

        CGRect f = self.frame;
        CGRect rPos = [self caretRectForPosition:[self.selectedTextRange end]];
        rPos = CGRectOffset( rPos, -self.contentOffset.x, -self.contentOffset.y );
        [[SuggestionsView sharedSuggestionsView] showResultsInRect:rPos inFrame:f];
    }
	// [self appendEditorString:string];
}

- (void) InkCollectorAsyncResultReady:(InkCollectorView*)inkView theResult:(NSString*)string
{
    [[SuggestionsView sharedSuggestionsView] showResultsInRect:self.bounds inFrame:self.bounds];
}

- (BOOL) InkCollectorRecognizedGesture:(InkCollectorView*)inkView withGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty
{
    // TODO: you may choose to support add or remove support for some gesture depending on app implementation
    [self hideSuggestions];
    switch( gesture )
    {
        case GEST_RETURN :
            if ( bEmpty  )
            {
                [self appendEditorString:@"\n"];
            }
            else
            {
                [inkView recognizeNow];
            }
            break;
                        
 		case GEST_SPACE :
			if ( bEmpty )
			{
				[self appendEditorString:@" "];
				return NO;
			}
			break;
			
		case GEST_TAB :
			if ( bEmpty )
			{
				[self appendEditorString:@"\t"];
				return NO;
			}
			break;
			
		case GEST_UNDO :
			if ( bEmpty )
			{
				//if ( [self.undoManager canUndo] )
                {
                    [self.undoManager undo];
                    return NO;
                }
			}
			break;
			
		case GEST_REDO :
			if ( bEmpty )
			{
				//if ( [self.undoManager canRedo] )
                {
                    [self.undoManager redo];
                    return NO;
                }
			}
			break;
			
		case GEST_CUT :
			if ( ! bEmpty )
			{
				[inkView empty];
				return NO;
			}
			if ( [self canPerformAction:@selector(cut:) withSender:nil] )
				[self cut:nil];
			return NO;
			
		case GEST_COPY :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(copy:) withSender:nil] )
					[self copy:nil];
				return NO;
			}
			break;
			
		case GEST_PASTE :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(paste:) withSender:nil] )
					[self paste:nil];
				return NO;
			}
			break;
			
		case GEST_DELETE :
			break;
			
		case GEST_MENU :
			break;
			
		case GEST_SPELL :
			break;
			
		case GEST_CORRECT :
			break;
			
		case GEST_SELECTALL :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(selectAll:) withSender:nil] )
					[self selectAll:nil];
				return NO;
			}
			break;
			
		case GEST_SCROLLDN :
            [self doScroll:NO yOffset:0];
			break;
			
		case GEST_SCROLLUP :
            [self doScroll:YES yOffset:0];
			break;
			
		case GEST_BACK :
		case GEST_BACK_LONG :
			if ( GEST_BACK_LONG == gesture && (!bEmpty) )
			{
				[inkView deleteLastStroke];
				return NO;
			}
			else if ( bEmpty )
			{
				[self backspaceEditor];
				return NO;
			}
			break;
			
		case GEST_LOOP :
			break;
			
		case GEST_SENDMAIL :
			break;
			
		case GEST_OPTIONS :
			break;
			
		case GEST_SENDTODEVICE :
			break;
			
		case GEST_SAVE :
			break;
			
		default :
		case GEST_NONE :
			break;
    }
    return NO;		// DO NOT add stroke...
}

#pragma mark -- Suggestions support

- (void) suggestionsWordSelected:(SuggestionsView*)caller theResult:(NSString *)word spellWord:(NSString *)spellWord
{
    if ( word != nil )
    {
        if ( nil == self.markedTextRange )
        {
            [self appendEditorString:word];
        }
        else
        {
            if ( [word length] == 0 )
            {
                [self replaceRange:self.markedTextRange withText:@""];
            }
            else
            {
                [self replaceRange:self.markedTextRange withText:word];
            }
        }
        [self scrollRangeToVisible:self.selectedRange];
        [self unmarkText];
    }
    [self.inkCollector empty];
    [[WritePadInputView sharedInputPanel] empty];
}

- (BOOL) suggestionsViewShouldTimeout:(SuggestionsView*)caller;
{
    // timeout can be disabled, if needed
    if( ![[NSUserDefaults standardUserDefaults] boolForKey:kRecoOptionsInsertResult] )
        return NO;
    [self unmarkText];
    return YES;
}

- (void) unmarkText
{
    [super unmarkText];
}

- (void) suggestionsCanceled:(SuggestionsView*)caller
{
}

- (void) hideSuggestions
{
    // [self unmarkText];
    SuggestionsView * suggestions = [SuggestionsView sharedSuggestionsView];
	if ( suggestions && (! [suggestions isHidden]) )
        [suggestions showResultsInRect:CGRectNull inFrame:CGRectNull];
}


#pragma mark -- Input panel Delegate Functions

- (void) writePadInputKeyPressed:(WritePadInputView*)inView keyText:(NSString*)string withSender:(id)sender
{
    [self hideSuggestions];
	if ( [string compare:@"\n"] == NSOrderedSame )
	{
		if ( inView.resultView.text != nil )
		{
            [inView.resultView learnNewWords];
			[self appendEditorString:inView.resultView.text];
			return;
		}
	}
	else if ( [string compare:@"\b"] == NSOrderedSame )
	{
		if ( [inView.inkCollector strokeCount] > 0 )
		{
			[inView.inkCollector deleteLastStroke];
		}
		else if ( self.text != nil )
		{
			[self backspaceEditor];
			[[WritePadInputView sharedInputPanel] empty];
		}
		return;
	}
	else if ( [string compare:@" "] == NSOrderedSame )
	{
		if ( [inView.inkCollector strokeCount] > 0 )
		{
			[[WritePadInputView sharedInputPanel] empty];
			return;
		}
	}
	else if ( [string compare:@"."] == NSOrderedSame )
	{
		if ( inView.resultView.text != nil )
		{
			[inView.resultView learnNewWords];
            NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
            NSString * text = [NSString stringWithFormat:@"%@. ", [inView.resultView.text stringByTrimmingCharactersInSet:whitespaceSet]];
			[self appendEditorString:text];
			return;
		}
	}
	[self appendEditorString:string];
}

- (void) WritePadInputPanelAsyncResultReady:(WritePadInputPanel*)inkView theResult:(NSString*)string
{
    [self unmarkText];
    SuggestionsView * suggestions = [SuggestionsView sharedSuggestionsView];
    if ( suggestions ) // [[NSUserDefaults standardUserDefaults] boolForKey:kEditOptionsShowSuggestions] )
    {
        // TODO: position suggestions where most appropriate...
        CGRect f = self.frame;
        CGRect rPos = [self caretRectForPosition:[self.selectedTextRange end]];
        rPos = CGRectOffset( rPos, -self.contentOffset.x, -self.contentOffset.y );
        [suggestions showResultsInRect:rPos inFrame:f];
    }
}

- (void) WritePadInputPanelChangeLanguage:(WritePadInputPanel*)inkView
{
}

- (BOOL) WritePadInputPanelRecognizedGesture:(WritePadInputPanel*)inkView withGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty
{
    [self unmarkText];
	switch( gesture )
	{
		case GEST_RETURN :
			if ( bEmpty )
			{
				[self appendEditorString:@"\n"];
			}
			else if ( inkView.inputPanel.resultView.text != nil )
			{
                NSString * text = inkView.inputPanel.resultView.text;
                if ( text && [text rangeOfString:@kEmptyWord].location == NSNotFound )
                {
                    [self setMarkedText:text selectedRange:NSMakeRange( 0, [text length]-1 )];
                    self.selectedRange = NSMakeRange( self.selectedRange.location + [text length], 0 );
                    [self scrollRangeToVisible:self.selectedRange];
                }
                [inkView.inputPanel empty];
			}
			return NO;
			
        case GEST_TIMEOUT :
            if ( [inkView.inputPanel.resultView.text length] > 0 )
            {
                NSString * text = inkView.inputPanel.resultView.text;
                if ( text && [text rangeOfString:@kEmptyWord].location == NSNotFound )
                {
                    [self setMarkedText:text selectedRange:NSMakeRange( 0, [text length]-1 )];
                    self.selectedRange = NSMakeRange( self.selectedRange.location + [text length], 0 );
                    [self scrollRangeToVisible:self.selectedRange];
                }
                [inkView.inputPanel empty];
            }
            return NO;
            
		case GEST_SPACE :
			if ( bEmpty )
			{
				[self appendEditorString:@" "];
				return NO;
			}
			break;
			
		case GEST_TAB :
			if ( bEmpty )
			{
				[self appendEditorString:@"\t"];
				return NO;
			}
			break;
			
		case GEST_UNDO :
			if ( bEmpty )
			{
				//if ( [self.undoManager canUndo] )
                {
                    [self.undoManager undo];
                    return NO;
                }
			}
			break;
			
		case GEST_REDO :
			if ( bEmpty )
			{
				//if ( [self.undoManager canRedo] )
                {
                    [self.undoManager redo];
                    return NO;
                }
			}
			break;
			
		case GEST_CUT :
			if ( ! bEmpty )
			{
				[[WritePadInputView sharedInputPanel] empty];
                [self hideSuggestions];
				return NO;
			}
			if ( [self canPerformAction:@selector(cut:) withSender:nil] )
				[self cut:nil];
			return NO;
			
		case GEST_COPY :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(copy:) withSender:nil] )
					[self copy:nil];
				return NO;
			}
			break;
			
		case GEST_PASTE :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(paste:) withSender:nil] )
					[self paste:nil];
				return NO;
			}
			break;
			
		case GEST_DELETE :
			break;
			
		case GEST_MENU :
			break;
			
		case GEST_SPELL :
			return NO;
			
		case GEST_CORRECT :
			break;
			
		case GEST_SELECTALL :
			if ( bEmpty )
			{
				if ( [self canPerformAction:@selector(selectAll:) withSender:nil] )
					[self selectAll:nil];
				return NO;
			}
			break;
			
		case GEST_SCROLLDN :
			break;
			
		case GEST_SCROLLUP :
			break;
			
		case GEST_BACK_LONG :
			if ( GEST_BACK_LONG == gesture && (!bEmpty) )
			{
				[inkView deleteLastStroke];
				return NO;
			}
			else if ( bEmpty )
			{
				[self backspaceEditor];
				return NO;
			}
			break;
			
		case GEST_LOOP :
			break;
			
		case GEST_SENDMAIL :
			break;
			
		case GEST_OPTIONS :
			break;
			
		case GEST_SENDTODEVICE :
			break;
			
		case GEST_SAVE :
			break;
			
		default :
        case GEST_BACK :
		case GEST_NONE :
			return YES;
	}
    [self hideSuggestions];
	return YES;		// add stroke...
}

@end
