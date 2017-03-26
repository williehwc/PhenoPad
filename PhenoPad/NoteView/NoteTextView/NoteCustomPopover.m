//
//  NoteCustomPopover.m
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-25.
//  Copyright © 2017 CCM. All rights reserved.
//

#import "NoteCustomPopover.h"
#import "WEColorUtils.h"

@implementation NoteCustomPopover {
    
}

- (id)init {
    if ((self = [super init])) {
        
        WEPopoverContainerViewProperties *props = [WEPopoverController defaultContainerViewProperties];
        props.arrowMargin = 0.0;
//        
//        props.leftBgCapSize = 20;
//        props.topBgCapSize = 20;
//        
        self.popoverLayoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
//        props.maskCornerRadius = 4.0;
//        
//        props.bgImageName = nil;
//        
//        self.primaryAnimationDuration = 0.3;
//        self.secundaryAnimationDuration = 0.2;
//        
        self.backgroundColor = [UIColor clearColor];
        props.backgroundColor = [UIColor clearColor];
//        
//        props.backgroundColor = UIColorMakeHex(0xfde9bd);
//        
//        //@(AHColorTypeVanille)   :@[C(0x63512c), C(0x947842), C(0xc5a059), C(0xfac75a), C(0xc6b6a1), C(0xfcdd9c), C(0xfde9bd), C(0xfef7e6)],
//        
//        props.shadowColor = [UIColor blackColor];
//        props.shadowOpacity = 0.8;
//        props.shadowRadius = 4.0;
        props.backgroundMargins = UIEdgeInsetsMake(0, 0, 0, 0);
        props.upArrowImage = [UIImage imageNamed:@"note_uparrow"];
        props.contentMargins = UIEdgeInsetsMake(0, 0, 0, 0);
        
        self.containerViewProperties = props;
    }
    return self;
}

@end
