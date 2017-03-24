///////////////////////////////////////
//
//
// Jixuan
//
//////////////////////////////////////
import UIKit

//class ViewController: UIViewController, FMMarkingMenuDelegate, UITextViewDelegate { //,  {
public class ViewController:  UIViewController, UITextViewDelegate, CariocaMenuDelegate{
   
    //////////  DrawingBoard //////////
    var brushes = [PencilBrush(), LineBrush(), DashLineBrush(), RectangleBrush(), EllipseBrush(), EraserBrush()]
    var nameToBrushes: [String: BaseBrush] = ["Pencil": PencilBrush(), "Line": LineBrush(), "Dotted": DashLineBrush(), "Eraser": EraserBrush()]
    //@IBOutlet weak var CCBoard: Board!
    @IBOutlet weak var HPIWritingPad: WPTextView!
    @IBOutlet weak var subStackView: UIStackView!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    var currentSettingsView: UIView?
    var speechView: UIView?
    
    @IBOutlet weak var toolbarHeight: NSLayoutConstraint!
    let toolbarMarkingGroup = UIStackView()
    var toolbarWidget: FMMarkingMenuWidget!
    var toolbarMarkingMenu: FMMarkingMenu!
    var toolbarMarkingMenuItems: [FMMarkingMenuItem]!
    
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

    // cool navigation menu
    var nmenu:CariocaMenu?
    // cool tools menu
    var tmenu:CariocaMenu?
    var curContentController:UIViewController!
    
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
        /// toolbar and view
        self.setupSpeechView()
        
        /// marking menu
        // self.createMarkingMenu()
        
        /// wp text view
        // WPTextView
        self.HPIWritingPad.initTextViewWithoutFrame()
        self.HPIWritingPad.delegate = self
        
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
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        nmenu?.addInView(self.view)
        nmenu?.isDraggableVertically = true
        //        menu?.showIndicator(.right, position: .Bottom, offset: -50)
        nmenu?.showIndicator(.left, position: .center, offset: 30)
        //        menu?.showIndicator(.right, position: .Top, offset: 50)
        //        menu?.showIndicator(.left, position: .Top, offset: 50)
        //        menu?.showIndicator(.left, position: .Center, offset: 50)
        
