
#import "NoteTextView.h"
#import "UIConst.h"
#import "OptionKeys.h"
#import "AsyncResultView.h"

////Jixuan
#define DEFAULT_HORIZONTAL_COLOR    [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1.0f]
#define DEFAULT_VERTICAL_COLOR      [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]

@implementation NoteTextView

@synthesize inkCollector;
@synthesize inputSystem;


+ (NoteTextView *) createTextView:(CGRect)frame
{
    NoteTextView * textView = [[NoteTextView alloc] initWithFrame:frame];

    textView.opaque = NO;
    textView.font = [UIFont fontWithName:@"Arial" size:20.0];
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
    if (self == [NoteTextView class]) {
        id appearance = [self appearance];
        [appearance setContentMode:UIViewContentModeRedraw];
        [appearance setHorizontalLineColor:DEFAULT_HORIZONTAL_COLOR];
        [appearance setVerticalLineColor:DEFAULT_VERTICAL_COLOR];
    }
}


/////////////////////////////////////////////////jixuan

#pragma mark - Superclass overrides

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, _lineWidth);
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:90.0/255.0 green:200.0/255.0 blue:250.0/255.0 alpha:0.6] CGColor]);
    //CGContextSetRGBStrokeColor(context, 255, 0, 0, 1);
    CGFloat dashes[] = {5,6};
    CGContextSetLineDash(context, 2.0, dashes, 2);
    
    if (self.horizontalLineColor) {
        CGContextBeginPath(context);
        //CGContextSetStrokeColorWithColor(context, self.horizontalLineColor.CGColor);
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
        NSInteger firstVisibleLine = MAX(1, (self.contentOffset.y / (self.font.lineHeight+_lineSpace)));
        NSInteger lastVisibleLine = ceilf((self.contentOffset.y + self.bounds.size.height) / self.font.lineHeight);
        
        for (NSInteger line = firstVisibleLine; line <= lastVisibleLine; line++) {
            CGFloat linePointY = baseOffset + self.font.lineHeight  * line + _lineSpace*(line-1) ;//+ kFactor;
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
        CGContextMoveToPoint(context, -_lineWidth + self.textContainerInset.left, self.contentOffset.y);
        CGContextAddLineToPoint(context, -_lineWidth + self.textContainerInset.left, self.contentOffset.y + self.bounds.size.height);
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
}


- (CGRect)caretRectForPosition:(UITextPosition *)position {
    CGRect originalRect = [super caretRectForPosition:position];
    originalRect.size.height = _fontSize;
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


- (void) initTextViewWithoutFrame
{
    self.fontSize = 22.0f;
    self.lineWidth = 1.0f;
    self.lineSpace = 10.0f;
    NoteTextView * textView = self;
    inputSystem = InputSystem_Default;
    
    // create full screen ink collector
    // create ink collector control
    // Create a Quartz View to embed later with a dummy rect for now.
    inkCollector = [[NoteInkController alloc] initWithFrame:self.frame];
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
    _lineWidth = _lineWidth / screen.scale;
    _lineSpace = _lineSpace / screen.scale;
    /// style
    textView.textContainerInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    
    //[self appendAttributedString:@"asdfasdf\nsdfasdfasdf\nasdfasdfasd\nadfasdfas"];
//    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//    style.lineSpacing = _lineSpace;
//    self.attributedText = [[NSAttributedString alloc]
//                           initWithString:@"jhgjhgjhgjg\ngjhgjhgjhgjhgjhgjhgj"
//                           attributes:@{NSParagraphStyleAttributeName : style}];
//    
//    [self setFont: [UIFont fontWithName:@"Arial" size:_fontSize]];
//    UIFont *font = self.font;
//    self.font = nil;
//    self.font = font;
    
    self.textContainerInset = UIEdgeInsetsMake(40.0f, 0.0f, 0.0f, 0.0f);
    //self.editable = NO;
    
    self.paragraphs = [[NSMutableArray alloc] init];
    [self.paragraphs addObject:@"Subjective"];
    [self showParagraphs];
}

- (void) appendAttributedString:(NSString*) s
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = _lineSpace;
    self.attributedText = [[NSAttributedString alloc]
                           initWithString:s
                           attributes:@{NSParagraphStyleAttributeName : style}];
    [self setFont: [UIFont fontWithName:@"Arial" size:_fontSize]];
    UIFont *font = self.font;
    self.font = nil;
    self.font = font;
}

////////////////////////////////////////////////////////////////////end jixuan

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
	{
        self.fontSize = 18.0f;
        self.lineWidth = 2.0f;
        self.lineSpace = 25.0f;
		inputSystem = InputSystem_Default;
        
        // create full screen ink collector
		// create ink collector control
		// Create a Quartz View to embed later with a dummy rect for now.
		inkCollector = [[NoteInkController alloc] initWithFrame:self.frame];
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
        
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.returnKeyType = UIReturnKeyDefault;
        self.autoresizesSubviews = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
        
        /////jixuan
        /// for background lines
        UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
        _lineWidth = _lineWidth / screen.scale;
        _lineSpace = _lineSpace / screen.scale;
        /// style
        self.textContainerInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        
//        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//        style.lineSpacing = _lineSpace;
//        self.attributedText = [[NSAttributedString alloc]
//                               initWithString:@"jhgjhgjhgjg\ngjhgjhgjhgjhgjhgjhgj"
//                               attributes:@{NSParagraphStyleAttributeName : style}];
//        
//        [self setFont: [UIFont fontWithName:@"Arial" size:_fontSize]];
//        UIFont *font = self.font;
//        self.font = nil;
//        self.font = font;
        
        self.textContainerInset = UIEdgeInsetsMake(40.0f, 0.0f, 0.0f, 0.0f);
        //self.editable = NO;
        
        self.paragraphs = [[NSMutableArray alloc] init];
        [self.paragraphs addObject:@"This is the first paragrah, hahahahahhhahahahahhahahahahhahahahahahhahahahahahahahahahahajfoaisdjfoaishfiohweofihaisduhflasdjflkajsdfhahahahahhahahahahhahahahahahhahahahahahahahahahahajfoaisdjfoaishfiohweofihaisduhflasdjflkajsdf"];
        [self.paragraphs addObject:@"This is the second paragrah, hahahahahhhahahahahhahahahhhahahahahahahahahahahajfoaisdjfoaishfiohweofihaisduhflasdjflkajsdf"];
        [self.paragraphs addObject:@"This is the Third paragrah, ahahahahahahahaasdjflkajsdf"];
        [self showParagraphs];
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
    UIView* emptyKeyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
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
            
        case InputSystem_NoKeyboard:
            self.inputView = emptyKeyView;
            break;
        case InputSystem_Keyboard :
        default :
            self.inputView = nil;
            break;
    }
    [self becomeFirstResponder];
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
    int touchline = [self lineByPosition:[touch locationInView:self]];
    //[self.layoutManager ensureLayoutForTextContainer:self.textContainer];
    //CGRect endPosition = [self firstRectForRange: [self textRangeFromPosition:self.endOfDocument toPosition:self.endOfDocument] ];
    int endline = self.contentSize.height / (self.lineSpace + self.font.lineHeight);
    if(touchline > endline){
        for (int i = 0; i < (touchline - endline); ++i){
            [self appendEditorString:@"\n"];
            UITextRange * range = [self textRangeFromPosition:self.endOfDocument toPosition:self.endOfDocument];
            self.selectedTextRange = range;
        }
    }else{
        UITextPosition * pos = [self closestPositionToPoint:[touch locationInView:self]];
        UITextRange * range = [self textRangeFromPosition:pos toPosition:pos];
        self.selectedTextRange = range;
    }
    
    

    [self hideSuggestions];
}

