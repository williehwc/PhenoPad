/*
Copyright (c) 2015 Kyohei Yamaguchi. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import UIKit

@objc public protocol MainViewControllerDelegate {
    @objc optional func drawerController(_ drawerController: MainViewController, stateChanged state: MainViewController.DrawerState)
}

open class MainViewController: UIViewController, UIGestureRecognizerDelegate {
    
    /**************************************************************************/
    // MARK: - Types
    /**************************************************************************/
    
    @objc public enum DrawerDirection: Int {
        case left, right
    }
    
    @objc public enum DrawerState: Int {
        case opened, closed
    }

    /**************************************************************************/
    // MARK: - Properties
    /**************************************************************************/

    @IBInspectable public var containerViewMaxAlpha: CGFloat = 0.2

    @IBInspectable public var drawerAnimationDuration: TimeInterval = 0.25

    @IBInspectable public var mainSegueIdentifier: String?
    
    @IBInspectable public var leftDrawerSegueIdentifier: String?
    @IBInspectable public var rightDrawerSegueIdentifier: String?
    
    private var _leftDrawerConstraint: NSLayoutConstraint!
    private var _rightDrawerConstraint: NSLayoutConstraint!
    
    private var _leftDrawerWidthConstraint: NSLayoutConstraint!
    private var _rightDrawerWidthConstraint: NSLayoutConstraint!
    
    private var _panStartLocation = CGPoint.zero
    
    private var _panDelta: CGFloat = 0
    
    private var whoIsChanging = 0 // -1 for left, 1 for right
    
    lazy private var _containerView: UIView = {
        let view = UIView(frame: self.view.frame)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.0, alpha: 0)
        view.addGestureRecognizer(self.containerViewTapGesture)
        return view
    }()

    /// Returns `true` if `beginAppearanceTransition()` has been called with `true` as the first parameter, and `false`
    /// if the first parameter is `false`. Returns `nil` if appearance transition is not in progress.
    private var _isAppearing: Bool?

    public var screenEdgePanGestureEnabled = true
    
    public private(set) lazy var screenLeftEdgePanGesture: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(MainViewController.handlePanGesture(_:))
        )
        gesture.edges = .left

        gesture.delegate = self
        return gesture
    }()
    public private(set) lazy var screenRightEdgePanGesture: UIScreenEdgePanGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(MainViewController.handlePanGesture(_:))
        )
        gesture.edges = .right
        
        gesture.delegate = self
        return gesture
    }()

    
    public private(set) lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(MainViewController.handlePanGesture(_:))
        )
        gesture.delegate = self
        return gesture
    }()

    public private(set) lazy var containerViewTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(MainViewController.didtapContainerView(_:))
        )
        gesture.delegate = self
        return gesture
    }()
    
    public weak var delegate: MainViewControllerDelegate?
    
    public var leftDrawerState: DrawerState = .closed;
    public var rightDrawerState: DrawerState = .closed;
    
