//
//  SpeechView.swift
//  PhenoPad
//
//  Created by Jixuan Wang on 2017-03-24.
//  Copyright © 2017 CCM. All rights reserved.
//

public class SpeechView : UIViewController, UITextViewDelegate, RichTextEditorDataSource, EditTextByDrawingViewDelegate {

    
    var textView: SpeechViewTextView?
    
    
    var inkCollect: EditTextByDrawingView?
    
    override public func viewDidLoad() {
        self.navigationController?.isNavigationBarHidden = true
        
        
        if self.textView != nil {
            return
        }   else {
            self.textView = SpeechViewTextView(frame: self.view.frame)
            self.view.addSubview(self.textView!)
            self.textView?.delegate = self
            UserDefaults.standard.set(Int(WPLanguageEnglishUS.rawValue), forKey: kGeneralOptionsCurrentLanguage)
            self.textView?.setInputMethod(InputSystem_NoKeyboard)
            self.inkCollect = EditTextByDrawingView(frame: self.textView!.frame)
            self.inkCollect?.backgroundColor = UIColor.clear
            self.inkCollect?.delegate = self
            self.inkCollect?.edit = self.textView
            self.inkCollect?.isHidden = false
            self.view.addSubview(self.inkCollect!)
        }

        self.textView?.addSpeech("Good Afternoon, doctor.\n")
        self.textView?.addSpeech("Good afternoon. What is your problem?\n")
        self.textView?.addSpeech("What do you feel?\n")
        self.textView?.addSpeech("What do you feel?\n")
        self.textView?.addSpeech("How long have you had this pain and acidity?\n")
        self.textView?.addSpeech("For 2 months now. It does not go way! I eat and after every meal my stomach hurts. Even at night the pain persists.\n")
        self.textView?.addSpeech("Tell me, in the last 2 months, have you eaten any kind of heavy food, or something different?\n")
        self.textView?.addSpeech("No.\n")
        self.textView?.addSpeech("How strong is the pain. Lets say in a 1 to 10 scale, how would you describe the intensity of the pain?\n")
        self.textView?.addSpeech("Between 4-5\n")
        self.textView?.addSpeech("Is the pain continuous or does it come and go?\n")
        self.textView?.addSpeech("It come and goes.\n")
        self.textView?.addSpeech("Does the pain come after meals?\n")
        self.textView?.addSpeech("That's possible because it hurts everytime after eating.\n")
        self.textView?.addSpeech("Is there a kind of food that affects you more?\n")
        self.textView?.addSpeech("Greasy food.\n")
        self.textView?.addSpeech("Greasy food affects you?\n")
        self.textView?.addSpeech("Yes. At home we eat a lot of greasy food.\n")
        self.textView?.addSpeech("Where in the abdomen does it hurt? Point please! Does the pain travel to your chest, shoulder, back or across your abdomen?\n")
        self.textView?.addSpeech("It hurts in the middle. Sometimes, the pain travels across my abdomen.\n")
        self.textView?.addSpeech("Besides the pain, you said you have heartburn?\n")
        self.textView?.addSpeech("Yes, after a burp, I feel a kind of sour taste.\n")
        self.textView?.addSpeech("Do you feel like this more during the day or in the evenings?\n")
        self.textView?.addSpeech("Both. I feel the acidity during the day and at night.\n")
        self.textView?.addSpeech("Is it worse when lying down?\n")
        self.textView?.addSpeech("Yes, I taste the acid in my mouth?\n")
        self.textView?.addSpeech("Besides greasy food, is there any other kind of food that irritates your stomach? Like spicy food?\n")
        self.textView?.addSpeech("No, at home we don't eat spicy food.\n")
        self.textView?.addSpeech("And tell me, how often do you regularly have a bowel movement? Has that changed since you have been having these problems?\n")
        self.textView?.addSpeech("It is regular. It hasn't changed since the problem.\n")
        self.textView?.addSpeech("Have you noticed any change in the consistency of the bowel movement?\n")
    }
    override public func viewDidAppear(_ animated: Bool) {
        
        // self.textView?.appendAttributedString("asdfasdfasdf\nasdfasdf\naefawefwe\nsdfsdfsd")
        
    
        
    }
    
    
}
