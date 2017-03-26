///////////////////////////////////////
//
//
// Jixuan
//
//////////////////////////////////////
import UIKit
import ImagePicker
import Lightbox

//class ViewController: UIViewController, FMMarkingMenuDelegate, UITextViewDelegate { //,  {
class NoteViewController:  UIViewController, UITextViewDelegate, CariocaMenuDelegate, NoteTextViewDelegate, ImagePickerDelegate{
    
    //////////  DrawingBoard //////////
    var brushes = [PencilBrush(), LineBrush(), DashLineBrush(), RectangleBrush(), EllipseBrush(), EraserBrush()]
    var nameToBrushes: [String: BaseBrush] = ["Pencil": PencilBrush(), "Line": LineBrush(), "Dotted": DashLineBrush(), "Eraser": EraserBrush()]
    //@IBOutlet weak var CCBoard: Board!
    var HPIWritingPad: NoteTextView!

    /***
     @IBOutlet var board: Board!
     
     // writing pad
     @IBOutlet weak var textView: WPTextView!
     ***/
    var suggestionsHeight : NSLayoutConstraint!
    var keyboardHeight : NSLayoutConstraint!
    
    // Marking menu
    var ccMarkingMenu: FMMarkingMenu!
    var ccMarkingMenuItems: [FMMarkingMenuItem]!
    var strokeWidthSlider = FMMarkingMenuItem(label: "Stroke width", valueSliderValue: 0.05, valueSliderType: 2)
    let strokeColorSlider = FMMarkingMenuItem(label: "Stoke Color", valueSliderValue: 0.0, valueSliderType: 1)
    
    var phenotypeBar: PhenotypeBar!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        /// drawing board
        /**
         self.CCBoard.brush = nameToBrushes["Pencil"]
         self.CCBoard.drawingStateChangedBlock = {(state: DrawingState) -> () in
         if state != .moved {
         }
         }
         **/
        
        /// marking menu
        // self.createMarkingMenu()
        
        /// wp text view
        // WPTextView
        self.HPIWritingPad = NoteTextView(frame: self.view.bounds)
        self.HPIWritingPad.delegate = self
        self.HPIWritingPad.noteDelegate = self
        self.view.addSubview(self.HPIWritingPad)
        /**
         let suggestions : SuggestionsView = SuggestionsView.shared()
         self.view.addSubview(suggestions)
         suggestions.showResultsinKeyboard(self.view, in:self.view.bounds)
         suggestions.translatesAutoresizingMaskIntoConstraints = false
         suggestions.backgroundColor = UIColor( white: 0.22, alpha:0.92)
         
         self.suggestionsHeight = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.height,
         relatedBy: NSLayoutRelation.equal, toItem: nil,
         attribute: NSLayoutAttribute.height,
         multiplier: 1.0, constant: SuggestionsView.getHeight())
         suggestions.addConstraint( self.suggestionsHeight )
         
         
         let leftS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.left,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.left,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( leftS )
         let topS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.bottom,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.bottom,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( topS )
         let rightS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.right,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.right,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( rightS )
         **/
        
        //        self.keyboardHeight = NSLayoutConstraint( item: self.view,
        //                                                  attribute: NSLayoutAttribute.bottom,
        //                                                  relatedBy: NSLayoutRelation.equal, toItem: self.view,
        //                                                  attribute: NSLayoutAttribute.bottom,
        //                                                  multiplier: 1.0, constant: 0.0 )
        //        self.view.addConstraint( self.keyboardHeight )
        //
        //        let notifications = NotificationCenter.default
        //        notifications.addObserver( self, selector:#selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //        notifications.addObserver( self, selector:#selector(ViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        //        notifications.addObserver( self, selector:#selector(ViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        //        notifications.addObserver( self, selector:#selector(ViewController.reloadOptions(_:)), name: NSNotification.Name(rawValue: EDITCTL_RELOAD_OPTIONS), object: nil)
        
        UserDefaults.standard.set(Int(WPLanguageEnglishUS.rawValue), forKey: kGeneralOptionsCurrentLanguage)
        
