
#import "RichTextEditor.h"
#import <QuartzCore/QuartzCore.h>
#import "UIFont+RichTextEditor.h"
#import "NSAttributedString+RichTextEditor.h"
#import "UIView+RichTextEditor.h"
// jixuan
#define RICHTEXTEDITOR_TOOLBAR_HEIGHT 0

@interface RichTextEditor() <RichTextEditorToolbarDelegate, RichTextEditorToolbarDataSource>{
    NSMutableArray *historyArray;
    int curNum;
}


// Gets set to YES when the user starts chaning attributes when there is no text selection (selecting bold, italic, etc)
// Gets set to NO  when the user changes selection or starts typing
@property (nonatomic, assign) BOOL typingAttributesInProgress;
@end

@implementation RichTextEditor

#pragma mark - Initialization -

- (id)init
{
    if (self = [super init])
	{
        [self commonInitialization];
    }
	
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
	{
        [self commonInitialization];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder])
	{
		[self commonInitialization];
	}
	
	return self;
}

- (void)commonInitialization
{
    self.borderColor = [UIColor lightGrayColor];
    self.borderWidth = 1.0;

	self.toolBar = [[RichTextEditorToolbar alloc] initWithFrame:CGRectMake(0, 0, [self currentScreenBoundsDependOnOrientation].size.width, RICHTEXTEDITOR_TOOLBAR_HEIGHT)
													   delegate:self
													 dataSource:self];
	
	self.typingAttributesInProgress = NO;
	self.defaultIndentationSize = 15;
	
	[self setupMenuItems];
    
    historyArray = [[NSMutableArray alloc] init];
    //If there is text already, then we do want to update the toolbar. Otherwise we don't.
    if ([self hasText]){
        [self updateToolbarState];
    }
    [self.undoManager setLevelsOfUndo:100000];
    
}

#pragma mark - Override Methods -

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
	[super setSelectedTextRange:selectedTextRange];
	
	[self updateToolbarState];
	self.typingAttributesInProgress = NO;
}

