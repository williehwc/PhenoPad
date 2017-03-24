

#import <UIKit/UIKit.h>

@interface AttributeUndoRedoTextView : UITextView

- (void)replaceSelectionWithAttributedText:(NSAttributedString *)text;
- (void)replaceRange:(NSRange)range withAttributedText:(NSAttributedString *)text;

@end
