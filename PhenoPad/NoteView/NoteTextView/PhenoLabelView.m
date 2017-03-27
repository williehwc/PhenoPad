//
//  PhenoLabelView.m
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-27.
//  Copyright © 2017 CCM. All rights reserved.
//

#import "PhenoLabelView.h"

@interface PhenoLabelView (){
}


@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (weak, nonatomic) IBOutlet UITextField *textfield;

@end

@implementation PhenoLabelView

-(void) viewDidLoad{
    [super viewDidLoad];
    self.dragging = false;
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc]
                                   initWithTarget: self
                                   action:@selector(handlePan:)];

    [self.view addGestureRecognizer:pgr];
    
    
    self.textfield.backgroundColor = [UIColor clearColor];
}

-(void) setPheno:(NSString*) str{
    [self.textfield setText:str];
}

- (IBAction)closeClicked:(id)sender {
    [self.view removeFromSuperview];
}

-(void)handlePan:(UIPanGestureRecognizer*)pgr
{
    switch (pgr.state) {
        case UIGestureRecognizerStateBegan:
            
            self.dragging = true;
            self.former = [pgr locationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged:
            
            if(self.dragging){
                self.now = [pgr locationInView:self.view];
                CGFloat xoff = self.now.x - self.former.x;
                CGFloat yoff = self.now.y - self.former.y;
                CGRect nframe = self.view.frame;
                nframe.origin.x = nframe.origin.x + xoff;
                nframe.origin.y = nframe.origin.y + yoff;
                self.view.frame = nframe;
                //self.former = self.now;
            }
            break;
        case UIGestureRecognizerStateEnded:
            self.dragging = false;
            
            break;
        case UIGestureRecognizerStateCancelled:
            self.dragging = false;
            
            break;
        default:
            break;
    }
    
}



@end
