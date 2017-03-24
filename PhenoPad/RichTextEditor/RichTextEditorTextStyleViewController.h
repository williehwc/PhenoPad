

#import <UIKit/UIKit.h>
#import "DropDownListView.h"

@protocol RichTextEditorTextStyleViewControllerDelegate <NSObject>
- (void)richTextEditorTextStyleViewControllerDidSelectFontWithName:(NSString *)fontName;
- (void)richTextEditorTextStyleViewControllerDidSelectClose;

- (void)richTextEditorTextStyleViewControllerDidSelectFontSize:(CGFloat) fontSize;
- (void)richTextEditorTextStyleViewControllerDidSelectBold;
- (void)richTextEditorTextStyleViewControllerDidSelectItalic;
- (void)richTextEditorTextStyleViewControllerDidSelectUnderline;
- (void)richTextEditorTextStyleViewControllerDidSelectFontColor:(UIColor*) fontColor;
@end

@protocol RichTextEditorTextStyleViewControllerDataSource <NSObject>
- (NSArray *)richTextEditorFontPickerViewControllerCustomFontFamilyNamesForSelection;
- (BOOL)richTextEditorFontPickerViewControllerShouldDisplayToolbar;
- (NSString*) richTextEditorTextStyleViewControllerFontName;
- (CGFloat) richTextEditorTextStyleViewControllerFontSize;
- (BOOL) richTextEditorTextStyleViewControllerBold;
- (BOOL) richTextEditorTextStyleViewControllerItalic;
- (BOOL) richTextEditorTextStyleViewControllerUnderline;
@end

@interface RichTextEditorTextStyleViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    DropDownListView * Dropobj;
}

@property (nonatomic, weak) id <RichTextEditorTextStyleViewControllerDelegate> delegate;
@property (nonatomic, weak) id <RichTextEditorTextStyleViewControllerDataSource> dataSource;
@property (nonatomic, strong) NSArray *fontNames;

@end
