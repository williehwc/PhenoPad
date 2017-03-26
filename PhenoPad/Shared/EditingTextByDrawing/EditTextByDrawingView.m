

#include <AudioToolbox/AudioToolbox.h>
#import "EditTextByDrawingView.h"
#import "OptionKeys.h"
#import "UIConst.h"
#import "RectObject.h"
#import "LanguageManager.h"
#import "RecognizerManager.h"
#import "WritePadInputPanel.h"
#import "WPTextView.h"
#import "utils.h"

CGPoint startSelTextPos;
int numberOfPoints;

@interface EditTextByDrawingView (){
    BOOL bSetStartSelText;
}

- (void) updateDisplayInThread:(RectObject *)rObject;
- (void) killRecoTimer;
- (void) killHoldTimer;
- (BOOL) enableAsyncInk:(BOOL)bEnable;
- (int)  addPointPoint:(CGPoint)point;
- (void) addPointToQueue:(CGPoint)point;
- (void) processEndOfStroke:(BOOL)fromThread;
- (int) AddPixelsX:(int)x Y:(int)y pressure:(int)pressure IsLastPoint:(BOOL)bLastPoint;

@property (nonatomic, copy ) NSString * currentResult;

@end

static DummyInputView * sharedDummyInputView = nil;

@implementation EditTextByDrawingView

@synthesize delegate;
@synthesize recognitionDelay;
@synthesize autoRecognize;
@synthesize strokeWidth;
@synthesize edit;
@synthesize backgroundReco;
@synthesize strokeColor;
@synthesize shortcuts;
@synthesize CurrPopover;
@synthesize asyncInkCollector = _bAsyncInkCollector;
@synthesize placeholder1;
@synthesize placeholder2;
@synthesize strokeLen;
@synthesize ptStroke;
@synthesize isStylus;

@synthesize currentResult;

#define STROKE_FILTER_TIMEOUT		1.0
#define STROKE_FILTER_DISTANCE		200


+ (void) ensureDefaultSettings:(Boolean)force
{
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];
    BOOL b = [defaults boolForKey:kRecoOptionsFirstStartKey];
    if ( b != YES || force )
    {
        // init default settings
        [defaults setBool:NO  forKey:kRecoOptionsSingleWordOnly];
        [defaults setBool:NO  forKey:kRecoOptionsSeparateLetters];
        [defaults setBool:NO  forKey:kRecoOptionsInternational];
        [defaults setBool:NO  forKey:kRecoOptionsDictOnly];
        [defaults setBool:NO  forKey:kRecoOptionsSuggestDictOnly];
        [defaults setBool:YES forKey:kRecoOptionsDrawGrid];
        [defaults setBool:NO  forKey:kRecoOptionsSpellIgnoreNum];
        [defaults setBool:NO  forKey:kRecoOptionsSpellIgnoreUpper];
        [defaults setBool:YES forKey:kRecoOptionsUseCorrector];
        [defaults setBool:YES forKey:kRecoOptionsUseUserDict];
        [defaults setBool:YES forKey:kRecoOptionsUseLearner];
        [defaults setBool:NO forKey:kRecoOptionsErrorVibrate];
        [defaults setBool:NO forKey:kEditOptionsAutocapitalize];
        [defaults setBool:NO forKey:kPhatPadOptionsPalmRest];
        [defaults setBool:NO forKey:kEditOptionsAutospace];
        [defaults setInteger:DEFAULT_BACKGESTURELEN forKey:kRecoOptionsBackstrokeLen];
        [defaults setFloat:DEFAULT_PENWIDTH forKey:kRecoOptionsInkWidth];
        [defaults setFloat:DEFAULT_RECODELAY forKey:kRecoOptionsTimerDelay];
        
        // init default settings
        [defaults setBool:NO forKey:kEditOptionsShowSuggestions];
        [defaults setBool:NO forKey:kEditEnableSpellChecker];
        [defaults setBool:YES forKey:kEditEnableTextAnalyzer];
    }
}

- (id) initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        isStylus = true;
        strokeLen = 0;
        strokeMemLen = DEFAULT_STROKE_LEN * sizeof( CGTracePoint );
        ptStroke = malloc( strokeMemLen );
        strokeWidth = DEFAULT_PENWIDTH;
        inkData = INK_InitData();
        recognitionDelay = 0.5;//DEFAULT_RECODELAY;
        _timerRecognizer = nil;
        _timerTouchAndHold = nil;
        gesturesEnabledIfEmpty = GEST_NONE;
        gesturesEnabledIfData = GEST_NONE;
        bSetStartSelText = NO;
        
        _bAddStroke = YES;
        backgroundReco = YES;
        _firstTouch = NO;
        _bSendTouchToEdit = NO;
        self.multipleTouchEnabled = NO;
        _bSelectionMode = NO;
        _nAdded = 0;
        _bAsyncInkCollector = NO;
        _inkQueueCondition = [[NSCondition alloc] init];
        _inkLock = [[NSLock alloc] init];
        _useAsyncRecognizer = YES;      // TODO: this can be disabled, if not needed
        self.currentResult = nil;
        edit = nil;
        
        _currentStrokeView = [[InkCurrentStrokeView alloc] initWithFrame:[self bounds]];
        _currentStrokeView.inkView = self;
        _currentStrokeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_currentStrokeView];
        
        // default ink color
        self.strokeColor = [UIColor colorWithRed:0.0 green:0.2 blue:1.0 alpha:1.0];
        
        // init recognizer options
        NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];
        BOOL b = [defaults boolForKey:kRecoOptionsFirstStartKey];
        if ( b != YES )
        {
            [EditTextByDrawingView ensureDefaultSettings:YES];
        }
        else
        {
            strokeWidth = [defaults floatForKey:kRecoOptionsInkWidth];
            if ( strokeWidth < 1.0 )
                strokeWidth = DEFAULT_PENWIDTH;
            recognitionDelay = [defaults floatForKey:kRecoOptionsTimerDelay];
            if ( recognitionDelay < MIN_DELAY || recognitionDelay > 5 * DEFAULT_TOUCHANDHOLDDELAY )
            {
                recognitionDelay = DEFAULT_RECODELAY;
                [defaults setFloat:recognitionDelay forKey:kRecoOptionsTimerDelay];
            }
        }
        
        // placeholder
        //self.placeholder1 = [NSString stringWithString:NSLocalizedString( @"Write Something", @"")];
        //self.placeholder2 = [NSString stringWithString:NSLocalizedString( @"to edit document", @"")];
        
        // Init shorctus
        shortcuts = [[Shortcuts alloc] init];
        
        self.multipleTouchEnabled = NO;
        
//        UIMenuItem *highLightItem = [[UIMenuItem alloc] initWithTitle:@"Style" action:@selector(openStyle)];
//        [[UIMenuController sharedMenuController] setMenuItems:@[highLightItem]];
//        UIMenuItem *highLightItem = [[UIMenuItem alloc] initWithTitle:@"HHHHHHHH" action:@selector(openStyle)];
//           [[UIMenuController sharedMenuController] setMenuItems:@[highLightItem]];
    }
    return self;
}

/*
 - (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
 {
	SET_CURR_POPOVER( nil );
 }
 */

#pragma mark AsyncInkCollector

- (BOOL) enableAsyncInk:(BOOL)bEnable
{
    // can't disable async ink if async reco is enabled
    if ( (!bEnable) && _bAsyncInkCollector )
    {
        // terminate ink thread
        if ( ! [_inkLock tryLock] )
        {
            _runInkThread = NO;
            [self addPointToQueue:CGPointMake( 0,0 )];
            [_inkLock lock];
        }
        [_inkLock unlock];
        _bAsyncInkCollector = NO;
    }
    else if ( bEnable && (!_bAsyncInkCollector)  )
    {
        _runInkThread = YES;
        [NSThread detachNewThreadSelector:@selector(inkCollectorThread:) toTarget:self
                               withObject:nil];
        _bAsyncInkCollector = YES;
    }
    _inkQueueGet = _inkQueuePut = 0;
    _bAddStroke = YES;
    // [[NSUserDefaults standardUserDefaults] setBool:_bAsyncInkCollector forKey:kRecoOptionsAsyncInking];
    return _bAsyncInkCollector;
}

