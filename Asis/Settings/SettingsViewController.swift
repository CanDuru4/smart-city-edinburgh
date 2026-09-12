import UIKit
import SideMenu
import FirebaseAuth

/// Shows account settings without presenting authentication before the screen is visible.
///
/// Owns its auth/profile listeners so account switches clear the preceding user's details.
/// Example: embed in the Settings navigation tab.
final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let greeting = UILabel()
    private let signInButton = UIButton(type: .system)
    private var handle: AuthStateDidChangeListenerHandle?
    private let profile = UserProfileStore()
    private var menu: SideMenuNavigationController?
    private let items = [String(localized: "personalPersonalInfoTable"), String(localized: "personalFAQTable"), String(localized: "personalLogOutButtonTable")]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.leading"), style: .plain, target: self, action: #selector(showMenu))
        greeting.font = .preferredFont(forTextStyle: .title1)
        greeting.numberOfLines = 0
        greeting.adjustsFontForContentSizeCategory = true
        signInButton.setTitle(String(localized: "loginButton"), for: .normal)
        signInButton.accessibilityIdentifier = "accountSignInButton"
        signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "setting")
        [greeting, signInButton, table].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            greeting.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            greeting.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            greeting.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            signInButton.topAnchor.constraint(equalTo: greeting.bottomAnchor, constant: 20),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            table.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 16),
            table.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard Backend.isConfigured else {
            greeting.text = String(localized: "accountUnavailable")
            table.isHidden = true
            signInButton.isHidden = true
            return
        }
        guard handle == nil else { return }
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.profile.stop()
            self.greeting.text = user == nil ? String(localized: "notLoggedInError") : String(localized: "hiText")
            self.table.isHidden = user == nil
            self.signInButton.isHidden = user != nil
            guard let user else { return }
            self.profile.observe(uid: user.uid) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let data):
                    self.greeting.text = String(localized: "hiText") + (data["name"] as? String ?? "")
                case .failure: self.showMessage(title: String(localized: "dataError"))
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        profile.stop()
        if let handle, Backend.isConfigured { Auth.auth().removeStateDidChangeListener(handle) }
        handle = nil
    }

    @objc private func showMenu() {
        guard let menu else { return }
        present(menu, animated: true)
    }

    @objc private func signIn() {
        guard Backend.isConfigured else { return }
        present(AuthViewController(), animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setting", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = indexPath.row == 2 ? .none : .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Backend.isConfigured, Auth.auth().currentUser != nil else { return }
        switch indexPath.row {
        case 0: navigationController?.pushViewController(PersonalInfoViewController(), animated: true)
        case 1: navigationController?.pushViewController(FAQViewController(), animated: true)
        case 2:
            do { try Auth.auth().signOut() }
            catch { showMessage(title: String(localized: "dataError")) }
        default: break
        }
    }

    deinit {
        if let handle, Backend.isConfigured { Auth.auth().removeStateDidChangeListener(handle) }
    }
}
