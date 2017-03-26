//
//  RichTextEditorToolbar.m
//  RichTextEdtor
//
//  Created by Aryan Gh on 7/21/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//
// https://github.com/aryaxt/iOS-Rich-Text-Editor
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PhenotypeToolbar.h"
#import <CoreText/CoreText.h>
#import "RichTextEditorPopover.h"
#import "RichTextEditorFontSizePickerViewController.h"
#import "RichTextEditorFontPickerViewController.h"
#import "RichTextEditorColorPickerViewController.h"
#import "RichTextEditorTextStyleViewController.h"
#import "RichTextEditorChangeStrokeViewController.h"
#import "RichTextEditorInsertMultimediaViewController.h"
#import "WEPopoverController.h"
#import "RichTextEditorToggleButton.h"
#import "UIFont+RichTextEditor.h"

#import "PhenotypePickerViewController.h"


#define ITEM_SEPARATOR_SPACE 5
#define ITEM_TOP_AND_BOTTOM_BORDER 5
#define ITEM_WITH 40

@interface PhenotypeToolbar() <PhenotypePickerViewControllerDelegate, PhenotypePickerViewControllerDataSource, RichTextEditorFontSizePickerViewControllerDelegate, RichTextEditorFontSizePickerViewControllerDataSource, RichTextEditorFontPickerViewControllerDelegate, RichTextEditorFontPickerViewControllerDataSource, RichTextEditorColorPickerViewControllerDataSource, RichTextEditorColorPickerViewControllerDelegate, RichTextEditorTextStyleViewControllerDelegate, RichTextEditorTextStyleViewControllerDataSource,
    RichTextEditorInsertMultimediaViewControllerDelegate,
    RichTextEditorInsertMultimediaViewControllerDataSource>{
    UIFont * curFont;
}
@property (nonatomic, strong) id <RichTextEditorPopover> popover;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBold;
@property (nonatomic, strong) RichTextEditorToggleButton *btnItalic;
@property (nonatomic, strong) RichTextEditorToggleButton *btnUnderline;
@property (nonatomic, strong) RichTextEditorToggleButton *btnStrikeThrough;
@property (nonatomic, strong) RichTextEditorToggleButton *btnFontSize;
@property (nonatomic, strong) RichTextEditorToggleButton *btnFont;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBackgroundColor;
@property (nonatomic, strong) RichTextEditorToggleButton *btnForegroundColor;
@property (nonatomic, strong) RichTextEditorToggleButton *btnTextAlignmentLeft;
@property (nonatomic, strong) RichTextEditorToggleButton *btnTextAlignmentCenter;
@property (nonatomic, strong) RichTextEditorToggleButton *btnTextAlignmentRight;
@property (nonatomic, strong) RichTextEditorToggleButton *btnTextAlignmentJustified;
@property (nonatomic, strong) RichTextEditorToggleButton *btnParagraphIndent;
@property (nonatomic, strong) RichTextEditorToggleButton *btnParagraphOutdent;
@property (nonatomic, strong) RichTextEditorToggleButton *btnParagraphFirstLineHeadIndent;
@property (nonatomic, strong) RichTextEditorToggleButton *btnBulletPoint;

@property (nonatomic, strong) NSMutableArray* btnNames;
@property (nonatomic, strong) NSMutableArray* btns;
@end

@implementation PhenotypeToolbar

#pragma mark - Initialization -

- (id)initWithFrame:(CGRect)frame delegate:(id <PhenotypeToolbarDelegate>)delegate dataSource:(id <PhenotypeToolbarDataSource>)dataSource
{
	if (self = [super initWithFrame:frame])
	{
		self.delegate = delegate;
		self.dataSource = dataSource;
		
		self.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
		self.layer.borderWidth = .7;
		self.layer.borderColor = [UIColor lightGrayColor].CGColor;
		
        self.btns = [[NSMutableArray alloc] init];
        self.btnNames = [[NSMutableArray alloc] init];
        
		[self initializeButtons];
        [self populateToolbar];
	}
	
	return self;
}

#pragma mark - Public Methods -

- (void)redraw
{
	[self populateToolbar];
}

