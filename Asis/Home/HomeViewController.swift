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
import Alamofire

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
    var totalwalk: Double
    var departureDate: Date
}

class HomeViewController: UIViewController, UISearchBarDelegate, FloatingPanelControllerDelegate {

//MARK: Set Up
    
    
    
    //MARK: Service Setup
    var servicesArray:[Service] = []
    var selectedServiceRouteCoordinates: [CLLocationCoordinate2D] = []
    var selectedServiceRouteStopIDs: [Int] = []
    var busname = ""

    //MARK: Loading View Setup
    let loadingVC = LoadingViewController()

    
    //MARK: Map Setup
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    //MARK: HowToGo Setup
    var timerForSelectedBus = Timer()
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
    var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routesArray: [Routes] = []
    private var routeSearchID = UUID()
    private var routeTimeout: DispatchWorkItem?
    private var walkingDirections: [MKDirections] = []
    private var timetableRequests: [GetBaseData] = []
    private var selectedService: String?
    private var localSearch: MKLocalSearch?
    private var busRequestInFlight = false
    private var busDataAvailable = false
    private var stopsDataAvailable = false
    private let transitStatus = UIButton(type: .system)

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
    
    //MARK: Bus Data Setup
    var timer = Timer()
    var busses: [Vehicle] = [] {
        didSet {
            let old = map.annotations.compactMap { $0 as? CustomPointAnnotation }.filter {
                $0.customidentifier == "busAnnotation" || $0.customidentifier == "selectedBusAnnotation"
            }
            map.removeAnnotations(old)
            if let selectedService { selectedBusLocation(selectedservice: selectedService) }
            else { busLocations() }
        }
    }

    //MARK: Stops Data Setup
    var stops:[Stop] = []
    
    //MARK: Side Menu Setup
    var menu: SideMenuNavigationController?
    lazy var menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.leading")?.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue), style: .plain, target: self, action: #selector(menuBarButtonItemTapped))
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

        //MARK: Service Load
        serviceDataCall()
        
        //MARK: Map Load
        view.addSubview(map)
        setMapLayout()
        mapLocation()
        setButton()
        cancelServiceButton.isHidden = true
        map.delegate = self
        
        
        //MARK: Bus Locations to Map Load
        BusData()
        BusDataRepeat()
        
        //MARK: Bus Stops Data Load
        BusStopsData()
        
