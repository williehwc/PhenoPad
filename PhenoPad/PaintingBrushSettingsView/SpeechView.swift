//
//  SpeechView.swift
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-24.
//  Copyright © 2017 CCM. All rights reserved.
//

public class SpeechView : UIViewController, UITextViewDelegate, RichTextEditorDataSource, EditTextByDrawingViewDelegate {

    @IBOutlet weak var textView: WPTextView!
    var inkCollect: EditTextByDrawingView?
    
    override public func viewDidLoad() {
        self.navigationController?.isNavigationBarHidden = true
    }
    override public func viewDidAppear(_ animated: Bool) {
        self.textView.initTextViewWithoutFrame()
        self.textView.delegate = self
        UserDefaults.standard.set(Int(WPLanguageEnglishUS.rawValue), forKey: kGeneralOptionsCurrentLanguage)
        self.textView.setInputMethod(InputSystem_NoKeyboard)
        self.inkCollect = EditTextByDrawingView(frame: self.textView.frame)
        self.inkCollect?.backgroundColor = UIColor.clear
        self.inkCollect?.delegate = self
        self.inkCollect?.edit = self.textView
        self.inkCollect?.isHidden = false
        self.view.addSubview(self.inkCollect!)
        self.textView?.appendAttributedString("asdfasdfasdf\nasdfasdf\naefawefwe\nsdfsdfsd")
    }
    
    
}