- (void)inkCollectorThread :(id)anObj
{
    @autoreleasepool
    {
        [_inkLock lock];
        
        while( _runInkThread )
        {
            [_inkQueueCondition lock];
            while ( _inkQueueGet == _inkQueuePut )
            {
                [_inkQueueCondition wait];
            }
            [_inkQueueCondition unlock];
            
            if ( ! _runInkThread )
            {
                // [_inkQueueCondition unlock];
                break;
            }
            
            register int iGet = _inkQueueGet, iPut = _inkQueuePut;
            int nAdded = 0;
            
            while( (iGet = _inkQueueGet) != iPut )
            {
                // NSLog(@"new point x=%f y=%f", point.x, point.y );
                if ( iGet > iPut )
                {
                    // NSLog(@"*** Error iGet (%i) > iPut (%i)", iGet, iPut );
                    while ( iGet < MAX_QUEUE_SIZE )
                    {
                        nAdded += [self addPointPoint:_inkQueue[iGet]];
                        iGet++;
                    }
                    iGet = 0;
                }
                while ( iGet < iPut )
                {
                    nAdded += [self addPointPoint:_inkQueue[iGet]];
                    iGet++;
                }
                _inkQueueGet = iPut;
            }
            
            if ( nAdded > 2 )
            {
                NSInteger from = MAX( 0, strokeLen-1-nAdded );
                NSInteger to = MAX( 0, strokeLen-1 );
                if ( from < to )
                {
                    CGFloat penwidth = 2.0 + strokeWidth/2.0;
                    CGRect rect = CGRectMake( ptStroke[to].pt.x, ptStroke[to].pt.y, ptStroke[to].pt.x, ptStroke[to].pt.y );
                    for ( NSInteger i = from; i < to; i++ )
                    {
                        rect.origin.x = MIN( rect.origin.x, ptStroke[i].pt.x );
                        rect.origin.y = MIN( rect.origin.y, ptStroke[i].pt.y );
                        rect.size.width = MAX( rect.size.width, ptStroke[i].pt.x );
                        rect.size.height = MAX( rect.size.height, ptStroke[i].pt.y);
                    }
                    rect.size.width -= rect.origin.x;
                    rect.size.height -= rect.origin.y;
                    rect = CGRectInset( rect, -penwidth, -penwidth );
                    
                    RectObject * obj = [[RectObject alloc] initWithRect:rect];
                    [self performSelectorOnMainThread:@selector(updateDisplayInThread:) withObject:obj waitUntilDone:YES];
                    nAdded = 0;
                }
            }
        }
        [_inkLock unlock];
    }
}

-(void)addPointToQueue:(CGPoint)point
{
    [_inkQueueCondition lock];
    
    int iPut = _inkQueuePut;
    _inkQueue[iPut] = point;
    iPut++;
    if ( iPut >= MAX_QUEUE_SIZE )
        iPut = 0;
    _inkQueuePut = iPut;
    [_inkQueueCondition broadcast];
    
    [_inkQueueCondition unlock];
}

- (int)addPointPoint:(CGPoint)point
// this method called from inkCollectorThread
{
    // NSLog(@"new point x=%f y=%f", point.x, point.y );
    int nAdded = 0;
    if ( point.y == -1 )
    {
        [self processEndOfStroke:YES];
    }
    else
    {
        nAdded += [self AddPixelsX:point.x Y:point.y pressure:DEFAULT_PRESSURE IsLastPoint:FALSE];
    }
    return nAdded;
}

-(void) updateDisplayInThread:(RectObject *)rObject
// This method is called when a updateDisplayInThread selector from main thread is called.
{
    if ( rObject == nil )
    {
        [_currentStrokeView setNeedsDisplay];
        if ( strokeLen == 0 )
            [self setNeedsDisplay];
    }
    else
    {
        [_currentStrokeView setNeedsDisplayInRect:rObject.rect];
        if ( strokeLen == 0 )
            [self setNeedsDisplayInRect:rObject.rect];
    }
}

-(void) strokeGestureInTread:(NSArray *)arr
// This method is called when a strokeGestureTread selector from main thread is called.
{
    GESTURE_TYPE	gesture = (GESTURE_TYPE)[(NSNumber *)[arr objectAtIndex:0] intValue];
    UInt32			nStrokeCount = [(NSNumber *)[arr objectAtIndex:1] unsignedIntValue];
    
    if ( gesture == GEST_LOOP && nStrokeCount > 0 && shortcuts != nil && [shortcuts isEnabled] )
    {
        // check if this is a correct
        CGRect rData;
        if ( INK_GetDataRect( inkData, &rData, FALSE ) )
        {
            CGFloat left, right;
            CGFloat bottom, top;
            left = right =  ptStroke[0].pt.x;
            bottom = top =  ptStroke[0].pt.y;
            for( register int i = 1; i < strokeLen; i++ )
            {
                left = MIN( ptStroke[i].pt.x, left );
                right = MAX( ptStroke[i].pt.x, right );
                top =  MIN( ptStroke[i].pt.y, top );
                bottom =  MAX( ptStroke[i].pt.y, bottom );
            }
            CGFloat dx = rData.size.width/8;
            CGFloat dy = rData.size.height/8;
            if ( left < (rData.origin.x + dx) && top < (rData.origin.y + dy) && right > (rData.origin.x + rData.size.width - dx) &&
                bottom > (rData.origin.y + rData.size.height - dy) )
            {
                // check if it fits into the current stroke
                NSLog( @"Loop!" );
                // get name of the shortcut and see if it matches...
                _bAddStroke = (![shortcuts recognizeInkData:inkData]);
                if ( ! _bAddStroke )
                {
                    // command was recognized; reset the recognizer and delete INK data
                    if ( backgroundReco )
                    {
                        [[RecognizerManager sharedManager] reset];
                    }
                    [self empty];
                }
            }
        }
    }
    else
    {
        [self processEditingGesture:gesture isEmpty:(nStrokeCount == 0)];
        if ([delegate respondsToSelector:@selector(InkCollectorRecognizedGesture:withGesture:isEmpty:)])
        {
            _bAddStroke = [delegate InkCollectorRecognizedGesture:self withGesture:gesture isEmpty:(nStrokeCount == 0)];
        }
    }
    if ( ! _bAddStroke )
        strokeLen = 0;
}


-(void) strokeShapeInTread:(NSArray *)arr
// This method is called when a strokeGestureTread selector from main thread is called.
{
    SHAPETYPE	shape = (SHAPETYPE)[(NSNumber *)[arr objectAtIndex:0] intValue];
    UInt32			nStrokeCount = [(NSNumber *)[arr objectAtIndex:1] unsignedIntValue];
    
    {
        if ([delegate respondsToSelector:@selector(InkCollectorRecognizedShape:withShape:isEmpty:)])
        {
            _bAddStroke = [delegate InkCollectorRecognizedShape:self withShape:shape isEmpty:(nStrokeCount == 0)];
        }
        _bAddStroke = [self processEditingShape:shape isEmpty:(nStrokeCount == 0)];

    }
    if ( ! _bAddStroke )
        strokeLen = 0;
}


#pragma mark ReloadOptions

- (void)reloadOptions
{
    NSUserDefaults*	defaults = [NSUserDefaults standardUserDefaults];
    
    [self stopAsyncRecoThread];
    
    BOOL b = [defaults boolForKey:kRecoOptionsFirstStartKey];
    if ( b == YES )
    {
        strokeWidth = [defaults floatForKey:kRecoOptionsInkWidth];
        if ( strokeWidth < 1.0 )
        {
            strokeWidth = DEFAULT_PENWIDTH;
            [defaults setFloat:strokeWidth forKey:kRecoOptionsInkWidth];
        }
        recognitionDelay = [defaults floatForKey:kRecoOptionsTimerDelay];
        if ( recognitionDelay < MIN_DELAY || recognitionDelay > 5 * DEFAULT_TOUCHANDHOLDDELAY )
        {
            recognitionDelay = DEFAULT_RECODELAY;
            [defaults setFloat:recognitionDelay forKey:kRecoOptionsTimerDelay];
        }
        
        // [self enableAsyncInk:NO];
        
        if ( shortcuts && [shortcuts isEnabled] )
        {
            // reload shortcuts recognizer
            [shortcuts enableRecognizer:NO];
            [shortcuts enableRecognizer:YES];
        }
        
        if ( [self isInkData] && _useAsyncRecognizer )
        {
            [self startAsyncRecoThread];
        }
        [self setNeedsDisplay];
    }
}

