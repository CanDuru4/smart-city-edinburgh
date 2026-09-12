import UIKit
import SideMenu
import CoreNFC
import FirebaseAuth

/// Displays the signed-in user's NFC identifier without inventing a transport balance.
///
/// Core NFC supplies a tag identifier, not the operator's balance or card number.
/// Example: show this controller in the My Cards navigation tab.
final class CardViewController: UIViewController, NFCTagReaderSessionDelegate {
    private var session: NFCTagReaderSession?
    private var handle: AuthStateDidChangeListenerHandle?
    private let profile = UserProfileStore()
    private var scanUserID: String?
    private let testcard = CreditCardView(frame: .zero, template: .Flat(.systemGray))
    private let addCardButton = UIButton(type: .system)
    private var menu: SideMenuNavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.leading"), style: .plain, target: self, action: #selector(showMenu))
        view.addSubview(testcard)
        view.addSubview(addCardButton)
        testcard.translatesAutoresizingMaskIntoConstraints = false
        addCardButton.translatesAutoresizingMaskIntoConstraints = false
        addCardButton.setTitle(String(localized: "addCardButton"), for: .normal)
        addCardButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        addCardButton.accessibilityIdentifier = "scanCardButton"
        NSLayoutConstraint.activate([
            testcard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            testcard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testcard.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -40),
            testcard.heightAnchor.constraint(equalToConstant: 215),
            addCardButton.topAnchor.constraint(equalTo: testcard.bottomAnchor, constant: 16),
            addCardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addCardButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        resetCard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard Backend.isConfigured else {
            addCardButton.isEnabled = false
            testcard.nameLabel.text = String(localized: "accountUnavailable")
            return
        }
        guard handle == nil else { return }
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.profile.stop()
            self.resetCard()
            guard let user else {
                self.session?.invalidate()
                self.scanUserID = nil
                return
            }
            self.profile.observe(uid: user.uid) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let data):
                    self.testcard.nameLabel.text = data["name"] as? String ?? ""
                    self.testcard.numLabel.text = data["cardnumber"] as? String ?? String(localized: "noCardAdded")
                case .failure:
                    self.showMessage(title: String(localized: "dataError"))
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        profile.stop()
        if let handle, Backend.isConfigured { Auth.auth().removeStateDidChangeListener(handle) }
        handle = nil
        session?.invalidate()
        session = nil
        scanUserID = nil
        resetCard()
    }

    private func resetCard() {
        testcard.nameLabel.text = ""
        testcard.numLabel.text = String(localized: "noCardAdded")
        testcard.expLabel.text = String(localized: "balanceUnavailable")
        testcard.numLabel.adjustsFontSizeToFitWidth = true
        testcard.numLabel.minimumScaleFactor = 0.4
    }

    @objc private func showMenu() {
        guard let menu else { return }
        present(menu, animated: true)
    }

    @objc private func pressed() {
        guard Backend.isConfigured, let user = Auth.auth().currentUser else {
            showMessage(title: String(localized: "notLoggedInError"))
            return
        }
        guard NFCTagReaderSession.readingAvailable else {
            showMessage(title: String(localized: "notScanSupportedError"), message: String(localized: "notScanSupportedErrorDetail"))
            return
        }
        guard session == nil else { return }
        scanUserID = user.uid
        session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: .main)
        session?.alertMessage = String(localized: "holdCardNearPhone")
        session?.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard self.session === session else { return }
        self.session = nil
        scanUserID = nil
        guard let readerError = error as? NFCReaderError,
              readerError.code != .readerSessionInvalidationErrorUserCanceled,
              readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead else { return }
        showMessage(title: String(localized: "timeOutError"), message: error.localizedDescription)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard self.session === session, let scanUserID,
              Backend.isConfigured, Auth.auth().currentUser?.uid == scanUserID else {
            session.invalidate(errorMessage: String(localized: "notLoggedInError"))
            return
        }
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = String(localized: "oneCardAtATime")
            session.restartPolling()
            return
        }
        let identifier: Data
        switch tag {
        case .iso15693(let card): identifier = card.identifier
        case .miFare(let card): identifier = card.identifier
        case .iso7816(let card): identifier = card.identifier
        default:
            session.invalidate(errorMessage: String(localized: "unsupportedCard"))
            return
        }
        let value = CardIdentifier.hex(identifier)
        guard !value.isEmpty else {
            session.invalidate(errorMessage: String(localized: "unsupportedCard"))
            return
        }
        self.session = nil
        self.scanUserID = nil
        session.alertMessage = String(localized: "cardIdentifierRead")
        session.invalidate()
        UserProfileStore.update(fields: ["cardnumber": value]) { [weak self] error in
            guard let self, Backend.isConfigured, Auth.auth().currentUser?.uid == scanUserID else { return }
            if let error {
                self.showMessage(title: String(localized: "dataError"), message: error.localizedDescription)
            } else {
                self.testcard.numLabel.text = value
                self.showMessage(title: String(localized: "cardSaved"))
            }
        }
    }

    deinit {
        if let handle, Backend.isConfigured { Auth.auth().removeStateDidChangeListener(handle) }
    }
}
