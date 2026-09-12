import XCTest
import UIKit
@testable import Asis

/// Protects the card's visible contents when UIKit starts it with a zero frame.
@MainActor
final class CardLayoutTests: XCTestCase {
    func testCardLabelsStayInsideTheCardAfterInitialLayoutAndResize() {
        let card = CreditCardView(frame: .zero, template: .Flat(.systemGray))
        card.nameLabel.text = "Example name"
        card.expLabel.text = "Unavailable"
        card.numLabel.text = "00010FFF"
        for width in [280.0, 350.0] {
            card.frame = CGRect(x: 0, y: 0, width: width, height: 215)
            card.setNeedsLayout()
            card.layoutIfNeeded()
            card.cardContentView.layoutIfNeeded()
            for label in [card.brandLabel, card.numLabel, card.nameLabel, card.expLabel] {
                let visibleFrame = label.convert(label.bounds, to: card)
                XCTAssertFalse(visibleFrame.isEmpty)
                XCTAssertTrue(card.bounds.contains(visibleFrame), "Label clipped: \(label.text ?? "") at \(visibleFrame)")
            }
        }
    }
}