- (BOOL) shortcutsEnable:(BOOL)bEnable delegate:(id)del uiDelegate:(id)uiDel
{
    if ( nil == shortcuts )
        return NO;
    shortcuts.delegate = del;
    shortcuts.delegateUI = uiDel;
    return [shortcuts enableRecognizer:bEnable];
}

- (BOOL) isInkData
{
    return (INK_StrokeCount( inkData, FALSE ) > 0) ? YES : NO;
}

- (void) killRecoTimer
{
    if ( nil != _timerRecognizer )
    {
        [_timerRecognizer invalidate];
        _timerRecognizer = nil;
    }
}

-(void) strokeAdded:(NSObject *)object
// This method is called when a strokeAddedInTread selector from main thread is called.
{
    if ( autoRecognize )
    {
        //Start recognition timer
        [self killRecoTimer];
        _timerRecognizer = [NSTimer scheduledTimerWithTimeInterval:recognitionDelay target:self
                                                          selector:@selector(recognizerTimer) userInfo:nil repeats:NO];
    }
}

-(void) recognizeNow
// This method is called when a strokeAddedInTread selector from main thread is called.
{
    //Start recognition timer
    [self killRecoTimer];
    _timerRecognizer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self
                                                      selector:@selector(recognizerTimer) userInfo:nil repeats:NO];
}

#pragma mark -- This code is used to automatically detect new line in handwritten text

- (BOOL) isNewLine:(CGRect)rLastWord previousWord:(CGRect)rPrevWord
{
    //  If the coordinates of the current word are below and to the left comparing to coordinates of the previous word
    // we assume that this is new line. Conditions can be changed, if needed
    if ( rLastWord.origin.y > rPrevWord.origin.y + rPrevWord.size.height && rPrevWord.size.width + rPrevWord.origin.x > rLastWord.origin.x )
        return YES;
    return NO;
}

- (NSString *) constructResultString
{
    NSMutableString * result = [[NSMutableString alloc] init];
    
    RECOGNIZER_PTR _reco = [RecognizerManager sharedManager].recognizer;
    NSInteger _wordCnt = HWR_GetResultWordCount( _reco );
    if ( _wordCnt < 1 )
        return nil;
    
    NSString *		word = nil;
    const UCHR *	chrWord = NULL;
    CGRect          rLastWord = CGRectNull, rPrevWord = CGRectNull;
    
    @autoreleasepool
    {
        for ( int iWord = 0; iWord < _wordCnt; iWord++ )
        {
            // int nAltCnt = HWR_GetResultAlternativeCount( _reco, iWord );
            // in this case, we are only interested in first alternative
            chrWord = HWR_GetResultWord( _reco, iWord, 0 );
            if ( NULL == chrWord || 0 == *chrWord )
            {
                NSLog( @"**** HWR_GetResultWord returnd error for first word; this should not happen" );
                return nil;
            }
            word = [RecognizerManager stringFromUchr:chrWord];
            // NSLog( @"Word %d: %@; alternatives %d", iWord, word, nAltCnt );
            
            // get coordinates of the current word in the current inkData object
            INK_SelectAllStrokes( inkData, FALSE );
            int * ids = NULL;
            int cnt = HWR_GetStrokeIDs( _reco, iWord, 0, (const int **)&ids );
            for ( int i = 0; i < cnt; i++ )
            {
                INK_SelectStroke( inkData, ids[i], TRUE );
            }
            INK_GetDataRect( inkData, &rLastWord, TRUE );
            
            // check if this is new line, then insert \n, otherwise insert sapce as words separator
            if ( CGRectIsNull( rPrevWord ) )
            {
                if ( [result length] > 0 )
                    [result appendString:@" "];
            }
            else
            {
                if ( [self isNewLine:rLastWord previousWord:rPrevWord] )
                {
                    // insert new line charactrer as words separator
                    [result appendString:@"\n"];
                }
                else
                {
                    // insert space character as words separator
                    [result appendString:@" "];
                }
            }
            rPrevWord = rLastWord;
            [result appendString:word];
        }
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:kEditOptionsAutospace] )
            [result appendString:@" "];
    }
    // NSLog( @"Result:\n%@", result );
    return (NSString *)result;
}

#pragma mark --


- (BOOL) recognizeInk:(BOOL)bErase
{
    [self killRecoTimer];
    
    NSMutableString * strResult;
    if ( _useAsyncRecognizer )
    {
        strResult = [self.currentResult mutableCopy];
        self.currentResult = nil;
    }
    else
    {
        
        if ( (! [self isInkData]) )
            return NO;
        const UCHR * pText = [[RecognizerManager sharedManager] recognizeInkData:inkData background:backgroundReco async:NO selection:NO];
        if ( pText == NULL || *pText == 0 )
        {
            [[RecognizerManager sharedManager] reportError];
            return NO;
        }
        strResult = [[NSMutableString alloc] initWithString:[RecognizerManager stringFromUchr:pText]];
    }
    if ( [strResult length] > 1 && [strResult characterAtIndex:[strResult length] - 1] == ' ' && [[NSUserDefaults standardUserDefaults] boolForKey:kEditOptionsAutospace] )
    {
        [strResult deleteCharactersInRange:NSMakeRange( [strResult length] - 1, 1 )];
    }
    if ( bErase )
        [self empty];
    
    // NSComparisonResult comp = [strResult compare:kEmptyWord options:NSCaseInsensitiveSearch range:NSMakeRange( 0, 5 )];
    if ( [strResult rangeOfString:@kEmptyWord].location != NSNotFound || [strResult rangeOfString:@"*Error*"].location != NSNotFound )
    {
        // error...
        [[RecognizerManager sharedManager] reportError];
        return NO;
    }
    
    if ([delegate respondsToSelector:@selector(InkCollectorResultReady:theResult:)])
    {
        [delegate InkCollectorResultReady:self theResult:strResult];
        [self redoDocument:strResult];
    }
    return YES;
}

- (void) enableGestures:(GESTURE_TYPE)gestures whenEmpty:(BOOL)bEmpty;
{
    if ( bEmpty )
        gesturesEnabledIfEmpty = gestures;
    else
        gesturesEnabledIfData = gestures;
}

- (BOOL) deleteLastStroke
{
    BOOL bResult = INK_DeleteStroke( inkData, -1 );  //
    
    if ( bResult && _useAsyncRecognizer )
    {
        [self startAsyncRecoThread];
    }
    else if ( bResult && backgroundReco )
    {
        [[RecognizerManager sharedManager] reset];
        if ( INK_StrokeCount( inkData, FALSE ) > 0 )
        {
            // restart background recognizer
            HWR_PreRecognizeInkData( [[RecognizerManager sharedManager] recognizer], inkData, 0, FALSE );
            [self strokeAdded:nil];	// restart recognizer timer
        }
    }
    
    return bResult;
}

#pragma mark - Ink Collection support


- (GESTURE_TYPE)recognizeGesture:(GESTURE_TYPE)gestures withStroke:(CGStroke)points withLength:(int)count
{
    if ( count < 2 )
        return GEST_NONE;
    
    int iLen = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kRecoOptionsBackstrokeLen];
    if ( iLen < 200 )
        iLen = DEFAULT_BACKGESTURELEN;
    GESTURE_TYPE type = HWR_CheckGesture( gestures, points, count, 1, iLen );
    return type;
}

- (SHAPETYPE)recognizeShape:(CGStroke)points withLength:(int)count inType:(SHAPETYPE)stype
{
    if ( count < 2 )
        return SHAPE_UNKNOWN;
    
    SHAPETYPE type = INK_RecognizeShape( points, count, stype);
    return type;
}