        // self.HPIWritingPad.text = "123"
        self.HPIWritingPad.setInputMethod(InputSystem_WriteAnywhere)
        
        let item : UITextInputAssistantItem = self.HPIWritingPad.inputAssistantItem
        item.leadingBarButtonGroups = []
        item.trailingBarButtonGroups = []
        
        /// tool bar Marking Menu
        // view.addSubview(toolbarMarkingGroup)
        // toolbarMarkingGroup.axis = UILayoutConstraintAxis.horizontal
        // toolbarMarkingGroup.distribution = UIStackViewDistribution.fillEqually
        
        
        /***
         // marking menu
         self.createMarkingMenu()
         
         // drawing board
         self.board.brush = nameToBrushes["Pencil"]
         self.board.drawingStateChangedBlock = {(state: DrawingState) -> () in
         if state != .moved {
         //                UIView.beginAnimations(nil, context: nil)
         //                if state == .began {
         //
         //                } else if state == .ended {
         //
         //                }
         //                UIView.commitAnimations()
         }
         }
         
         // WPTextView
         self.textView.initTextViewWithoutFrame()
         self.textView.delegate = self
         
         let suggestions : SuggestionsView = SuggestionsView.shared()
         suggestions.showResultsinKeyboard(self.view, in:self.view.bounds)
         suggestions.translatesAutoresizingMaskIntoConstraints = false
         suggestions.backgroundColor = UIColor( white: 0.22, alpha:0.92)
         
         self.suggestionsHeight = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.height,
         relatedBy: NSLayoutRelation.equal, toItem: nil,
         attribute: NSLayoutAttribute.height,
         multiplier: 1.0, constant: SuggestionsView.getHeight())
         suggestions.addConstraint( self.suggestionsHeight )
         
         let leftS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.left,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.left,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( leftS )
         let topS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.top,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.top,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( topS )
         let rightS = NSLayoutConstraint( item:suggestions,
         attribute: NSLayoutAttribute.right,
         relatedBy: NSLayoutRelation.equal, toItem:self.view,
         attribute: NSLayoutAttribute.right,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( rightS )
         
         
         self.keyboardHeight = NSLayoutConstraint( item: self.view,
         attribute: NSLayoutAttribute.bottom,
         relatedBy: NSLayoutRelation.equal, toItem: self.view,
         attribute: NSLayoutAttribute.bottom,
         multiplier: 1.0, constant: 0.0 )
         self.view.addConstraint( self.keyboardHeight )
         
         let notifications = NotificationCenter.default
         notifications.addObserver( self, selector:#selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
         notifications.addObserver( self, selector:#selector(ViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
         notifications.addObserver( self, selector:#selector(ViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
         notifications.addObserver( self, selector:#selector(ViewController.reloadOptions(_:)), name: NSNotification.Name(rawValue: EDITCTL_RELOAD_OPTIONS), object: nil)
         
         UserDefaults.standard.set(Int(WPLanguageEnglishUS.rawValue), forKey: kGeneralOptionsCurrentLanguage)
         
         self.textView.text = "123"
         self.textView.setInputMethod(InputSystem_InputPanel)
         ***/
        
