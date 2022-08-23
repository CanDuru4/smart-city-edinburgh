//
//  BusStopsViewController.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

//MARK: Import
import UIKit
import SideMenu
import CoreLocation
import MapKit

//MARK: Yapılacaklar: Sadece üzerine basınca adresi çekecek, internet

class BusStopsViewController: UIViewController, UISearchBarDelegate {

    
//MARK: Set Up
    
    
    
    //MARK: Table Setup
    lazy var BusStopsTable: UITableView = {
        let tb = UITableView()
        tb.delegate = self
        tb.dataSource = self
        tb.register(BusStopTableViewCellSetup.self, forCellReuseIdentifier: BusStopTableViewCellSetup.identifer)
        return tb
    }()
    
    var selectedCellIndexPath: IndexPath?
    let selectedCellHeight: CGFloat = 350
    let unselectedCellHeight: CGFloat = 100

    //MARK: Search Bar Setup
    lazy var searchController: UISearchController = {
        let search = UISearchController()
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = String(localized: "searchBar")
        search.searchBar.sizeToFit()
        search.searchBar.searchBarStyle = .prominent
        
        search.searchBar.delegate = self
        
        return search
    }()

    //MARK: Data Setup
    var stops:[Stop] = [] {
        didSet{
            //MARK: Table Reload
            BusStopsTable.reloadData()
            filteredStops = stops
        }
    }
    
    //MARK: Filtered Data Setup
    var filteredStops: [Stop] = []{
        didSet{
            BusStopsTable.reloadData()
        }
    }
    
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
    
    //MARK: Map Setup
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
   
    
    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Internet Connection True
        if Network.shared.isConnnected() {
            
            
            //MARK: Table Load
            view.addSubview(BusStopsTable)
            setTableLayout()
  
            //MARK: Bus Stops Data Load
            BusStopsData()
            
            //MARK: Side Menu Load
            navigationItem.setLeftBarButton(menuBarButtonItem, animated: false)
            menu = SideMenuNavigationController(rootViewController: MenuListController())
            menu?.leftSide = true
            menu?.setNavigationBarHidden(true, animated: false)
            
            //MARK: Search Bar Load
            navigationItem.searchController = searchController
            
            
        //MARK: Internet Connection False
        } else{
            let alert = UIAlertController(title: String(localized: "internetConnection"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    

//MARK: Table
    func setTableLayout(){
        BusStopsTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([BusStopsTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), BusStopsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), BusStopsTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 1), BusStopsTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)])
    }
    
    
    
//MARK: Search Bar
    func isSearchBarEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredStops = stops
        if isSearchBarEmpty() {

        } else{
            filteredStops = filteredStops.filter { ($0.name?.lowercased().contains(searchText.lowercased()))! }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filteredStops = stops
    }
    
    

//MARK: Adressline
    func getAddressFromLocation(latitude_1: Double, longitude_2: Double, completion: @escaping (String) -> ()) {
        
        let location = CLLocation(latitude: latitude_1, longitude: longitude_2)
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            completion(placemarks?.first?.compactAddress ?? "")
        }
        completion("")
    }
    
    
    
//MARK: Bus Stops Data
    func BusStopsData(){
        let basedata = GetBaseData()
        basedata.completionHandler { stops, error, message in
            self.stops = stops ?? []
        }
        basedata.getStopsBaseData(endPoint: "stops")
    }
}



