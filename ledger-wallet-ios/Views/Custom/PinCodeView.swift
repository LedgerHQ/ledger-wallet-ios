//
//  PinCodeView.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 21/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

@objc protocol PinCodeViewDelegate: class {
    
    optional func pinCodeView(pinCodeView: PinCodeView, didChangeText text: String)
    optional func pinCodeView(pinCodeView: PinCodeView, didRequestNewIndex index: Int, placeholderChar: String?)
    func pinCodeViewDidComplete(pinCodeView: PinCodeView, text: String)
    
}

class PinCodeView: View {
    
    var highlightedColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var filledColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var boxColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var length: Int = 0 {
        didSet {
            _textField.text = ""
            handleTextFieldDidChangeNotification()
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    var boxSize: CGSize = CGSizeZero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    var boxSpacing: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    var placeholder: String? {
        didSet {
            handleTextFieldDidChangeNotification()
            setNeedsDisplay()
        }
    }
    var borderWidth: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var dotRadius: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var restrictedCharacterSet: NSCharacterSet?
    weak var delegate: PinCodeViewDelegate?
    lazy private var _textField: UITextField = {
       let textField = UITextField()
        textField.tintColor = UIColor.clearColor()
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.secureTextEntry = true
        textField.hidden = true
        textField.borderStyle = UITextBorderStyle.None
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.keyboardType = UIKeyboardType.ASCIICapable
        return textField
    }()
    
    // MARK: Value
    
    func text() -> String {
        return _textField.text ?? ""
    }

    // MARK: Responder

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        _textField.becomeFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return _textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return _textField.resignFirstResponder()
    }
    
    override func isFirstResponder() -> Bool {
        return _textField.isFirstResponder()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return _textField.canBecomeFirstResponder()
    }
    
    // MARK: Content size
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake((boxSize.width * CGFloat(length)) + CGFloat(boxSpacing * CGFloat(length)) - (length > 0 ? boxSpacing : CGFloat(0)), length > 0 ? boxSize.height : 0)
    }
    
    // MARK: Drawing
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let borderDecal = (borderWidth / DeviceManager.sharedInstance.screenScale)
        let drawLetter: (_ : NSString, point: CGPoint, font: UIFont, color: UIColor) -> Void = { letter, point, font, color in
            let attributes = [NSForegroundColorAttributeName: color, NSFontAttributeName: font, NSParagraphStyleAttributeName: NSParagraphStyle.defaultParagraphStyle()]
            let size = letter.sizeWithAttributes(attributes)
            letter.drawAtPoint(CGPointMake(point.x - ceil(size.width) / 2.0, point.y - ceil(size.height) / 2.0), withAttributes: attributes)
        }

        for var i = 0; i < length; ++i {
            // draw box
            let boxRect = CGRectMake(CGFloat(i) * (boxSize.width - borderDecal + boxSpacing) + borderDecal, borderDecal, boxSize.width - borderDecal * 2, boxSize.height - borderDecal * 2)
            let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: VisualFactory.Metrics.BordersRadius.Large)
            let textFieldLength = _textField.text?.characters.count ?? 0
            boxPath.lineWidth = borderWidth
            var fillColor: UIColor!
            var strokeColor: UIColor!

            if (i == textFieldLength) {
                strokeColor = highlightedColor
                fillColor = boxColor
            }
            else if (i < textFieldLength) {
                strokeColor = filledColor
                fillColor = boxColor
            }
            else {
                strokeColor = filledColor?.colorWithAlphaComponent(0.5)
                fillColor = boxColor?.colorWithAlphaComponent(0.5)
            }
            fillColor?.setFill()
            strokeColor?.setStroke()
            boxPath.fill()
            boxPath.stroke()
            
            // draw content
            let boxCenter = CGPointMake(CGRectGetMidX(boxRect), CGRectGetMidY(boxRect))
            if (i == textFieldLength) {
                if let thePlaceholder = placeholder {
                    drawLetter((thePlaceholder as NSString).substringWithRange(NSMakeRange(i, 1)) ?? "", point: boxCenter, font: VisualFactory.Fonts.semiboldFontWithSize(VisualFactory.Fonts.Size.UltraHuge), color: strokeColor)
                }
            }
            else if (i < textFieldLength) {
                let dotPath = UIBezierPath(ovalInRect: CGRectInset(CGRectMake(boxCenter.x, boxCenter.y, 0, 0), -dotRadius / 2.0, -dotRadius / 2.0))
                UIColor.blackColor().setFill()
                dotPath.fill()
            }
            else {
                if let thePlaceholder = placeholder {
                    drawLetter((thePlaceholder as NSString).substringWithRange(NSMakeRange(i, 1)) ?? "", point: boxCenter, font: VisualFactory.Fonts.lightFontWithSize(VisualFactory.Fonts.Size.UltraHuge), color: strokeColor)
                }
            }
        }
    }
    
    // MARK: Initialization
    
    private func initialize() {
        backgroundColor = VisualFactory.Colors.Transparent
        addSubview(_textField)
        _textField.delegate = self
        observeTextFieldNotifications(true)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    deinit {
        observeTextFieldNotifications(false)
    }
    
}

// MARK: - UITextFieldDelegate

extension PinCodeView: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let restrictedCharacterSet = restrictedCharacterSet {
            if ((string as NSString).rangeOfCharacterFromSet(restrictedCharacterSet.invertedSet).location != NSNotFound) {
                return false
            }
        }
        if (range.length + range.location > (textField.text?.characters.count ?? 0)) {
            return false
        }
        let newLength = (textField.text?.characters.count ?? 0) + (string as NSString).length - range.length
        return (newLength > self.length) ? false : true
    }
    
}

// MARK: - Notifications

extension PinCodeView {
    
    private func observeTextFieldNotifications(observe: Bool) {
        if (observe) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTextFieldDidChangeNotification", name: UITextFieldTextDidChangeNotification, object: _textField)
        }
        else {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: _textField)
        }
    }
    
    private dynamic func handleTextFieldDidChangeNotification() {
        setNeedsDisplay()
        
        let textFieldText = _textField.text ?? ""
        delegate?.pinCodeView?(self, didChangeText: textFieldText)
        let textLength = textFieldText.characters.count
        if (textLength < length) {
            delegate?.pinCodeView?(self, didRequestNewIndex: textLength, placeholderChar: (placeholder as NSString?)?.substringWithRange(NSMakeRange(textLength, 1)))
        }
        if (length > 0 && textLength == length) {
            delegate?.pinCodeViewDidComplete(self, text: textFieldText)
        }
        
    }
    
}