- (BOOL)canBecomeFirstResponder
{
	if (![self.dataSource respondsToSelector:@selector(shouldDisplayToolbarForRichTextEditor:)] ||
		[self.dataSource shouldDisplayToolbarForRichTextEditor:self])
	{
		self.inputAccessoryView = self.toolBar;
		
		// Redraw in case enabbled features have changes
        ///jixuan 
		//  [self.toolBar redraw];
        
	}
	else
	{
		self.inputAccessoryView = nil;
	}
	
	return [super canBecomeFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	RichTextEditorFeature features = [self featuresEnabledForRichTextEditorToolbar];
	
	if ([self.dataSource respondsToSelector:@selector(shouldDisplayRichTextOptionsInMenuControllerForRichTextEditor:)] &&
		[self.dataSource shouldDisplayRichTextOptionsInMenuControllerForRichTextEditor:self])
	{
		if (action == @selector(richTextEditorToolbarDidSelectBold) && (features & RichTextEditorFeatureBold  || features & RichTextEditorFeatureAll))
			return YES;
		
		if (action == @selector(richTextEditorToolbarDidSelectItalic) && (features & RichTextEditorFeatureItalic  || features & RichTextEditorFeatureAll))
			return YES;
		
		if (action == @selector(richTextEditorToolbarDidSelectUnderline) && (features & RichTextEditorFeatureUnderline  || features & RichTextEditorFeatureAll))
			return YES;
		
		if (action == @selector(richTextEditorToolbarDidSelectStrikeThrough) && (features & RichTextEditorFeatureStrikeThrough  || features & RichTextEditorFeatureAll))
			return YES;
	}
	
	if (action == @selector(selectParagraph:) && self.selectedRange.length > 0)
		return YES;
	
	return [super canPerformAction:action withSender:sender];
}

#pragma mark - MenuController Methods -

- (void)setupMenuItems
{
//	UIMenuItem *selectParagraph = [[UIMenuItem alloc] initWithTitle:@"Select Paragraph" action:@selector(selectParagraph:)];
//	UIMenuItem *boldItem = [[UIMenuItem alloc] initWithTitle:@"Bold" action:@selector(richTextEditorToolbarDidSelectBold)];
//	UIMenuItem *italicItem = [[UIMenuItem alloc] initWithTitle:@"Italic" action:@selector(richTextEditorToolbarDidSelectItalic)];
//	UIMenuItem *underlineItem = [[UIMenuItem alloc] initWithTitle:@"Underline" action:@selector(richTextEditorToolbarDidSelectUnderline)];
//	UIMenuItem *strikeThroughItem = [[UIMenuItem alloc] initWithTitle:@"Strike" action:@selector(richTextEditorToolbarDidSelectStrikeThrough)];
	
//	[[UIMenuController sharedMenuController] setMenuItems:@[selectParagraph, boldItem, italicItem, underlineItem, strikeThroughItem]];
    
    UIMenuItem *highLightItem = [[UIMenuItem alloc] initWithTitle:@"Highlight" action:@selector(richTextEditorMenuDidSelectHighLight)];
    [[UIMenuController sharedMenuController] setMenuItems:@[highLightItem]];
    

}

- (void)selectParagraph:(id)sender
{
    if (![self hasText])
		return;
	
	NSRange range = [self.attributedText firstParagraphRangeFromTextRange:self.selectedRange];
	[self setSelectedRange:range];

	[[UIMenuController sharedMenuController] setTargetRect:[self frameOfTextAtRange:self.selectedRange] inView:self];
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

#pragma mark - Public Methods -

- (NSString *)htmlString
{
	return [self.attributedText htmlString];
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

#pragma mark - RichTextEditorToolbarDelegate Methods -

- (void)richTextEditorToolbarDidSelectBold
{
	UIFont *font = [self fontAtIndex:self.selectedRange.location];
	[self applyFontAttributesToSelectedRangeWithBoldTrait:[NSNumber numberWithBool:![font isBold]] italicTrait:nil fontName:nil fontSize:nil];
}

- (void)richTextEditorToolbarDidSelectItalic
{
	UIFont *font = [self fontAtIndex:self.selectedRange.location];
	[self applyFontAttributesToSelectedRangeWithBoldTrait:nil italicTrait:[NSNumber numberWithBool:![font isItalic]] fontName:nil fontSize:nil];
}

- (void)richTextEditorToolbarDidSelectFontSize:(NSNumber *)fontSize
{
	[self applyFontAttributesToSelectedRangeWithBoldTrait:nil italicTrait:nil fontName:nil fontSize:fontSize];
}

- (void)richTextEditorToolbarDidSelectFontWithName:(NSString *)fontName
{
	[self applyFontAttributesToSelectedRangeWithBoldTrait:nil italicTrait:nil fontName:fontName fontSize:nil];
}

- (void)richTextEditorToolbarDidSelectTextBackgroundColor:(UIColor *)color
{
	[self applyAttrubutesToSelectedRange:color forKey:NSBackgroundColorAttributeName];
}

- (void)richTextEditorToolbarDidSelectTextForegroundColor:(UIColor *)color
{
	[self applyAttrubutesToSelectedRange:color forKey:NSForegroundColorAttributeName];
}

- (void) richTextEditorDidInsertImage:(int)mediaType{
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    switch (mediaType) {
        case 0: // Text
        default:
            textAttachment.image = [UIImage imageNamed:@"TextBtn"];
//            textAttachment.fileType = @"Text";
            break;
        case 1: // Image
            textAttachment.image = [UIImage imageNamed:@"ImageBtn"];
//            textAttachment.fileType = @"Image";
            break;
            
        case 2: // voice
            textAttachment.image = [UIImage imageNamed:@"VoiceBtn"];
//            textAttachment.fileType = @"Voice";
            break;
            
        case 3:
            textAttachment.image = [UIImage imageNamed:@"VideoBtn"];
//            textAttachment.fileType = @"Video";
            break;
    }
    //I'm subtracting 10px to make the image display nicely, accounting
    //for the padding inside the textView
    UIFont *font = [self.typingAttributes objectForKey:NSFontAttributeName];
    CGFloat scale = 6.0f / (font.pointSize / 20.0f);
    textAttachment.image = [UIImage imageWithCGImage:textAttachment.image.CGImage scale:scale orientation:UIImageOrientationUp];
    
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    
    NSRange range = self.selectedRange;
    // If any text selected apply attributes to text
    if (range.length > 0)
    {
        NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
        
        // Workaround for when there is only one paragraph,
        // sometimes the attributedString is actually longer by one then the displayed text,
        // and this results in not being able to set to lef align anymore.
        if (range.length == attributedString.length-1 && range.length == self.text.length)
            ++range.length;        
        //[attributedString replaceCharactersInRange:range withAttributedString:attrStringWithImage];
        [self replaceSelectionWithAttributedText:attrStringWithImage];
        [self saveHistory];
    }
    // If no text is selected apply attributes to typingAttribute
    else
    {
        NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
        [attributedString insertAttributedString:attrStringWithImage atIndex:range.location];
        [self replaceSelectionWithAttributedText:attrStringWithImage];
        //[self setAttributedText:attributedString];
        [self saveHistory];
    }
}

- (void)richTextEditorMenuDidSelectHighLight{
    NSMutableAttributedString *attrSelectedString = [self.attributedText attributedSubstringFromRange:self.selectedRange];
    NSDictionary *attributesFromString = [attrSelectedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, attrSelectedString.length)];
    if([attributesFromString objectForKey:@"NSBackgroundColor"] != nil && [attributesFromString objectForKey:@"NSBackgroundColor"] == [UIColor yellowColor]){
        [self applyAttrubutesToSelectedRange:[UIColor whiteColor] forKey:NSBackgroundColorAttributeName];
    }
    else{
        [self applyAttrubutesToSelectedRange:[UIColor yellowColor] forKey:NSBackgroundColorAttributeName];
    }
    
}

- (void)richTextEditorToolbarDidSelectUnderline
{
	NSDictionary *dictionary = [self dictionaryAtIndex:self.selectedRange.location];
	NSNumber *existingUnderlineStyle = [dictionary objectForKey:NSUnderlineStyleAttributeName];
	
	if (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone)
		existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
	else
		existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleNone];
	
	[self applyAttrubutesToSelectedRange:existingUnderlineStyle forKey:NSUnderlineStyleAttributeName];
}

- (void)richTextEditorToolbarDidSelectStrikeThrough
{
	NSDictionary *dictionary = [self dictionaryAtIndex:self.selectedRange.location];
	NSNumber *existingUnderlineStyle = [dictionary objectForKey:NSStrikethroughStyleAttributeName];
	
	if (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone)
		existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleSingle];
	else
		existingUnderlineStyle = [NSNumber numberWithInteger:NSUnderlineStyleNone];
	
	[self applyAttrubutesToSelectedRange:existingUnderlineStyle forKey:NSStrikethroughStyleAttributeName];
}

