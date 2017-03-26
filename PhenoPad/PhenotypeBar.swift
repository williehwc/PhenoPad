//
//  PhenotypeBar.swift
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-26.
//  Copyright © 2017 CCM. All rights reserved.
//

import Foundation
import UIKit

public class PhenotypeBar: UIScrollView {
    let ITEM_SPACE:CGFloat = 10.0
    let TOP_BOTTOM:CGFloat = 5.0
    var formerview:UIView?
    var noteViewController:UIViewController?

    
    override init(frame:CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.init(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1)
        //self.layer.borderWidth = 0.7;
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        self.addPhenotype(phenotype: "Phenotype 1")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype asdfasdf")
        self.addSeperator()
        self.addPhenotype(phenotype: "Phenotype 23235235")
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func buttonWithText(text: String) -> UIButton
    {
        let btn = UIButton()
        btn.setTitle(text, for: .normal)
        return btn;
    }
    
    public func addPhenotype(phenotype: String){
        let btn = self.buttonWithText(text: phenotype)
        btn.width = 50.0
        btn.setTitleColor(UIColor.init(red: 0, green: 122, blue: 255), for: .normal)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
        self.addView(view: btn, after: formerview, withSpace: true)
        formerview = btn
    }
    
    public func addSeperator(){
        let s = UIView(frame: CGRect(x:0, y:0, width:0.7, height:0))
        s.backgroundColor = UIColor.lightGray
        self.addView(view: s, after: formerview, withSpace: true)
        formerview = s
    }
    
    public func addView(view:UIView, after:UIView?, withSpace:Bool){
        let afterRect = after == nil ? CGRect.zero : after!.frame
        var rect = view.frame
        rect.origin.x = afterRect.size.width + afterRect.origin.x
        if(withSpace){
            rect.origin.x += ITEM_SPACE
        }
        rect.origin.y = TOP_BOTTOM
        rect.size.height = self.frame.size.height - 2*TOP_BOTTOM
        view.frame = rect
        view.autoresizingMask = UIViewAutoresizing.flexibleHeight
        self.addSubview(view)
        self.updateContentSize()
    }
    
    public func updateContentSize() {
        var maxloc:CGFloat = 0.0
        for view : UIView in self.subviews{
            let endloc = view.frame.size.width + view.frame.origin.x
            if endloc > maxloc{
                maxloc = endloc
            }
        }
        self.contentSize = CGSize(width: maxloc+ITEM_SPACE, height: self.frame.size.height);
    }
    
    @IBAction func btnTapped(sender: UIButton) {
        let tableViewController = UITableViewController()
        tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        tableViewController.preferredContentSize = CGSize(width: 400, height: 200)
        
        noteViewController?.present(tableViewController, animated: true, completion: nil)
        
        let popoverPresentationController = tableViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
    }

}
