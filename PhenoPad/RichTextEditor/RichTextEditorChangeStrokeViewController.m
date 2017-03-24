

#import "RichTextEditorChangeStrokeViewController.h"

@interface RichTextEditorChangeStrokeViewController (){
    CGFloat strokeWidth;
}
@property (weak, nonatomic) IBOutlet UILabel *lblFontSize;
@property (weak, nonatomic) IBOutlet UIButton *btnBlueFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnGreenFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnRedFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnYellowFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnBlackFontColor;
@property (weak, nonatomic) IBOutlet UILabel *lblStrokeWidth;

@end

@implementation RichTextEditorChangeStrokeViewController

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
    
    self.preferredContentSize = CGSizeMake(200, 200);
#else
    
    self.contentSizeForViewInPopover = CGSizeMake(200, 200);
#endif
    self.btnBlueFontColor.layer.cornerRadius = 11;
    self.btnGreenFontColor.layer.cornerRadius = 11;
    self.btnRedFontColor.layer.cornerRadius = 11;
    self.btnYellowFontColor.layer.cornerRadius = 11;
    self.btnBlackFontColor.layer.cornerRadius = 11;
    strokeWidth = [self.dataSource richTextEditorChangeStrokeViewControllerStrokeSize];
    [self.lblStrokeWidth setText:[NSString stringWithFormat:@"~%d~", (int)strokeWidth]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions -

- (void)closeSelected:(id)sender
{
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectClose];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)decreaseStrokeWidth:(id)sender {
    if(strokeWidth <= 2)
        return;
    strokeWidth -= 1;
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeSize:strokeWidth];
    [self.lblStrokeWidth setText:[NSString stringWithFormat:@"~%d~", (int)strokeWidth]];
}

- (IBAction)increaseStrokeWidth:(id)sender {
    if(strokeWidth >= 30)
        return;
    strokeWidth += 1;
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeSize:strokeWidth];
    [self.lblStrokeWidth setText:[NSString stringWithFormat:@"~%d~", (int)strokeWidth]];
}

- (IBAction)setFontColorBlue:(id)sender {
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:[UIColor blueColor]];
}
- (IBAction)setFontColorGreen:(id)sender {
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:[UIColor greenColor]];
}
- (IBAction)setFontColorRed:(id)sender {
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:[UIColor redColor]];
}
- (IBAction)setFontColorYellow:(id)sender {
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:[UIColor yellowColor]];
}
- (IBAction)setFontColorBlack:(id)sender {
    [self.delegate richTextEditorChangeStrokeViewControllerDidSelectStrokeColor:[UIColor blackColor]];
}

@end
