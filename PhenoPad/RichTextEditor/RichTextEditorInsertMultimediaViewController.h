

#import <UIKit/UIKit.h>

@protocol RichTextEditorInsertMultimediaViewControllerDelegate <NSObject>
- (void)richTextEditorInsertMultimediaViewControllerDidInsertImage;
- (void)richTextEditorInsertMultimediaViewControllerDidInsertVoice;
- (void)richTextEditorInsertMultimediaViewControllerDidInsertVideo;
- (void)richTextEditorInsertMultimediaViewControllerDidInsertDocument;
@end

@protocol RichTextEditorInsertMultimediaViewControllerDataSource <NSObject>
- (BOOL)richTextEditorFontPickerViewControllerShouldDisplayToolbar;
@end

@interface RichTextEditorInsertMultimediaViewController : UIViewController
@property (nonatomic, weak) id <RichTextEditorInsertMultimediaViewControllerDelegate> delegate;
@property (nonatomic, weak) id <RichTextEditorInsertMultimediaViewControllerDataSource> dataSource;
@end