        /// phenotype view
        phenotypeBar = PhenotypeBar(frame: CGRect(x: 0, y: self.view.frame.size.height - 40 , width: self.view.frame.width, height: 40))
        self.view.addSubview(self.phenotypeBar)
        phenotypeBar.noteViewController = self

    }
    
    override public func viewDidAppear(_ animated: Bool) {
        self.HPIWritingPad.toolBar.isHidden = true;
    }
    
    override public func viewDidLayoutSubviews() {
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    ///////////////////////////////////////////////
    // Marking menu
    /********
     func createMarkingMenu(){
     //        let toolTopLevel = FMMarkingMenuItem(label: MenuCategories.DrawingTools.rawValue, subItems:[
     //            FMMarkingMenuItem(label: MenuItems.Pencil.rawValue, category: MenuCategories.DrawingTools.rawValue, isSelected: true),
     //            FMMarkingMenuItem(label: MenuItems.Line.rawValue, category: MenuCategories.DrawingTools.rawValue),
     //            FMMarkingMenuItem(label: MenuItems.Dotted.rawValue, category: MenuCategories.DrawingTools.rawValue),
     //            FMMarkingMenuItem(label: MenuItems.Eraser.rawValue, category: MenuCategories.DrawingTools.rawValue),
     //            strokeWidthSlider,
     //            strokeColorSlider])
     let toolTopLevel = [
     FMMarkingMenuItem(label: MenuItems.Pencil.rawValue, category: MenuCategories.DrawingTools.rawValue, isSelected: true),
     FMMarkingMenuItem(label: MenuItems.Line.rawValue, category: MenuCategories.DrawingTools.rawValue),
     FMMarkingMenuItem(label: MenuItems.Dotted.rawValue, category: MenuCategories.DrawingTools.rawValue),
     FMMarkingMenuItem(label: MenuItems.Eraser.rawValue, category: MenuCategories.DrawingTools.rawValue),
     strokeWidthSlider,
     strokeColorSlider]
     
     ccMarkingMenuItems = toolTopLevel
     ccMarkingMenu = FMMarkingMenu(viewController: self, view: self.CCBoard, markingMenuItems: ccMarkingMenuItems)
     ccMarkingMenu.markingMenuDelegate = self
     
     toolbarMarkingMenuItems = [ FMMarkingMenuItem(label: MenuItems.Speech.rawValue,category: MenuCategories.Tools.rawValue),
     FMMarkingMenuItem(label: MenuItems.Camera.rawValue,category: MenuCategories.Tools.rawValue),
     FMMarkingMenuItem(label: MenuItems.Video.rawValue,category: MenuCategories.Tools.rawValue)]
     toolbarWidget = FMMarkingMenuWidget(label: "TOOLS",
     viewController: self,
     markingMenuItems: toolbarMarkingMenuItems)
     
     toolbarWidget?.markingMenuDelegate = self
     toolbarMarkingGroup.addArrangedSubview(toolbarWidget!)
     }
     ****/
    enum MenuCategories: String
    {
        case DrawingTools = "Drawing tools"
        
        case Tools
    }
    
    enum MenuItems: String{
        case Pencil
        case Line
        case Dotted
        case Eraser
        case Speech
        case Camera
        case Video
    }
    /****
     func FMMarkingMenuItemSelected(_ markingMenu: FMMarkingMenu, markingMenuItem: FMMarkingMenuItem)
     {
     guard let category = MenuCategories(rawValue: markingMenuItem.category!),
     let itemName = MenuItems(rawValue: markingMenuItem.label)?.rawValue else
     {
     return
     }
     
     
     // var brushes = [PencilBrush(), LineBrush(), DashLineBrush(), RectangleBrush(), EllipseBrush(), EraserBrush()]
     if markingMenu === ccMarkingMenu {
     FMMarkingMenu.setExclusivelySelected(markingMenuItem, markingMenuItems: ccMarkingMenuItems)
     switch category {
     case MenuCategories.DrawingTools:
     self.CCBoard.brush = nameToBrushes[itemName]
     if itemName == "Eraser"{
     strokeWidthSlider = FMMarkingMenuItem(label: "Stroke width", valueSliderValue: 0.6, valueSliderType: 2)
     self.CCBoard.strokeWidth = 20 * strokeWidthSlider.valueSliderValue
     } else {
     // FIX ME
     strokeWidthSlider = FMMarkingMenuItem(label: "Stroke width", valueSliderValue: 0.05, valueSliderType: 2)
     self.CCBoard.strokeWidth = 20 * strokeWidthSlider.valueSliderValue
     }
     default:
     break
     }
     }
     else {
     switch category {
     case MenuCategories.Tools:
     if itemName == "Speech"{
     if self.speechView?.isHidden == true {
     self.speechView?.isHidden = false
     speechView?.frame = CGRect(x: 0, y: self.view.frame.height - 75 - (speechView?.height)!, width: view.frame.width, height: (speechView?.height)!)
     //self.updateToolbarForSettingsView(self.speechView!.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height + CGFloat(75))
     } else {
     self.speechView?.isHidden = true
     // self.updateToolbarForSettingsView(CGFloat(75))
     }
     
     }
     default:
     break
     }
     }
     //updateFilters()
     }
     func FMMarkingMenuValueSliderChange(_ markingMenu: FMMarkingMenu, markingMenuItem: FMMarkingMenuItem, newValue: CGFloat, distanceToMenuOrigin: CGFloat) {
     if markingMenu === ccMarkingMenu {
     if markingMenuItem.valueSlideType == 2{
     if newValue > 0.01 {
     self.CCBoard.strokeWidth = 20 * strokeWidthSlider.valueSliderValue
     }
     } else if markingMenuItem.valueSlideType == 1{
     var v = Float(1)
     if distanceToMenuOrigin < 234 {
     v = Float((distanceToMenuOrigin-50)>0 ? (distanceToMenuOrigin-50) : 0) / Float(234 - 50)
     }
     let rgb = HSV.rgb(h: 360.0*Float(newValue), s: 1.0, v: v)
     self.CCBoard.strokeColor = UIColor.init(red: CGFloat(rgb.r), green: CGFloat(rgb.g), blue: CGFloat(rgb.b), alpha: CGFloat(1.0))
     }
     }
     
     }***/
    // Marking Menu
    /////////////////////////////////////////
    
    
    /////////////////////////////////////////
    // Writingpad
    @objc func reloadOptions( _ notification: Notification )
    {
        let recognizer = RecognizerManager.shared()
        let mode = recognizer?.getMode()
        recognizer?.disable( true )
        recognizer?.enable()
        recognizer?.setMode( mode! )
        self.HPIWritingPad.reloadOptions()
        HPIWritingPad.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(_ notification: Notification)
    {
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let kbFrame : NSValue = info.object( forKey: UIKeyboardFrameEndUserInfoKey ) as! NSValue
        let animationDuration : NSNumber = info.object( forKey: UIKeyboardAnimationDurationUserInfoKey ) as! NSNumber
        let keyboardFrame : CGRect = kbFrame.cgRectValue
        let duration : TimeInterval = animationDuration.doubleValue
        
        let height = keyboardFrame.size.height
        self.keyboardHeight.constant = -height;
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    
    @objc func keyboardWillHide(_ notification: Notification)
    {
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let animationDuration : NSNumber = info.object( forKey: UIKeyboardAnimationDurationUserInfoKey ) as! NSNumber
        let duration : TimeInterval = animationDuration.doubleValue
        
        self.keyboardHeight.constant = 0;
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardDidShow(_ notification: Notification)
    {
        HPIWritingPad.scrollToVisible()
    }
    // WritingPad
    /////////////////////////////////////////
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if HPIWritingPad.isFirstResponder && touches.first?.view != HPIWritingPad {
            HPIWritingPad.resignFirstResponder()
        }
        super.touchesBegan(touches, with: event)
    }
    
    // MARK: - Various demo controllers
    
    
    fileprivate func getEqualConstraint(_ item: AnyObject, toItem: AnyObject, attribute: NSLayoutAttribute) -> NSLayoutConstraint{
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: .equal, toItem: toItem, attribute: attribute, multiplier: 1, constant: 0)
    }
    
    @objc public func selectCameraOrPhoto(){
//        Configuration.doneButtonTitle = "Finish"
//        Configuration.noImagesTitle = "Sorry! There are no images here!"
//        Configuration.recordLocation = false
        //var config = Configuration()

        let imagePicker = ImagePickerController()
        //imagePicker.configuration = config
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - ImagePickerDelegate
    
    public func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    public func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
        
        let lightboxImages = images.map {
            return LightboxImage(image: $0)
        }
        
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        imagePicker.present(lightbox, animated: true, completion: nil)
    }
    
    public func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
}


