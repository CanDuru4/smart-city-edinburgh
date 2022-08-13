//
//  SettingsViewController.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

//MARK: Import
import UIKit
import SideMenu
import FirebaseAuth
import FirebaseFirestore
class SettingsViewController: UIViewController {

//MARK: Setup
    
    
    
    //MARK: Table Setup
    lazy var SettingsTable: UITableView = {
        let tb = UITableView()
        tb.delegate = self
        tb.dataSource = self
        tb.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.identifer)
        return tb
    }()
    var items = [String(localized: "personalPersonalInfoTable"), String(localized: "personalFAQTable"), String(localized: "personalLogOutButtonTable")]

    //MARK: Auth Setup
    weak var handle: AuthStateDidChangeListenerHandle?
    
    //MARK: Side Menu Setup
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
        view.backgroundColor = .white
        
        //MARK: User Check
        
        
        
                //MARK: User Logged In
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else {return}
            if ((user) != nil) {
                //MARK: Settings Table Set
                self.setView()
                self.view.addSubview(self.SettingsTable)
                self.setTableLayout()
                self.getUserData()
            
                //MARK: User Not Logged In
            } else {
                let vc = AuthViewController()
                vc.modalPresentationStyle = .currentContext
                self.navigationController?.present(vc, animated: true)
            }
        }
        
        //MARK: Side Menu Load
        navigationItem.setLeftBarButton(menuBarButtonItem, animated: false)
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        menu?.setNavigationBarHidden(true, animated: false)
    }
    
    
//MARK: Hi Text Function
    var hiText = UILabel()
    func setView(){
        hiText.text = ""
        hiText.font = hiText.font.withSize(30)
        hiText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hiText)

        NSLayoutConstraint.activate([
            hiText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            hiText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            ])
    }
    
    
    
//MARK: Table Layout
    func setTableLayout(){
        SettingsTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            SettingsTable.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            SettingsTable.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -10),
            SettingsTable.widthAnchor.constraint(equalToConstant: 300),
            SettingsTable.heightAnchor.constraint(equalToConstant: 300)
            ])
    }
    
    
    
//MARK: Log Out
    func logOut(){
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
    
    
//MARK: Color Text Beginning
    func addSpecificColorText(fullString: NSString, colorPartOfString: NSString) -> NSAttributedString {
        let nonColorFontAttribute = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue]
        let colorFontAttribute = [NSAttributedString.Key.foregroundColor: UIColor.black]
        let coloredString = NSMutableAttributedString(string: fullString as String, attributes:nonColorFontAttribute)
        coloredString.addAttributes(colorFontAttribute, range: fullString.range(of: colorPartOfString as String))
        return coloredString
    }
}

//MARK: Table Extension
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: Rov Number
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    //MARK: Cell Content
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifer, for: indexPath) as! SettingsTableViewCell
        cell.textLabel?.text = items[indexPath.row]
        cell.textLabel?.numberOfLines = -1
        cell.textLabel?.textColor = .black
        return cell
    }
    
    //MARK: Cell Select Function
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            tableView.deselectRow(at: indexPath, animated: true)
            self.navigationController?.pushViewController(PersonalInfoViewController(), animated: true)
        }
        if (indexPath.row == 1) {
            tableView.deselectRow(at: indexPath, animated: true)
            self.navigationController?.pushViewController(FAQViewController(), animated: true)
        }
        if (indexPath.row == 2) {
            tableView.deselectRow(at: indexPath, animated: true)
            logOut()
        }
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
                            self.hiText.text = ((String(localized: "hiText")) + ((data) as! String))
                            self.hiText.attributedText = self.addSpecificColorText(fullString: self.hiText.text! as NSString, colorPartOfString: "Hi, ")
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
}
