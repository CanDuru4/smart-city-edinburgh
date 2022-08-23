//
//  CardViewController.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

//MARK: Import
import UIKit
import SideMenu
import CoreNFC
import FirebaseAuth
import FirebaseFirestore

class CardViewController: UIViewController, NFCTagReaderSessionDelegate {
    
    
//MARK: Set Up
    
    //MARK: NFC Set Up
    var session: NFCReaderSession?
    
    
    //MARK: Auth Set Up
    weak var handle: AuthStateDidChangeListenerHandle?

    //MARK: Side Menu Set Up
    var menu: SideMenuNavigationController?
    lazy var menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.leading")?.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue), style: .done, target: self, action: #selector(menuBarButtonItemTapped))
    @objc
    func menuBarButtonItemTapped(){
        present(menu!, animated: true)
    }
    lazy var menuView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    
    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //MARK: Side Menu Load
        navigationItem.setLeftBarButton(menuBarButtonItem, animated: false)
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        menu?.setNavigationBarHidden(true, animated: false)
        
        //MARK: Default Card View
        defaultView()
        
                //MARK: User Logged In
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else {return}
            if ((user) != nil) {
                //MARK: Card Name Set
                self.getUserData()
                self.getCardData()
                self.getBalanceData()
                //MARK: User Not Logged In
            } else {

            }
        }
    }
    

    
//MARK: Default View
    var testcard = CreditCardView()
    func defaultView(){
        //MARK: Card
        let c3:UIColor = UIColor(ciColor: .gray)
        let midX = self.view.bounds.midX
        let minY = self.view.safeAreaInsets.top
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        testcard = CreditCardView(frame: CGRect(x: midX-((width-40)/2), y: (minY+(height/8)), width: width-40, height: 215), template: .Flat(c3))
        testcard.numLabel.text = "XXXX XXXX XXX XXX"
        view.addSubview(testcard)
        
        //MARK: Button
        let addCardButton = UIButton(type: .custom)
        addCardButton.setTitle(String(localized: "addCardButton"), for: .normal)
        addCardButton.tintColor = .black
        addCardButton.backgroundColor = .systemBlue
        addCardButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        view.addSubview(addCardButton)
    
        addCardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([addCardButton.topAnchor.constraint(equalTo: testcard.bottomAnchor, constant: 10), addCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50), addCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50), addCardButton.heightAnchor.constraint(equalToConstant: 30)])
        addCardButton.layer.cornerRadius = 15
        addCardButton.layer.masksToBounds = true
    }
    


//MARK: Get User Data
    func getUserData(){
        userid(name: "String") { (useruid) in
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if (user != nil) {
                    let db = Firestore.firestore()
                    db.collection("users").document(useruid)
                        .addSnapshotListener { documentSnapshot, error in
                          guard let document = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                          }
                          guard let data = document.data()?["name"] else {
                            print("Document data was empty.")
                            return
                          }
                            self.testcard.nameLabel.text = data as? String
                            
                        }
                }
            }
        }
    }
    
    
    
//MARK: Get Card Data
    func getCardData(){
        userid(name: "String") { (useruid) in
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if (user != nil) {
                    let db = Firestore.firestore()
                    db.collection("users").document(useruid)
                        .addSnapshotListener { documentSnapshot, error in
                          guard let document = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                          }
                          guard let data = document.data()?["cardnumber"] else {
                            print("Document data was empty.")
                            return
                          }
                            if (data as! String) != ("") {
                                self.testcard.numLabel.text = data as? String
                                
                            }
                        }
                }
            }
        }
    }

    
    
//MARK: Get Balance Data
    func getBalanceData(){
        userid(name: "String") { (useruid) in
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if (user != nil) {
                    let db = Firestore.firestore()
                    db.collection("users").document(useruid)
                        .addSnapshotListener { documentSnapshot, error in
                          guard let document = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                          }
                          guard let data = document.data()?["balance"] else {
                            print("Document data was empty.")
                            return
                          }
                            if (data as! String) != ("") {
                                self.testcard.expLabel.text = ((data as? String)!) + " £"
                                
                            }
                        }
                }
            }
        }
    }

    
    
//MARK: Get User Path
    func userid(name: String, completion: @escaping (String) -> Void){
        let db = Firestore.firestore()
        let user = Auth.auth().currentUser
        let uid = user!.uid
        db.collection("users").whereField("uid", isEqualTo: uid)
            .getDocuments() { (querySnapshot, err) in
                if err != nil {
                    let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    for document in (querySnapshot!.documents) {
                        let useruid = document.documentID
                        completion(useruid)
                    }
                }
            }
    }
    
    
    
