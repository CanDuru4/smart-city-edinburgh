//
//  ViewController.swift
//  Asis
//
//  Created by Can Duru on 1.08.2022.
//

//MARK: Import
import UIKit
import SideMenu
import MapKit
import CoreLocation
import FloatingPanel

//MARK: Routes Array
struct Routes {
    var departureID: Int
    var departureName: String
    var departureTime: String
    var departureCoordinates: MKPlacemark
    var destinationID: Int
    var destinationName: String
    var destinationTime: String
    var destinationCoordinates: MKPlacemark
    var routetime: Int
    var walkingfromcurrent: Double
    var walkingtodestination: Double
    var services: String
}

class HomeViewController: UIViewController, UISearchBarDelegate, FloatingPanelControllerDelegate {

//MARK: Set Up
    
    //MARK: Map Setup
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    //MARK: HowToGo Setup
    lazy var searchController: UISearchController = {
        let search = UISearchController()
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = String(localized: "howToGoSearchBar")
        search.searchBar.sizeToFit()
        search.searchBar.searchBarStyle = .prominent        
        search.searchBar.delegate = self
        return search
    }()
    let floatingpanelview = FloatingPanelTableViewController()
    var suitableStopsAroundDestinationArray: [Stop] = []
    var suitableStopsAroundCurentLocationArray: [Stop] = []
    var startingpoint: MKPlacemark!
    var finishingpoint: MKPlacemark!
    var routesArray: [Routes] = [] {
        didSet{
            //MARK: Floating Panel Cell Content
            for times in routesArray {
                if times.walkingtodestination != 0 && times.walkingfromcurrent != 0 {
                    map.deselectAnnotation(selectedItemAnnotation, animated: true)
                    floatingPanel.show()
                    let totalduration = Int(times.walkingtodestination + times.walkingfromcurrent + Double(times.routetime))
                    if totalduration > 60 {
                        let hour = Int(totalduration / 60)
                        let minute = totalduration - (hour*60)
                        floatingpanelview.walkingToDestinationTime = Int(times.walkingtodestination)
                        floatingpanelview.walkingFromCurrentTime = Int(times.walkingfromcurrent)
                        floatingpanelview.routeTime = Int(times.routetime)
                        floatingpanelview.totaltime = ("\(hour) hour and \(minute) minutes")
                        floatingpanelview.service = times.services
                    } else{
                        floatingpanelview.walkingToDestinationTime = Int(times.walkingtodestination)
                        floatingpanelview.walkingFromCurrentTime = Int(times.walkingfromcurrent)
                        floatingpanelview.routeTime = Int(times.routetime)
                        floatingpanelview.totaltime = String(totalduration)
                        floatingpanelview.service = times.services
                    }
                }
            }
        }
    }

        //MARK: Get Route Details
    var times:[Trip] = [] {
        didSet {
            getRouteDetails()
            getStartandFinishCoordinates()
            getWalkingTime()
        }
    }
    
    //MARK: Table Setup
    lazy var howToGoSearchTable: UITableView = {
        let tb = UITableView()
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.delegate = self
        tb.dataSource = self
        tb.register(HowToGoSearchTableCellSetup.self, forCellReuseIdentifier: HowToGoSearchTableCellSetup.identifer)
        return tb
    }()
    var matchingItems: [MKMapItem] = [] {
        didSet{
            howToGoSearchTable.reloadData()
        }
    }
    
