//
//  ChatSendMessagePanel.swift
//  ExchangeAndReturnChat
//
//  Created by Pavel Kazantsev on 01/10/15.
//  Copyright © 2015 Anywayanyday. All rights reserved.
//

import UIKit

private let minTextViewHeight: CGFloat = 28.0
private let maxTextViewHeight: CGFloat = 152.0 // 7 lines

class ChatSendMessagePanel: UIView, UITextViewDelegate {

    private let textView: UITextView = {
        let textView = UITextView()
        textView.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.iphoneDefaultFont(16.0)
        textView.layer.cornerRadius = 6.0
        textView.autocorrectionType = .No
        textView.spellCheckingType = .No
        textView.keyboardAppearance = .Dark
        //textView.contentInset = UIEdgeInsets(top: -4.0, left: 0.0, bottom: -4.0, right: 0.0)
        //textView.placeholder = NSLocalizedString("LocExchangeMessage", comment: "Placeholder for a exchange & refund chat text field")

        return textView
    }()
    private let attachButton: UIButton = {
        let button = UIButton(type: .System)
        button.setImage(UIImage(named: "Chat Camera Icon"), forState: .Normal)
        button.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.iphoneBlueColor()

        return button
    }()
    private let sendButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Send", forState: .Normal)
        button.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.iphoneDefaultFont(14.0)
        // TODO: This could be applied application-wide
        button.setTitleColor(UIColor.iphoneBlueColor(), forState: .Normal)
        button.setTitleColor(UIColor.iphoneMainGrayColor(), forState: .Disabled)

        return button
    }()
    private var textViewHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        sendButton.addTarget(self, action: "sendButtonPressed", forControlEvents: .TouchUpInside)
        attachButton.addTarget(self, action: "attachButtonPressed", forControlEvents: .TouchUpInside)

        textView.delegate = self

        initializeView()
        enableTextViewContentSizeObserver(true)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        enableTextViewContentSizeObserver(false)
    }

    private func initializeView() {
        backgroundColor = UIColor.iphoneMainNavbarColor()
        translatesAutoresizingMaskIntoConstraints = false

        let topLineView = UIView()
        topLineView.backgroundColor = UIColor.iphoneTroutColor()
        topLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLineView)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[line]|", options: [], metrics: nil, views: ["line": topLineView]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[line(1)]", options: [], metrics: nil, views: ["line": topLineView]))

        addSubview(attachButton)
        addSubview(textView)
        addSubview(sendButton)

        let views = ["attachButton": attachButton, "textView": textView, "sendButton": sendButton]

        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-5-[attachButton(44)]-5-[textView]-8-[sendButton]-8-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[textView]-8-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[attachButton(44)]-5-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[sendButton(44)]-5-|", options: [], metrics: nil, views: views))

        textViewHeightConstraint = NSLayoutConstraint(item: textView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minTextViewHeight)
        addConstraint(textViewHeightConstraint)
    }

    @objc private func attachButtonPressed() {
        NSLog("Attach button pressed")
    }

    @objc private func sendButtonPressed() {
        NSLog("Send button pressed")
    }

    // MARK: Text view delegate
    private func enableTextViewContentSizeObserver(enable: Bool) {
        if enable {
            textView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
        } else {
            textView.removeObserver(self, forKeyPath: "contentSize")
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let textView = object as? UITextView else {
            return
        }
        let newValue = textView.contentSize

        if newValue.height < minTextViewHeight {
            self.textViewHeightConstraint.constant = minTextViewHeight
        } else if newValue.height <= maxTextViewHeight {
            self.textViewHeightConstraint.constant = newValue.height
        }
        textView.layoutIfNeeded()
    }

    @objc func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView.text.characters.count > 0 && text == "\n" {
            if range.location > 0 && textView.text[textView.text.startIndex.advancedBy(range.location - 1)] == "\n" {
                // Character before
                return false;
            } else if textView.text.characters.count > range.location && textView.text[textView.text.startIndex.advancedBy(range.location)] == "\n" {
                // Character after
                return false;
            }
        }
        return true;
    }

}