        //MARK: Side Menu Load
        navigationItem.setLeftBarButton(menuBarButtonItem, animated: false)
        menuBarButtonItem.accessibilityIdentifier = "openMenuButton"
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
        floatingpanelview.parentvc = self
        floatingPanel.set(contentViewController: floatingpanelview)
        floatingPanel.track(scrollView: floatingpanelview.tableView)
        floatingPanel.addPanel(toParent: self)
        floatingPanel.hide()
        configureTransitStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(stopLiveUpdates), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeLiveUpdates), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BusData()
        BusDataRepeat()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopLiveUpdates()
        localSearch?.cancel()
    }

    @objc private func stopLiveUpdates() {
        timer.invalidate()
        timerForSelectedBus.invalidate()
        if routeTimeout != nil {
            cancelPendingRouteSearch()
            loadingVC.dismiss(animated: false)
            setRouteControls(hidden: false)
        }
    }

    @objc private func resumeLiveUpdates() {
        guard viewIfLoaded?.window != nil else { return }
        BusData()
        BusDataRepeat()
    }

    private func configureTransitStatus() {
        var statusConfiguration = UIButton.Configuration.plain()
        statusConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        transitStatus.configuration = statusConfiguration
        transitStatus.translatesAutoresizingMaskIntoConstraints = false
        transitStatus.titleLabel?.numberOfLines = 0
        transitStatus.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        transitStatus.titleLabel?.textAlignment = .center
        transitStatus.backgroundColor = .systemBackground
        transitStatus.layer.cornerRadius = 8
        transitStatus.accessibilityIdentifier = "transitStatus"
        transitStatus.addTarget(self, action: #selector(retryTransit), for: .touchUpInside)
        transitStatus.setTitle(String(localized: "loadingTransit"), for: .normal)
        view.addSubview(transitStatus)
        NSLayoutConstraint.activate([
            transitStatus.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            transitStatus.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transitStatus.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -80),
            transitStatus.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func updateTransitStatus() {
        transitStatus.isHidden = busDataAvailable && stopsDataAvailable
        transitStatus.setTitle(String(localized: "transitUnavailableRetry"), for: .normal)
    }

    @objc private func retryTransit() {
        transitStatus.setTitle(String(localized: "loadingTransit"), for: .normal)
        BusData()
        BusStopsData()
        serviceDataCall()
    }

    deinit {
        timer.invalidate()
        timerForSelectedBus.invalidate()
        NotificationCenter.default.removeObserver(self)
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
        localSearch?.cancel()
        matchingItems = []
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
        localSearch?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = map.region
        let search = MKLocalSearch(request: request)
        localSearch = search
        search.start { [weak self, weak search] response, _ in
            guard let self, self.localSearch === search,
                  self.searchController.searchBar.text == query else { return }
            self.matchingItems = response?.mapItems ?? []
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
    @objc func makeRoad() {
        cancelPendingRouteSearch()
        guard stopsDataAvailable, !stops.isEmpty else {
            showRouteError(String(localized: "transitUnavailable"))
            return
        }
        let requestID = routeSearchID
        routesArray = []
        routeCoordinates = []
        setRouteControls(hidden: true)
        loadingVC.modalPresentationStyle = .overCurrentContext
        present(loadingVC, animated: false)
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.routeSearchID == requestID else { return }
            self.finishRouteSearch(error: String(localized: "routeSearchTimedOut"))
        }
        routeTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: timeout)
        LocationManager.shared.getUserLocation(onError: { [weak self] _ in
            guard let self, self.routeSearchID == requestID else { return }
            self.finishRouteSearch(error: String(localized: "locationUnavailable"))
        }) { [weak self] location in
            guard let self, self.routeSearchID == requestID else { return }
            self.findJourneys(from: location, requestID: requestID)
        }
    }

    private func findJourneys(from location: CLLocation, requestID: UUID) {
        let radius = meter500check ? 100.0 : (meter1000check ? 250.0 : 400.0)
        let horizon = minute15check ? 15 : (minute30check ? 30 : 45)
        let reference = Date()
        let destination = CLLocation(latitude: selectedItemCoordination.latitude, longitude: selectedItemCoordination.longitude)
        suitableStopsAroundCurentLocationArray = stops.filter { stop in
            guard let latitude = stop.latitude, let longitude = stop.longitude, stop.hasValidCoordinate else { return false }
            return location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) <= radius
        }
        suitableStopsAroundDestinationArray = stops.filter { stop in
            guard let latitude = stop.latitude, let longitude = stop.longitude, stop.hasValidCoordinate else { return false }
            return destination.distance(from: CLLocation(latitude: latitude, longitude: longitude)) <= radius
        }
        guard !suitableStopsAroundCurentLocationArray.isEmpty, !suitableStopsAroundDestinationArray.isEmpty else {
            finishRouteSearch(error: String(localized: "routeTimeError"))
            return
        }
        let group = DispatchGroup()
        var journeys: [Trip] = []
        var failed = false
        for start in suitableStopsAroundCurentLocationArray {
            for finish in suitableStopsAroundDestinationArray where start.stopID != finish.stopID {
                group.enter()
                let request = GetBaseData()
                timetableRequests.append(request)
                request.timeCompletionHandler { [weak self] trips, success, _ in
                    defer { group.leave() }
                    guard let self, self.routeSearchID == requestID else { return }
                    failed = failed || !success
                    journeys.append(contentsOf: trips ?? [])
                }
                request.getTimeBaseData(endPoint: "stoptostop-timetable/?start_stop_id=\(start.stopID)&finish_stop_id=\(finish.stopID)&date=\(Int(reference.timeIntervalSince1970))&duration=\(horizon)")
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self, self.routeSearchID == requestID else { return }
            guard !failed else {
                self.finishRouteSearch(error: String(localized: "transitUnavailable"))
                return
            }
            self.routesArray = journeys.compactMap { trip in
                guard let first = trip.departures.first, let last = trip.departures.last,
                      first.stopID != last.stopID,
                      let duration = TransitTime.duration(from: first.time, to: last.time),
                      let departure = TransitTime.departureDate(first.time, after: reference, within: horizon),
                      let start = self.stops.first(where: { $0.stopID == first.stopID && $0.hasValidCoordinate }),
                      let finish = self.stops.first(where: { $0.stopID == last.stopID && $0.hasValidCoordinate }),
                      let startLat = start.latitude, let startLon = start.longitude,
                      let finishLat = finish.latitude, let finishLon = finish.longitude else { return nil }
                return Routes(departureID: first.stopID, departureName: first.name, departureTime: first.time,
                    departureCoordinates: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: startLat, longitude: startLon)),
                    destinationID: last.stopID, destinationName: last.name, destinationTime: last.time,
                    destinationCoordinates: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: finishLat, longitude: finishLon)),
                    routetime: duration, walkingfromcurrent: .infinity, walkingtodestination: .infinity,
                    services: trip.serviceName, totalwalk: .infinity, departureDate: departure)
            }
            self.measureWalking(from: location, index: 0, requestID: requestID)
        }
    }

    private func measureWalking(from location: CLLocation, index: Int, requestID: UUID) {
        guard routeSearchID == requestID else { return }
        guard routesArray.indices.contains(index) else {
            chooseRoute(from: location)
            return
        }
        let route = routesArray[index]
        walkingTime(from: location.coordinate, to: route.departureCoordinates.coordinate) { [weak self] first in
            guard let self, self.routeSearchID == requestID else { return }
            self.walkingTime(from: route.destinationCoordinates.coordinate, to: self.selectedItemCoordination) { [weak self] second in
                guard let self, self.routeSearchID == requestID else { return }
                self.routesArray[index].walkingfromcurrent = first
                self.routesArray[index].walkingtodestination = second
                self.routesArray[index].totalwalk = first + second
                self.measureWalking(from: location, index: index + 1, requestID: requestID)
            }
        }
    }

    private func walkingTime(from start: CLLocationCoordinate2D, to finish: CLLocationCoordinate2D, completion: @escaping (Double) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: finish))
        request.transportType = .walking
        let directions = MKDirections(request: request)
        walkingDirections.append(directions)
        directions.calculate { response, _ in
            let minutes = response?.routes.map { $0.expectedTravelTime / 60 }.min() ?? .infinity
            completion(minutes)
        }
    }

    private func chooseRoute(from location: CLLocation) {
        let now = Date()
        guard let route = routesArray.filter({
            $0.totalwalk.isFinite && $0.departureDate.timeIntervalSince(now) >= $0.walkingfromcurrent * 60
        }).min(by: { $0.totalwalk < $1.totalwalk }) else {
            finishRouteSearch(error: String(localized: "routeTimeError"))
            return
        }
        routeCoordinates = []
        for service in servicesArray where service.name == route.services {
            for variant in service.routes {
                guard let start = variant.points.firstIndex(where: { Int($0.stopID ?? "") == route.departureID }),
                      let finish = variant.points.indices.first(where: { $0 > start && Int(variant.points[$0].stopID ?? "") == route.destinationID }) else { continue }
                routeCoordinates = variant.points[start...finish].map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }.filter(CLLocationCoordinate2DIsValid)
                break
            }
            if !routeCoordinates.isEmpty { break }
        }
        if routeCoordinates.count < 2 {
            routeCoordinates = [route.departureCoordinates.coordinate, route.destinationCoordinates.coordinate]
        }
        map.removeOverlays(map.overlays)
        polyLines(currentLocationLatitude: location.coordinate.latitude, currentLocationLongitude: location.coordinate.longitude,
                  startStopLatitude: route.departureCoordinates.coordinate.latitude, startStopLongitude: route.departureCoordinates.coordinate.longitude,
                  finalStopLatitude: route.destinationCoordinates.coordinate.latitude, finalStopLongitude: route.destinationCoordinates.coordinate.longitude,
                  busRouteCoordinates: routeCoordinates, destinationLatitude: selectedItemCoordination.latitude,
                  destinationLongitude: selectedItemCoordination.longitude, polymapView: map)
        floatingpanelview.walkingFromCurrentTime = Int(ceil(route.walkingfromcurrent))
        floatingpanelview.walkingToDestinationTime = Int(ceil(route.walkingtodestination))
        floatingpanelview.routeTime = route.routetime
        let total = Int(ceil(route.departureDate.timeIntervalSince(now) / 60)) + route.routetime + Int(ceil(route.walkingtodestination))
        floatingpanelview.totaltime = String(total) + String(localized: "minutes")
        floatingpanelview.departuretime = route.departureTime
        floatingpanelview.service = route.services
        selectedBusDataRepeat(selectedservice: route.services)
        finishRouteSearch(error: nil)
    }

    private func setRouteControls(hidden: Bool) {
        [minutesFor15Button, minutesFor30Button, minutesFor45Button, metersFor500Button, metersFor1000Button, metersFor1500Button].forEach { $0.isHidden = hidden }
    }

    private func finishRouteSearch(error: String?) {
        cancelPendingRouteSearch()
        loadingVC.dismiss(animated: false) { [weak self] in
            guard let self else { return }
            if let error {
                self.setRouteControls(hidden: false)
                self.showRouteError(error)
            } else {
                self.floatingPanel.show()
            }
        }
    }

    private func cancelPendingRouteSearch() {
        routeSearchID = UUID()
        routeTimeout?.cancel()
        routeTimeout = nil
        walkingDirections.forEach { $0.cancel() }
        walkingDirections.removeAll()
        timetableRequests.forEach { $0.cancel() }
        timetableRequests.removeAll()
    }

    private func showRouteError(_ message: String) {
        guard presentedViewController == nil, viewIfLoaded?.window != nil else { return }
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "openInMaps"), style: .default) { [weak self] _ in
            guard let self else { return }
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: self.selectedItemCoordination))
            destination.name = self.selectedItemAnnotation.title
            destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
        })
        present(alert, animated: true)
    }

    //MARK: Cancel Route Button
    func cancelRoute(){
        cancelPendingRouteSearch()
        selectedService = nil
        timerForSelectedBus.invalidate()
        
        for selectedItemAnnotation in self.map.annotations {
            if let selectedItemAnnotation = selectedItemAnnotation as? CustomPointAnnotation, selectedItemAnnotation.customidentifier == "howToGoAnnotation" {
                self.map.removeAnnotation(selectedItemAnnotation)
            }
        }
        for BusAnnotation in self.map.annotations {
            if let BusAnnotation = BusAnnotation as? CustomPointAnnotation, BusAnnotation.customidentifier == "selectedBusAnnotation" {
                self.map.removeAnnotation(BusAnnotation)
            }
        }
        minutesFor15Button.isHidden = false
        minutesFor30Button.isHidden = false
        minutesFor45Button.isHidden = false
        metersFor500Button.isHidden = false
        metersFor1000Button.isHidden = false
        metersFor1500Button.isHidden = false
        minute15()
        meter500()
        pressed()
        self.map.removeOverlays(self.map.overlays)
        
        BusData()
        BusDataRepeat()
        searchController.isActive = true
        searchController.isActive = false
        floatingPanel.hide()
    }
    
    //MARK: Draw Polyline
    var toFirst: MKPolyline?
    var toFinal: MKPolyline?
    var toDestination: MKPolyline?
    func polyLines(currentLocationLatitude: Double, currentLocationLongitude: Double, startStopLatitude: Double, startStopLongitude: Double, finalStopLatitude: Double, finalStopLongitude: Double, busRouteCoordinates: [CLLocationCoordinate2D], destinationLatitude: Double, destinationLongitude: Double, polymapView: MKMapView){
        let current = CLLocationCoordinate2DMake(currentLocationLatitude, currentLocationLongitude);
        let start = CLLocationCoordinate2DMake(startStopLatitude, startStopLongitude);
        let final = CLLocationCoordinate2DMake(finalStopLatitude, finalStopLongitude);
        let destination = CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude);
        
        let starttostartstop: [CLLocationCoordinate2D]
        starttostartstop = [current, start]
        let finalstoptodestination: [CLLocationCoordinate2D]
        finalstoptodestination = [final, destination]
        
        let polyline1 = MKPolyline(coordinates: starttostartstop, count: starttostartstop.count)
        let polyline2 = MKPolyline(coordinates: busRouteCoordinates, count: busRouteCoordinates.count)
        let polyline3 = MKPolyline(coordinates: finalstoptodestination, count: finalstoptodestination.count)
        toFirst = polyline1
        toFinal = polyline2
        toDestination = polyline3
        polymapView.addOverlay(polyline1)
        polymapView.addOverlay(polyline2)
        polymapView.addOverlay(polyline3)
    }
    
    //MARK: Selected Bus Service Annotation
    func selectedBusLocation(selectedservice: String){
        let busCount = busses.count
        for i in (0..<busCount){
            if busses[i].serviceName == selectedservice{
                let coordinate = CLLocationCoordinate2DMake(busses[i].latitude, busses[i].longitude)
                let BusAnnotation = CustomPointAnnotation()
                BusAnnotation.coordinate = coordinate
                BusAnnotation.title = busses[i].serviceName
                BusAnnotation.subtitle = busses[i].destination
                BusAnnotation.customidentifier = "selectedBusAnnotation"
                map.addAnnotation(BusAnnotation)
            }
        }
    }
    
    //MARK: Selected Bus Service Reload
    func selectedBusDataRepeat(selectedservice: String) {
        selectedService = selectedservice
        timerForSelectedBus.invalidate()
        let current = busses
        busses = current
        BusData()
        BusDataRepeat()
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

    
    
//MARK: Service Lines
    
    
    
    //MARK: Service Data
    func serviceDataCall(){
        serviceData(servicestring: "services")
    }
    
    //MARK: Service Route Coordinates
    func serviceLines(serviceName: String) {
        guard let service = servicesArray.first(where: { $0.name == serviceName }), !service.routes.isEmpty else {
            showMessage(title: String(localized: "serviceRouteUnavailable"))
            return
        }
        let buttons = [route1, route2, route3, route4]
        for (index, button) in buttons.enumerated() { button.isHidden = index >= service.routes.count }
        let requested = route2check ? 1 : (route3check ? 2 : (route4check ? 3 : 0))
        let index = service.routes.indices.contains(requested) ? requested : 0
        route1check = index == 0
        route2check = index == 1
        route3check = index == 2
        route4check = index == 3
        for (position, button) in buttons.enumerated() {
            button.backgroundColor = position == index ? UIColor.systemBlue.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.8)
        }
        selectedServiceRouteCoordinates = service.routes[index].points.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }.filter(CLLocationCoordinate2DIsValid)
        selectedServiceRouteStopIDs = service.routes[index].points.compactMap { Int($0.stopID ?? "") }
        guard selectedServiceRouteCoordinates.count >= 2 else {
            showMessage(title: String(localized: "serviceRouteUnavailable"))
            return
        }
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.compactMap { $0 as? CustomPointAnnotation }.filter { $0.customidentifier == "busStopAnnotation" })
        cancelServiceButton.isHidden = false
        setRouteControls(hidden: true)
        servicePolyLine(selectedServiceRouteCoordinates: selectedServiceRouteCoordinates, stopID: selectedServiceRouteStopIDs, servicepPolyMapView: map)
        selectedBusDataRepeat(selectedservice: serviceName)
    }

    //MARK: Service Route Polyline
    var servicePolyline: MKPolyline?
    func servicePolyLine(selectedServiceRouteCoordinates: [CLLocationCoordinate2D], stopID: [Int], servicepPolyMapView: MKMapView){
        let servicepolyline = MKPolyline(coordinates: selectedServiceRouteCoordinates, count: selectedServiceRouteCoordinates.count)
        self.servicePolyline = servicepolyline
        servicepPolyMapView.addOverlay(servicepolyline)
        for busStops in self.stops {
            for stopIDs in stopID{
                if busStops.stopID == stopIDs {
                    guard let latitude = busStops.latitude, let longitude = busStops.longitude,
                          busStops.hasValidCoordinate else { continue }
                    let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    let busStopAnnotation = CustomPointAnnotation()
                    busStopAnnotation.coordinate = coordinate
                    busStopAnnotation.title = busStops.name
                    busStopAnnotation.customidentifier = "busStopAnnotation"
                    self.map.addAnnotation(busStopAnnotation)
                }
            }
        }
    }
    
    //MARK: Service Route Cancel
    @objc func removeServicePolyline(){
        selectedService = nil
        timerForSelectedBus.invalidate()
        cancelServiceButton.isHidden = true
        minutesFor15Button.isHidden = false
        minutesFor30Button.isHidden = false
        minutesFor45Button.isHidden = false
        metersFor500Button.isHidden = false
        metersFor1000Button.isHidden = false
        metersFor1500Button.isHidden = false
        self.map.removeOverlays(self.map.overlays)
        for ServiceStopAnnotation in self.map.annotations {
            if let ServiceStopAnnotation = ServiceStopAnnotation as? CustomPointAnnotation, ServiceStopAnnotation.customidentifier == "busStopAnnotation" {
                self.map.removeAnnotation(ServiceStopAnnotation)
            }
        }
        for BusAnnotation in self.map.annotations {
            if let BusAnnotation = BusAnnotation as? CustomPointAnnotation, BusAnnotation.customidentifier == "selectedBusAnnotation" {
                self.map.removeAnnotation(BusAnnotation)
            }
        }
        route1.isHidden = true
        route2.isHidden = true
        route3.isHidden = true
        route4.isHidden = true
        route1check = true
        route1.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route2.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route3.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route4.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route2check = false
        route3check = false
        route4check = false
        BusData()
        BusDataRepeat()
    }
    
    
    
    
