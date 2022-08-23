//
//  LoginViewController.swift
//  Asis
//
//  Created by Can Duru on 9.08.2022.
//

//MARK: Import
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

//MARK: Set Up
    
    
    
    //MARK: Set Variables
    var emailField = UITextField()
    var passwordField = UITextField()
    var loginButton = UIButton()
    var noAccountButton = UIButton()
    var resetPasswordButton = UIButton()
    
    
    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setLabels()
        
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

        //MARK: Email Field Features
        emailField.placeholder = String(localized: "emailPlaceHolder")
        emailField.borderStyle = .roundedRect
        emailField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        emailField.layer.borderWidth = CGFloat(1)
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none
        view.addSubview(emailField)
        emailField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Password Field Features
        passwordField.placeholder = String(localized: "passwordPlaceHolder")
        passwordField.borderStyle = .roundedRect
        passwordField.layer.borderColor = CGColor(red: 13/255, green: 95/255, blue: 255/255, alpha: 1)
        passwordField.layer.borderWidth = CGFloat(1)
        view.addSubview(passwordField)
        passwordField.isSecureTextEntry = true
        passwordField.autocorrectionType = .no
        passwordField.autocapitalizationType = .none
        passwordField.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Login Button Features
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitle(String(localized: "loginButton"), for: .normal)
        loginButton.tintColor = .white
        loginButton.layer.cornerRadius = 5
        loginButton.clipsToBounds = true
        view.addSubview(loginButton)
        loginButton.addTarget(self, action: #selector(logIn), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: No Account Button Features
        noAccountButton.setTitle(String(localized: "createAccountButton"), for: .normal)
        noAccountButton.setTitleColor(.systemBlue, for: .normal)
        noAccountButton.clipsToBounds = true
        view.addSubview(noAccountButton)
        noAccountButton.addTarget(self, action: #selector(transitiontoSignUp), for: .touchUpInside)
        noAccountButton.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Reset Password Features
        resetPasswordButton.setTitle(String(localized: "resetPasswordButton"), for: .normal)
        resetPasswordButton.setTitleColor(.black, for: .normal)
        resetPasswordButton.clipsToBounds = true
        view.addSubview(resetPasswordButton)
        resetPasswordButton.addTarget(self, action: #selector(resetPassword), for: .touchUpInside)
        resetPasswordButton.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Varibles Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Image Constraints
            imageView.centerXAnchor.constraint(equalTo: emailField.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: emailField.topAnchor, constant: -50),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            //MARK: Email Field Constraints
            emailField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emailField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Password Field Constraints
            passwordField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 5),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 35),

      
            //MARK: Login Button Constraints
            loginButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 5),
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: Reset Password Button Constraints
            resetPasswordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            resetPasswordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 5),
            resetPasswordButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            resetPasswordButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            resetPasswordButton.heightAnchor.constraint(equalToConstant: 35),
            
            //MARK: No Account Button Constraints
            noAccountButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            noAccountButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            noAccountButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            noAccountButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            noAccountButton.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    
    
//MARK: Log In Button Action
    @objc func logIn(){
        
        
        //MARK: Validate All Fields Filled
        let error = validateFields()
        
        
        //MARK: Not Filled
        if error != nil {
            let alert = UIAlertController(title: String(localized: "advancedFillError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        //MARK: Filled
        } else {
            let email = emailField.text?.lowercased()
            let password = passwordField.text
            Auth.auth().signIn(withEmail: email ?? "", password: password ?? "") { [weak self] authResult, error in
              guard let strongSelf = self else { return }
                //MARK: Wrong User Credentials
                if error != nil {
                    let alert = UIAlertController(title: String(localized: "emailpasswordMatchError"), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                    strongSelf.present(alert, animated: true, completion: nil)
                    
                //MARK: Correct User Credentials
                } else {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }


    
//MARK: Rest Password Button Action
    @objc func resetPassword(){
        let email = passwordField.text
        if email != nil {
            Auth.auth().sendPasswordReset(withEmail: email!) { (error) in
                if error != nil {
                    //MARK: Email Not Correct
                    let alert = UIAlertController(title: String(localized: "emailError"), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            //MARK: Email Field Empty
            let alert = UIAlertController(title: String(localized: "emailemptyError"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
//MARK: Transition to Sign Up
    @objc func transitiontoSignUp(){
        self.navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
    
    
    
//MARK: Validate All Fields
    func validateFields() -> String? {
        if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields."
        }
        return nil
    }
}



//MARK: Hide Keyboard
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