- (void)richTextEditorToolbarDidSelectParagraphIndentation:(ParagraphIndentation)paragraphIndentation
{
	[self enumarateThroughParagraphsInRange:self.selectedRange withBlock:^(NSRange paragraphRange){
		NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
		NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
		
		if (!paragraphStyle)
			paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		
		if (paragraphIndentation == ParagraphIndentationIncrease)
		{
			paragraphStyle.headIndent += self.defaultIndentationSize;
			paragraphStyle.firstLineHeadIndent += self.defaultIndentationSize;
		}
		else if (paragraphIndentation == ParagraphIndentationDecrease)
		{
			paragraphStyle.headIndent -= self.defaultIndentationSize;
			paragraphStyle.firstLineHeadIndent -= self.defaultIndentationSize;
			
			if (paragraphStyle.headIndent < 0)
				paragraphStyle.headIndent = 0;
			
			if (paragraphStyle.firstLineHeadIndent < 0)
				paragraphStyle.firstLineHeadIndent = 0;
		}
		
		[self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphRange];
	}];
}

- (void)richTextEditorToolbarDidSelectParagraphFirstLineHeadIndent
{
	[self enumarateThroughParagraphsInRange:self.selectedRange withBlock:^(NSRange paragraphRange){
		NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
		NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
		
		if (!paragraphStyle)
			paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		
		if (paragraphStyle.headIndent == paragraphStyle.firstLineHeadIndent)
		{
			paragraphStyle.firstLineHeadIndent += self.defaultIndentationSize;
		}
		else
		{
			paragraphStyle.firstLineHeadIndent = paragraphStyle.headIndent;
		}
		
		[self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphRange];
	}];
}