- (void)updateStateWithAttributes:(NSDictionary *)attributes
{
	UIFont *font = [attributes objectForKey:NSFontAttributeName];
    curFont = font;
	NSParagraphStyle *paragraphTyle = [attributes objectForKey:NSParagraphStyleAttributeName];
	
	[self.btnFontSize setTitle:[NSString stringWithFormat:@"%.f", font.pointSize] forState:UIControlStateNormal];
	[self.btnFont setTitle:font.familyName forState:UIControlStateNormal];
	
	self.btnBold.on = [font isBold];
	self.btnItalic.on = [font isItalic];
	
	self.btnTextAlignmentLeft.on = NO;
	self.btnTextAlignmentCenter.on = NO;
	self.btnTextAlignmentRight.on = NO;
	self.btnTextAlignmentJustified.on = NO;
	self.btnParagraphFirstLineHeadIndent.on = (paragraphTyle.firstLineHeadIndent > paragraphTyle.headIndent) ? YES : NO;
	
	switch (paragraphTyle.alignment)
	{
		case NSTextAlignmentLeft:
			self.btnTextAlignmentLeft.on = YES;
			break;
		case NSTextAlignmentCenter:
			self.btnTextAlignmentCenter.on = YES;
			break;
			
		case NSTextAlignmentRight:
			self.btnTextAlignmentRight.on = YES;
			break;
			
		case NSTextAlignmentJustified:
			self.btnTextAlignmentJustified.on = YES;
			break;
			
		default:
			self.btnTextAlignmentLeft.on = YES;
			break;
	}
	
	NSNumber *existingUnderlineStyle = [attributes objectForKey:NSUnderlineStyleAttributeName];
	self.btnUnderline.on = (!existingUnderlineStyle || existingUnderlineStyle.intValue == NSUnderlineStyleNone) ? NO :YES;
	
	NSNumber *existingStrikeThrough = [attributes objectForKey:NSStrikethroughStyleAttributeName];
	self.btnStrikeThrough.on = (!existingStrikeThrough || existingStrikeThrough.intValue == NSUnderlineStyleNone) ? NO :YES;
}

#pragma mark - IBActions -



- (void)fontSizeSelected:(UIButton *)sender
{
	RichTextEditorFontSizePickerViewController *fontSizePicker = [[RichTextEditorFontSizePickerViewController alloc] init];
	fontSizePicker.delegate = self;
	fontSizePicker.dataSource = self;
	[self presentViewController:fontSizePicker fromView:sender];
}

- (void)fontSelected:(UIButton *)sender
{
	RichTextEditorFontPickerViewController *fontPicker= [[RichTextEditorFontPickerViewController alloc] init];
	fontPicker.fontNames = [self.dataSource fontFamilySelectionForRichTextEditorToolbar];
	fontPicker.delegate = self;
	fontPicker.dataSource = self;
	[self presentViewController:fontPicker fromView:sender];
}

- (void)textBackgroundColorSelected:(UIButton *)sender
{
	RichTextEditorColorPickerViewController *colorPicker = [[RichTextEditorColorPickerViewController alloc] init];
	colorPicker.action = RichTextEditorColorPickerActionTextBackgroundColor;
	colorPicker.delegate = self;
	colorPicker.dataSource = self;
	[self presentViewController:colorPicker fromView:sender];
}

- (void)textForegroundColorSelected:(UIButton *)sender
{
	RichTextEditorColorPickerViewController *colorPicker = [[RichTextEditorColorPickerViewController alloc] init];
	colorPicker.action = RichTextEditorColorPickerActionTextForegroudColor;
	colorPicker.delegate = self;
	colorPicker.dataSource = self;
	[self presentViewController:colorPicker fromView:sender];
}


#pragma mark - Private Methods -

- (void)populateToolbar
{
    // Remove any existing subviews.
    for (UIView *subView in self.subviews)
	{
        [subView removeFromSuperview];
    }
    
    UIView *lastAddedView = nil;
    
    for(RichTextEditorToggleButton* btn in self.btns){
        UIView *separatorView = [self separatorView];
        [self addView:btn afterView:lastAddedView withSpacing:YES];
        [self addView:separatorView afterView:btn withSpacing:YES];
        lastAddedView = separatorView;
    }
}

- (void)btnSelected:(UIButton *)sender
{
    PhenotypePickerViewController *phenoPicker= [[PhenotypePickerViewController alloc] init];
    phenoPicker.phenoNames = [self.dataSource phenotypeToolbarDataSourceRelatedPhenotypes];
    phenoPicker.delegate = self;
    phenoPicker.dataSource = self;
    [self presentViewController:phenoPicker fromView:sender];
}

