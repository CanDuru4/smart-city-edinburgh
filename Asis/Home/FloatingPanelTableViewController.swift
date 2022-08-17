//
//  FloatingPanelTableViewController.swift
//  Asis
//
//  Created by Can Duru on 17.08.2022.
//

//MARK: Import
import UIKit

class FloatingPanelTableViewController: UITableViewController {

//MARK: Set Up
    var parentvc: HomeViewController!
    var routeTime: Int!
    var walkingFromCurrentTime: Int! {
        didSet{
            tableView.reloadData()
        }
    }
    var walkingToDestinationTime: Int! {
        didSet{
            tableView.reloadData()
        }
    }
    var totaltime: String! {
        didSet{
            tableView.reloadSections(IndexSet(0..<1), with: .automatic)
        }
    }
    var service: String! {
        didSet{
            tableView.reloadData()
        }
    }
    
    
    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(FloatingTableViewCell.self, forCellReuseIdentifier: FloatingTableViewCell.identifer)
    }

    
    
//MARK: Table
    
    
    
    //MARK: Row Number
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    //MARK: Cell Content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FloatingTableViewCell.identifer, for: indexPath) as! FloatingTableViewCell
        if indexPath == [0, 0] {
            cell.titleLabel.text = String(localized: "walkingToStop")
            cell.detailLabel_howlong.text = String(localized: "walkingToStopTime") + (String(describing: walkingFromCurrentTime))
            cell.detailLabel_services.text = ""
            cell.imagePlace.image = UIImage(systemName: "figure.walk")
        }
        if indexPath == [0, 1] {
            cell.titleLabel.text = String(localized: "transportation")
            cell.detailLabel_howlong.text = String(localized: "transportationTime") + (String(describing: routeTime))
            cell.detailLabel_services.text = String(localized: "transportationServices") + (String(describing: service))
            cell.imagePlace.image = UIImage(systemName: "bus.fill")
        }
        if indexPath == [0, 2] {
            cell.titleLabel.text = String(localized: "walkingToDestination")
            cell.detailLabel_howlong.text = String(localized: "walkingToDestinationTime") + (String(describing: walkingToDestinationTime))
            cell.detailLabel_services.text = ""
            cell.imagePlace.image = UIImage(systemName: "figure.walk")
        }
        return cell
    }
    
    //MARK: Cell Height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    

    //MARK: Header Content
    var headerView: UIView!
    var labelView: UILabel!
    var cancelButton: UIButton!
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        
        //MARK: Title Label
        labelView = UILabel()
        let boldFont = UIFont.boldSystemFont(ofSize: 20)
        labelView.text = String(localized: "totalTravelTime") + (String(describing: totaltime))
        labelView.font = boldFont
        headerView.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        //MARK: Cancel Button
        cancelButton =  UIButton()
        cancelButton.setImage(UIImage(systemName: "multiply.circle.fill")?.resized(to: CGSize(width: 25,height: 25)).withTintColor(.systemBlue), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelRoute), for: .touchUpInside)
        headerView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        //MARK: Constraints
        NSLayoutConstraint.activate([labelView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 5), labelView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor), cancelButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20), cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)])

        return headerView
    }
    
    //MARK: Header Height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    //MARK: Cancel Route Button Action
    @objc func cancelRoute(){
        parentvc.cancelRoute()
    }
}
