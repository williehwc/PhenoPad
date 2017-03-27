//
//  FloatPanelView.h
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-26.
//  Copyright © 2017 CCM. All rights reserved.
//
#import <UIKit/UIKit.h>
typedef enum{
    DRAWING_PANEL = 0,
    PHOTO_PANEL,
    PHENOTYPE_PANEL
} PANEL_TYPE;

@interface FloatPanelView : UIViewController

@property (nonatomic) bool dragging;
@property (nonatomic) CGPoint former;
@property (nonatomic) CGPoint now;
@property (nonatomic) PANEL_TYPE type;
@end