//    public var leftDrawerState: DrawerState {
//        get {
//            if _containerView.isHidden {
//                return .closed
//            } else {
//                return rightDrawerState == .closed ? .opened : .closed
//            }
//        }
//        set{}
//        // set { setLeftDrawerState(self.leftDrawerState, animated: false) }
//    }
//    public var rightDrawerState: DrawerState{
//        get {
//            if _containerView.isHidden {
//                return .closed
//            } else {
//                return leftDrawerState == .closed ? .opened : .closed
//            }
//        }
//        set{}
//        // set { setRightDrawerState(self.rightDrawerState, animated: false) }
//    }
    
    @IBInspectable public var leftDrawerWidth: CGFloat = 280 {
        didSet { _leftDrawerWidthConstraint?.constant = leftDrawerWidth }
    }
    @IBInspectable public var rightDrawerWidth: CGFloat = 720 {
        didSet { _rightDrawerWidthConstraint?.constant = rightDrawerWidth }
    }

    public var displayingViewController: UIViewController? {
        if(leftDrawerState == .opened && rightDrawerState == .opened){
            assertionFailure("Left Drawer and Right Drawer can not be open at the same time!")
        }
        
        if leftDrawerState == .opened{
            return leftDrawerViewController
        } else if rightDrawerState == .opened {
            return rightDrawerViewController
        } else {
            return mainViewController
        }
    }

    public var mainViewController: ViewController! {
        didSet {
            if let oldController = oldValue {
                oldController.willMove(toParentViewController: nil)
                oldController.view.removeFromSuperview()
                oldController.removeFromParentViewController()
            }

            guard let mainViewController = mainViewController else { return }
            addChildViewController(mainViewController)

            mainViewController.view.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(mainViewController.view, at: 0)

            let viewDictionary = ["mainView" : mainViewController.view!]
            view.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-0-[mainView]-0-|",
                    options: [],
                    metrics: nil,
                    views: viewDictionary
                )
            )
            view.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-0-[mainView]-0-|",
                    options: [],
                    metrics: nil,
                    views: viewDictionary
                )
            )

            mainViewController.didMove(toParentViewController: self)
        }
    }
    
    public var leftDrawerViewController : UIViewController? {
        didSet {
            if let oldController = oldValue {
                oldController.willMove(toParentViewController: nil)
                oldController.view.removeFromSuperview()
                oldController.removeFromParentViewController()
            }

            guard let leftDrawerViewController = leftDrawerViewController else { return }
            addChildViewController(leftDrawerViewController)

            leftDrawerViewController.view.layer.shadowColor   = UIColor.black.cgColor
            leftDrawerViewController.view.layer.shadowOpacity = 0.4
            leftDrawerViewController.view.layer.shadowRadius  = 5.0
            leftDrawerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            _containerView.addSubview(leftDrawerViewController.view)

            let itemAttribute: NSLayoutAttribute
            let toItemAttribute: NSLayoutAttribute
            itemAttribute   = .right
            toItemAttribute = .left

            _leftDrawerWidthConstraint = NSLayoutConstraint(
                item: leftDrawerViewController.view,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: nil,
                attribute: NSLayoutAttribute.width,
                multiplier: 1,
                constant: leftDrawerWidth
            )
            leftDrawerViewController.view.addConstraint(_leftDrawerWidthConstraint)
            
            _leftDrawerConstraint = NSLayoutConstraint(
                item: leftDrawerViewController.view,
                attribute: itemAttribute,
                relatedBy: NSLayoutRelation.equal,
                toItem: _containerView,
                attribute: toItemAttribute,
                multiplier: 1,
                constant: 0
            )
            _containerView.addConstraint(_leftDrawerConstraint)

            let viewDictionary = ["leftDrawerView" : leftDrawerViewController.view!]
            _containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-0-[leftDrawerView]-0-|",
                    options: [],
                    metrics: nil,
                    views: viewDictionary
                )
            )
            _containerView.updateConstraints()
            leftDrawerViewController.updateViewConstraints()
            leftDrawerViewController.didMove(toParentViewController: self)
        }
    }
    
    public var rightDrawerViewController : UIViewController? {
        didSet {
            if let oldController = oldValue {
                oldController.willMove(toParentViewController: nil)
                oldController.view.removeFromSuperview()
                oldController.removeFromParentViewController()
            }
            
            guard let rightDrawerViewController = rightDrawerViewController else { return }
            addChildViewController(rightDrawerViewController)
            
            rightDrawerViewController.view.layer.shadowColor   = UIColor.black.cgColor
            rightDrawerViewController.view.layer.shadowOpacity = 0.4
            rightDrawerViewController.view.layer.shadowRadius  = 5.0
            rightDrawerViewController.view.translatesAutoresizingMaskIntoConstraints = false
            _containerView.addSubview(rightDrawerViewController.view)
            
            let itemAttribute: NSLayoutAttribute
            let toItemAttribute: NSLayoutAttribute
            itemAttribute   = .left
            toItemAttribute = .right
            
            _rightDrawerWidthConstraint = NSLayoutConstraint(
                item: rightDrawerViewController.view,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: nil,
                attribute: NSLayoutAttribute.width,
                multiplier: 1,
                constant: rightDrawerWidth
            )
            rightDrawerViewController.view.addConstraint(_rightDrawerWidthConstraint)
            
            _rightDrawerConstraint = NSLayoutConstraint(
                item: rightDrawerViewController.view,
                attribute: itemAttribute,
                relatedBy: NSLayoutRelation.equal,
                toItem: _containerView,
                attribute: toItemAttribute,
                multiplier: 1,
                constant: 0
            )
            _containerView.addConstraint(_rightDrawerConstraint)
            
            let viewDictionary = ["rightDrawerView" : rightDrawerViewController.view!]
            _containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-0-[rightDrawerView]-0-|",
                    options: [],
                    metrics: nil,
                    views: viewDictionary
                )
            )
            _containerView.updateConstraints()
            rightDrawerViewController.updateViewConstraints()
            rightDrawerViewController.didMove(toParentViewController: self)
        }
    }

    
    
    /**************************************************************************/
    // MARK: - initialize
    /**************************************************************************/
    
    public init(leftDrawerWidth: CGFloat, rightDrawerWidth: CGFloat) {
        super.init(nibName: nil, bundle: nil)
        self.leftDrawerWidth     = leftDrawerWidth
        self.rightDrawerWidth     = rightDrawerWidth
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    /**************************************************************************/
    // MARK: - Life Cycle
    /**************************************************************************/
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let viewDictionary = ["_containerView": _containerView]
        
        view.addGestureRecognizer(screenLeftEdgePanGesture)
        view.addGestureRecognizer(screenRightEdgePanGesture)
        // view.addGestureRecognizer(panGesture)
        view.addSubview(_containerView)
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[_containerView]-0-|",
                options: [],
                metrics: nil,
                views: viewDictionary
            )
        )
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[_containerView]-0-|",
                options: [],
                metrics: nil,
                views: viewDictionary
            )
        )
        _containerView.isHidden = true
        
        self.leftDrawerState = .closed
        self.rightDrawerState = .closed
        
        if let mainSegueID = mainSegueIdentifier {
            performSegue(withIdentifier: mainSegueID, sender: self)
        }
        if let leftDrawerSegueID = leftDrawerSegueIdentifier {
            performSegue(withIdentifier: leftDrawerSegueID, sender: self)
        }
        if let rightDrawerSegueID = rightDrawerSegueIdentifier {
            performSegue(withIdentifier: rightDrawerSegueID, sender: self)
        }
        
        // cool navigation menu
        //Initialise the tableviewcontroller of the menu
        //Initialise the tableviewcontroller of the menu
        let naviMenuCtrl = self.storyboard?.instantiateViewController(withIdentifier: "naviMenu") as! MyMenuContentController
        
        var iconNames = Array<String>()
        iconNames.append("subjective")
        iconNames.append("objective")
        iconNames.append("assessment")
        iconNames.append("plan")
        var menuNames = Array<String>()
        menuNames.append("Subjective")
        menuNames.append("Objective")
        menuNames.append("Assessment")
        menuNames.append("Plan")
        naviMenuCtrl.iconNames = iconNames
        naviMenuCtrl.menuNames = menuNames
        
        //Set the tableviewcontroller for the shared carioca menu
        let nmenu = CariocaMenu(dataSource: naviMenuCtrl)
        nmenu.selectedIndexPath = IndexPath(item: 0, section: 0)
        
        
        nmenu.boomerang = .none
        
        //reverse delegate for cell selection by tap :
        naviMenuCtrl.cariocaMenu = nmenu
        
        //show the first demo controller
        let mv = mainViewController
        nmenu.delegate = mv
        mv?.nmenu = nmenu
        mv?.showDemoControllerForIndex(0)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayingViewController?.beginAppearanceTransition(true, animated: animated)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayingViewController?.endAppearanceTransition()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayingViewController?.beginAppearanceTransition(false, animated: animated)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displayingViewController?.endAppearanceTransition()
    }

    // We will manually call `mainViewController` or `drawerViewController`'s
    // view appearance methods.
    override open var shouldAutomaticallyForwardAppearanceMethods: Bool {
        get {
            return false
        }
    }

    /**************************************************************************/
    // MARK: - Public Method
    /**************************************************************************/
    
    public func setLeftDrawerState(_ state: DrawerState, animated: Bool) {
        self.leftDrawerState = state
        _containerView.isHidden = false
        let duration: TimeInterval = animated ? drawerAnimationDuration : 0

        let isAppearing = state == .opened
        if _isAppearing != isAppearing {
            _isAppearing = isAppearing
            leftDrawerViewController?.beginAppearanceTransition(isAppearing, animated: animated)
            mainViewController?.beginAppearanceTransition(!isAppearing, animated: animated)
        }

        UIView.animate(withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: { () -> Void in
                switch state {
                case .closed:
                    self._leftDrawerConstraint.constant     = 0
                    self._containerView.backgroundColor = UIColor(white: 0, alpha: 0)
                case .opened:
                    let constant: CGFloat
                    constant = self.leftDrawerWidth
                   
                    self._leftDrawerConstraint.constant     = constant
                    self._containerView.backgroundColor = UIColor(
                        white: 0
                        , alpha: self.containerViewMaxAlpha
                    )
                }
                self._containerView.layoutIfNeeded()
            }) { (finished: Bool) -> Void in
                if state == .closed {
                    self._containerView.isHidden = true
                }
                self.leftDrawerViewController?.endAppearanceTransition()
                self.mainViewController?.endAppearanceTransition()
                self._isAppearing = nil
                self.delegate?.drawerController?(self, stateChanged: state)
        }
    }
    
    public func setRightDrawerState(_ state: DrawerState, animated: Bool) {
        self.rightDrawerState = state
        _containerView.isHidden = false
        let duration: TimeInterval = animated ? drawerAnimationDuration : 0
        
        let isAppearing = state == .opened
        if _isAppearing != isAppearing {
            _isAppearing = isAppearing
            rightDrawerViewController?.beginAppearanceTransition(isAppearing, animated: animated)
            mainViewController?.beginAppearanceTransition(!isAppearing, animated: animated)
        }
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: { () -> Void in
                        switch state {
                        case .closed:
                            self._rightDrawerConstraint.constant     = 0
                            self._containerView.backgroundColor = UIColor(white: 0, alpha: 0)
                        case .opened:
                            let constant: CGFloat
                            constant = -self.rightDrawerWidth
                            self._rightDrawerConstraint.constant     = constant
                            self._containerView.backgroundColor = UIColor(
                                white: 0
                                , alpha: self.containerViewMaxAlpha
                            )
                        }
                        self._containerView.layoutIfNeeded()
        }) { (finished: Bool) -> Void in
            if state == .closed {
                self._containerView.isHidden = true
            }
            self.rightDrawerViewController?.endAppearanceTransition()
            self.mainViewController?.endAppearanceTransition()
            self._isAppearing = nil
            self.delegate?.drawerController?(self, stateChanged: state)
        }
    }

    
    /**************************************************************************/
    // MARK: - Private Method
    /**************************************************************************/

    final func handlePanGesture(_ sender: UIGestureRecognizer) {
        _containerView.isHidden = false
        if sender.state == .began {
            _panStartLocation = sender.location(in: view)
            if self.leftDrawerState == .opened {
                whoIsChanging = -1
            } else if self.rightDrawerState == .opened {
                whoIsChanging = 1
            }
        }
        
        let delta           = CGFloat(sender.location(in: view).x - _panStartLocation.x)
        let constant        : CGFloat
        let backGroundAlpha : CGFloat
        var lDrawerState     : DrawerState
        var rDrawerState     : DrawerState
        
        lDrawerState = .closed
        rDrawerState = .closed
        if whoIsChanging == 0{
            if delta > 0 {
                whoIsChanging = -1
            }
            if delta < 0 {
                whoIsChanging = 1
            }
        } else if whoIsChanging == -1{
            lDrawerState = _panDelta > 0 ? .opened : .closed
            constant        = min(_leftDrawerConstraint.constant + delta, leftDrawerWidth)
            backGroundAlpha = min(
                containerViewMaxAlpha,
                containerViewMaxAlpha*(abs(constant)/leftDrawerWidth)
            )
            _leftDrawerConstraint.constant = constant
            _containerView.backgroundColor = UIColor(
                white: 0,
                alpha: backGroundAlpha
            )
        } else {
            rDrawerState = _panDelta < 0 ? .opened : .closed
            constant = max(_rightDrawerConstraint.constant + delta, -rightDrawerWidth)
            backGroundAlpha = min(
                containerViewMaxAlpha,
                containerViewMaxAlpha*(abs(constant)/rightDrawerWidth)
            )
            _rightDrawerConstraint.constant = constant
            _containerView.backgroundColor = UIColor(
                white: 0,
                alpha: backGroundAlpha
            )

        }
        
        switch sender.state {
        case .changed:
            if whoIsChanging == -1{
                let isAppearing = lDrawerState != .opened
                if _isAppearing == nil {
                    _isAppearing = isAppearing
                    leftDrawerViewController?.beginAppearanceTransition(isAppearing, animated: true)
                    mainViewController?.beginAppearanceTransition(!isAppearing, animated: true)
                }
            } else if whoIsChanging == 1 {
                let isAppearing = rDrawerState != .opened
                if _isAppearing == nil {
                    _isAppearing = isAppearing
                    rightDrawerViewController?.beginAppearanceTransition(isAppearing, animated: true)
                    mainViewController?.beginAppearanceTransition(!isAppearing, animated: true)
                }
            }
        
            _panStartLocation = sender.location(in: view)
            _panDelta         = delta
        case .ended, .cancelled:
            if whoIsChanging == -1{
                setLeftDrawerState(lDrawerState, animated: true)
                if lDrawerState == .closed {
                    whoIsChanging = 0
                }
                
            } else if whoIsChanging == 1 {
                setRightDrawerState(rDrawerState, animated: true)
                if rDrawerState == .closed {
                    whoIsChanging = 0
                }
            }
        default:
            break
        }
    }
    
    final func didtapContainerView(_ gesture: UITapGestureRecognizer) {
        setLeftDrawerState(.closed, animated: true)
        setRightDrawerState(.closed, animated: true)

    }
    
    
    /**************************************************************************/
    // MARK: - UIGestureRecognizerDelegate
    /**************************************************************************/
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case panGesture:
            return leftDrawerState == .opened || rightDrawerState == .opened
        case screenLeftEdgePanGesture:
            return screenEdgePanGestureEnabled ? leftDrawerState == .closed : false
        case screenRightEdgePanGesture:
            return screenEdgePanGestureEnabled ? rightDrawerState == .closed : false
        default:
            return touch.view == gestureRecognizer.view
        }
   }

}