- (void)richTextEditorToolbarDidSelectTextAlignment:(NSTextAlignment)textAlignment
{
	[self enumarateThroughParagraphsInRange:self.selectedRange withBlock:^(NSRange paragraphRange){
		NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
		NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
		
		if (!paragraphStyle)
			paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		
		paragraphStyle.alignment = textAlignment;
		
		[self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphRange];
	}];
}

- (void)richTextEditorToolbarDidSelectBulletPoint
{
    // TODO: implement this
}

#pragma mark - Private Methods -

- (CGRect)frameOfTextAtRange:(NSRange)range
{
	UITextRange *selectionRange = [self selectedTextRange];
	NSArray *selectionRects = [self selectionRectsForRange:selectionRange];
	CGRect completeRect = CGRectNull;
	
	for (UITextSelectionRect *selectionRect in selectionRects)
	{
		completeRect = (CGRectIsNull(completeRect))
			? selectionRect.rect
			: CGRectUnion(completeRect,selectionRect.rect);
	}
	
	return completeRect;
}

- (void)enumarateThroughParagraphsInRange:(NSRange)range withBlock:(void (^)(NSRange paragraphRange))block
{
	if (![self hasText])
		return;
	
	NSArray *rangeOfParagraphsInSelectedText = [self.attributedText rangeOfParagraphsFromTextRange:self.selectedRange];
	
	for (int i=0 ; i<rangeOfParagraphsInSelectedText.count ; i++)
	{
		NSValue *value = [rangeOfParagraphsInSelectedText objectAtIndex:i];
		NSRange paragraphRange = [value rangeValue];
		block(paragraphRange);
	}
	
	NSRange fullRange = [self fullRangeFromArrayOfParagraphRanges:rangeOfParagraphsInSelectedText];
	[self setSelectedRange:fullRange];
}

- (void)updateToolbarState
{
	// If no text exists or typing attributes is in progress update toolbar using typing attributes instead of selected text
	if (self.typingAttributesInProgress || ![self hasText])
	{
		[self.toolBar updateStateWithAttributes:self.typingAttributes];
	}
	else
	{
		int location = [self offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];
		
		if (location == self.text.length)
			location --;
		
		[self.toolBar updateStateWithAttributes:[self.attributedText attributesAtIndex:location effectiveRange:nil]];
	}
}

- (NSRange)fullRangeFromArrayOfParagraphRanges:(NSArray *)paragraphRanges
{
	if (!paragraphRanges.count)
		return NSMakeRange(0, 0);
	
	NSRange firstRange = [[paragraphRanges objectAtIndex:0] rangeValue];
	NSRange lastRange = [[paragraphRanges lastObject] rangeValue];
	return NSMakeRange(firstRange.location, lastRange.location + lastRange.length - firstRange.location);
}

- (UIFont *)fontAtIndex:(NSInteger)index
{
	// If index at end of string, get attributes starting from previous character
	if (index == self.attributedText.string.length && [self hasText])
		--index;
    
	// If no text exists get font from typing attributes
    NSDictionary *dictionary = ([self hasText])
		? [self.attributedText attributesAtIndex:index effectiveRange:nil]
		: self.typingAttributes;
    
    return [dictionary objectForKey:NSFontAttributeName];
}

- (NSDictionary *)dictionaryAtIndex:(NSInteger)index
{
	// If index at end of string, get attributes starting from previous character
	if (index == self.attributedText.string.length && [self hasText])
        --index;
	
    // If no text exists get font from typing attributes
    return  ([self hasText])
		? [self.attributedText attributesAtIndex:index effectiveRange:nil]
		: self.typingAttributes;
}

- (void)applyAttributeToTypingAttribute:(id)attribute forKey:(NSString *)key
{
	NSMutableDictionary *dictionary = [self.typingAttributes mutableCopy];
	[dictionary setObject:attribute forKey:key];
	[self setTypingAttributes:dictionary];
}

