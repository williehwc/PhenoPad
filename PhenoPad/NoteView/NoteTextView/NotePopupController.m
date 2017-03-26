//
//  NotePopupController.m
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-25.
//  Copyright © 2017 CCM. All rights reserved.
//

#import "NotePopupController.h"

@interface NotePopupController (){
}
@property (weak, nonatomic) IBOutlet UIButton *keyboardBtn;
@property (weak, nonatomic) IBOutlet UIButton *stylusBtn;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIButton *videoBtn;
@end

@implementation NotePopupController

- (void) viewDidLoad{
    UIColor* highcolor = [UIColor colorWithRed:18.0f/255.0f green:212.0f/255.0f blue:219.0f/255.0f alpha:1.0f];
    [self.keyboardBtn setBackgroundImage:[self imageWithColor:highcolor] forState:UIControlStateHighlighted];
    [self.stylusBtn setBackgroundImage:[self imageWithColor:highcolor] forState:UIControlStateHighlighted];
    [self.cameraBtn setBackgroundImage:[self imageWithColor:highcolor] forState:UIControlStateHighlighted];
    [self.photoBtn setBackgroundImage:[self imageWithColor:highcolor] forState:UIControlStateHighlighted];
    [self.videoBtn setBackgroundImage:[self imageWithColor:highcolor] forState:UIControlStateHighlighted];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)photoClick:(UIButton *)sender {
    [self.delegate NotePopupControllerDidSelect: photo];
}
- (IBAction)cameraClick:(UIButton *)sender {
    [self.delegate NotePopupControllerDidSelect: camera];
}

- (IBAction)keyboardClick:(UIButton *)sender {
    [self.delegate NotePopupControllerDidSelect: keyboard];
}
- (IBAction)stylusClick:(UIButton *)sender {
    [self.delegate NotePopupControllerDidSelect: stylus];
}
- (IBAction)videoClick:(UIButton *)sender {
    [self.delegate NotePopupControllerDidSelect: video];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end