// this function is called from secondary thread
-(void) processEndOfStroke:(BOOL)fromThread
{
    if ( strokeLen < 2 )
    {
        strokeLen = 0;
        return;
    }
    
    GESTURE_TYPE	gesture = GEST_NONE;
    SHAPETYPE shape = SHAPE_UNKNOWN;
    UInt32			nStrokeCount = INK_StrokeCount( inkData, FALSE );
    
    _bAddStroke = YES;
    if ( strokeLen > 2  && nStrokeCount > 0 && gesturesEnabledIfData != GEST_NONE )
    {
        // recognize gesture
        gesture = [self recognizeGesture:gesturesEnabledIfData withStroke:ptStroke withLength:strokeLen];
    }
    else if ( strokeLen > 5 && nStrokeCount == 0 && gesturesEnabledIfEmpty != GEST_NONE )
    {
        // recognize gesture
        gesture = [self recognizeGesture:gesturesEnabledIfEmpty withStroke:ptStroke withLength:strokeLen];
    }
    
    if ( gesture != GEST_NONE )
    {
        NSArray * arr = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:gesture], [NSNumber numberWithInt:nStrokeCount], nil];
        if ( fromThread )
        {
            // gesture recognized, notify main thread
            [self performSelectorOnMainThread:@selector(strokeGestureInTread:) withObject:arr waitUntilDone:YES];
        }
        else
        {
            [self strokeGestureInTread:arr];
        }
    }
    else // try shape
    {
        shape = [self recognizeShape:ptStroke withLength:strokeLen inType:SHAPE_ALL];
        if(shape != SHAPE_UNKNOWN){
            NSArray * arr = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:shape], [NSNumber numberWithInt:nStrokeCount], nil];
            if ( fromThread )
            {
                // gesture recognized, notify main thread
                [self performSelectorOnMainThread:@selector(strokeShapeInTread:) withObject:arr waitUntilDone:YES];
            }
            else
            {
                [self strokeShapeInTread:arr];
            }
        }
        else{
            int nStrokes = INK_StrokeCount( inkData, FALSE );
            //    if ( edit != nil && nStrokes  <  1 && _firstTouch )
            //        [edit processTouchAndHoldAtLocation:_previousLocation];
            //    else
            if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
            {
                CGPoint	from = ptStroke[0].pt;
                CGPoint to = ptStroke[strokeLen-1].pt;
                
                [edit selectTextFromPosition:from toPosition:to];
                
                if((to.x < from.x && to.y < from.y) || (to.y < from.y - 20)){
                    [edit replaceRange:edit.selectedTextRange withText:@""];
                }
                else{
                    UIMenuController * menu = [UIMenuController sharedMenuController];
                    CGRect rect = CGRectMake((from.x + to.x) / 2, (from.y + to.y) / 2, 0, 0);
                    [menu setTargetRect:rect inView:self.edit];
                    menu.arrowDirection = UIMenuControllerArrowDefault;
                    [menu setMenuVisible:YES animated:YES];
                    
                    
                    //shows the Font
                    //                    CGRect drawnRt = [self getMinMaxTopLeft];
                    //                    CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
                    //
                    //                    CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y + rbPos.y) / 2, 0, 0);
                    //                    CGFloat xx = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.x : ptStroke[0].pt.x;
                    //                    CGFloat yy = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.y : ptStroke[0].pt.y;
                    
                    //                        UITextRange * selectionRange = [self.edit selectedTextRange];
                    //                        CGRect end = [self.edit caretRectForPosition:selectionRange.end];
                    //                        CGRect rt = CGRectMake( end.origin.x, end.origin.y+end.size.height, 0, 0);
                    //                        [self.edit.toolBar showFontSettingDialog:rt inView:self.edit];
                }
                
                //[self recognizeInk:YES];x
                [self empty];
            }
            strokeLen = 0;
            [_currentStrokeView setNeedsDisplay];
        }
    }
    
    CGRect rect = CGRectNull;
    _bAddStroke = NO;
    if ( _bAddStroke )
    {
        if ( (!_useAsyncRecognizer) && backgroundReco && INK_StrokeCount( inkData, FALSE ) < 1 )
        {
            [[RecognizerManager sharedManager] reset];
        }
        // call up the app delegate
        COLORREF	 coloref = [utils _uiColorToColorRef:strokeColor];
        
        if ( INK_AddStroke( inkData, ptStroke, strokeLen, (int)strokeWidth, coloref ) )
        {
            if ( _useAsyncRecognizer )
            {
                [self startAsyncRecoThread];
            }
            else if ( backgroundReco )
            {
                HWR_RecognizerAddStroke( [[RecognizerManager sharedManager] recognizer], ptStroke, strokeLen );
            }
            if ( fromThread )
            {
                [self performSelectorOnMainThread:@selector(strokeAdded:) withObject:nil waitUntilDone:NO];
            }
            else
            {
                [self strokeAdded:nil];
            }
            INK_GetStrokeRect( inkData, -1, &rect, TRUE );
        }
    }
    // else
    {
        numberOfPoints = strokeLen;
        strokeLen = 0;
        // MUST UPDATE THE ENTIRE VIEW
        if ( fromThread )
        {
            RectObject * obj = nil;
            if ( ! CGRectIsNull( rect ) )
                obj = [[RectObject alloc] initWithRect:rect];
            [self performSelectorOnMainThread:@selector (updateDisplayInThread:) withObject:obj waitUntilDone:YES];
        }
        else
        {
            [_currentStrokeView setNeedsDisplay];
            if ( CGRectIsNull( rect ) )
                [self setNeedsDisplay];
            else
                [self setNeedsDisplayInRect:rect];
        }
    }
}

// Releases resources when they are not longer needed.
- (void) dealloc
{
    [self killRecoTimer];
    [self killHoldTimer];
    
    // pressing home button in while in the options dialog does not save recognizer files
    if ( NULL != ptStroke )
        free( ptStroke );
    ptStroke = NULL;
    INK_FreeData( inkData );
}

- (UIColor *) _colorRefToUiColor:(COLORREF)coloref
{
    UIColor * color = [UIColor colorWithRed:GetRValue(coloref) green:GetGValue(coloref) blue:GetBValue(coloref) alpha:GetAValue(coloref)];
    return color;
}


-(void)drawRect:(CGRect)rect
{
    CGContextRef	context = UIGraphicsGetCurrentContext();
    
    // draw the current stroke
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary * attrib = @{ NSFontAttributeName: [UIFont fontWithName:@"Zapfino" size:(IS_PHONE ? 40.0 : 60.0)], NSParagraphStyleAttributeName: paragraphStyle };
    
    if ( self.placeholder1 != nil )
    {
        CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1, 0.6 );
        CGRect rText = rect;
        rText.origin.y = IS_PHONE ? 50 : 150;
        rText.size.height = IS_PHONE ? 100 : 160;
        rText.origin.x = -10;
        [self.placeholder1 drawInRect:rText withAttributes:attrib];
    }
    if ( self.placeholder2 != nil )
    {
        CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1, 0.6 );
        CGRect rText = rect;
        rText.origin.y = IS_PHONE ? 170 : 350;
        rText.size.height = IS_PHONE ? 100 : 160;
        rText.origin.x = -10;
        [self.placeholder2 drawInRect:rText withAttributes:attrib];
    }
    
    register int		nStroke = 0;
    int			nStrokeLen = 0;
    float       nWidth = 1.0;
    CGStroke	points = NULL;
    COLORREF	coloref = 0;
    CGRect		rStroke = CGRectZero;
    
    while ( INK_GetStrokeRect( inkData, nStroke, &rStroke, FALSE ) )
    {
        if ( CGRectIntersectsRect( rStroke, rect ) )
        {
            nStrokeLen = INK_GetStrokeP( inkData, nStroke, &points, &nWidth, &coloref );
            if ( nStrokeLen < 1 || NULL == points )
                break;
            //[WPInkView _renderLine:points pointCount:nStrokeLen inContext:context withWidth:nWidth withColor:[utils _uiColorRefToColor:coloref]];
            if(isStylus)
                [WPInkView _renderLine:points pointCount:nStrokeLen inContext:context withWidth:nWidth withColor:[UIColor blueColor]];
            else
                [WPInkView _renderLine:points pointCount:nStrokeLen inContext:context withWidth:nWidth withColor:[UIColor lightGrayColor]];
        }
        nStroke++;
    }
    
    if ( NULL != points )
        free( (void *)points );
}