- (void)applyAttributes:(id)attribute forKey:(NSString *)key atRange:(NSRange)range
{
	// If any text selected apply attributes to text
	if (range.length > 0)
	{
		NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
        
        // Workaround for when there is only one paragraph,
		// sometimes the attributedString is actually longer by one then the displayed text,
		// and this results in not being able to set to lef align anymore.
        if (range.length == attributedString.length-1 && range.length == self.text.length)
            ++range.length;
        //[attributedString addAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] range:range];
        
        NSMutableAttributedString *attrSelectedString = [[self.attributedText attributedSubstringFromRange:range] mutableCopy];
        NSString *selectedText = [attrSelectedString string];
        NSRange attrSelectedNewRange = NSMakeRange(0, selectedText.length);
		[attrSelectedString addAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] range:attrSelectedNewRange];
        [self replaceRange:range withAttributedText:attrSelectedString];
        
		[self setSelectedRange:range];
        [self saveHistory];
	}
	// If no text is selected apply attributes to typingAttribute
	else
	{
		self.typingAttributesInProgress = YES;
		[self applyAttributeToTypingAttribute:attribute forKey:key];
	}
	
	[self updateToolbarState];
}

- (void)applyAttrubutesToSelectedRange:(id)attribute forKey:(NSString *)key
{
	[self applyAttributes:attribute forKey:key atRange:self.selectedRange];
}

- (void)applyFontAttributesToSelectedRangeWithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize
{
	[self applyFontAttributesWithBoldTrait:isBold italicTrait:isItalic fontName:fontName fontSize:fontSize toTextAtRange:self.selectedRange];
}

- (void)applyFontAttributesWithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize toTextAtRange:(NSRange)range
{
	// If any text selected apply attributes to text
	if (range.length > 0)
	{
		NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
		
		[attributedString beginEditing];
		[attributedString enumerateAttributesInRange:range
											 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
										  usingBlock:^(NSDictionary *dictionary, NSRange range, BOOL *stop){
											  
											  UIFont *newFont = [self fontwithBoldTrait:isBold
																			italicTrait:isItalic
																			   fontName:fontName
																			   fontSize:fontSize
																		 fromDictionary:dictionary];
											  
                                              if (newFont){
                                                  NSMutableAttributedString *attrSelectedString = [[self.attributedText attributedSubstringFromRange:range] mutableCopy];
                                                  NSString *selectedText = [attrSelectedString string];
                                                  NSRange attrSelectedNewRange = NSMakeRange(0, selectedText.length);
                                                  [attrSelectedString addAttributes:[NSDictionary dictionaryWithObject:newFont forKey:NSFontAttributeName] range:attrSelectedNewRange];
                                                  [self replaceRange:range withAttributedText:attrSelectedString];
                                              }
										  }];
		[attributedString endEditing];
		
		[self setSelectedRange:range];
	}
	// If no text is selected apply attributes to typingAttribute
	else
	{		
		self.typingAttributesInProgress = YES;
		
		UIFont *newFont = [self fontwithBoldTrait:isBold
									  italicTrait:isItalic
										 fontName:fontName
										 fontSize:fontSize
								   fromDictionary:self.typingAttributes];
		if (newFont) 
            [self applyAttributeToTypingAttribute:newFont forKey:NSFontAttributeName];
	}
	
	[self updateToolbarState];
}

// Returns a font with given attributes. For any missing parameter takes the attribute from a given dictionary
- (UIFont *)fontwithBoldTrait:(NSNumber *)isBold italicTrait:(NSNumber *)isItalic fontName:(NSString *)fontName fontSize:(NSNumber *)fontSize fromDictionary:(NSDictionary *)dictionary
{
	UIFont *newFont = nil;
	UIFont *font = [dictionary objectForKey:NSFontAttributeName];
	BOOL newBold = (isBold) ? isBold.intValue : [font isBold];
	BOOL newItalic = (isItalic) ? isItalic.intValue : [font isItalic];
	CGFloat newFontSize = (fontSize) ? fontSize.floatValue : font.pointSize;
	
	if (fontName)
	{
		newFont = [UIFont fontWithName:fontName size:newFontSize boldTrait:newBold italicTrait:newItalic];
	}
	else
	{
		newFont = [font fontWithBoldTrait:newBold italicTrait:newItalic andSize:newFontSize];
	}
	
	return newFont;
}

