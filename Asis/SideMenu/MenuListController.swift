//
//  MenuListController.swift
//  Asis
//
//  Created by Can Duru on 3.08.2022.
//

//MARK: Import
import Foundation
import SideMenu

class MenuListController: UITableViewController {
    static let shared = MenuListController()
    
//MARK: Set Up
        
    
    
    //MARK: Side Menu Items
    var items = [String(localized: "sideMenuAllBusStops"), String(localized: "sideMenuLanguage"), String(localized: "sideMenuShareApp")]
    let darkColor = UIColor(red: 33/255.0, green: 33/255.0, blue: 33/255.0, alpha: 1)
    var selectedCellIndexPath: IndexPath?


    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = darkColor
        tableView.register(SideMenuTableViewCell.self, forCellReuseIdentifier: SideMenuTableViewCell.identifer)
    }
    
    
    
//MARK: Table View
    
    
    
    //MARK: Row Number
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    var heightOfRow = CGFloat(0)
    let pre = Locale.preferredLanguages[0]
    //MARK: Cell Content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuTableViewCell.identifer, for: indexPath) as! SideMenuTableViewCell
        cell.titleLabel.text = items[indexPath.row]
        cell.backgroundColor = darkColor
        
        //MARK: Language Content
        if indexPath == [0, 1] {
            if pre == "de" {
                cell.imagePlace.image = UIImage(named: "German")
            }
            if pre == "en" {
                cell.imagePlace.image = UIImage(named: "English")
            }
            if pre == "es" {
                cell.imagePlace.image = UIImage(named: "Spanish")
            }
            if pre == "fr" {
                cell.imagePlace.image = UIImage(named: "French")
            }
            if pre == "ru" {
                cell.imagePlace.image = UIImage(named: "Russian")
            }
            if pre == "tr" {
                cell.imagePlace.image = UIImage(named: "Turkish")
            }
            if pre == "zh-Hans" {
                cell.imagePlace.image = UIImage(named: "Chinese")
            }
        }
        if indexPath == [0,0] {
            heightOfRow = self.calculateHeight(inString: cell.description)
        }
        return cell

    }
    
    //MARK: Header Content
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50))
        let imageView = UIImageView(image: UIImage(named: "logo-dark"))
        imageView.contentMode = .scaleAspectFit
        header.addSubview(imageView)
        return header
    }
    
    
    
    //MARK: Header Height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    
    
    //MARK: Cell Height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == [0,0] {
            print(heightOfRow)
            return heightOfRow
        }
        if indexPath == [0,1] {
            return 40
        }

        if indexPath == [0,2] {
            return 40
        }
        return 0
    }
        
    func calculateHeight(inString:String) -> CGFloat
        {
            let messageString = inString

            let attributedString : NSAttributedString = NSAttributedString(string: messageString, attributes: nil)

            let rect : CGRect = attributedString.boundingRect(with: CGSize(width: view.bounds.width , height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)

            let requredSize:CGRect = rect
            return requredSize.height
        }
    
    
    //MARK: Select function
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            tableView.deselectRow(at: indexPath, animated: true)
            let newViewController = AllStopsViewController()
            self.navigationController?.pushViewController(newViewController, animated: true)
        }
        if (indexPath.row == 1) {
            let settingsURL = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            let alert = UIAlertController(title: String(localized: "restartApp"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        if (indexPath.row == 2) {
            tableView.deselectRow(at: indexPath, animated: true)
            presentShareSheet()
        }
    }
    
    
    
//MARK: Share Sheet
    private func presentShareSheet() {
        guard let url = URL(string: "https://apps.apple.com/developer/can-duru/id1601190409") else {
            return
        }
        
        let shareSheetVC = UIActivityViewController(
            activityItems: [
                url,
            ],
            applicationActivities: [Safari()]
        )
        present(shareSheetVC, animated: true)
    }
}



//MARK: Share Sheet Class
class Safari: UIActivity {
    override var activityTitle: String? { "openSafari" }
    override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("openSafari") }
    override var activityImage: UIImage? { UIImage(systemName: "safari.fill") }
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }
    override class var activityCategory: UIActivity.Category { .action }
    override func prepare(withActivityItems activityItems: [Any]) {
    }
    override func perform() {
        if let url = URL(string: "https://apps.apple.com/developer/can-duru/id1601190409") {
            UIApplication.shared.open(url)
        }
    }
}