    //MARK: Data Setup
    var timer = Timer()
    var busses:[Vehicle] = [] {
        didSet{
            //MARK: Annotate Bus Locations
            for BusAnnotation in self.map.annotations {
                if let BusAnnotation = BusAnnotation as? CustomPointAnnotation, BusAnnotation.customidentifier == "busAnnotation" {
                    self.map.removeAnnotation(BusAnnotation)
                }
            }
            busLocations()
        }
    }
    var stops:[Stop] = []
    
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

    
    
//MARK: Load
    var floatingPanel :FloatingPanelController!
    override func viewDidLoad() {
        super.viewDidLoad() 
        view.backgroundColor = .systemBackground
        howToGoSearchTable.isHidden = true

        //MARK: Map Load
        view.addSubview(map)
        setMapLayout()
        mapLocation()
        setButton()
        map.delegate = self
        
        //MARK: Bus Locations to Map Load
        BusData()
        BusDataRepeat()
        
        //MARK: Bus Stops Data Load
        BusStopsData()
        
        //MARK: Side Menu Load
        navigationItem.setLeftBarButton(menuBarButtonItem, animated: false)
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        
        //MARK: Search Bar Load
        navigationItem.searchController = searchController
        
        //MARK: HowToGo Search Table Load
        view.addSubview(howToGoSearchTable)
        setTableLayout()
        
        //MARK: Floating Panel Load
        floatingPanel = FloatingPanelController()
        floatingPanel.delegate = self
        let source = FloatingPanelTableViewController()
        source.parentvc = self
        floatingPanel.set(contentViewController: source)
        floatingPanel.track(scrollView: source.tableView)
        floatingPanel.addPanel(toParent: self)
        floatingPanel.hide()
    }

    
    
//MARK: Table Constraints
    func setTableLayout(){
        howToGoSearchTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([howToGoSearchTable.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 1),
                                     howToGoSearchTable.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                                     howToGoSearchTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                                     howToGoSearchTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)])
    }
    
    
    
//MARK: Search Bar
    func isSearchBarEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if isSearchBarEmpty() {
            howToGoSearchTable.isHidden = true
            zoomInButton.isHidden = false
            zoomOutButton.isHidden = false
            currentlocationButton.isHidden = false
            map.isHidden = false
        } else{
            //MARK: HowToGo Search
            howToGoSearchTable.isHidden = false
            zoomInButton.isHidden = true
            zoomOutButton.isHidden = true
            currentlocationButton.isHidden = true
            map.isHidden = true
            findLocations(with: searchText)
            howToGoSearchTable.reloadData()
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        howToGoSearchTable.isHidden = true
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        currentlocationButton.isHidden = false
        map.isHidden = false
    }

    