        //nmenu?.addGestureHelperViews([.left,.right], width:30)
        nmenu?.addGestureHelperViews([.left, .right], width:30)

    }

    override public func viewDidLayoutSubviews() {
        // self.CCBoard.drawingBackgroundLines()
        toolbarMarkingGroup.frame = CGRect(x: 0, y: view.frame.height - 75, width: view.frame.width, height: 75)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    
    @IBAction func openSpeechView(_ sender: UIBarButtonItem) {
        self.currentSettingsView = self.bottomToolbar.viewWithTag(1)
        if self.currentSettingsView?.isHidden == true {
            self.currentSettingsView?.isHidden = false
            self.updateToolbarForSettingsView(self.currentSettingsView!.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height + CGFloat(44))
        } else {
            self.currentSettingsView?.isHidden = true
            self.updateToolbarForSettingsView(CGFloat(44))
        }
    }
    
    func updateToolbarForSettingsView(_ height: CGFloat) {
        self.toolbarWidget?.height = height
        // self.bottomToolbar.setItems(self.toolbarEditingItems, animated: true)
        UIView.beginAnimations(nil, context: nil)
        self.bottomToolbar.layoutIfNeeded()
        UIView.commitAnimations()
        
        self.bottomToolbar.bringSubview(toFront: self.currentSettingsView!)
    }
    
    func setupSpeechView(){
        //speechView = UINib(nibName: "SpeechView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! SpeechView
        //self.view.addSubview(speechView!)
        
        // self.addConstraintsToToolbarForSettingsView(speechView)
        //speechView?.isHidden = true
    }
    
    func addConstraintsToToolbarForSettingsView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.toolbarWidget?.addSubview(view)
        self.toolbarWidget?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[settingsView]-0-|",
                                                                   options: NSLayoutFormatOptions(),
                                                                   metrics: nil,
                                                                   views: ["settingsView" : view]))
        self.toolbarWidget?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[settingsView(==height)]",
                                                                   options: NSLayoutFormatOptions(),
                                                                   metrics: ["height" : view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height],
                                                                   views: ["settingsView" : view]))
    }
    
    
    // MARK: - Various demo controllers
    
    func showDemoControllerForIndex(_ index:Int){
        
        if curContentController != nil {
            curContentController.view.removeFromSuperview()
            curContentController.removeFromParentViewController()
            curContentController = nil
        }
        
        switch index {
            
        case 1:
            if let obj = self.storyboard?.instantiateViewController(withIdentifier: "objectiveCtrl") {
                self.addChildViewController(obj)
                self.view.addSubview(obj.view)
                curContentController = obj as UIViewController
            }
            break
        case 2:
            if let assess = self.storyboard?.instantiateViewController(withIdentifier: "assessmentCtrl"){
                self.addChildViewController(assess)
                self.view.addSubview(assess.view)
                curContentController = assess as UIViewController
            }
            break
        default:
            if let sub = self.storyboard?.instantiateViewController(withIdentifier: "planCtrl") {
                self.addChildViewController(sub)
                self.view.addSubview(sub.view)
                curContentController = sub as UIViewController
            }
            break
        }
        
        curContentController.view.translatesAutoresizingMaskIntoConstraints = false
        
        //Add constraints for autolayout
        self.view.addConstraints([
            getEqualConstraint(curContentController.view, toItem: self.view, attribute: .trailing),
            getEqualConstraint(curContentController.view, toItem: self.view, attribute: .leading),
            getEqualConstraint(curContentController.view, toItem: self.view, attribute: .bottom),
            getEqualConstraint(curContentController.view, toItem: self.view, attribute: .top)
            ])
        
        self.view.setNeedsLayout()
        
        nmenu?.moveToTop()
    }
    
    
    fileprivate func getEqualConstraint(_ item: AnyObject, toItem: AnyObject, attribute: NSLayoutAttribute) -> NSLayoutConstraint{
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: .equal, toItem: toItem, attribute: attribute, multiplier: 1, constant: 0)
    }
    
    // MARK: - CariocaMenu Delegate
    
    ///`Optional` Called when a menu item was selected
    ///- parameters:
    ///  - menu: The menu object
    ///  - indexPath: The selected indexPath
    public func cariocaMenuDidSelect(_ menu:CariocaMenu, indexPath:IndexPath) {
        
        showDemoControllerForIndex(indexPath.row)
    }
    
    ///`Optional` Called when the menu is about to open
    ///- parameters:
    ///  - menu: The opening menu object
    public func cariocaMenuWillOpen(_ menu:CariocaMenu) {
        //if(logging){
        //    print("carioca MenuWillOpen \(menu)")
        //}
    }
    
    ///`Optional` Called when the menu just opened
    ///- parameters:
    ///  - menu: The opening menu object
    public func cariocaMenuDidOpen(_ menu:CariocaMenu){
//        if(logging){
//            switch menu.openingEdge{
//            case .left:
//                print("carioca MenuDidOpen \(menu) left")
//                break;
//            default:
//                print("carioca MenuDidOpen \(menu) right")
//                break;
//            }
//        }
    }
    
    ///`Optional` Called when the menu is about to be dismissed
    ///- parameters:
    ///  - menu: The disappearing menu object
    public func cariocaMenuWillClose(_ menu:CariocaMenu) {
//        if(logging){
//            print("carioca MenuWillClose \(menu)")
//        }
    }
    
    ///`Optional` Called when the menu is dismissed
    ///- parameters:
    ///  - menu: The disappearing menu object
    public func cariocaMenuDidClose(_ menu:CariocaMenu){
//        if(logging){
//            print("carioca MenuDidClose \(menu)")
//        }
    }
    
    // MARK: -
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
}


