//
//  PersonalInfoViewController.swift
//  Asis
//
//  Created by Can Duru on 11.08.2022.
//

//MARK: Import
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

class PersonalInfoViewController: UIViewController {
    
//MARK: Set Up
    
    
    
    //MARK: Set Variables
    var nameField = UITextField()
    var emailField = UITextField()
    var currentpasswordField = UITextField()
    var passwordField = UITextField()
    var passwordAuthenticateField = UITextField()
    var saveButton = UIButton()
    

    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setLabels()
        getUserData()
        
        //MARK: Hide Keyboard
        self.hideKeyboardWhenTappedAround()
    }


    
//MARK: Variable Features
    func setLabels(){
        
        
        //MARK: Image Features
        let imageAsis = UIImage(named: "ASIS_LOGO_SEFFAF-2")?.resized(to: CGSize(width: 600, height: 600))
        let imageView = UIImageView(image: imageAsis)
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Name Field Features
        nameField.backgroundColor = .gray
        nameField.placeholder = String(localized: "namePlaceHolder")
        nameField.borderStyle = .roundedRect
        nameField.autocorrectionType = .no
        view.addSubview(nameField)
        nameField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Email Field Features
        emailField.backgroundColor = .gray
        emailField.placeholder = String(localized: "emailPlaceHolder")
        emailField.borderStyle = .roundedRect
        emailField.autocorrectionType = .no
        view.addSubview(emailField)
        emailField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Current Password Field Features
        currentpasswordField.backgroundColor = .gray
        currentpasswordField.placeholder = String(localized: "passwordPlaceHolder")
        currentpasswordField.borderStyle = .roundedRect
        view.addSubview(currentpasswordField)
        currentpasswordField.isSecureTextEntry = true
        currentpasswordField.autocorrectionType = .no
        currentpasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: New Password Field Features
        passwordField.backgroundColor = .gray
        passwordField.placeholder = String(localized: "newPasswordPlaceHolder")
        passwordField.borderStyle = .roundedRect
        view.addSubview(passwordField)
        passwordField.isSecureTextEntry = true
        passwordField.autocorrectionType = .no
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Authenticate Password Field Features
        passwordAuthenticateField.backgroundColor = .gray
        passwordAuthenticateField.placeholder = String(localized: "authenticatePlaceHolder")
        passwordAuthenticateField.borderStyle = .roundedRect
        view.addSubview(passwordAuthenticateField)
        passwordAuthenticateField.isSecureTextEntry = true
        passwordAuthenticateField.autocorrectionType = .no
        passwordAuthenticateField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Save Button Field Features
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitle(String(localized: "updateUserButton"), for: .normal)
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 15
        saveButton.clipsToBounds = true
        view.addSubview(saveButton)
        saveButton.addTarget(self, action: #selector(updateUser), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        

        //MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Image Constraints
            imageView.centerXAnchor.constraint(equalTo: nameField.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: nameField.topAnchor, constant: -20),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            //MARK: Name Field Constraints
            nameField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            nameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Email Field Constraints
            emailField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 5),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Current Field Constraints
            currentpasswordField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            currentpasswordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 5),
            currentpasswordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            currentpasswordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            currentpasswordField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Password Field Constraints
            passwordField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passwordField.topAnchor.constraint(equalTo: currentpasswordField.bottomAnchor, constant: 5),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Password Authenticate Field Constraints
            passwordAuthenticateField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passwordAuthenticateField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 5),
            passwordAuthenticateField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordAuthenticateField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordAuthenticateField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Save Button Constraints
            saveButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            saveButton.topAnchor.constraint(equalTo: passwordAuthenticateField.bottomAnchor, constant: 10),
            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            saveButton.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
  
    
    
//MARK: Update User Button Action
    @objc func updateUser(){
        
        
        //MARK: Validate Fields
        let error = validateFields()
    
        if error != nil {

        } else {
            
            //MARK: Name, Email, and Password Field Checked
            let user = Auth.auth().currentUser
            let email = user?.email?.lowercased()
            let password = currentpasswordField.text
            Auth.auth().signIn(withEmail: email ?? "", password: password ?? "") { [weak self] authResult, error in
              guard let strongSelf = self else { return }
                if error != nil {
                    
                    //MARK: User Current Password Wrong
                    let alert = UIAlertController(title: String(localized: "passwordError"), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                    strongSelf.present(alert, animated: true, completion: nil)
                } else {
                    
                    //MARK: User Current Password Correct
                    self?.changeuser()
                }
            }
        }
    }
    
    

//MARK: Get User Data
    func getUserData(){
        userid(name: "String") { (useruid) in
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if (user != nil) {
                    let user = Auth.auth().currentUser
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
                            self.nameField.text = data as? String
                            self.emailField.text = user?.email
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
    
    

//MARK: Update User Function
    func changeuser(){
        let changeName =  nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let changeEmail = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let changePassword = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)

        let db = Firestore.firestore()
        let user = Auth.auth().currentUser
        let uid = user!.uid
        
        //MARK: Update User Name
        userid(name: "String") { (useruid) in
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if (user != nil) {
                    db.collection("users").document(useruid).updateData(["name": changeName, "uid": uid]) { (error) in
                        
                        if error != nil {
                            let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        
        //MARK: Update Email
        Auth.auth().currentUser?.updateEmail(to: changeEmail) { (error) in
            if error != nil {
                let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }

        //MARK: Update Password
        let error = validatePasswordChange()
        if error != nil
        {
            
            //MARK: Password Change Not Wanted
            let alert = UIAlertController(title: String(localized: "updatedUser"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            
            //MARK: Password Change Wanted
            let error_pass = validatePasswords()
            if error_pass != nil {
            } else {
                
                //MARK: Passwords Matched
                Auth.auth().currentUser?.updatePassword(to: changePassword) {  (error) in
                    if error != nil {
                        let alert = UIAlertController(title: String(localized: "dataError"), message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: String(localized: "updatedUser"), message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                }
            }
        }
    }
    

    
//MARK: Validate Password Change
    func validatePasswordChange() -> String? {
        
        if passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordAuthenticateField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "şifre değişimi yok"
        }
        return nil
    }
    
    

//MARK: Validate Match Between Password
    func validatePasswords() -> String? {
        let cleanedPassword = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let authenticatecleanedPassword = passwordAuthenticateField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedPassword != authenticatecleanedPassword{
            let alert = UIAlertController(title: String(localized: "passwordNotMatchError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Doğrulama şifreniz ile girdiğiniz şifre uyuşmuyor. "
        }
        
        //MARK: Password Requirements Not Matched
        if isPasswordValid(cleanedPassword) == false {
            let alert = UIAlertController(title: String(localized: "passwordRequirementError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Lütfen şifrenizin en az 8 karakter olduğundan, özel bir karakter (!,?,&,...) ve bir sayı içerdiğinden emin olun."

        }
        return nil
    }
    
    
    
//MARK: Valite Name, Email, and Current Password Field
    func validateFields() -> String? {
        if nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            currentpasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            let alert = UIAlertController(title: String(localized: "basicFillError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Lütfen bütün boşlukları doldurun."
        }
        return nil
    }
        


//MARK: Password Requirements
    func isPasswordValid(_ password : String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[0-9])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
}