//MARK: HowToGo
    
    
    
    //MARK: Address Seaarch
    func findLocations(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
    
        search.start { response, _ in
            guard response != nil else {
                return
            }
            self.matchingItems = response!.mapItems
        }
    }
    
    //MARK: Set Address
    func parseAddress(selectedItem:MKPlacemark) -> String {
        let firstSpace = (selectedItem.subThoroughfare != nil &&
                            selectedItem.thoroughfare != nil) ? " " : ""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) &&
                    (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil &&
                            selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            selectedItem.thoroughfare ?? "",
            comma,
            selectedItem.locality ?? "",
            secondSpace,
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
    
    //MARK: Find Close Stops
    var selectedItemCoordination = CLLocationCoordinate2D()
    @objc func makeRoad(){
        let busstopsCount = stops.count
        var userlatitude: Double = 0
        var userlongitude: Double = 0

        LocationManager.shared.getUserLocation { [weak self] location in
            guard let self = self else {
                return
            }
            userlatitude = location.coordinate.latitude
            userlongitude = location.coordinate.longitude
            
            //MARK: 500 Metre
            for i in (0..<busstopsCount){
                if (((self.selectedItemCoordination.latitude)-0.005) < (self.stops[i].latitude!) &&
                    (self.stops[i].latitude!) < ((self.selectedItemCoordination.latitude)+0.005) &&
                    ((self.selectedItemCoordination.longitude)-0.005) < (self.stops[i].longitude!) &&
                    (self.stops[i].longitude!) < ((self.selectedItemCoordination.longitude)+0.005)) {
                    self.suitableStopsAroundDestinationArray.append(self.stops[i])
                }

                if (((userlatitude)-0.005) < (self.stops[i].latitude!) &&
                    (self.stops[i].latitude!) < ((userlatitude)+0.005) &&
                    ((userlongitude)-0.005) < (self.stops[i].longitude!) &&
                    (self.stops[i].longitude!) < ((userlongitude)+0.005)){
                    self.suitableStopsAroundCurentLocationArray.append(self.stops[i])
                }
            }
            
            //MARK: APİI Decoder
            let timestamp = Date().timeIntervalSince1970
            self.timeData(timestring: "stoptostop-timetable/?start_stop_id=36236495&finish_stop_id=36232896&date=\(timestamp)&duration=\(15)")
//            for start in (0..<self.suitableStopsAroundCurentLocationArray.count) {
//                for destination in (0..<self.suitableStopsAroundDestinationArray.count) {
//                    let timestamp = Date().timeIntervalSince1970
//                    self.timeData(timestring: "stoptostop-timetable/?start_stop_id=\(start)&finish_stop_id=\(destination)&date=\(timestamp)&duration=\(15)")
//                }
//            }
        }
    }

    //MARK: Get Route Details
    func getRouteDetails() {
        for times in (0..<self.times.count) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT+00:00")
            let departure = self.times[times].departures[0].time
            let destination = self.times[times].departures[self.times[times].departures.count-1].time
            let departuredate = dateFormatter.date(from: departure)
            let destinationdate =  dateFormatter.date(from: destination)
            let diffSeconds = destinationdate!.timeIntervalSinceReferenceDate - departuredate!.timeIntervalSinceReferenceDate
            let diffMinutes = diffSeconds / 60
            routesArray.append(Routes(departureID: self.times[times].departures[0].stopID,
                                      departureName: self.times[times].departures[0].name,
                                      departureTime: self.times[times].departures[0].time,
                                      departureCoordinates: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
                                      destinationID: self.times[times].departures[self.times[times].departures.count-1].stopID,
                                      destinationName: self.times[times].departures[self.times[times].departures.count-1].name,
                                      destinationTime: self.times[times].departures[self.times[times].departures.count-1].time,
                                      destinationCoordinates: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
                                      routetime: Int(diffMinutes),
                                      walkingfromcurrent: 0,
                                      walkingtodestination: 0,
                                      services: self.times[times].serviceName))
        }
    }

    //MARK: Get Start and Finish Stop Coordinates
    func getStartandFinishCoordinates(){
        for stop in stops {
            for routes in (0..<routesArray.count) {
                if stop.stopID == routesArray[routes].departureID{
                    routesArray[routes].departureCoordinates = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: stop.latitude!, longitude: stop.longitude!), addressDictionary: nil)
                }
                if stop.stopID == routesArray[routes].destinationID{
                    routesArray[routes].destinationCoordinates = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: stop.latitude!, longitude: stop.longitude!), addressDictionary: nil)
                }
            }
        }
    }
    
    //MARK: Get Walking Time
    func getWalkingTime(){
        LocationManager.shared.getUserLocation { [weak self] location in
            guard let self = self else {
                return
            }
            for walkings in (0..<self.routesArray.count) {
                var currenttostart: Double = 0
                var finishtodestination: Double = 0
                let request = MKDirections.Request()
                let secondrequest = MKDirections.Request()
            
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), addressDictionary: nil))
                request.destination = MKMapItem(placemark: self.routesArray[walkings].departureCoordinates)
                request.requestsAlternateRoutes = true
                request.transportType = .walking
                
                secondrequest.source = MKMapItem(placemark: self.routesArray[walkings].destinationCoordinates)
                secondrequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.selectedItemCoordination))
                secondrequest.requestsAlternateRoutes = true
                secondrequest.transportType = .walking
                
                let directionsfromcurrent = MKDirections(request: request)
                directionsfromcurrent.calculate {(response, error) -> Void in
                    guard let response = response else {
                       if let error = error {
                           print("Error: \(error)")
                       }
                       return
                    }
                    if response.routes.count > 0 {
                        let route = response.routes[0]
                        currenttostart = (route.expectedTravelTime / 60)
                        self.routesArray[walkings].walkingfromcurrent = currenttostart
                    }
                }
                
                let directionstodestination = MKDirections(request: secondrequest)
                directionstodestination.calculate {(response, error) -> Void in
                    guard let response = response else {
                       if let error = error {
                           print("Error: \(error)")
                       }
                       return
                    }
                    if response.routes.count > 0 {
                        let route = response.routes[0]
                        finishtodestination = (route.expectedTravelTime / 60)
                        self.routesArray[walkings].walkingtodestination = finishtodestination
                    }
                }
            }
        }
    }
    
    //MARK: Cancel Route Button
    func cancelRoute(){
        for selectedItemAnnotation in self.map.annotations {
            if let selectedItemAnnotation = selectedItemAnnotation as? CustomPointAnnotation, selectedItemAnnotation.customidentifier == "howToGoAnnotation" {
                self.map.removeAnnotation(selectedItemAnnotation)
            }
        }
        searchController.isActive = false
        floatingPanel.hide()
    }
    
    //MARK: Floating Panel Move Limit
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        if vc.isAttracting == false {
            let loc = vc.surfaceLocation
            let minY = vc.surfaceLocation(for: .half).y
            let maxY = vc.surfaceLocation(for: .tip).y+10
            vc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
        }
    }

    
    
    
