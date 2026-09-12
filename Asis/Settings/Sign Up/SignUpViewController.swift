//
//  SignUpViewController.swift
//  Asis
//
//  Created by Can Duru on 9.08.2022.
//

//MARK: Import
import UIKit
import FirebaseFirestore
import FirebaseAuth

class SignUpViewController: UIViewController {
    private var pendingProfileUser: User?
    private var profileSaved = false

//MARK: Set Up
    
    
    
    //MARK: Set Variables
    var nameField = UITextField()
    var emailField = UITextField()
    var passwordField = UITextField()
    var passwordAuthenticateField = UITextField()
    var signUpButton = UIButton()
    

    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setLabels()
        
        //MARK: Hide Keyboard
        self.hideKeyboardWhenTappedAround()
    }
    

    
//MARK: Variables Features
    func setLabels(){
        
        
        //MARK: Image Feature
        let imageCan = UIImage(named: "can-duru-ana-logo")
        let imageView = UIImageView(image: imageCan)
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Name Field Feature
        nameField.placeholder = String(localized: "namePlaceHolder")
        nameField.borderStyle = .roundedRect
        nameField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        nameField.layer.borderWidth = CGFloat(1)
        nameField.autocorrectionType = .no
        view.addSubview(nameField)
        nameField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Email Field Feature
        emailField.placeholder = String(localized: "emailPlaceHolder")
        emailField.borderStyle = .roundedRect
        emailField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        emailField.layer.borderWidth = CGFloat(1)
        emailField.autocorrectionType = .no
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        view.addSubview(emailField)
        emailField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Password Field Feature
        passwordField.placeholder = String(localized: "passwordPlaceHolder")
        passwordField.borderStyle = .roundedRect
        passwordField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        passwordField.layer.borderWidth = CGFloat(1)
        view.addSubview(passwordField)
        passwordField.isSecureTextEntry = true
        passwordField.autocorrectionType = .no
        passwordField.autocapitalizationType = .none
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Password Authenticate Field Feature
        passwordAuthenticateField.placeholder = String(localized: "authenticatePlaceHolder")
        passwordAuthenticateField.borderStyle = .roundedRect
        passwordAuthenticateField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        passwordAuthenticateField.layer.borderWidth = CGFloat(1)
        view.addSubview(passwordAuthenticateField)
        passwordAuthenticateField.isSecureTextEntry = true
        passwordAuthenticateField.autocorrectionType = .no
        emailField.autocapitalizationType = .none
        passwordAuthenticateField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Sign Up Button Feature
        signUpButton.backgroundColor = .systemBlue
        signUpButton.setTitle(String(localized: "signUpButton"), for: .normal)
        signUpButton.tintColor = .white
        signUpButton.layer.cornerRadius = 15
        signUpButton.clipsToBounds = true
        view.addSubview(signUpButton)
        signUpButton.addTarget(self, action: #selector(signUpUser), for: .touchUpInside)
        signUpButton.accessibilityIdentifier = "signUpButton"
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        //MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Image Constraints
            imageView.centerXAnchor.constraint(equalTo: nameField.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: nameField.topAnchor, constant: -50),
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

            
            //MARK: Password Field Constraints
            passwordField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 5),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 35),

            
            //MARK: Password Authenticate Field Constraints
            passwordAuthenticateField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passwordAuthenticateField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 5),
            passwordAuthenticateField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordAuthenticateField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordAuthenticateField.heightAnchor.constraint(equalToConstant: 35),

            
            //MARK: Sign Up Button Constraints
            signUpButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            signUpButton.topAnchor.constraint(equalTo: passwordAuthenticateField.bottomAnchor, constant: 10),
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            signUpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            signUpButton.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
    

    
//MARK: Sign Up Button Action
    @objc func signUpUser() {
        guard Backend.isConfigured, signUpButton.isEnabled else { return }
        if profileSaved {
            navigationController?.dismiss(animated: true)
            return
        }
        guard validateFields() == nil else { return }
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let user = pendingProfileUser {
            saveNewProfile(user: user, name: name)
            return
        }
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""
        signUpButton.isEnabled = false
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            guard let user = result?.user, error == nil else {
                self.signUpButton.isEnabled = true
                self.showMessage(title: String(localized: "creatingError"))
                return
            }
            self.pendingProfileUser = user
            self.emailField.isEnabled = false
            self.passwordField.isEnabled = false
            self.passwordAuthenticateField.isEnabled = false
            self.saveNewProfile(user: user, name: name)
        }
    }

    private func saveNewProfile(user: User, name: String) {
        guard Auth.auth().currentUser?.uid == user.uid else {
            signUpButton.isEnabled = true
            showMessage(title: String(localized: "notLoggedInError"))
            return
        }
        signUpButton.isEnabled = false
        Firestore.firestore().collection("users").document(user.uid).setData(["name": name, "uid": user.uid], merge: true) { [weak self] error in
            guard let self else { return }
            guard error == nil else {
                self.signUpButton.isEnabled = true
                self.signUpButton.setTitle(String(localized: "retryProfileSetup"), for: .normal)
                self.showMessage(title: String(localized: "profileSetupIncomplete"))
                return
            }
            self.profileSaved = true
            user.sendEmailVerification { [weak self] error in
                guard let self else { return }
                self.signUpButton.isEnabled = true
                if error != nil {
                    self.signUpButton.setTitle(String(localized: "continueButton"), for: .normal)
                    self.showMessage(title: String(localized: "verificationEmailFailed"))
                } else {
                    self.navigationController?.dismiss(animated: true)
                }
            }
        }
    }

//MARK: Validate Fields
    func validateFields() -> String? {
        
        
        //MARK: Check Empty Fields
        if (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            (passwordField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            (passwordAuthenticateField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let alert = UIAlertController(title: String(localized: "advancedFillError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Lütfen bütün boşlukları doldurun."
        }
        
        //MARK: Check Match Between Passwords
        let cleanedPassword = (passwordField.text ?? "")
        let authenticatecleanedPassword = (passwordAuthenticateField.text ?? "")
        if cleanedPassword != authenticatecleanedPassword{
            let alert = UIAlertController(title: String(localized: "passwordNotMatchError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Doğrulama şifreniz ile girdiğiniz şifre uyuşmuyor. "

        }
        
        //MARK: Validate Password
        if isPasswordValid(cleanedPassword) == false {
            let alert = UIAlertController(title: String(localized: "passwordRequirementError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return "Lütfen şifrenizin en az 8 karakter olduğundan, özel bir karakter (!,?,&,...) ve bir sayı içerdiğinden emin olun."
        }
        return nil
    }
    
    
    
//MARK: Password Requirements
    func isPasswordValid(_ password : String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[0-9])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
}
