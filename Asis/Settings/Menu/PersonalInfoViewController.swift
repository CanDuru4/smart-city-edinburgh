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

class PersonalInfoViewController: UIViewController {
    
//MARK: Set Up
    
    
    
    //MARK: Set Variables
    var nameField = UITextField()
    var emailField = UITextField()
    var currentpasswordField = UITextField()
    var passwordField = UITextField()
    var passwordAuthenticateField = UITextField()
    var saveButton = UIButton()
    private let profile = UserProfileStore()
    

    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setLabels()
        getUserData()
        
        //MARK: Hide Keyboard
        self.hideKeyboardWhenTappedAround()
    }


    
//MARK: Variable Features
    func setLabels(){
        
        
        //MARK: Image Features
        let imageCan = UIImage(named: "can-duru-ana-logo")
        let imageView = UIImageView(image: imageCan)
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Name Field Features
        nameField.placeholder = String(localized: "namePlaceHolder")
        nameField.borderStyle = .roundedRect
        nameField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        nameField.layer.borderWidth = CGFloat(1)
        nameField.autocorrectionType = .no
        view.addSubview(nameField)
        nameField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Email Field Features
        emailField.placeholder = String(localized: "emailPlaceHolder")
        emailField.borderStyle = .roundedRect
        emailField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        emailField.layer.borderWidth = CGFloat(1)
        emailField.autocorrectionType = .no
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        view.addSubview(emailField)
        emailField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Current Password Field Features
        currentpasswordField.placeholder = String(localized: "passwordPlaceHolder")
        currentpasswordField.borderStyle = .roundedRect
        currentpasswordField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        currentpasswordField.layer.borderWidth = CGFloat(1)
        view.addSubview(currentpasswordField)
        currentpasswordField.isSecureTextEntry = true
        currentpasswordField.autocorrectionType = .no
        currentpasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: New Password Field Features
        passwordField.placeholder = String(localized: "newPasswordPlaceHolder")
        passwordField.borderStyle = .roundedRect
        passwordField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        passwordField.layer.borderWidth = CGFloat(1)
        view.addSubview(passwordField)
        passwordField.isSecureTextEntry = true
        passwordField.autocorrectionType = .no
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Authenticate Password Field Features
        passwordAuthenticateField.placeholder = String(localized: "authenticatePlaceHolder")
        passwordAuthenticateField.borderStyle = .roundedRect
        passwordAuthenticateField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        passwordAuthenticateField.layer.borderWidth = CGFloat(1)
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
    @objc func updateUser() {
        guard Backend.isConfigured, saveButton.isEnabled, let user = Auth.auth().currentUser,
              let currentEmail = user.email else {
            showMessage(title: String(localized: "notLoggedInError"))
            return
        }
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let currentPassword = currentpasswordField.text ?? ""
        let newPassword = passwordField.text ?? ""
        let confirmation = passwordAuthenticateField.text ?? ""
        guard !name.isEmpty, !email.isEmpty, !currentPassword.isEmpty else {
            showMessage(title: String(localized: "basicFillError"))
            return
        }
        guard newPassword == confirmation else {
            showMessage(title: String(localized: "passwordNotMatchError"))
            return
        }
        guard newPassword.isEmpty || isPasswordValid(newPassword) else {
            showMessage(title: String(localized: "passwordRequirementError"))
            return
        }
        saveButton.isEnabled = false
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self else { return }
            guard error == nil, Auth.auth().currentUser?.uid == user.uid else {
                self.finishUpdate(error: error ?? UserProfileStore.ProfileError.signedOut)
                return
            }
            UserProfileStore.update(fields: ["name": name]) { [weak self] error in
                guard let self else { return }
                guard error == nil, Auth.auth().currentUser?.uid == user.uid else {
                    self.finishUpdate(error: error ?? UserProfileStore.ProfileError.signedOut)
                    return
                }
                let updateEmail = { [weak self] in
                    guard let self else { return }
                    guard Auth.auth().currentUser?.uid == user.uid else {
                        self.finishUpdate(error: UserProfileStore.ProfileError.signedOut)
                        return
                    }
                    if email.caseInsensitiveCompare(currentEmail) != .orderedSame {
                        user.sendEmailVerification(beforeUpdatingEmail: email) { [weak self] error in
                            self?.finishUpdate(error: error, emailPending: error == nil)
                        }
                    } else {
                        self.finishUpdate(error: nil)
                    }
                }
                if newPassword.isEmpty {
                    updateEmail()
                } else {
                    user.updatePassword(to: newPassword) { [weak self] error in
                        if let error { self?.finishUpdate(error: error) }
                        else { updateEmail() }
                    }
                }
            }
        }
    }

    private func finishUpdate(error: Error?, emailPending: Bool = false) {
        saveButton.isEnabled = true
        if let error {
            showMessage(title: String(localized: "updateIncomplete"), message: error.localizedDescription)
        } else {
            currentpasswordField.text = ""
            passwordField.text = ""
            passwordAuthenticateField.text = ""
            showMessage(title: String(localized: emailPending ? "verifyNewEmail" : "updatedUser"))
        }
    }

    func getUserData() {
        guard Backend.isConfigured, let user = Auth.auth().currentUser else { return }
        emailField.text = user.email
        profile.observe(uid: user.uid) { [weak self] result in
            guard let self else { return }
            self.profile.stop()
            switch result {
            case .success(let data): self.nameField.text = data["name"] as? String ?? ""
            case .failure: self.showMessage(title: String(localized: "dataError"))
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        profile.stop()
        currentpasswordField.text = ""
        passwordField.text = ""
        passwordAuthenticateField.text = ""
    }

    func isPasswordValid(_ password: String) -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[0-9])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
}
