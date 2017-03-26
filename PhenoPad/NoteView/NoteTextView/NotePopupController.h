//
//  NotePopupController.h
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-25.
//  Copyright © 2017 CCM. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "DropDownListView.h"
typedef enum POPUP_BUTTONS{
    keyboard, stylus, camera, photo, video
} POPBUTTON_TYPE;

@protocol NotePopupControllerDelegate <NSObject>
- (void) NotePopupControllerDidSelect:(POPBUTTON_TYPE) btn;
@end

@protocol NotePopupControllerDataSource <NSObject>
- (NSArray *)richTextEditorFontPickerViewControllerCustomFontFamilyNamesForSelection;
- (BOOL)richTextEditorFontPickerViewControllerShouldDisplayToolbar;
- (NSString*) richTextEditorTextStyleViewControllerFontName;
- (CGFloat) richTextEditorTextStyleViewControllerFontSize;
- (BOOL) richTextEditorTextStyleViewControllerBold;
- (BOOL) richTextEditorTextStyleViewControllerItalic;
- (BOOL) richTextEditorTextStyleViewControllerUnderline;
@end

@interface NotePopupController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    DropDownListView * Dropobj;
}
@property (nonatomic, weak) id <NotePopupControllerDelegate> delegate;
@property (nonatomic, weak) id <NotePopupControllerDataSource> dataSource;
@property (nonatomic, strong) NSArray *fontNames;

@end