-(void) empty
{
    [self killRecoTimer];
    [self killHoldTimer];
    INK_Erase( inkData );
    [_currentStrokeView setNeedsDisplay];
    [self setNeedsDisplay];
}

#pragma mark - AddPixelToStroke

#define SEGMENT2            2
#define SEGMENT3            3
#define SEGMENT4            4

#define SEGMENT_DIST_1      3
#define SEGMENT_DIST_2      6
#define SEGMENT_DIST_3      12

-(int)AddPixelsX:(int)x Y:(int)y pressure:(int)pressure IsLastPoint:(BOOL)bLastPoint
// this method called from inkCollectorThread
{
    CGFloat		xNew, yNew, x1, y1;
    CGFloat		nSeg = SEGMENT3;
    
    if ( NULL == ptStroke )
        return 0;
    
    if  ( strokeLen < 1 )
    {
        ptStroke[strokeLen].pt.x = _previousLocation.x = x;
        ptStroke[strokeLen].pt.y = _previousLocation.y = y;
        ptStroke[strokeLen].pressure = pressure;
        strokeLen = 1;
        return  1;
    }
    
    CGFloat dx = fabs( x - ptStroke[strokeLen-1].pt.x );
    CGFloat dy = fabs( y - ptStroke[strokeLen-1].pt.y );
    
    if  ( dx + dy < 1.0f )
        return 0;
    
    if ( dx + dy > 100.0f * SEGMENT_DIST_2 )
        return 0;
    
    int nNewLen = (strokeLen + 2 * SEGMENT4 + 1) * sizeof( CGTracePoint );
    if ( nNewLen >= strokeMemLen )
    {
        strokeMemLen += DEFAULT_STROKE_LEN * sizeof( CGTracePoint );
        ptStroke = realloc( ptStroke, strokeMemLen );
        if ( NULL == ptStroke )
            return 0;
    }
    
    if  ( (dx + dy) < SEGMENT_DIST_1 )
    {
        ptStroke[strokeLen].pt.x = _previousLocation.x = x;
        ptStroke[strokeLen].pt.y = _previousLocation.y = y;
        ptStroke[strokeLen].pressure = pressure;
        strokeLen++;
        return  1;
    }
    
    if ( (dx + dy) < SEGMENT_DIST_2 )
        nSeg = SEGMENT2;
    else if ( (dx + dy) < SEGMENT_DIST_3 )
        nSeg = SEGMENT3;
    else
        nSeg = SEGMENT4;
    int     nPoints = 0;
    for ( register int i = 1;  i < nSeg;  i++ )
    {
        x1 = _previousLocation.x + ((x - _previousLocation.x)*i ) / nSeg;  //the point "to look at"
        y1 = _previousLocation.y + ((y - _previousLocation.y)*i ) / nSeg;  //the point "to look at"
        
        xNew = ptStroke[strokeLen-1].pt.x + (x1 - ptStroke[strokeLen-1].pt.x) / nSeg;
        yNew = ptStroke[strokeLen-1].pt.y + (y1 - ptStroke[strokeLen-1].pt.y) / nSeg;
        
        if ( xNew != ptStroke[strokeLen-1].pt.x || yNew != ptStroke[strokeLen-1].pt.y )
        {
            ptStroke[strokeLen].pt.x = xNew;
            ptStroke[strokeLen].pt.y = yNew;
            ptStroke[strokeLen].pressure = pressure;
            strokeLen++;
            nPoints++;
        }
    }
    
    if ( bLastPoint )
    {
        // add last point
        if ( x != ptStroke[strokeLen-1].pt.x || y != ptStroke[strokeLen-1].pt.y )
        {
            ptStroke[strokeLen].pt.x = x;
            ptStroke[strokeLen].pt.y = y;
            ptStroke[strokeLen].pressure = pressure;
            strokeLen++;
            nPoints++;
        }
    }
    
    _previousLocation.x = x;
    _previousLocation.y = y;
    return nPoints;
}


#pragma mark - Main thread callback methods

- (void) endSelectionMode
{
    _bSendTouchToEdit = NO;
    _bSelectionMode = NO;
}

- (void) enterSelectionMode
{
    _bSendTouchToEdit = YES;
    _bSelectionMode = YES;
}

- (void) recognizerTimer
{
    [self recognizeInk:YES];
}

- (void) touchAndHoldTimer
{
    [self killHoldTimer];
    int nStrokes = INK_StrokeCount( inkData, FALSE );
//    if ( edit != nil && nStrokes  <  1 && _firstTouch )
//        [edit processTouchAndHoldAtLocation:_previousLocation];
//    else
    if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
    {
        CGPoint	from = ptStroke[0].pt;
        CGPoint to = ptStroke[strokeLen-1].pt;
        [edit selectTextFromPosition:from toPosition:to];
        
        UIMenuController * menu = [UIMenuController sharedMenuController];
        CGRect rect = CGRectMake((from.x + to.x) / 2, (from.y + to.y) / 2, 0, 0);
        [menu setTargetRect:rect inView:self.edit];
        menu.arrowDirection = UIMenuControllerArrowDefault;
        [menu setMenuVisible:YES animated:YES];
        
    }
    
    strokeLen = 0;
    [_currentStrokeView setNeedsDisplay];
}

- (void)addPointAndDraw:(CGPoint)point IsLastPoint:(BOOL)isLastPoint
{
    int	lenSave = strokeLen-1;
    if ( lenSave < 0 )
    {
        return;
    }
    
    // must not contain negative coordinates
    if ( point.x < 0 )
        point.x = 0;
    if ( point.y < 0 )
        point.y = 0;
    
    if ( isLastPoint )
    {
        // make sure last point is not too far
        if ( ABS( ptStroke[lenSave].pt.x - point.x ) > 20 || ABS( ptStroke[lenSave].pt.y - point.y ) > 20 )
        {
            point = ptStroke[lenSave].pt;
        }
    }
    
    // TODO: if pen pressure is supported, you may change DEFAULT_PRESSURE to actual pressure value,
    // The pressure is assumed to changes between 1 (min) and 255 (mac), 150 considered to be default.
    _nAdded += [self AddPixelsX:point.x Y:point.y pressure:DEFAULT_PRESSURE IsLastPoint:FALSE];
    if ( _nAdded > 0 )
    {
        NSInteger from = MAX( 0, strokeLen-1-_nAdded );
        NSInteger to = MAX( 0, strokeLen-1 );
        CGFloat penwidth = 2.0 + strokeWidth/2.0;
        CGRect rect = CGRectMake( ptStroke[to].pt.x, ptStroke[to].pt.y, ptStroke[to].pt.x, ptStroke[to].pt.y );
        for ( NSInteger i = from; i < to; i++ )
        {
            rect.origin.x = MIN( rect.origin.x, ptStroke[i].pt.x );
            rect.origin.y = MIN( rect.origin.y, ptStroke[i].pt.y );
            rect.size.width = MAX( rect.size.width, ptStroke[i].pt.x );
            rect.size.height = MAX( rect.size.height, ptStroke[i].pt.y);
        }
        rect.size.width -= rect.origin.x;
        rect.size.height -= rect.origin.y;
        rect = CGRectInset( rect, -penwidth, -penwidth );
        [_currentStrokeView setNeedsDisplayInRect:rect];
        _nAdded = 0;
    }
}


#pragma mark - Touches Handles