//MARK: Map
    
    
    
    //MARK: Map Location
    func mapLocation(){
        map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 55.9533, longitude: -3.1883), latitudinalMeters: 7000, longitudinalMeters: 7000), animated: false)
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
    
    

//MARK: Buttons Setup
    let currentlocationButton = UIButton(type: .custom)
    let zoomOutButton = UIButton(type: .custom)
    let zoomInButton = UIButton(type: .custom)
    let minutesFor15Button = UIButton(type: .custom)
    let minutesFor30Button = UIButton(type: .custom)
    let minutesFor45Button = UIButton(type: .custom)
    let route1 = UIButton(type: .custom)
    let route2 = UIButton(type: .custom)
    let route3 = UIButton(type: .custom)
    let route4 = UIButton(type: .custom)
    let metersFor500Button = UIButton(type: .custom)
    let metersFor1000Button = UIButton(type: .custom)
    let metersFor1500Button = UIButton(type: .custom)
    let cancelServiceButton = UIButton(type: .custom)
    var minute15check = true
    var minute30check = false
    var minute45check = false
    var meter500check = true
    var meter1000check = false
    var meter1500check = false
    var route1check = true
    var route2check = false
    var route3check = false
    var route4check = false
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
        zoomOutButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        
        //MARK: Zoom In Button
        zoomInButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        zoomInButton.setImage(UIImage(systemName: "plus.square.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)
        
        zoomInButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([zoomInButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), zoomInButton.bottomAnchor.constraint(equalTo: zoomOutButton.topAnchor), zoomInButton.widthAnchor.constraint(equalToConstant: 50), zoomInButton.heightAnchor.constraint(equalToConstant: 50)])
        zoomInButton.layer.cornerRadius = 10
        zoomInButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        
        //MARK: 15 Minutes Button
        minutesFor15Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        minutesFor15Button.setTitle("15", for: .normal)
        minutesFor15Button.setTitleColor(.black, for: .normal)
        minutesFor15Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        minutesFor15Button.addTarget(self, action: #selector(minute15), for: .touchUpInside)
        view.addSubview(minutesFor15Button)
        
        minutesFor15Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([minutesFor15Button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10), minutesFor15Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), minutesFor15Button.widthAnchor.constraint(equalToConstant: 30), minutesFor15Button.heightAnchor.constraint(equalToConstant: 25)])
        minutesFor15Button.layer.cornerRadius = 8
        minutesFor15Button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        //MARK: 30 Minutes Button
        minutesFor30Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor30Button.setTitle("30", for: .normal)
        minutesFor30Button.setTitleColor(.black, for: .normal)
        minutesFor30Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        minutesFor30Button.addTarget(self, action: #selector(minute30), for: .touchUpInside)
        view.addSubview(minutesFor30Button)
        
        minutesFor30Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([minutesFor30Button.leadingAnchor.constraint(equalTo: minutesFor15Button.trailingAnchor), minutesFor30Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), minutesFor30Button.widthAnchor.constraint(equalToConstant: 30), minutesFor30Button.heightAnchor.constraint(equalToConstant: 25)])
        
        //MARK: 45 Minutes Button
        minutesFor45Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor45Button.setTitle("45 \(String(localized: "min"))", for: .normal)
        minutesFor45Button.setTitleColor(.black, for: .normal)
        minutesFor45Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        minutesFor45Button.addTarget(self, action: #selector(minute45), for: .touchUpInside)
        view.addSubview(minutesFor45Button)
        minutesFor45Button.layer.cornerRadius = 8
        minutesFor45Button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        
        minutesFor45Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([minutesFor45Button.leadingAnchor.constraint(equalTo: minutesFor30Button.trailingAnchor), minutesFor45Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), minutesFor45Button.widthAnchor.constraint(equalToConstant: 60), minutesFor45Button.heightAnchor.constraint(equalToConstant: 25)])
        
        //MARK: 400 Meters Button
        metersFor1500Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1500Button.setTitle("400 m", for: .normal)
        metersFor1500Button.setTitleColor(.black, for: .normal)
        metersFor1500Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        metersFor1500Button.addTarget(self, action: #selector(meter1500), for: .touchUpInside)
        view.addSubview(metersFor1500Button)
        
        metersFor1500Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([metersFor1500Button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), metersFor1500Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), metersFor1500Button.widthAnchor.constraint(equalToConstant: 70), metersFor1500Button.heightAnchor.constraint(equalToConstant: 25)])
        metersFor1500Button.layer.cornerRadius = 8
        metersFor1500Button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        
        //MARK: 250 Meters Button
        metersFor1000Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1000Button.setTitle("250", for: .normal)
        metersFor1000Button.setTitleColor(.black, for: .normal)
        metersFor1000Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        metersFor1000Button.addTarget(self, action: #selector(meter1000), for: .touchUpInside)
        view.addSubview(metersFor1000Button)

        metersFor1000Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([metersFor1000Button.trailingAnchor.constraint(equalTo: metersFor1500Button.leadingAnchor), metersFor1000Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), metersFor1000Button.widthAnchor.constraint(equalToConstant: 60), metersFor1000Button.heightAnchor.constraint(equalToConstant: 25)])
        
        //MARK: 100 Meters Button
        metersFor500Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        metersFor500Button.setTitle("100", for: .normal)
        metersFor500Button.setTitleColor(.black, for: .normal)
        metersFor500Button.titleLabel?.font = minutesFor15Button.titleLabel?.font.withSize(14)
        metersFor500Button.addTarget(self, action: #selector(meter500), for: .touchUpInside)
        view.addSubview(metersFor500Button)
        
        metersFor500Button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([metersFor500Button.trailingAnchor.constraint(equalTo: metersFor1000Button.leadingAnchor), metersFor500Button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), metersFor500Button.widthAnchor.constraint(equalToConstant: 60), metersFor500Button.heightAnchor.constraint(equalToConstant: 25)])
        metersFor500Button.layer.cornerRadius = 8
        metersFor500Button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        //MARK: Cancel Service Button
        cancelServiceButton.backgroundColor = UIColor(white: 1, alpha: 1)
        cancelServiceButton.setTitle(String(localized: "cancelButton"), for: .normal)
        cancelServiceButton.setTitleColor(.black, for: .normal)
        cancelServiceButton.titleLabel?.font = cancelServiceButton.titleLabel?.font.withSize(14)
        cancelServiceButton.addTarget(self, action: #selector(removeServicePolyline), for: .touchUpInside)
        view.addSubview(cancelServiceButton)
        
        cancelServiceButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cancelServiceButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), cancelServiceButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), cancelServiceButton.widthAnchor.constraint(equalToConstant: 60), cancelServiceButton.heightAnchor.constraint(equalToConstant: 25)])
        cancelServiceButton.layer.cornerRadius = 8
        cancelServiceButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    
        //MARK: Route 1 Button
        route1.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route1.setTitle("\(String(localized: "routesButton")) 1", for: .normal)
        route1.setTitleColor(.black, for: .normal)
        route1.titleLabel?.font = route1.titleLabel?.font.withSize(14)
        route1.addTarget(self, action: #selector(route1Function), for: .touchUpInside)
        view.addSubview(route1)
        
        route1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([route1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10), route1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), route1.widthAnchor.constraint(equalToConstant: 80), route1.heightAnchor.constraint(equalToConstant: 25)])
        route1.layer.cornerRadius = 8
        route1.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        //MARK: Route 2 Button
        route2.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route2.setTitle("2", for: .normal)
        route2.setTitleColor(.black, for: .normal)
        route2.titleLabel?.font = route2.titleLabel?.font.withSize(14)
        route2.addTarget(self, action: #selector(route2Function), for: .touchUpInside)
        view.addSubview(route2)
        
        route2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([route2.leadingAnchor.constraint(equalTo: route1.trailingAnchor), route2.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), route2.widthAnchor.constraint(equalToConstant: 30), route2.heightAnchor.constraint(equalToConstant: 25)])
        
        //MARK: Route 3 Button
        route3.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route3.setTitle("3", for: .normal)
        route3.setTitleColor(.black, for: .normal)
        route3.titleLabel?.font = route3.titleLabel?.font.withSize(14)
        route3.addTarget(self, action: #selector(route3Function), for: .touchUpInside)
        view.addSubview(route3)
        
        route3.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([route3.leadingAnchor.constraint(equalTo: route2.trailingAnchor), route3.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), route3.widthAnchor.constraint(equalToConstant: 30), route3.heightAnchor.constraint(equalToConstant: 25)])
        
        //MARK: Route 4 Button
        route4.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route4.setTitle("4", for: .normal)
        route4.setTitleColor(.black, for: .normal)
        route4.titleLabel?.font = route4.titleLabel?.font.withSize(14)
        route4.addTarget(self, action: #selector(route4Function), for: .touchUpInside)
        view.addSubview(route4)
        route4.layer.cornerRadius = 8
        route4.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        
        route4.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([route4.leadingAnchor.constraint(equalTo: route3.trailingAnchor), route4.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), route4.widthAnchor.constraint(equalToConstant: 30), route4.heightAnchor.constraint(equalToConstant: 25)])
    
        route1.isHidden = true
        route2.isHidden = true
        route3.isHidden = true
        route4.isHidden = true
    }
    
    //MARK: Current Location Button Action
    @objc func pressed() {
        zoom_count = 0
        LocationManager.shared.getUserLocation(onError: { [weak self] _ in
            self?.showMessage(title: String(localized: "locationUnavailable"))
        }) { [weak self] location in DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.map.setRegion(MKCoordinateRegion(center: location.coordinate, span:MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
            }
        }
    }
    
    var zoom_count = 0
    //MARK: Zoom In Button Action
    @objc func zoomIn() {
        zoomMap(byFactor: 0.5)
        zoom_count = zoom_count-1
    }
    
    //MARK: Zoom Out Button Action
    @objc func zoomOut() {
        if zoom_count < 14 {
            zoomMap(byFactor: 2)
            zoom_count = zoom_count+1
        }
    }
    
    //MARK: 15 Minutes Button Action
    @objc func minute15() {
        minutesFor15Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        minutesFor30Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor45Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minute15check = true
        minute30check = false
        minute45check = false
    }
    
    //MARK: 30 Minutes Button Action
    @objc func minute30() {
        minutesFor15Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor30Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        minutesFor45Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minute15check = false
        minute30check = true
        minute45check = false
    }
    
    //MARK: 45 Minutes Button Action
    @objc func minute45() {
        minutesFor15Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor30Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        minutesFor45Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        minute15check = false
        minute30check = false
        minute45check = true
    }
    
    //MARK: 500 Meter Button Action
    @objc func meter500() {
        metersFor500Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        metersFor1000Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1500Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        meter500check = true
        meter1000check = false
        meter1500check = false
    }
    
    //MARK: 1000 Meter Button Action
    @objc func meter1000() {
        metersFor500Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1000Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        metersFor1500Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        meter500check = false
        meter1000check = true
        meter1500check = false
    }
    
    //MARK: 1500 Meter Button Action
    @objc func meter1500() {
        metersFor500Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1000Button.backgroundColor = UIColor(white: 1, alpha: 0.8)
        metersFor1500Button.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        meter500check = false
        meter1000check = false
        meter1500check = true
    }
    
    //MARK: Route 1 Button Action
    @objc func route1Function() {
        route1.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route2.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route3.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route4.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route1check = true
        route2check = false
        route3check = false
        route4check = false
        serviceLines(serviceName: busname)
    }
    
    //MARK: Route 2 Button Action
    @objc func route2Function() {
        route1.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route2.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route3.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route4.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route1check = false
        route2check = true
        route3check = false
        route4check = false
        serviceLines(serviceName: busname)
    }
    
    //MARK: Route 3 Button Action
    @objc func route3Function() {
        route1.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route2.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route3.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route4.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route1check = false
        route2check = false
        route3check = true
        route4check = false
        serviceLines(serviceName: busname)
    }
    
    //MARK: Route 4 Button Action
    @objc func route4Function() {
        route1.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route2.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route3.backgroundColor = UIColor(white: 1, alpha: 0.8)
        route4.backgroundColor = UIColor(red: 10/255, green: 96/255, blue: 254/255, alpha: 0.5)
        route1check = false
        route2check = false
        route3check = false
        route4check = true
        serviceLines(serviceName: busname)
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
        span.latitudeDelta = min(170, max(0.0001, span.latitudeDelta * delta))
        span.longitudeDelta = min(350, max(0.0001, span.longitudeDelta * delta))
        region.span = span
        map.setRegion(region, animated: true)
    }
    
    
    
//MARK: Bus Data
    func BusDataRepeat() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.BusData() }
    }

    @objc func BusData() {
        guard !busRequestInFlight else { return }
        busRequestInFlight = true
        let request = GetBaseData()
        request.busCompletionHandler { [weak self] busses, success, _ in
            guard let self else { return }
            self.busRequestInFlight = false
            self.busDataAvailable = success
            self.busses = success ? (busses ?? []) : []
            self.updateTransitStatus()
        }
        request.getBusBaseData(endPoint: "vehicle_locations")
    }

    func BusStopsData() {
        let request = GetBaseData()
        request.completionHandler { [weak self] stops, success, _ in
            guard let self else { return }
            self.stopsDataAvailable = success
            self.stops = stops ?? []
            self.updateTransitStatus()
        }
        request.getStopsBaseData(endPoint: "stops")
    }