//MARK: NFC
    @objc func pressed() {
        
        //MARK: Kullanıcı Var
        let user = Auth.auth().currentUser
        if ((user) != nil) {
            guard NFCNDEFReaderSession.readingAvailable else {
                let alertController = UIAlertController(
                    title: String(localized: "notScanSupportedError"),
                    message: String(localized: "notScanSupportedErrorDetail"),
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: String(localized: "okButton"), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }

            //MARK: NFC Taraması Başlatıldı
            session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)
            session?.alertMessage = String(localized: "scanSuccess")
            session?.begin()
            
        //MARK: Kullanıcı Yok
        } else {
            let alert = UIAlertController(title: String(localized: "notLoggedInError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }


    
//MARK: NFC Taraması Aktif
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    

    
//MARK: Hata Oluştu
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: String(localized: "timeOutError"),
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: String(localized: "okButton"), style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }

        self.session = nil
    }
    
    
    
//MARK: Kart Okundu
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        let db = Firestore.firestore()
        let user = Auth.auth().currentUser
        let uid = user!.uid
        
        //MARK: 15693 Kodlu Kart
        if case .iso15693(let nfc15693Tag) = tag {
            var byteData = [UInt8]()
            nfc15693Tag.identifier.withUnsafeBytes { byteData.append(contentsOf: $0) }
            var uidcard = "0"
            byteData.forEach {
                uidcard.append(String($0, radix: 16))
            }
            
            //MARK: Set Card Number
            let first_four = uidcard.prefix(4)
            
            let start = uidcard.index(uidcard.startIndex, offsetBy: 4)
            let end = uidcard.index(uidcard.startIndex, offsetBy: 7)
            let range = start...end
            let second_four = String(uidcard[range])
            
            let start1 = uidcard.index(uidcard.startIndex, offsetBy: 8)
            let end1 = uidcard.index(uidcard.startIndex, offsetBy: 10)
            let range1 = start1...end1
            let first_three = String(uidcard[range1])
            
            let start2 = uidcard.index(uidcard.startIndex, offsetBy: 11)
            let end2 = uidcard.index(uidcard.startIndex, offsetBy: uidcard.count-1)
            let range2 = start2...end2
            let second_three = String(uidcard[range2])

            let cardnumber = first_four + " " + second_four + " " + first_three + " " + second_three
            userid(name: "String") { (useruid) in
                Auth.auth().addStateDidChangeListener { (auth, user) in
                    if (user != nil) {
                        let randomint = Int.random(in: 1..<100)
                        
                        //MARK: Update User
                        db.collection("users").document(useruid).updateData(["cardnumber": cardnumber, "balance": String(randomint), "uid": uid]) { (error) in
                            if error != nil {
                                let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                let _ = { () in
                    self.dismiss(animated: true, completion: {
                    })
                }
            }
            session.invalidate()
        }
        
        //MARK: Mifare Kodlu Kart
        if case .miFare(let mifareTag) = tag {
            var byteData = [UInt8]()
            mifareTag.identifier.withUnsafeBytes { byteData.append(contentsOf: $0) }
            var uidcard = "0"
            byteData.forEach {
                uidcard.append(String($0, radix: 16))
            }
            
            //MARK: Set Card Number
            let first_four = uidcard.prefix(4)
            
            let start = uidcard.index(uidcard.startIndex, offsetBy: 4)
            let end = uidcard.index(uidcard.startIndex, offsetBy: 7)
            let range = start...end
            let second_four = String(uidcard[range])
            
            let start1 = uidcard.index(uidcard.startIndex, offsetBy: 8)
            let end1 = uidcard.index(uidcard.startIndex, offsetBy: 10)
            let range1 = start1...end1
            let first_three = String(uidcard[range1])
            
            let start2 = uidcard.index(uidcard.startIndex, offsetBy: 11)
            let end2 = uidcard.index(uidcard.startIndex, offsetBy: uidcard.count-1)
            let range2 = start2...end2
            let second_three = String(uidcard[range2])

            let cardnumber = first_four + " " + second_four + " " + first_three + " " + second_three
            userid(name: "String") { (useruid) in
                Auth.auth().addStateDidChangeListener { (auth, user) in
                    if (user != nil) {
                        let randomint = Int.random(in: 1..<100)
                        
                        //MARK: Update User
                        db.collection("users").document(useruid).updateData(["cardnumber": cardnumber, "balance": String(randomint), "uid": uid]) { (error) in
                            if error != nil {
                                let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                let _ = { () in
                    self.dismiss(animated: true, completion: {
                    })
                }
            }
            session.invalidate()
        }
        
        //MARK: 7816 Kodlu Kart
        if case .iso7816(let nfc7816Tag) = tag {
            var byteData = [UInt8]()
            nfc7816Tag.identifier.withUnsafeBytes { byteData.append(contentsOf: $0) }
            var uidcard = "0"
            byteData.forEach {
                uidcard.append(String($0, radix: 16))
            }
            
            //MARK: Set Card Number
            let first_four = uidcard.prefix(4)
            
            let start = uidcard.index(uidcard.startIndex, offsetBy: 4)
            let end = uidcard.index(uidcard.startIndex, offsetBy: 7)
            let range = start...end
            let second_four = String(uidcard[range])
            
            let start1 = uidcard.index(uidcard.startIndex, offsetBy: 8)
            let end1 = uidcard.index(uidcard.startIndex, offsetBy: 10)
            let range1 = start1...end1
            let first_three = String(uidcard[range1])
            
            let start2 = uidcard.index(uidcard.startIndex, offsetBy: 11)
            let end2 = uidcard.index(uidcard.startIndex, offsetBy: uidcard.count-1)
            let range2 = start2...end2
            let second_three = String(uidcard[range2])

            let cardnumber = first_four + " " + second_four + " " + first_three + " " + second_three
            userid(name: "String") { (useruid) in
                Auth.auth().addStateDidChangeListener { (auth, user) in
                    if (user != nil) {
                        let randomint = Int.random(in: 1..<100)
                        
                        //MARK: Update User
                        db.collection("users").document(useruid).updateData(["cardnumber": cardnumber, "balance": String(randomint), "uid": uid]) { (error) in
                            if error != nil {
                                let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                let _ = { () in
                    self.dismiss(animated: true, completion: {
                    })
                }
            }
            session.invalidate()
        }
    }
}
