

#import "AttributeUndoRedoTextView.h"

@implementation AttributeUndoRedoTextView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)replaceSelectionWithAttributedText:(NSAttributedString *)text
{
    [self replaceRange:self.selectedRange withAttributedText:text];
}

- (void)replaceRange:(NSRange)range withAttributedText:(NSAttributedString *)text
{
    [self replaceRange:range withAttributedText:text andSelectRange:NSMakeRange(range.location, text.length)];
}

- (void)replaceRange:(NSRange)range withAttributedText:(NSAttributedString *)text andSelectRange:(NSRange)selection
{
    [[self.undoManager prepareWithInvocationTarget:self] replaceRange:NSMakeRange(range.location, text.length)
                                                   withAttributedText:[self.attributedText attributedSubstringFromRange:range]
                                                       andSelectRange:self.selectedRange];
    [self.textStorage replaceCharactersInRange:range withAttributedString:text];
    self.selectedRange = selection;
}


@end