- (void) setTextLocation:(CGPoint) pointInTextView startOrEnd:(BOOL)startOrEnd{
    
    if(startOrEnd){
        self.startSelTextPos = [self closestPositionToPoint:pointInTextView];
        UITextRange * range = [self textRangeFromPosition:self.startSelTextPos toPosition:self.startSelTextPos];
        self.selectedTextRange = range;
    }else{
        [self becomeFirstResponder];
        self.endSelTextPos = [self closestPositionToPoint:pointInTextView];
        UITextRange * range = [self textRangeFromPosition:self.startSelTextPos toPosition:self.endSelTextPos];
        [self setSelectedTextRange:range];
    }
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

- (void) InkCollectorResultReady:(NoteInkController*)inkView theResult:(NSString*)string
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

- (void) InkCollectorAsyncResultReady:(NoteInkController*)inkView theResult:(NSString*)string
{
    [[SuggestionsView sharedSuggestionsView] showResultsInRect:self.bounds inFrame:self.bounds];
}

- (BOOL) InkCollectorRecognizedGesture:(NoteInkController*)inkView withGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty
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
- (id <NotePopover>)popoverWithViewController:(UIViewController *)viewController
{
    id <NotePopover> popover;
    
    if (!popover)
    {
        //popover = (id<NotePopover>) [[NoteCustomPopover alloc] initWithContentViewController:viewController];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            UIPopoverController* uu = [[UIPopoverController alloc] initWithContentViewController:viewController];
             //uu.backgroundColor = [UIColor colorWithRed:20 green:146 blue:255 alpha:1];
            popover = (id<NotePopover>) uu;
        }
        else
        {
            popover = (id<NotePopover>) [[NoteCustomPopover alloc] initWithContentViewController:viewController];

        }
    }
    
    [self.popover dismissPopoverAnimated:NO];
    self.popover = popover;
    
    return popover;
}

