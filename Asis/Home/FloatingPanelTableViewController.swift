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
    var walkingFromCurrentTime: Int!
    var walkingToDestinationTime: Int!
    var totaltime: String!
    var departuretime: String!
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
            cell.detailLabel_howlong.text = String(localized: "walkingToStopTime") + (String(walkingFromCurrentTime ?? 0) + String(localized: "minutes"))
            cell.detailLabel_services.text = ""
            cell.detailLabel_departuretime.text = ""
            cell.imagePlace.image = UIImage(systemName: "figure.walk")
        }
        if indexPath == [0, 1] {
            cell.titleLabel.text = String(localized: "transportation")
            cell.detailLabel_howlong.text = String(localized: "transportationTime") + (String(routeTime ?? 0) + String(localized: "minutes"))
            cell.detailLabel_services.text = String(localized: "transportationServices") + (String(service ?? "0"))
            cell.detailLabel_departuretime.text = String(localized: "departure") + (String(departuretime ?? "0"))
            cell.imagePlace.image = UIImage(systemName: "bus.fill")
        }
        if indexPath == [0, 2] {
            cell.titleLabel.text = String(localized: "walkingToDestination")
            cell.detailLabel_howlong.text = String(localized: "walkingToDestinationTime") + (String(walkingToDestinationTime ?? 0) + String(localized: "minutes"))
            cell.detailLabel_services.text = ""
            cell.detailLabel_departuretime.text = ""
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
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        
        //MARK: Title Label
        labelView = UILabel()
        let boldFont = UIFont.boldSystemFont(ofSize: 18)
        labelView.text = String(localized: "totalTravelTime") + (String(totaltime ?? "0"))
        labelView.numberOfLines = -1
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
        NSLayoutConstraint.activate([labelView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 5), labelView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor), cancelButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20), cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor), cancelButton.widthAnchor.constraint(equalToConstant: 25), labelView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -5)])

        return headerView
    }
    
    //MARK: Header Height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    //MARK: Cancel Route Button Action
    @objc func cancelRoute(){
        parentvc.cancelRoute()
    }
}