//MARK: Map
    
    
    
    //MARK: Map Location
    func mapLocation(){
        LocationManager.shared.getUserLocation { [weak self] location in DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
                strongSelf.map.showsUserLocation = true
            }
        }
    }
    
    //MARK: Map Layout
    func setMapLayout(){
        map.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([map.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), map.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), map.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor), map.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)])
    }
    
  
    
let currentlocationButton = UIButton(type: .custom)
let zoomOutButton = UIButton(type: .custom)
let zoomInButton = UIButton(type: .custom)
//MARK: Buttons Setup
    func setButton(){
        
        
        //MARK: Current Location Button
        currentlocationButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        currentlocationButton.setImage(UIImage(systemName: "location.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        currentlocationButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        view.addSubview(currentlocationButton)
        
        currentlocationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([currentlocationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), currentlocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60), currentlocationButton.widthAnchor.constraint(equalToConstant: 50), currentlocationButton.heightAnchor.constraint(equalToConstant: 50)])
        currentlocationButton.layer.cornerRadius = 25
        currentlocationButton.layer.masksToBounds = true
        
        //MARK: Zoom Out Button
        zoomOutButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        zoomOutButton.setImage(UIImage(systemName: "minus.square.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        view.addSubview(zoomOutButton)
        
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([zoomOutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), zoomOutButton.bottomAnchor.constraint(equalTo: currentlocationButton.topAnchor, constant: -20), zoomOutButton.widthAnchor.constraint(equalToConstant: 50), zoomOutButton.heightAnchor.constraint(equalToConstant: 50)])
        zoomOutButton.layer.cornerRadius = 10
        zoomOutButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner] // Top right corner, Top left corner respectively
        
        //MARK: Zoom In Button
        zoomInButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        zoomInButton.setImage(UIImage(systemName: "plus.square.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)
        
        zoomInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([zoomInButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), zoomInButton.bottomAnchor.constraint(equalTo: zoomOutButton.topAnchor), zoomInButton.widthAnchor.constraint(equalToConstant: 50), zoomInButton.heightAnchor.constraint(equalToConstant: 50)])
        zoomInButton.layer.cornerRadius = 10
        zoomInButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
    }
    
    //MARK: Current Location Button Action
    @objc func pressed() {
        LocationManager.shared.getUserLocation { [weak self] location in DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate, span:MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
            }
        }
    }
    
    //MARK: Zoom In Button Action
    @objc func zoomIn() {
        zoomMap(byFactor: 0.5)
    }
    
    //MARK: Zoom Out Button Action
    @objc func zoomOut() {
        zoomMap(byFactor: 2)
    }
    
    
    
//MARK: Bus Location Annotation
    var BusAnnotation: CustomPointAnnotation!
    var BusAnnotationView:MKPinAnnotationView!
    //MARK: Check and mark bus locations in every 15 second
    @objc func busLocations(){
        let busCount = busses.count
        for i in (0..<busCount){
            let coordinate = CLLocationCoordinate2DMake(busses[i].latitude, busses[i].longitude)
            let BusAnnotation = CustomPointAnnotation()
            BusAnnotation.coordinate = coordinate
            BusAnnotation.title = busses[i].serviceName
            BusAnnotation.subtitle = busses[i].destination
            BusAnnotation.customidentifier = "busAnnotation"
            map.addAnnotation(BusAnnotation)
        }
    }
    
    