- (void) showPopMenu:(CGRect) fromRect inView:(UIView*)inView
{
    NotePopupController *textStylePopup= [[NotePopupController alloc] init];
    textStylePopup.delegate = self;
    //textStylePopup.dataSource = self;
    // textStylePopup.contentSizeForViewInPopover = CGSizeMake(200, 250);
    textStylePopup.preferredContentSize = CGSizeMake(400, 30);
    id <NotePopover> popover = [self popoverWithViewController:textStylePopup];
    [popover presentPopoverFromRect:fromRect inView:inView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

-(void) popupRect:(CGRect) rt{
    self.insertPosi = rt;
    [self showPopMenu:rt inView:self];
}

-(void) openStyle
{
    CGPoint start = self.inkCollector.ptStroke[0].pt;
    CGPoint end = self.inkCollector.ptStroke[self.inkCollector.strokeLen-1].pt;
//    UITextRange * selectionRange = [self selectedTextRange];
//    CGRect end = [self caretRectForPosition:selectionRange.end];
    CGRect rt = CGRectMake( (start.x+end.x)/2, (start.y+end.y)/2, 0, 0);
    self.insertPosi = rt;
    [self showPopMenu:rt inView:self];
}

- (void) NotePopupControllerDidSelect:(POPBUTTON_TYPE) btn
{
    [self.popover dismissPopoverAnimated:NO];
    switch (btn) {
        case keyboard:
            [self setInputMethod: InputSystem_Keyboard];
             [self.noteDelegate selectKeyboard];
            break;
        case paint:
            [self.noteDelegate selectPaint];
            break;
        case edit:
            [self.noteDelegate selectEdit];
            break;
        case camera:
        case photo:
            [self.noteDelegate selectCameraOrPhoto];
            break;
        case video:
            
            break;
        case stylus:
            [self setInputMethod: InputSystem_WriteAnywhere];
            [self.noteDelegate selectStylus];
            break;
        default:
            break;
    }
}
- (BOOL) InkCollectorRecognizedShape:(NoteInkController *)inkView withShape:(SHAPETYPE)gesture isEmpty:(BOOL)bEmptys
{
    [self unmarkText];
    switch (gesture) {
        case SHAPE_UNKNOWN:
            NSLog(@"SHAPE_UNKNOWN");
            break;
        case SHAPE_TRIANGLE:
            break;
        case SHAPE_CIRCLE:
        case SHAPE_ELLIPSE:
            
            break;
        case SHAPE_RECTANGLE:
            NSLog(@"SHAPE_RECTANGLE");
            break;
        case SHAPE_LINE:
        {
            [self openStyle];
        }

            break;
        case SHAPE_ARROW:
            NSLog(@"SHAPE_ARROW");
            break;
        case SHAPE_SCRATCH:
            NSLog(@"SHAPE_SCRATCH");
            break;
        case SHAPE_ALL:
            NSLog(@"SHAPE_ALL");
            break;
            
        default:
            break;
    }
    return NO;
}

- (BOOL) WritePadInputPanelRecognizedShape:(WritePadInputPanel *)inkView withGesture:(SHAPETYPE)shape isEmpty:(BOOL)bEmpty
{
    [self unmarkText];
    switch (shape) {
        case SHAPE_UNKNOWN:
            NSLog(@"SHAPE_UNKNOWN");
            break;
        case SHAPE_TRIANGLE:
            NSLog(@"SHAPE_TRIANGLE");
            break;
        case SHAPE_CIRCLE:
            NSLog(@"SHAPE_CIRCLE");
            break;
        case SHAPE_ELLIPSE:
            NSLog(@"SHAPE_ELLIPSE");
            break;
        case SHAPE_RECTANGLE:
            NSLog(@"SHAPE_RECTANGLE");
            break;
        case SHAPE_LINE:
            NSLog(@"SHAPE_LINE");
            break;
        case SHAPE_ARROW:
            NSLog(@"SHAPE_ARROW");
            break;
        case SHAPE_SCRATCH:
            NSLog(@"SHAPE_SCRATCH");
            break;
        case SHAPE_ALL:
            NSLog(@"SHAPE_ALL");
            break;
            
        default:
            break;
    }
    return NO;
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

#pragma mark - prepare note paragraphs

- (int) lineByPosition: (CGPoint)pt{
    int line = (pt.y + self.contentOffset.y) / (self.font.lineHeight+_lineSpace) + 1;
    NSLog(@"in line:   %d", line);
    return line;
}

- (void) showParagraphs
{
    NSString* texts = @"";
    for (int p = 0; p < [self.paragraphs count]; ++p)
    {
        texts = [texts stringByAppendingString:[self.paragraphs objectAtIndex:p]];
        texts = [texts stringByAppendingString:@"\n"];
        
        [self appendAttributedString:texts];
        CGRect endPosition = [self firstRectForRange: [self textRangeFromPosition:self.endOfDocument toPosition:self.endOfDocument] ];
        NSLog(@"Paragraph [ %d ] ends at line [ %d ]", p, [self lineByPosition: endPosition.origin]-1);
        
    }
}

- (void) initSubjective
{
    self.paragraphs = [[NSMutableArray alloc] init];
    [self.paragraphs addObject:@"Subjective\n"];
    [self.paragraphs addObject:@"Name: Mr. ABC"];
    [self.paragraphs addObject:@"Date of Birth: 12/12/1912\n"];
    [self.paragraphs addObject:@"CHIEF COMPLAINT:"];
    [self.paragraphs addObject:@"Headache, nausea, vomiting, and diarhea.\n"];
    [self.paragraphs addObject:@"HISTORY OF PRESENT ILLNESS:"];
    [self.paragraphs addObject:@"This 62 yo female with a PMH notable for TTP in 1996 who presents with intermittent dizziness, nausea, vomiting, and diarrhea of about 1 week duration. Over this period of time, she has been unable to take in any significant PO intake without vomiting. Her dizziness and lightheadedness are most notable when she stands up, and she has difficulty maintaining her balance due to this. She also notes that has been very tired for this past week, spending approximately 20 hours per day in bed sleeping. She denies pain, headache, fevers, chills, SOB, chest pain, hematemesis, bloody stool, tarry stool, dysuria, hematuria, and increased bleeding or bruising. The patient is unable to provide further details or further describe her symptoms, and has no idea what might be causing them.  She does deny any recent sick contacts, eating any new or abnormal foods, eating any potentially raw meats, and drinking large amounts of tonic water, or anything else that contains quinine.\n"];
    [self.paragraphs addObject:@"FAMILY HISTORY:"];
    [self.paragraphs addObject:@"Both of her parents are dead, but she does not remember how old they were when they died. Her father had COPD and coronary artery disease. Mother had diabetes and stoke.  One of her siblings has congenital deftness. Another sibling has adult onset diabetes.\n"];
    
    
    
    [self showParagraphs];
}

-(void)initObjective
{
    self.paragraphs = [[NSMutableArray alloc] init];
    [self.paragraphs addObject:@"Objective\n"];
    [self.paragraphs addObject:@"PHYSICAL EXAMINATION:"];
    [self.paragraphs addObject:@"Vital Signs – temp 36.5°C, BP 159/76, pulse 58, RR 18, 98% on RA, weight 105 kg, height 166 cm, BMI 38."];
    [self.paragraphs addObject:@"General – Pleasant, obese 62 year old female currently in no apparent distress."];
    [self.paragraphs addObject:@"Lymph nodes – No periauricular, cervical, supraclavicular, axillary lymphadenectomy."];
    [self.paragraphs addObject:@"Neck – Neck supple. Trachea midline. Thyroid gland normal and nontender. No carotid bruits. Difficult to assess for JVD secondary to body habitus."];
    [self.paragraphs addObject:@"Heart – Normal S1 and S2. Regular rate and rhythm with no rubs, murmurs, or gallops. PMI normal.\n"];
    [self.paragraphs addObject:@"LABORATORY DATA:"];
    [self.paragraphs addObject:@"Peripheral Blood Smear: 5% of RBCs are shistocytes (28 per high power field). One target-cell seen. Large platelets and clumping of platelets."];
    [self.paragraphs addObject:@"Urine Electrolytes: "];
    [self.paragraphs addObject:@"94 sodium, 16 potassium, 88 chloride, 50 creatinine. FENA is 18%"];
    
    
    [self showParagraphs];
}
-(void)initAssessment
{
    self.paragraphs = [[NSMutableArray alloc] init];
    [self.paragraphs addObject:@"Assessment\n"];
    [self.paragraphs addObject:@"Diagnostic Pentad:"];
    [self.paragraphs addObject:@"Microangiopathic hemolytic anemia-This patient has a hemolytic anemia with a significant shistocytosis. The average shishtocytosis in TTP is 8.45% (with a range of 1% to 18%); her shistocytosis was 5%. Her elevated LDH is also confirmatory of her shistocytosis. On her admission for TTP in 1996, her renal biopsy showed a thrombotic microangioma. Repeating renal biopsy would cause unnecessary morbidity in this case since the diagnosis is already quite certain."];
    
    [self.paragraphs addObject:@"Thrombocyopenia, often with purpura-This patient does have a significant thrombocytopenia, with a platelet count of 66. In addition large platelets and clumping of platelets were noted on the peripheral blood smear, but of which are indicative of TTP. Some purpura were noted on physical exam, but they were not particularly prominent."];
    
    [self.paragraphs addObject:@"Fever-The patient has been afebrile by history and has not had a fever in her first several hours in the hospital.\n"];
    
    [self.paragraphs addObject:@"Differential Diagnosis:"];
    
    [self.paragraphs addObject:@"The main other diagnosis to consider in this clinical picture is diffuse intravascular coagulation (DIC). This diagnosis has been ruled out with a DIC screen that showed slightly elevated fibrinogen levels and undetectable levels of fragmented D-dimer. The presence of normal (or slightly above normal in this case) shows that fibrinogen is not being consumed by DIC, and the absence of D-dimer also shows that the coagulation pathway is not actively taking place in this patient."];
    
    [self showParagraphs];

}
-(void)initPlan
{
    self.paragraphs = [[NSMutableArray alloc] init];
    [self.paragraphs addObject:@"Plan\n"];
    [self.paragraphs addObject:@"(1) Treatment for TTP is plasmapheresis and administration of fresh frozen plasma (FFP). One randomized trial has shown this therapy to increase survival from 50% to 78% in patients with TTP (N Engl J Med 1991 Aug 8;325(6):393-7). A vascath has been placed in the patient’s femoral vein, and she will receive plasmapheresis once a day, along with daily administration of FFP\n"];
    [self.paragraphs addObject:@"(2) This patient has acute renal failure, with a BUN of 119 and a creatinine of 13.6, on top of her preexisting chronic renal insufficiency (baseline creatinine is 1.7). The cause of this renal failure is TTP, so it will be treated by treating the underlying TTP, as described above. In addition, the patient’s Lasix, Atenolol, and Norvasc are being held.  These drug are being held both because they can impair renal function during episodes of acute renal failure, and because, in the setting of the large volume shifts associated with plasmaphoresis, they may complicate the clinical picture and make assessment of the patient’s fluid status more difficult. Norvasc will be restarted if the patient becomes significantly hypertensive, and lasix can be administered if she develops pulmonary edema."];
    [self.paragraphs addObject:@"(3) The patient’s diarrhea appears to be fairly mild, and it is not among her most significant complaints. It does not appear to be causing excessive volume loss or any electrolyte abnormalities. As described above, fecal samples have been sent for fecal leukocytes, culture, fecal parasite screen, and C. dificil toxin. If a treatable cause of her diarrhea is found, it will be treated appropriately."];
    [self showParagraphs];
}


@end