- (CGRect)currentScreenBoundsDependOnOrientation
{
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
	
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
	{
        screenBounds.size = CGSizeMake(width, height);
    }
	else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
	{
        screenBounds.size = CGSizeMake(height, width);
    }
	
    return screenBounds ;
}

#pragma mark - RichTextEditorToolbarDataSource Methods -

- (NSArray *)fontFamilySelectionForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(fontFamilySelectionForRichTextEditor:)])
	{
		return [self.dataSource fontFamilySelectionForRichTextEditor:self];
	}
	
	return nil;
}

- (NSArray *)fontSizeSelectionForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(fontSizeSelectionForRichTextEditor:)])
	{
		return [self.dataSource fontSizeSelectionForRichTextEditor:self];
	}
	
	return nil;
}

- (RichTextEditorToolbarPresentationStyle)presentationStyleForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(presentationStyleForRichTextEditor:)])
	{
		return [self.dataSource presentationStyleForRichTextEditor:self];
	}

	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		? RichTextEditorToolbarPresentationStylePopover
		: RichTextEditorToolbarPresentationStyleModal;
}

- (UIModalPresentationStyle)modalPresentationStyleForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(modalPresentationStyleForRichTextEditor:)])
	{
		return [self.dataSource modalPresentationStyleForRichTextEditor:self];
	}
	
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		? UIModalPresentationFormSheet
		: UIModalPresentationFullScreen;
}

- (UIModalTransitionStyle)modalTransitionStyleForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(modalTransitionStyleForRichTextEditor:)])
	{
		return [self.dataSource modalTransitionStyleForRichTextEditor:self];
	}
	
	return UIModalTransitionStyleCoverVertical;
}

- (RichTextEditorFeature)featuresEnabledForRichTextEditorToolbar
{
	if (self.dataSource && [self.dataSource respondsToSelector:@selector(featuresEnabledForRichTextEditor:)])
	{
		return [self.dataSource featuresEnabledForRichTextEditor:self];
	}
	
	return RichTextEditorFeatureAll;
}

- (UIViewController *)firsAvailableViewControllerForRichTextEditorToolbar
{
	return [self firstAvailableViewController];
}

//Edit document function by hand
- (void) ParagraphIndentIncrease{
    [self enumarateThroughParagraphsInRange:self.selectedRange withBlock:^(NSRange paragraphRange){
        NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
        NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
        if (!paragraphStyle)
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.headIndent += self.defaultIndentationSize;
        paragraphStyle.firstLineHeadIndent += self.defaultIndentationSize;
        [self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphRange];
    }];

}

- (void) ParagraphIndentDecrease{
    [self enumarateThroughParagraphsInRange:self.selectedRange withBlock:^(NSRange paragraphRange){
        NSDictionary *dictionary = [self dictionaryAtIndex:paragraphRange.location];
        NSMutableParagraphStyle *paragraphStyle = [[dictionary objectForKey:NSParagraphStyleAttributeName] mutableCopy];
        
        if (!paragraphStyle)
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.headIndent -= self.defaultIndentationSize;
        paragraphStyle.firstLineHeadIndent -= self.defaultIndentationSize;
        
        if (paragraphStyle.headIndent < 0)
            paragraphStyle.headIndent = 0;
        
        if (paragraphStyle.firstLineHeadIndent < 0)
            paragraphStyle.firstLineHeadIndent = 0;
        //[self applyAttributes:paragraphStyle forKey:NSParagraphStyleAttributeName atRange:paragraphRange];
    }];

}


- (void) saveHistory{
    [historyArray addObject:self.attributedText];
    curNum = (int)historyArray.count;
}

- (void) undoAttribute{
    if(curNum == 0)
        return;
    curNum -= 1;
    [self setAttributedText:(NSAttributedString*)[historyArray objectAtIndex:curNum]];
}

- (void) redoAttribute{
    if(curNum >= historyArray.count - 1 || historyArray.count == 0)
        return;
    curNum += 1;
    
    [self setAttributedText:(NSAttributedString*)[historyArray objectAtIndex:curNum]];
}
@end