//MARK: TableView Extension
extension BusStopsViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: Row Number
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchBarEmpty(){
            return stops.count
        } else{
            return filteredStops.count
        }
    }

    
    //MARK: Cell Content
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BusStopTableViewCellSetup.identifer, for: indexPath) as! BusStopTableViewCellSetup
        cell.busstoptableStop = stops[indexPath.row]
        
        
        //MARK: Search Bar Empty TableView
        if isSearchBarEmpty(){
            cell.map.removeAnnotations(cell.map.annotations)
            cell.titleLabel.text = stops[indexPath.row].name
            
            //MARK: Service
            var servicelist = ""
            var flag = false
            for item in (stops[indexPath.row].services) {
                if flag {
                    servicelist = servicelist + ", " + item

                } else {
                    servicelist = servicelist + item
                    flag = true
                }
            }
            
            //MARK: Destination
            var destinationlist = ""
            var flag_2 = false
            for item in (stops[indexPath.row].destinations) {
                if flag_2 {
                    destinationlist = destinationlist + ", " + item

                } else {
                    destinationlist = destinationlist + item
                    flag_2 = true
                }
            }
            
            //MARK: Address Set
            let latitude = stops[indexPath.row].latitude
            let longitude = stops[indexPath.row].longitude
            if selectedCellIndexPath == indexPath {
                getAddressFromLocation(latitude_1: latitude!, longitude_2: longitude!) { addressText in
                    cell.detailLabel_adress.text = String(localized: "address") + addressText
                    cell.detailLabel_adress.attributedText = self.addBoldText(fullString: cell.detailLabel_adress.text! as NSString, boldPartOfString: String(localized: "address") as NSString)
                }
            }
            let coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
            let stopAnnotation = MKPointAnnotation()
            cell.map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: true)
            stopAnnotation.coordinate = coordinate
            stopAnnotation.title = stops[indexPath.row].name
            cell.map.addAnnotation(stopAnnotation)
            
            
            //MARK: Services, Destinations, and Image Set
            cell.detailLabel_services.text = ((String(localized: "service")) + servicelist)
            cell.detailLabel_destinations.text = ((String(localized: "destination")) + destinationlist)
            cell.detailLabel_destinations.attributedText = addBoldText(fullString: cell.detailLabel_destinations.text! as NSString, boldPartOfString: (String(localized: "destination")) as NSString)
            cell.detailLabel_services.attributedText = addBoldText(fullString: cell.detailLabel_services.text! as NSString, boldPartOfString: (String(localized: "service")) as NSString)
            cell.imagePlace.image = UIImage(systemName: "bus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            return cell
            
            
        //MARK: Search Bar not Empty TableView
        } else{
            cell.map.removeAnnotations(cell.map.annotations)
            cell.titleLabel.text = filteredStops[indexPath.row].name
            
            //MARK: Service
            var servicelist = ""
            var flag = false
            for item in (filteredStops[indexPath.row].services) {
                if flag {
                    servicelist = servicelist + ", " + item
                } else {
                    servicelist = servicelist + item
                    flag = true
                }
            }
            
            //MARK: Destination
            var destinationlist = ""
            var flag_2 = false
            for item in (filteredStops[indexPath.row].destinations) {
                if flag_2 {
                    destinationlist = destinationlist + ", " + item
                    
                } else {
                    destinationlist = destinationlist + item
                    flag_2 = true
                }
            }
            
            //MARK: Address Set
            let latitude_filter = filteredStops[indexPath.row].latitude
            let longitude_filter = filteredStops[indexPath.row].longitude
            
            if selectedCellIndexPath == indexPath {
                getAddressFromLocation(latitude_1: latitude_filter!, longitude_2: longitude_filter!) { addressText in
                    cell.detailLabel_adress.text = String(localized: "address") + addressText
                    cell.detailLabel_adress.attributedText = self.addBoldText(fullString: cell.detailLabel_adress.text! as NSString, boldPartOfString: String(localized: "address") as NSString)
                }
            }
            let coordinate = CLLocationCoordinate2DMake(latitude_filter!, longitude_filter!)
            let stopAnnotation = MKPointAnnotation()
            cell.map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: true)
            stopAnnotation.coordinate = coordinate
            stopAnnotation.title = filteredStops[indexPath.row].name
            cell.map.addAnnotation(stopAnnotation)
            
            //MARK: Services, Destinations, and Image Set
            cell.detailLabel_services.text = ((String(localized: "service")) + servicelist)
            cell.detailLabel_destinations.text = ((String(localized: "destination")) + destinationlist)
            cell.detailLabel_destinations.attributedText = addBoldText(fullString: cell.detailLabel_destinations.text! as NSString, boldPartOfString: (String(localized: "destination")) as NSString)
            cell.detailLabel_services.attributedText = addBoldText(fullString: cell.detailLabel_services.text! as NSString, boldPartOfString: (String(localized: "service")) as NSString)
            cell.imagePlace.image = UIImage(systemName: "bus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            return cell
        }
    }

    //MARK: Table Height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if selectedCellIndexPath == indexPath {
            return selectedCellHeight
        }
        return unselectedCellHeight
        
    }
    
    //MARK: Select Function
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCellIndexPath != nil && selectedCellIndexPath == indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            selectedCellIndexPath = nil
        } else {
            selectedCellIndexPath = indexPath
            tableView.reloadRows(at: [indexPath], with: .fade)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        }

        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    
//MARK: Bold Text Beginning
    func addBoldText(fullString: NSString, boldPartOfString: NSString) -> NSAttributedString {
        let nonBoldFontAttribute = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 16)]
        let boldFontAttribute = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 16)]
        let boldString = NSMutableAttributedString(string: fullString as String, attributes:nonBoldFontAttribute)
        boldString.addAttributes(boldFontAttribute, range: fullString.range(of: boldPartOfString as String))
        return boldString
    }
}



//MARK: Adress Extension
extension CLPlacemark {
    var compactAddress: String? {
        if let name = name {
            var result = name

            if let street = thoroughfare {
                result += ", \(street)"
            }
            if let city = locality {
                result += ", \(city)"
            }
            if let postalCode = postalCode {
                result += ", \(postalCode)"
            }
            if let country = country {
                result += ", \(country)"
            }
            return result
        }

        return nil
    }
}
