
#import "RichTextEditorInsertMultimediaViewController.h"

@interface RichTextEditorInsertMultimediaViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btnInsertText;
@property (weak, nonatomic) IBOutlet UIButton *btnInsertImage;
@property (weak, nonatomic) IBOutlet UIButton *btnInsertVoice;
@property (weak, nonatomic) IBOutlet UIButton *btnInsertVideo;

@end

@implementation RichTextEditorInsertMultimediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.dataSource richTextEditorFontPickerViewControllerShouldDisplayToolbar])
    {
        CGFloat reservedSizeForStatusBar = (
                                            UIDevice.currentDevice.systemVersion.floatValue >= 7.0
                                            && !(   UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad
                                                 && self.modalPresentationStyle==UIModalPresentationFormSheet
                                                 )
                                            ) ? 20.:0.; //Add the size of the status bar for iOS 7, not on iPad presenting modal sheet
        
        CGFloat toolbarHeight = 44 +reservedSizeForStatusBar;
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, toolbarHeight)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:toolbar];
        
        UIBarButtonItem *flexibleSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                           target:nil
                                                                                           action:nil];
        
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(closeSelected:)];
        [toolbar setItems:@[closeItem, flexibleSpaceItem]];
        
        //        self.tableview.frame = CGRectMake(0, toolbarHeight, self.view.frame.size.width, self.view.frame.size.height - toolbarHeight);
    }
    else
    {
        //        self.tableview.frame = self.view.bounds;
    }
    
    //    [self.view addSubview:self.tableview];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    
    self.preferredContentSize = CGSizeMake(220, 70);
#else
    
    self.contentSizeForViewInPopover = CGSizeMake(220, 70);
#endif
    [self setRoundButton:self.btnInsertText];
    [self setRoundButton:self.btnInsertImage];
    [self setRoundButton:self.btnInsertVoice];
    [self setRoundButton:self.btnInsertVideo];
    
}

- (void) setRoundButton:(UIButton*) btn{
    CALayer *layer = [btn layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:3.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)insertText:(id)sender {
    [self.delegate richTextEditorInsertMultimediaViewControllerDidInsertDocument];
}

- (IBAction)insertImage:(id)sender {
    [self.delegate richTextEditorInsertMultimediaViewControllerDidInsertImage];
}

- (IBAction)insertVoice:(id)sender {
    [self.delegate richTextEditorInsertMultimediaViewControllerDidInsertVoice];
}

- (IBAction)insertVideo:(id)sender {
    [self.delegate richTextEditorInsertMultimediaViewControllerDidInsertVideo];
}

@end
