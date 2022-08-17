//
//  DealerViewController.swift
//  Asis
//
//  Created by Can Duru on 2.08.2022.
//

//MARK: Import
import UIKit
import MapKit 

class AllStopsViewController: UIViewController {

//MARK: Set Up
    
    
    
    //MARK: Data Setup
    var stopsAnnotation:CustomPointAnnotation!
    var stopsAnnotationView:MKPinAnnotationView!
    var stops:[Stop] = [] {
        didSet{
            let stopscount = stops.count
            for i in (0..<stopscount){
                //MARK: Annotate Stops
                let coordinate = CLLocationCoordinate2DMake(stops[i].latitude!, stops[i].longitude!)
                let stopsAnnotation = CustomPointAnnotation()
                stopsAnnotation.coordinate = coordinate
                stopsAnnotation.title = stops[i].name
                stopsAnnotationView = MKPinAnnotationView(annotation: stopsAnnotation, reuseIdentifier: "custom")
                map.addAnnotation(stopsAnnotationView.annotation!)

            }
        }
    }
    
    //MARK: Map Setup
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    

    
//MARK: Load
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        //MARK: Bus Stops Load
        BusStopsData()

        //MARK: Map Load
        view.addSubview(map)
        setMapLayout()
        mapLocation()
        setButton()
        map.delegate = self
        
        //MARK: Side Menu Load
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.hidesBackButton = true
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.backward")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue), for: .normal)
        button.setTitle(String(localized: "backButton"), for: .normal) //MARK: Localize
        button.titleLabel?.font = button.titleLabel?.font.withSize(18)
        button.sizeToFit()
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @objc func back() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.popViewController(animated: true)
    }

   
    
//MARK: Map
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
    func setMapLayout(){
        map.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([map.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), map.bottomAnchor.constraint(equalTo: view.bottomAnchor), map.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor), map.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)])
    }
    
    
    
//MARK: Buttons Setup
    func setButton(){
        
        
        //MARK: Current Location Button
        let currentlocationButton = UIButton(type: .custom)
        currentlocationButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        currentlocationButton.setImage(UIImage(systemName: "location.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        currentlocationButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        view.addSubview(currentlocationButton)
        
        currentlocationButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([currentlocationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), currentlocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60), currentlocationButton.widthAnchor.constraint(equalToConstant: 50), currentlocationButton.heightAnchor.constraint(equalToConstant: 50)])
        currentlocationButton.layer.cornerRadius = 25
        currentlocationButton.layer.masksToBounds = true
        
        //MARK: Zoom Out Button
        let zoomOutButton = UIButton(type: .custom)
        zoomOutButton.backgroundColor = UIColor(white: 1, alpha: 0.8)
        zoomOutButton.setImage(UIImage(systemName: "minus.square.fill")?.resized(to: CGSize(width: 25, height: 25)).withTintColor(.systemBlue), for: .normal)
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        view.addSubview(zoomOutButton)
        
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([zoomOutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), zoomOutButton.bottomAnchor.constraint(equalTo: currentlocationButton.topAnchor, constant: -20), zoomOutButton.widthAnchor.constraint(equalToConstant: 50), zoomOutButton.heightAnchor.constraint(equalToConstant: 50)])
        zoomOutButton.layer.cornerRadius = 10
        zoomOutButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner] // Top right corner, Top left corner respectively
        
        //MARK: Zoom In
        let zoomInButton = UIButton(type: .custom)
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
    
    
    
//MARK: Zoom in and Out Function
    func zoomMap(byFactor delta: Double) {
        var region: MKCoordinateRegion = self.map.region
        var span: MKCoordinateSpan = map.region.span
        span.latitudeDelta *= delta
        span.longitudeDelta *= delta
        region.span = span
        map.setRegion(region, animated: true)
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



//MARK: Pin With Photo Extension
extension AllStopsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseIdentifier = "custom"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "bus-stop-logo")!.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue).resized(to: CGSize(width: 25, height: 25))
        return annotationView
    }
}
