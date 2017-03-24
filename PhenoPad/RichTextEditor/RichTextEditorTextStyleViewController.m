
#import "RichTextEditorTextStyleViewController.h"
#import "RichTextEditorToggleButton.h"

@interface RichTextEditorTextStyleViewController (){
    CGFloat curFontSize;
}
@property (weak, nonatomic) IBOutlet UIButton *btnSelectFont;
@property (weak, nonatomic) IBOutlet RichTextEditorToggleButton *btnBold;
@property (weak, nonatomic) IBOutlet RichTextEditorToggleButton *btnItalic;
@property (weak, nonatomic) IBOutlet RichTextEditorToggleButton *btnUnderline;
@property (weak, nonatomic) IBOutlet UILabel *lblFontSize;
@property (weak, nonatomic) IBOutlet UIButton *btnBlueFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnGreenFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnRedFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnYellowFontColor;
@property (weak, nonatomic) IBOutlet UIButton *btnBlackFontColor;

@end

@implementation RichTextEditorTextStyleViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *customizedFontFamilies = [self.dataSource richTextEditorFontPickerViewControllerCustomFontFamilyNamesForSelection];
    
    if (customizedFontFamilies) {
        self.fontNames = customizedFontFamilies;
    } else {
        self.fontNames = [[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    
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
    
    self.preferredContentSize = CGSizeMake(200, 250);
#else
    
    self.contentSizeForViewInPopover = CGSizeMake(200, 250);
#endif

    // Do any additional setup after loading the view from its nib.
    
    [self.btnSelectFont setTitle:[self.dataSource richTextEditorTextStyleViewControllerFontName] forState:UIControlStateNormal];
    curFontSize = [self.dataSource richTextEditorTextStyleViewControllerFontSize];
    [self.lblFontSize setText:[NSString stringWithFormat:@"%d", (int)curFontSize]];
    self.btnBold.on = [self.dataSource richTextEditorTextStyleViewControllerBold];
    self.btnItalic.on = [self.dataSource richTextEditorTextStyleViewControllerItalic];
    self.btnUnderline.on = [self.dataSource richTextEditorTextStyleViewControllerUnderline];
    self.btnBlueFontColor.layer.cornerRadius = 11;
    self.btnGreenFontColor.layer.cornerRadius = 11;
    self.btnRedFontColor.layer.cornerRadius = 11;
    self.btnYellowFontColor.layer.cornerRadius = 11;
    self.btnBlackFontColor.layer.cornerRadius = 11;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions -

- (void)closeSelected:(id)sender
{
    [self.delegate richTextEditorTextStyleViewControllerDidSelectClose];
}


- (IBAction)openFontDropList:(id)sender {
    [Dropobj fadeOut];
    [self showPopUpWithTitle:@"Select Font" withOption:_fontNames xy:CGPointMake(self.btnSelectFont.frame.origin.x , self.btnSelectFont.frame.origin.y + self.btnSelectFont.bounds.size.height) size:CGSizeMake(self.btnSelectFont.bounds.size.width, 130) isMultiple:NO];
}

-(void)showPopUpWithTitle:(NSString*)popupTitle withOption:(NSArray*)arrOptions xy:(CGPoint)point size:(CGSize)size isMultiple:(BOOL)isMultiple{
    
    
    Dropobj = [[DropDownListView alloc] initWithTitle:popupTitle options:arrOptions xy:point size:size isMultiple:isMultiple];
    Dropobj.delegate = self;
    [Dropobj showInView:self.view animated:YES];
    
    /*----------------Set DropDown backGroundColor-----------------*/
    [Dropobj SetBackGroundDropDown_R:0.0 G:108.0 B:194.0 alpha:0.70];
    
}
- (void)DropDownListView:(DropDownListView *)dropdownListView didSelectedIndex:(NSInteger)anIndex{
    /*----------------Get Selected Value[Single selection]-----------------*/
    //    _lblSelectedCountryNames.text=[arryList objectAtIndex:anIndex];
    [self.btnSelectFont setTitle:[_fontNames objectAtIndex:anIndex] forState:UIControlStateNormal];
    
    NSString *fontName = [_fontNames objectAtIndex:anIndex ];
    UIFont *font = self.btnSelectFont.font;
    self.btnSelectFont.font = [UIFont fontWithName:fontName size:font.pointSize];
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontWithName:fontName];
}

- (void)DropDownListViewDidCancel{
    
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if ([touch.view isKindOfClass:[UIView class]]) {
        [Dropobj fadeOut];
    }
}
- (IBAction)plusFontSize:(id)sender {
    curFontSize += 1;
    if(curFontSize > 45){
        curFontSize = 45;
        return;
    }
    self.lblFontSize.text = [NSString stringWithFormat:@"%d", (int)curFontSize];
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontSize:curFontSize];
}
- (IBAction)minusFontSize:(id)sender {
    curFontSize -= 1;
    if(curFontSize < 8){
        curFontSize = 8;
        return;
    }
    self.lblFontSize.text = [NSString stringWithFormat:@"%d", (int)curFontSize];
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontSize:curFontSize];
}

- (IBAction)setBold:(id)sender {
    self.btnBold.on = !self.btnBold.on;
    [self.delegate richTextEditorTextStyleViewControllerDidSelectBold];
}

- (IBAction)setItalic:(id)sender {
    self.btnItalic.on = !self.btnItalic.on;
    [self.delegate richTextEditorTextStyleViewControllerDidSelectItalic];
}

- (IBAction)setUnderline:(id)sender {
    self.btnUnderline.on = !self.btnUnderline.on;
    [self.delegate richTextEditorTextStyleViewControllerDidSelectUnderline];
}

- (IBAction)setFontColorBlue:(id)sender {
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontColor:[UIColor blueColor]];
}
- (IBAction)setFontColorGreen:(id)sender {
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontColor:[UIColor greenColor]];
}
- (IBAction)setFontColorRed:(id)sender {
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontColor:[UIColor redColor]];
}
- (IBAction)setFontColorYellow:(id)sender {
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontColor:[UIColor yellowColor]];
}
- (IBAction)setFontColorBlack:(id)sender {
    [self.delegate richTextEditorTextStyleViewControllerDidSelectFontColor:[UIColor blackColor]];
}

@end