-(void) killHoldTimer
{
    if ( nil != _timerTouchAndHold )
    {
        [_timerTouchAndHold invalidate];
        _timerTouchAndHold = nil;
    }
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch*	touch = nil;
    CGPoint		location;
    
    [self killHoldTimer];
    [edit becomeFirstResponder];
    
    // [edit hideSuggestions];
    
    if ( self.placeholder1 != nil )
    {
        self.placeholder1 = nil;
        self.placeholder2 = nil;
        [self setNeedsDisplay];
    }
    
    touch =  [touches anyObject];
    location = [touch locationInView:self];
    
    if(touch.type == UITouchTypeStylus)
        isStylus = true;
    if(touch.type == UITouchTypeDirect)
        isStylus = false;
        
    
    [self killRecoTimer];
    
    _nAdded = 0;
    _bSendTouchToEdit = _bSelectionMode;
    strokeLen = 0;
    _firstTouch = YES;
    
    _previousLocation = location;
    
    if ( nil != edit )
    {
        // TODO: this is optional, if you do not need to send touch events to undelying views, this code can be disabled.
        if ( edit.selectedRange.length > 0 )
        {
            // TODO: you may try to handle selection mode by forwarding touche events to the edit view
        }
        else if ( _bSendTouchToEdit )
        {
            // TODO: you may change the way you forward events to other views depending on your application interface
            [edit touchesBegan:touches withEvent:event];
            return;
        }
        if ( INK_StrokeCount( inkData, FALSE )  <  1 )
        {
            //_timerTouchAndHold = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_TOUCHANDHOLDDELAY target:self
             //                                                   selector:@selector(touchAndHoldTimer) userInfo:nil repeats:NO];
        }
    }
    
    if ( _bAsyncInkCollector )
    {
        if ( _inkQueueGet == _inkQueuePut )
            _inkQueueGet = _inkQueuePut = 0;
        [self addPointToQueue:location];
    }
    else
    {
        ptStroke[0].pressure = DEFAULT_PRESSURE;
        ptStroke[0].pt = _previousLocation;
        strokeLen = 1;
        _nAdded = 1;
    }
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch  *touch =  [touches anyObject];
    
    
    if ( touch == nil )
        return;
    
    if(touch.type == UITouchTypeStylus)
        isStylus = true;
    if(touch.type == UITouchTypeDirect)
        isStylus = false;
    
    if ( [[UIMenuController sharedMenuController] isMenuVisible] || strokeLen == 0 )
    {
        strokeLen = 0;
        return;
    }
    
    CGPoint		location = [touch locationInView:self];
    
    CGFloat		dy = location.y - _previousLocation.y;
    CGFloat		dx = location.x - _previousLocation.x;
    if ( dx*dx + dy*dy <= 2.0 )
        return;
    
    if ( _firstTouch )
    {
        if ( dx*dx + dy*dy > 2 )
        {
            [self killHoldTimer];
            _firstTouch = NO;
        }
    }
    else
    {
        [self killHoldTimer];
    }
    
    if ( _bSendTouchToEdit && edit != nil )
    {
        [edit touchesMoved:touches withEvent:event];
        return;
    }
    
    if ( nil != edit && INK_StrokeCount( inkData, FALSE )  <  1 && (!_firstTouch) )
    {
        // this is for selection
        /**
        _timerTouchAndHold = [NSTimer scheduledTimerWithTimeInterval:DEFAULT_TOUCHANDHOLDDELAY target:self
                                                            selector:@selector(touchAndHoldTimer) userInfo:nil repeats:NO];
         **/
    }
    if ( _bAsyncInkCollector  )
    {
        [self addPointToQueue:location];
    }
    else if ( (location.y != _previousLocation.y || location.x != _previousLocation.x) && NULL != ptStroke )
    {
        // if this is the first stroke, re-enable the touch timer
        [self addPointAndDraw:location IsLastPoint:FALSE];
        
    }
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self killHoldTimer];
    
    if ( [[UIMenuController sharedMenuController] isMenuVisible] || strokeLen == 0 )
    {
        strokeLen = 0;
        return;
    }
    
    if ( [touches count] > 1 )
    {
        // do not emulate touch if there are multiple touches in the queue
        _firstTouch = NO;
    }
    
    UInt32		nStrokeCount = INK_StrokeCount( inkData, FALSE );
    UITouch  *	touch =  [touches anyObject];
    
    if ( touch == nil )
    {
        _firstTouch = NO;
        return;
    }
    
    if(touch.type == UITouchTypeStylus)
        isStylus = true;
    if(touch.type == UITouchTypeDirect)
        isStylus = false;
    
    CGPoint		location = [touch locationInView:self];
    
    if ( _bSendTouchToEdit )
    {
        if ( edit != nil )
        {
            [edit touchesEnded:touches withEvent:event];
        }
        _firstTouch = NO;
        return;
    }
    
    if ( _firstTouch )
    {
        _firstTouch = NO;
        if ( nStrokeCount < 1  )
        {
            if ( nil != edit )
                [edit tapAtLocation:touches withEvent:event];
            if ( strokeLen > 0 )
            {
                strokeLen = 0;
                
                [_currentStrokeView setNeedsDisplay];
            }
            return;
        }
        else
        {
            location.x++;
        }
    }
    if ( nStrokeCount < 1 && strokeLen < 2 )
    {
        if ( nil != edit )
        {
            [edit tapAtLocation:touches withEvent:event];
        }
        if ( strokeLen > 0 )
        {
            strokeLen = 0;
//            
//            CGRect rect;
//            rect.origin.x = MIN( location.x, ptStroke[0].pt.x ) - strokeWidth * 2;
//            rect.origin.y = MIN( location.y, ptStroke[0].pt.y ) - strokeWidth * 2;
//            rect.size.width = (MAX( location.x, ptStroke[0].pt.x ) + strokeWidth * 4) - rect.origin.x;
//            rect.size.height = (MAX( location.y, ptStroke[0].pt.y ) + strokeWidth * 4) - rect.origin.y;
//            [_currentStrokeView setNeedsDisplayInRect:rect];
            [_currentStrokeView setNeedsDisplay];
        }
        return;
    }
    
    if ( _bAsyncInkCollector )
    {
        [self addPointToQueue:location];
        [self addPointToQueue:CGPointMake( 0, -1 )];
    }
    else
    {
        [self addPointAndDraw:location IsLastPoint:TRUE];
        
        // process the new stroke
        [self processEndOfStroke:NO];
        // _strokeFilterTimeout = [[NSDate date] timeIntervalSinceReferenceDate];
    }
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _firstTouch = NO;
    
    // cancel current stroke
    strokeLen = 0;
    [_currentStrokeView setNeedsDisplay];
    // [self setNeedsDisplay];
}

#pragma mark - Asyncronous Recognizer Thread

-(BOOL) startAsyncRecoThread
{
    if ( ! _useAsyncRecognizer )
        return NO;
    // make sure another recognizer thread is not already running
    [self stopAsyncRecoThread];
    
    self.currentResult = nil;
    if ( [[RecognizerManager sharedManager] isEnabled] &&  [self isInkData] )
    {
        InkObject * ink = [[InkObject alloc] initWithInkData:inkData];
        // create a new async recognizer thread
        [NSThread detachNewThreadSelector:@selector(asyncRecoThread:) toTarget:self withObject:ink];
        return YES;
    }
    return NO;
}

-(void) stopAsyncRecoThread
{
    if ( _useAsyncRecognizer )
    {
        HWR_StopAsyncReco( [[RecognizerManager sharedManager] recognizer] );
    }
}

-(void) showAsyncRecoResult:(NSString *)strResult
{
    [self processEditingMark:strResult];
    if ([delegate respondsToSelector:@selector(InkCollectorAsyncResultReady:theResult:)])
    {
        [delegate InkCollectorAsyncResultReady:self theResult:strResult];
    }
}

-(void) asyncRecoThread:(id)obj
{
    @autoreleasepool
    {
        [NSThread setThreadPriority:0.2];
        InkObject * ink = obj;
        if ( ink.inkData != NULL )
        {
            const UCHR * pText = NULL;
            @synchronized( self )
            {
                pText = [[RecognizerManager sharedManager] recognizeInkData:ink.inkData background:NO async:YES selection:NO];
                if ( pText != NULL )
                {
                    // send result to main thread
                    NSString * strText = [RecognizerManager stringFromUchr:pText];
                    self.currentResult = strText;
                    NSLog(@"CurText = %@", strText);
                                    }
            }
            if ( [self.currentResult length] > 0 )
                [self performSelectorOnMainThread:@selector(showAsyncRecoResult:) withObject:self.currentResult waitUntilDone:YES];
            // exit thread, recognition completed
        }
    }
}

