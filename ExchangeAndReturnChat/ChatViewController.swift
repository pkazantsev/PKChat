//
//  ExchangeAndReturnChatViewController.swift
//  ExchangeAndReturnChat
//
//  Created by Pavel Kazantsev on 29/09/15.
//  Copyright © 2015 Anywayanyday. All rights reserved.
//

import UIKit

private let chatCellIdentifier = "ExchangeAndReturnChatBubble"
private let chatHeaderIdentifier = "ExchangeAndReturnChatDateAndTime"
private let chatFooterIdentifier = "ExchangeAndReturnChatFinishStatus"

enum ChatElementType {
    case ClientBubble(date: NSDate, text: String?, url: NSURL?)
    case OperatorBubble(date: NSDate, text: String?, url: NSURL?)
}

enum ChatRequestStatus: String {
    case Requested = "REQUESTED"
    case Answered = "ANSWERED"
    case AwaitingConfirmation = "AWAITING_CONFIRM"
    case Confirmed = "CONFIRMED"
    case Cancelled = "CANCELED"
    case Finished = "FINISHED"
//    case Other

    var description: String {
        let statusCode: String
        switch self {
        case .Requested: statusCode = "LocExchangeRequested" // Could also be "LocExchangeInProcess"
        case .Answered: statusCode = "LocExchangeAnswered"
        case .AwaitingConfirmation: statusCode = "LocExchangeAwaitingConfirm"
        case .Confirmed: statusCode = "LocExchangeConfirmed"
        case .Cancelled: statusCode = "LocRequestCancelled"
        case .Finished: statusCode = "LocRequestFinished"
        }

        return NSLocalizedString(statusCode, comment: "Exchange & Refund request status description")
    }
}

enum MessageAuthorType {
    case Client
    case Operator
}

struct ChatMessage {
    let date: NSDate
    let text: String?
    let imageUrl: NSURL?
    let requestStatus: ChatRequestStatus
    let authorType: MessageAuthorType

    init(date: NSDate, text: String? = nil, imageUrl: NSURL? = nil, requestStatus: ChatRequestStatus, author: MessageAuthorType) {
        self.date = date
        self.text = text
        self.imageUrl = imageUrl
        self.requestStatus = requestStatus
        self.authorType = author
    }

    func rowsCount() -> Int {
        var count = 0
        if imageUrl != nil {
            count++
        }
        if text != nil {
            count++
        }
        return count
    }
}

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var data = [ChatMessage]()

    private let layout = UICollectionViewFlowLayout()

    init() {
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        edgesForExtendedLayout = UIRectEdge.None
        view.translatesAutoresizingMaskIntoConstraints = false

        if let c = collectionView {
            c.backgroundColor = UIColor.iphoneDarkBackgroundColor()

            c.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

            c.registerClass(ChatCollectionViewCell.self, forCellWithReuseIdentifier: chatCellIdentifier)
            c.registerClass(ChatDateAndTimeReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: chatHeaderIdentifier)
            c.registerClass(ChatFinishedReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: chatFooterIdentifier)
        }

        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        layout.headerReferenceSize = CGSize(width: 100, height: 24)
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return data.count
    }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // If section has image and a text
        guard data.count > section else {
            return 0
        }
        let message = data[section]

        return message.rowsCount()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var cellHeight: CGFloat = 40.0
        let cellWidth = bubbleCellWidth()

        // Calculate a cell height
        let message = data[indexPath.section]
        if indexPath.row == 0 && message.imageUrl != nil {
            cellHeight = ceil(cellWidth * 0.5 * 0.66) // 2/3 of a half of the width. Bubble width should be a half of the cell width
        } else if let text = message.text {
            cellHeight = ChatCollectionViewCell.sizeWithText(text, maxWidth: maxBubbleWidth()).height
        }

        return CGSize(width: cellWidth, height: CGFloat(cellHeight))
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatCellIdentifier, forIndexPath: indexPath) as! ChatCollectionViewCell
        cell.maxBubbleWidth = maxBubbleWidth()
        cell.backgroundColor = self.collectionView?.backgroundColor

        let message = data[indexPath.section]
        let position: ChatElementPosition
        switch message.authorType {
        case .Client:
            position = .Right // Client is always right
        case .Operator:
            position = .Left
        }

        if indexPath.row == 0 {
            if let imageUrl = message.imageUrl {
                cell.configure(imageUrl, position: position)
            } else if let text =  message.text {
                cell.configure(text, position: position)
            }
        } else if let text = message.text {
            // Duplicated call! Rid of it if possible
            cell.configure(text, position: position)
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let message = data[section]

        if message.requestStatus == .Cancelled || message.requestStatus == .Finished {
            return CGSize(width: 200, height: 24)
        } else {
            return CGSizeZero
        }
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let message = data[indexPath.section]

            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: chatHeaderIdentifier, forIndexPath: indexPath) as! ChatDateAndTimeReusableView
            view.backgroundColor = self.collectionView?.backgroundColor
            view.configure(date: message.date)

            return view
        } else if kind == UICollectionElementKindSectionFooter {
            let message = data[indexPath.section]

            if message.requestStatus == .Cancelled || message.requestStatus == .Finished {
                let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: chatFooterIdentifier, forIndexPath: indexPath) as! ChatFinishedReusableView
                view.backgroundColor = self.collectionView?.backgroundColor
                view.configure(statusDescription: message.requestStatus.description, date: message.date, showUnderline: false)

                return view
            }
        }
        return UICollectionReusableView()
    }

    func maxBubbleWidth() -> CGFloat {
        return bubbleCellWidth() * 0.7
    }
    func bubbleCellWidth() -> CGFloat {
        return ceil((self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right) * 0.95)
    }

}

private class ChatDateAndTimeReusableView: UICollectionReusableView {

    private static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        return formatter
    }()

    private var label: UILabel = {
        let label = UILabel()

        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        label.textColor = UIColor.iphoneMainGrayColor()
        label.font = UIFont.iphoneDefaultFont(16.0)

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        initializeView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(date date: NSDate) {
        label.text = "\(ChatDateAndTimeReusableView.dateFormatter.stringFromDate(date))"
    }

    private func initializeView() {

        addSubview(label)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [.AlignAllCenterX], metrics: nil, views: ["label": label]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [.AlignAllCenterY], metrics: nil, views: ["label": label]))
    }

}

private class ChatFinishedReusableView: UICollectionReusableView {

    private static let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        return dateFormatter
    }()

    private var label: UILabel = {
        let label = UILabel()

        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        label.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Vertical)
        label.textColor = UIColor.iphoneMainGrayColor()
        label.font = UIFont.iphoneRegularFont(14.0)

        return label
    }()
    lazy private var separator: UIView = {
        let separator = UIView()

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.iphoneTroutColor()

        return separator
    }()
    private var verticalConstraints = [NSLayoutConstraint]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        initializeView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        separator.removeFromSuperview()
    }

    func configure(statusDescription statusText: String, date: NSDate, showUnderline: Bool) {
        label.text = "\(ChatFinishedReusableView.dateFormatter.stringFromDate(date)) \(statusText)"

        if showUnderline {
            addSubview(separator)
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[separator]|", options: [], metrics: nil, views: ["separator": separator]))
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]-3-[separator(1)]|", options: [], metrics: nil, views: ["label": label, "separator": separator]))
        } else {
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: ["label": label]))
        }
    }

    private func initializeView() {

        addSubview(label)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: ["label": label]))
    }

}