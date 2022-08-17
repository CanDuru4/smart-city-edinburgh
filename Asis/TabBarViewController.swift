//
//  TabBarViewController.swift
//  Asis
//
//  Created by Can Duru on 1.08.2022.
//

//MARK: Import
import UIKit

class TabBarViewController : UITabBarController {
    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        UITabBar.appearance().barTintColor = .systemBackground
        tabBar.backgroundColor = .white
        tabBar.tintColor = .label
        setupVCs()
    }
    
    //MARK: Create ViewControllers
    func setupVCs() {
          viewControllers = [
            createNavController(for: HomeViewController(), title: NSLocalizedString("", comment: ""), image: UIImage(systemName: "house.fill")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue)),
              createNavController(for: BusStopsViewController(), title: NSLocalizedString("", comment: ""), image: UIImage(systemName: "bus.fill")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue)),
              createNavController(for: CardViewController(), title: NSLocalizedString("", comment: ""), image: UIImage(systemName: "creditcard.fill")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue)),
              createNavController(for: SettingsViewController(), title: NSLocalizedString("", comment: ""), image: UIImage(systemName: "gear.circle.fill")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue))
          ]
      }
    
    //MARK: Set Tabbar Items
    var i = -1
    fileprivate func createNavController(for rootViewController: UIViewController,
                                                    title: String,
                                                    image: UIImage) -> UIViewController {
          let items = [String(localized: "tabBarItemHome"), String(localized: "tabBarItemStops"), String(localized: "tabBarItemsMyCards"), String(localized: "tabBarItemsSettings")]
          i = i+1
          let navController = UINavigationController(rootViewController: rootViewController)

          navController.tabBarItem.title = items[i]
          navController.tabBarItem.image = image
          navController.navigationBar.prefersLargeTitles = false
          rootViewController.navigationItem.title = title
          return navController
      }
}
