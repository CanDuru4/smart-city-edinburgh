//
//  CreditCardView.swift
//  CreditCardView
//
//  Created by Can Duru on 2.08.2022.
//

import UIKit

public class CreditCardView: UIView {

    
    public var backgroundView:CCBackgroundView
    var cardContentView:CCContentView
    
    var CONTENT_PADDING:CGFloat = 25
    
    public var nameLabel:UILabel {
        get { return cardContentView.nameLabel }
    }
    
    public var expLabel:UILabel {
        get { return cardContentView.expLabel }
    }
    
    public var numLabel:UILabel {
        get { return cardContentView.numberLabel }
    }
    
    public var brandLabel:UILabel {
        get { return cardContentView.brandLabel }
    }
    
    
    public override init(frame: CGRect) {
        backgroundView = CCBackgroundView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        cardContentView = CCContentView(frame: .zero)
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        backgroundView = CCBackgroundView()
        cardContentView = CCContentView()
        super.init(coder: aDecoder)
        setupViews()
    }
    
    public init(frame: CGRect, template: CCBackgroundView.CCBackgroundTemplate) {
        backgroundView = CCBackgroundView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), template: template)
        cardContentView = CCContentView(frame: .zero)
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.addSubview(backgroundView)
        backgroundView.layer.cornerRadius = 10.0
        
        self.addSubview(cardContentView)
    }

    /// Resizes the card contents when Auto Layout changes the card's bounds.
    ///
    /// Initial frames may be zero on modern scene-based layouts. This keeps both layers
    /// inside their final bounds. Takes no parameters, returns nothing, and does not throw.
    /// Example: called by UIKit after the My Cards screen receives its safe area.
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        cardContentView.frame = bounds.insetBy(dx: min(CONTENT_PADDING, bounds.width / 2), dy: min(CONTENT_PADDING, bounds.height / 2))
    }
    
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */

}