-(CGRect) getMinMaxTopLeft{
    if(strokeLen == 0)
        return CGRectZero;
    float minLef = ptStroke[0].pt.x;
    float minTop = ptStroke[0].pt.y;
    float maxLef = ptStroke[0].pt.x;
    float maxTop = ptStroke[0].pt.y;
    for(int i = 0; i < strokeLen; i++){
        if(minLef > ptStroke[i].pt.x)
            minLef = ptStroke[i].pt.x;
        if(maxLef < ptStroke[i].pt.x)
            maxLef = ptStroke[i].pt.x;
        if(minTop > ptStroke[i].pt.y)
            minTop = ptStroke[i].pt.y;
        if(maxTop < ptStroke[i].pt.y)
            maxTop = ptStroke[i].pt.y;
    }
    return CGRectMake(minLef, minTop, maxLef - minLef, maxTop - minTop);
}

-(CGPoint*) getMinMax
{
    CGPoint left = ptStroke[0].pt;
    CGPoint right = ptStroke[0].pt;
    for(int i = 0; i < strokeLen; i++){
        if(left.x > ptStroke[i].pt.x)
            left = ptStroke[i].pt;
        if(right.x < ptStroke[i].pt.x)
            right = ptStroke[i].pt;
    }
    CGPoint ps[2] = {left, right};
    return ps;
}
-(void) openStyle
{
    UITextRange * selectionRange = [self.edit selectedTextRange];
    CGRect end = [self.edit caretRectForPosition:selectionRange.end];
    CGRect rt = CGRectMake( end.origin.x, end.origin.y+end.size.height, 0, 0);
    [self.edit.toolBar showFontSettingDialog:rt inView:self.edit];
}
-(BOOL) processEditingShape:(SHAPETYPE)shape isEmpty:(BOOL)bEmpty
{
    switch (shape) {
        case SHAPE_UNKNOWN:
            NSLog(@"SHAPE_UNKNOWN");
            break;
        case SHAPE_TRIANGLE:
            NSLog(@"SHAPE_TRIANGLE");
            break;
        case SHAPE_CIRCLE:
        case SHAPE_ELLIPSE:
            {
                [self openStyle];

            }
            break;
        case SHAPE_RECTANGLE:
            NSLog(@"SHAPE_RECTANGLE");
            break;
        case SHAPE_LINE:
            {
                if(isStylus){
                    int nStrokes = INK_StrokeCount( inkData, FALSE );
                    //    if ( edit != nil && nStrokes  <  1 && _firstTouch )
                    //        [edit processTouchAndHoldAtLocation:_previousLocation];
                    //    else
                    if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
                    {
                        CGPoint	from = ptStroke[0].pt;
                        CGPoint to = ptStroke[strokeLen-1].pt;
                        
                        [edit selectTextFromPosition:from toPosition:to];
                        
                        if((to.x < from.x && to.y < from.y) || (to.y < from.y - 20)){
                            [edit replaceRange:edit.selectedTextRange withText:@""];
                        }
                        else{
                        UIMenuController * menu = [UIMenuController sharedMenuController];
                        CGRect rect = CGRectMake((from.x + to.x) / 2, (from.y + to.y) / 2, 0, 0);
                        [menu setTargetRect:rect inView:self.edit];
                        menu.arrowDirection = UIMenuControllerArrowDefault;
                        [menu setMenuVisible:YES animated:YES];
                        
                        
                        //shows the Font
    //                    CGRect drawnRt = [self getMinMaxTopLeft];
    //                    CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
    //                    
    //                    CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y + rbPos.y) / 2, 0, 0);
    //                    CGFloat xx = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.x : ptStroke[0].pt.x;
    //                    CGFloat yy = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.y : ptStroke[0].pt.y;
                        
//                        UITextRange * selectionRange = [self.edit selectedTextRange];
//                        CGRect end = [self.edit caretRectForPosition:selectionRange.end];
//                        CGRect rt = CGRectMake( end.origin.x, end.origin.y+end.size.height, 0, 0);
//                        [self.edit.toolBar showFontSettingDialog:rt inView:self.edit];
                        }
                       
                        //[self recognizeInk:YES];x
                        [self empty];
                    }
                    strokeLen = 0;
                    [_currentStrokeView setNeedsDisplay];
                }
                else
                {
                    if(ptStroke[0].pt.x < ptStroke[strokeLen-1].pt.x){
                        if([self.edit.undoManager canRedo])
                            [self.edit.undoManager redo];
                    } else {
                        if([self.edit.undoManager canUndo])
                            [self.edit.undoManager undo];
                    }
                    //[self recognizeInk:YES];
                    [self empty];
                }
                break;
            }
        case SHAPE_ARROW:
            {
                if(ptStroke[0].pt.x < ptStroke[strokeLen-1].pt.x)
                    [self.edit.toolBar.delegate richTextEditorToolbarDidSelectParagraphIndentation:ParagraphIndentationIncrease];
                else
                    [self.edit.toolBar.delegate richTextEditorToolbarDidSelectParagraphIndentation:ParagraphIndentationDecrease];
                [self empty];
            }
            break;
        case SHAPE_SCRATCH:
            {
                int nStrokes = INK_StrokeCount( inkData, FALSE );
                //    if ( edit != nil && nStrokes  <  1 && _firstTouch )
                //        [edit processTouchAndHoldAtLocation:_previousLocation];
                //    else
                if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
                {
                    CGPoint* lr = [self getMinMax];
                    CGPoint	from = lr[0];
                    CGPoint to = lr[1];
                    [edit selectTextFromPosition:from toPosition:to];
                    //[edit replaceRange:edit.selectedTextRange withText:@""];
                    [self.edit.toolBar.delegate richTextEditorMenuDidSelectHighLight];
                    
                }
                strokeLen = 0;
                [_currentStrokeView setNeedsDisplay];

                break;
            }
        case SHAPE_ALL:
            NSLog(@"SHAPE_ALL");
            break;
            
        default:
            break;
    }
    return NO;
}
-(BOOL) processEditingGesture:(GESTURE_TYPE)gesture isEmpty:(BOOL)bEmpty
{
    switch( gesture )
    {
        case GEST_RETURN :
            if ( bEmpty  )
            {
                //[self.textView appendEditorString:@"\n"];
            }
            else
            {
                [self recognizeNow];
            }
            break;
            
        case GEST_SPACE :
            if ( bEmpty )
            {
                //[self appendEditorString:@" "];
                return NO;
            }
            break;
            
        case GEST_TAB :
            if ( bEmpty )
            {
                //[self appendEditorString:@"\t"];
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
                [self empty];
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
            if ( bEmpty )
            {
                if(isStylus)
                {
                    int nStrokes = INK_StrokeCount( inkData, FALSE );
                    //    if ( edit != nil && nStrokes  <  1 && _firstTouch )
                    //        [edit processTouchAndHoldAtLocation:_previousLocation];
                    //    else
                    if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
                    {
                        CGPoint	from = ptStroke[0].pt;
                        CGPoint to = ptStroke[strokeLen-1].pt;
                        [edit selectTextFromPosition:from toPosition:to];
                        
                        UIMenuController * menu = [UIMenuController sharedMenuController];
                        CGRect rect = CGRectMake((from.x + to.x) / 2, (from.y + to.y) / 2, 0, 0);
                        [menu setTargetRect:rect inView:self.edit];
                        menu.arrowDirection = UIMenuControllerArrowDefault;
                        [menu setMenuVisible:YES animated:YES];
                        
                        
                        //shows the Font
                        //                    CGRect drawnRt = [self getMinMaxTopLeft];
                        //                    CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
                        //
                        //                    CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y + rbPos.y) / 2, 0, 0);
                        //                    CGFloat xx = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.x : ptStroke[0].pt.x;
                        //                    CGFloat yy = ptStroke[strokeLen-1].pt.y > ptStroke[0].pt.y ? ptStroke[strokeLen-1].pt.y : ptStroke[0].pt.y;
                   
                    }
                    else
                    {
                        if([self.edit.undoManager canRedo])
                            [self.edit.undoManager redo];
                        //[self recognizeInk:YES];
                        [self empty];
                    }
                    
                    
                }
                strokeLen = 0;
                [_currentStrokeView setNeedsDisplay];
            }
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
            [self.edit doScroll:NO yOffset:0];
            break;
            
        case GEST_SCROLLUP :
            [self.edit doScroll:YES yOffset:0];
            break;
            
        case GEST_BACK :
        case GEST_BACK_LONG :
            if ( GEST_BACK_LONG == gesture && (!bEmpty) )
            {
                [self deleteLastStroke];
                return NO;
            }
            else if ( bEmpty )
            {
                if(isStylus)
                {
                    //[self backspaceEditor];
                    int nStrokes = INK_StrokeCount( inkData, FALSE );
                    //    if ( edit != nil && nStrokes  <  1 && _firstTouch )
                    //        [edit processTouchAndHoldAtLocation:_previousLocation];
                    //    else
                    NSLog(@"stoke length: %d", strokeLen);
                    if (  edit != nil && nStrokes < 1 && strokeLen > 2 )
                    {
                        CGPoint	from = ptStroke[0].pt;
                        CGPoint to = ptStroke[strokeLen-1].pt;
                        [edit selectTextFromPosition:from toPosition:to];
                        
                        [edit replaceRange:edit.selectedTextRange withText:@""];
                    }
                    
                    strokeLen = 0;
                    [_currentStrokeView setNeedsDisplay];
                    return NO;
                }
                else
                {
                    if([self.edit.undoManager canUndo])
                        [self.edit.undoManager undo];
                    //[self recognizeInk:YES];
                    [self empty];
                }
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
    return NO;
}

-(void) processEditingMark:(NSString*) strText{
    strText = [strText stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([strText isEqualToString:@"->"] ||
       [strText isEqualToString:@"-)"] ||
       [strText isEqualToString:@"-}"] ||
       [strText isEqualToString:@"-]"] ||
       [strText isEqualToString:@"-7"]){
        
        [self.edit.toolBar.delegate richTextEditorToolbarDidSelectParagraphIndentation:ParagraphIndentationIncrease];
        [self recognizeInk:YES];
        [self empty];
    }else if([strText isEqualToString:@"<-"] ||
             [strText isEqualToString:@"C-"] ||
             [strText isEqualToString:@"[-"] ||
             [strText isEqualToString:@"{-"] ||
             [strText isEqualToString:@"(-"] ||
             [strText isEqualToString:@"E"]){
        [self.edit.toolBar.delegate richTextEditorToolbarDidSelectParagraphIndentation:ParagraphIndentationDecrease];
        [self recognizeInk:YES];
        [self empty];
    }else if([strText isEqualToString:@"0"] ||
             [strText isEqualToString:@"O"] ||
             [strText isEqualToString:@"o"] ||
             [strText isEqualToString:@"Q"]){
        CGRect rt = [self getMinMaxTopLeft];
        CGPoint toPos = CGPointMake(rt.origin.x + rt.size.width, rt.origin.y + rt.size.height);
        [self.edit selectTextFromPosition:rt.origin toPosition:toPos];
        numberOfPoints = 0;
        
        UIMenuController * menu = [UIMenuController sharedMenuController];
        float left = (rt.origin.x + toPos.x) / 2;
        float top = (rt.origin.y + toPos.y) / 2;
        CGRect rect = CGRectMake(left, top, 0, 0);
        [menu setTargetRect:rect inView:self.edit];
        menu.arrowDirection = UIMenuControllerArrowDefault;
        [menu setMenuVisible:YES animated:YES];
        
        [self recognizeInk:YES];
        [self empty];
        //[self.edit.toolBar.delegate richTextEditorToolbarDidSelectBold];
    }else if([strText isEqualToString:@"~"] ||
             [strText isEqualToString:@"n"] ||
             [strText isEqualToString:@"r"] ||
             [strText isEqualToString:@"N"]){
        
        //shows the stroke
        CGRect drawnRt = [self getMinMaxTopLeft];
        CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
        
        CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y + rbPos.y) / 2, 0, 0);
        [self showChangeStylePopupDialog:rt];
        [self recognizeInk:YES];
        [self empty];
    }else if([strText isEqualToString:@"1t"] ||
             [strText isEqualToString:@"lt"] ||
             [strText isEqualToString:@"A"]){
        //shows the Font
        CGRect drawnRt = [self getMinMaxTopLeft];
        CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
        
        CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y + rbPos.y) / 2, 0, 0);
        [self.edit.toolBar showFontSettingDialog:rt inView:self.edit];
        [self recognizeInk:YES];
        [self empty];
    }else if([strText isEqualToString:@"1"]){
        CGRect drawnRt = [self getMinMaxTopLeft];
        if(drawnRt.size.width < 10){
            CGPoint rbPos = CGPointMake(drawnRt.origin.x + drawnRt.size.width, drawnRt.origin.y + drawnRt.size.height);
            
            CGRect rt = CGRectMake((drawnRt.origin.x + rbPos.x) / 2, rbPos.y, 0, 0);
            [self.edit.toolBar showInsertMultimediaDialog:rt inView:self.edit];
            CGPoint cursorPos = CGPointMake((drawnRt.origin.x + rbPos.x) / 2, (drawnRt.origin.y +rbPos.y) / 2);
            [self.edit selectTextFromPosition:cursorPos toPosition:cursorPos];
            [self recognizeInk:YES];
            [self empty];
        }
    }else if([strText isEqualToString:@">"] ||
            [strText isEqualToString:@")"] ||
            [strText isEqualToString:@"}"] ||
            [strText isEqualToString:@"7"] ||
            [strText isEqualToString:@"]"]){
        if([self.edit.undoManager canUndo])
            [self.edit.undoManager undo];
//        else{
//            [self.edit undoAttribute];
//        }
        [self recognizeInk:YES];
        [self empty];
    }
}