- (void)initializeButtons
{
    for(NSString* name in self.btnNames){
        RichTextEditorToggleButton* btn = [self getButton:120 andSelector:@selector(btnSelected:)];
        [btn setTitle:name forState:UIControlStateNormal];
        [self.btns addObject: btn];
    }
    
}
- (RichTextEditorToggleButton *)getButton:(NSInteger)width andSelector:(SEL)selector
{
    RichTextEditorToggleButton *button = [[RichTextEditorToggleButton alloc] init];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, width, 0)];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
    [button.titleLabel setTextColor:[UIColor blackColor]];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    return button;
}

- (RichTextEditorToggleButton *)buttonWithImageNamed:(NSString *)image width:(NSInteger)width andSelector:(SEL)selector
{
	RichTextEditorToggleButton *button = [[RichTextEditorToggleButton alloc] init];
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	[button setFrame:CGRectMake(0, 0, width, 0)];
	[button.titleLabel setFont:[UIFont boldSystemFontOfSize:10]];
	[button.titleLabel setTextColor:[UIColor blackColor]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
	
	return button;
}

- (RichTextEditorToggleButton *)buttonWithImageNamed:(NSString *)image andSelector:(SEL)selector
{
	return [self buttonWithImageNamed:image width:ITEM_WITH andSelector:selector];
}

- (UIView *)separatorView
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.frame.size.height)];
	view.backgroundColor = [UIColor lightGrayColor];
	
	return view;
}

- (void)addView:(UIView *)view afterView:(UIView *)otherView withSpacing:(BOOL)space
{
	CGRect otherViewRect = (otherView) ? otherView.frame : CGRectZero;
	CGRect rect = view.frame;
	rect.origin.x = otherViewRect.size.width + otherViewRect.origin.x;
	if (space)
		rect.origin.x += ITEM_SEPARATOR_SPACE;
	
	rect.origin.y = ITEM_TOP_AND_BOTTOM_BORDER;
	rect.size.height = self.frame.size.height - (2*ITEM_TOP_AND_BOTTOM_BORDER);
	view.frame = rect;
	view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	
	[self addSubview:view];
	[self updateContentSize];
}

- (void)updateContentSize
{
	NSInteger maxViewlocation = 0;
	
	for (UIView *view in self.subviews)
	{
		NSInteger endLocation = view.frame.size.width + view.frame.origin.x;
		
		if (endLocation > maxViewlocation)
			maxViewlocation = endLocation;
	}
	
	self.contentSize = CGSizeMake(maxViewlocation+ITEM_SEPARATOR_SPACE, self.frame.size.height);
}

- (void)presentViewController:(UIViewController *)viewController fromView:(UIView *)view
{
    [[self.dataSource firsAvailableViewControllerForRichTextEditorToolbar] presentViewController:viewController animated:YES completion:nil];

//    id <RichTextEditorPopover> popover = [self popoverWithViewController:viewController];
//    [popover presentPopoverFromRect:view.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];

//	if ([self.dataSource presentationStyleForRichTextEditorToolbar] == RichTextEditorToolbarPresentationStyleModal)
//	{
//		viewController.modalPresentationStyle = [self.dataSource modalPresentationStyleForRichTextEditorToolbar];
//		viewController.modalTransitionStyle = [self.dataSource modalTransitionStyleForRichTextEditorToolbar];
//		[[self.dataSource firsAvailableViewControllerForRichTextEditorToolbar] presentViewController:viewController animated:YES completion:nil];
//	}
//	else if ([self.dataSource presentationStyleForRichTextEditorToolbar] == RichTextEditorToolbarPresentationStylePopover)
//	{
//		id <RichTextEditorPopover> popover = [self popoverWithViewController:viewController];
//		[popover presentPopoverFromRect:view.frame inView:self permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
//	}
}

- (id <RichTextEditorPopover>)popoverWithViewController:(UIViewController *)viewController
{
	id <RichTextEditorPopover> popover;
	
	if (!popover)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			popover = (id<RichTextEditorPopover>) [[UIPopoverController alloc] initWithContentViewController:viewController];
		}
		else
		{
			popover = (id<RichTextEditorPopover>) [[WEPopoverController alloc] initWithContentViewController:viewController];
		}
	}
	
	[self.popover dismissPopoverAnimated:YES];
	self.popover = popover;
	
	return popover;
}

- (void)dismissViewController{

		[[self.dataSource firsAvailableViewControllerForRichTextEditorToolbar] dismissViewControllerAnimated:YES completion:NO];

		// [self.popover dismissPopoverAnimated:YES];
}

@end
