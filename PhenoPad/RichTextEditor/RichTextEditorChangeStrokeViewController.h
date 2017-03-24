

#import <UIKit/UIKit.h>

@protocol RichTextEditorChangeStrokeViewControllerDelegate <NSObject>

- (void)richTextEditorChangeStrokeViewControllerDidSelectClose;

- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeSize:(CGFloat) strokeSize;
- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeType;
- (void)richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:(UIColor*) strokeColor;
@end

@protocol RichTextEditorChangeStrokeViewControllerDataSource <NSObject>
- (BOOL)richTextEditorFontPickerViewControllerShouldDisplayToolbar;
- (CGFloat) richTextEditorChangeStrokeViewControllerStrokeSize;
- (int) richTextEditorChangeStrokeViewControllerStrokeType;
- (UIColor*) richTextEditorChangeStrokeViewControllerStrokeColor;
@end

@interface RichTextEditorChangeStrokeViewController : UIViewController

@property (nonatomic, weak) id <RichTextEditorChangeStrokeViewControllerDelegate> delegate;
@property (nonatomic, weak) id <RichTextEditorChangeStrokeViewControllerDataSource> dataSource;

@end