-(void) redoDocument:(NSString*) strResult{
    NSString *strText = [strResult stringByReplacingOccurrencesOfString:@" " withString:@""];
    if([strText isEqualToString:@"<"] ||
       [strText isEqualToString:@"("] ||
       [strText isEqualToString:@"{"] ||
       [strText isEqualToString:@"C"] ||
       [strText isEqualToString:@"["]){
        if([self.edit.undoManager canRedo])
            [self.edit.undoManager redo];
//        else{
//            [self.edit redoAttribute];
//        }
        [self empty];
    }
}

#pragma mark - richTextEditorChangeStrokeViewControllerDelegate & RichTextEditorTextSyleDatasource
- (BOOL)richTextEditorFontPickerViewControllerShouldDisplayToolbar
{
    return ([self.edit.toolBar.dataSource presentationStyleForRichTextEditorToolbar] == RichTextEditorToolbarPresentationStyleModal) ? YES: NO;
}

- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeSize:(CGFloat) strokeSize
{
    strokeWidth = strokeSize;
}

- (void)richTextEditorChangeStrokeViewControllerDidSelectClose
{
    [self.edit.toolBar dismissViewController];
}

- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeType{
    
}
- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:(UIColor *)strColor{
    strokeColor = strColor;
}
- (CGFloat) richTextEditorChangeStrokeViewControllerStrokeSize{
    return strokeWidth;
}
- (int) richTextEditorChangeStrokeViewControllerStrokeType{
    return 0;
}
- (UIColor*) richTextEditorChangeStrokeViewControllerStrokeColor{
    return strokeColor;
}
- (void) showChangeStylePopupDialog:(CGRect) fromRect{
    RichTextEditorChangeStrokeViewController *insertMediaPopup= [[RichTextEditorChangeStrokeViewController alloc] init];
    insertMediaPopup.delegate = self;
    insertMediaPopup.dataSource = self;
    insertMediaPopup.contentSizeForViewInPopover = CGSizeMake(200, 200);
    insertMediaPopup.preferredContentSize = CGSizeMake(200, 200);
    [self.edit.toolBar showChangeStyleDialog:insertMediaPopup fromRect:fromRect inView:self.edit];
}
@end

