//
//  PaintingBrushSettingsView.swift
//  DrawingBoard
//
//  Created by ZhangAo on 15-3-28.
//  Copyright (c) 2015年 zhangao. All rights reserved.
//

import UIKit

class SpeechView: UIView {
    
    @IBOutlet weak var stackView: UIStackView!
    let timeToLabel = [
        "2017.3.1 12:30:24": "Hello, what’s the matter?",
        "2017.3.1 12:30:50": "I have a terrible pain in my left hand.",
        "2017.3.1 12:31:24": "For how long has your hand been bothering you?",
        "2017.3.1 12:32:33": "It's been more than a week. It was okay, but from the last two days, I'm unable to bear it.",
        "2017.3.1 12:33:11": "Well, has it been injured or hurt before?",
        "2017.3.1 12:34:54": "No doctor, this is the first time.",
        "2017.3.1 12:35:34": "Have you taken any medicine?",
        "2017.3.1 12:35:43": "Yes, I have been taking this painkiller.",
        "2017.3.1 12:36:54": "Any other information you would want me to know before I start checking your hand?",
        "2017.3.1 12:36:34": "Yes, I carried a heavy box two weeks before with both hands. It was okay then, but after a week, my left hand started hurting.",
        "2017.3.1 12:36:44": "Oh, that’s strange. Let’s have a look at your hand."
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        for (t, label) in timeToLabel {
//            let aline = UIStackView()
//            aline.axis = UILayoutConstraintAxis.horizontal
//            let tt = UILabel()
//            tt.text = t
//            tt.textAlignment = NSTextAlignment.right
//            tt.width = 160
//            let ll = MyLabel(label)
//            aline.addArrangedSubview(tt)
//            aline.addArrangedSubview(ll)
//            stackView.addArrangedSubview(aline)
//        }
    }
}