//MARK: Service Data
    func serviceData(servicestring: String){
        let basedata = GetBaseData()
        basedata.serviceCompletionHandler { services, status, message in
            self.servicesArray = services ?? []
        }
        basedata.getServiceData(endPoint: servicestring)
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
        
        //MARK: Selected Bus Annotation
        if annotation.customidentifier == "selectedBusAnnotation" {
            annotationView?.image = UIImage(systemName: "bus")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue).resized(to: CGSize(width: 15, height: 15))
        }
        
        //MARK: Selected Bus Annotation
        if annotation.customidentifier == "selectedServiceBusAnnotation" {
            annotationView?.image = UIImage(systemName: "bus")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue).resized(to: CGSize(width: 15, height: 15))
        }
        
        //MARK: Selected Bus Annotation
        if annotation.customidentifier == "busStopAnnotation" {
            annotationView?.image = UIImage(named: "bus-stop-logo")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue).resized(to: CGSize(width: 25, height: 25))
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
    
    
    
    //MARK: Select Annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)  {
        let annotation = view.annotation as? CustomPointAnnotation
        
        if annotation?.customidentifier == "busAnnotation" {
            busname = annotation?.title ?? ""
            serviceLines(serviceName: annotation?.title ?? "")
        }
    }
    
    
    
    //MARK: Polyline Addition
    func mapView(_ mapView : MKMapView , rendererFor overlay: MKOverlay) ->MKOverlayRenderer {

        if overlay is MKPolyline {
            if ( toFirst  != nil) && (toFinal != nil ) && (toDestination != nil ) {
                if overlay as? MKPolyline  == toFirst {
                    let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
                    polyLineRenderer.strokeColor = .systemBlue
                    polyLineRenderer.lineWidth = 6
                    return polyLineRenderer
                }
                
                if overlay as? MKPolyline  == toFinal {
                    let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
                    polyLineRenderer.strokeColor = .systemRed
                    polyLineRenderer.lineWidth = 6
                    return polyLineRenderer
                }
                
                if overlay as? MKPolyline  == toDestination {
                    let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
                    polyLineRenderer.strokeColor = .systemBlue
                    polyLineRenderer.lineWidth = 6
                    return polyLineRenderer
                }
            }
        }
        
        if overlay is MKPolyline {
            if (servicePolyline != nil) {
                if overlay as? MKPolyline  == servicePolyline {
                    let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
                    polyLineRenderer.strokeColor = .systemRed
                    polyLineRenderer.lineWidth = 6
                    return polyLineRenderer
                }
            }
        }
        return MKOverlayRenderer()
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
        searchController.isActive = false
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