//MARK: Zoom in and Out Function
    func zoomMap(byFactor delta: Double) {
        var region: MKCoordinateRegion = self.map.region
        var span: MKCoordinateSpan = map.region.span
        span.latitudeDelta *= delta
        span.longitudeDelta *= delta
        region.span = span
        map.setRegion(region, animated: true)
    }
    
    
    
//MARK: Bus Data
    func BusDataRepeat(){
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { _ in
            self.BusData()
        })
    }
    @objc func BusData(){
        let basedata = GetBaseData()
        basedata.busCompletionHandler { busses, error, message in
            self.busses = busses ?? []
        }
        basedata.getBusBaseData(endPoint: "vehicle_locations")
    }
    
    
    
//MARK: Bus Stops Data
    func BusStopsData(){
        let basedata = GetBaseData()
        basedata.completionHandler { stops, error, message in
            
            self.stops = stops ?? []
        }
        basedata.getStopsBaseData(endPoint: "stops")
    }
    
    
    
//MARK: Time Data
    func timeData(timestring: String){
        let basedata = GetBaseData()
        basedata.timeCompletionHandler { times, status, message in
            self.times = times ?? []
        }
        basedata.getTimeBaseData(endPoint: timestring)
    }
    
    let selectedItemAnnotation = CustomPointAnnotation()
}



//MARK: Image Resize Extension
extension UIImage {
    public func resized(to target: CGSize) -> UIImage {
        let ratio = min(
            target.height / size.height, target.width / size.width
        )
        let new = CGSize(
            width: size.width * ratio, height: size.height * ratio
        )
        let renderer = UIGraphicsImageRenderer(size: new)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: new))
        }
    }
}



//MARK: Pin With Image Extension
extension HomeViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?  {
        
        guard let annotation = annotation as? CustomPointAnnotation else {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "reuseIdentifier")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "reuseIdentifier")
            annotationView?.canShowCallout = true

        } else {
            annotationView?.annotation = annotation
        }

        //MARK: Bus Annotation
        if annotation.customidentifier == "busAnnotation" {
            annotationView?.image = UIImage(systemName: "bus")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue).resized(to: CGSize(width: 15, height: 15))
        }
        //MARK: Location Annotation
        if annotation.customidentifier == "howToGoAnnotation" {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            let rightButton = UIButton(type: .contactAdd)
            rightButton.setImage(UIImage(named: "customAnnotationButton"), for: .normal)
            rightButton.tag = annotation.hash
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.rightCalloutAccessoryView = rightButton
            rightButton.addTarget(self, action: #selector(makeRoad), for: .touchUpInside)
            return pinView
        }

        return annotationView
    }
}



//MARK: Adress Search Tableview
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Row Number
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    //MARK: Cell Content
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HowToGoSearchTableCellSetup.identifer, for: indexPath) as! HowToGoSearchTableCellSetup
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.titleLabel?.text = selectedItem.name
        cell.detailLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    //MARK: Cell Height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    //MARK: Select Function
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        //MARK: Hidden
        howToGoSearchTable.isHidden = true
        zoomInButton.isHidden = false
        zoomOutButton.isHidden = false
        currentlocationButton.isHidden = false
        map.isHidden = false
        searchController.searchBar.text = nil
        searchController.searchBar.endEditing(true)
        
        //MARK: Selected Location Coordinates and Annotation
        selectedItemCoordination = matchingItems[indexPath.row].placemark.coordinate
        let selectedItemName = matchingItems[indexPath.row].placemark.name
        let selectedItemSubtitle = matchingItems[indexPath.row].placemark.compactAddress
        for selectedItemAnnotation in self.map.annotations {
            if let selectedItemAnnotation = selectedItemAnnotation as? CustomPointAnnotation, selectedItemAnnotation.customidentifier == "howToGoAnnotation" {
                self.map.removeAnnotation(selectedItemAnnotation)
            }
        }
        selectedItemAnnotation.coordinate = selectedItemCoordination
        selectedItemAnnotation.title = selectedItemName
        selectedItemAnnotation.subtitle = selectedItemSubtitle
        selectedItemAnnotation.customidentifier = "howToGoAnnotation"
        map.addAnnotation(selectedItemAnnotation)
        map.selectAnnotation(selectedItemAnnotation, animated: true)
    }
}
