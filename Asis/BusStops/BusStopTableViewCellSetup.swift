//
//  StopTableViewCell.swift
//  Asis
//
//  Created by Can Duru on 3.08.2022.
//

//MARK: Import
import UIKit
import MapKit

class BusStopTableViewCellSetup: UITableViewCell {
    
//MARK: Set Up
    static let identifer = "stopTableViewCell"
    var busstoptableStop:Stop!
    
    var titleLabel:UILabel!
    var detailLabel_services:UILabel!
    var detailLabel_destinations:UILabel!
    var detailLabel_adress: UILabel!
    var imagePlace: UIImageView!
    var map: MKMapView!
    var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    

//MARK: Select Cell Function
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            detailLabel_adress.isHidden = false
            map.isHidden = false
            button.isHidden = false
        } else {
            detailLabel_adress.isHidden = true
            map.isHidden = true
            button.isHidden = true
        }
        super.setSelected(selected, animated: animated)
     
    }
    
    
    
//MARK: Load
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: BusStopTableViewCellSetup.identifer)
        configureViews()

    }
    
    //MARK: Set Contents
    func configureViews(){
        
        //MARK: Title
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .systemGray
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        self.addSubview(titleLabel)
        
        
        //MARK: Subtitle
        detailLabel_services = UILabel()
        detailLabel_services.numberOfLines = -1
        detailLabel_services.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabel_services)
        
        //MARK: Subtitle_2
        detailLabel_destinations = UILabel()
        detailLabel_destinations.numberOfLines = -1
        detailLabel_destinations.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabel_destinations)
        
        //MARK: Subtitle_3
        detailLabel_adress = UILabel()
        detailLabel_adress.numberOfLines = -1
        detailLabel_adress.isHidden = true
        detailLabel_adress.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabel_adress)
        
        //MARK: Image
        imagePlace = UIImageView()
        imagePlace.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imagePlace)
        
        //MARK: Map
        map = MKMapView()
        map.isHidden = true
        map.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(map)
        
        //MARK: Button
        button = UIButton()
        button.isHidden = true
        button.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        button.addTarget(self, action: #selector(createRoute), for: .touchUpInside)
    
        

//MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Title Constraints
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
            
            //MARK: Subtitle Constraints
            detailLabel_destinations.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
            detailLabel_destinations.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            detailLabel_destinations.topAnchor.constraint(equalTo: detailLabel_services.bottomAnchor, constant: 1),
            
            detailLabel_services.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
            detailLabel_services.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            detailLabel_services.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            
            detailLabel_adress.topAnchor.constraint(equalTo: detailLabel_destinations.bottomAnchor, constant: 20),
            detailLabel_adress.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            detailLabel_adress.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            
            //MARK: Image Constraints
            imagePlace.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            imagePlace.widthAnchor.constraint(equalToConstant: 30),
            imagePlace.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            imagePlace.heightAnchor.constraint(equalToConstant: 30),
              
            //MARK: Map Constraints
            map.topAnchor.constraint(equalTo: detailLabel_adress.bottomAnchor, constant: 20),
            map.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            map.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            map.heightAnchor.constraint(equalToConstant: 180),
            
            //MARK: Button Constraints
            button.topAnchor.constraint(equalTo: map.topAnchor),
            button.trailingAnchor.constraint(equalTo: map.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: map.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: map.leadingAnchor),
        ])
        
    }
    
    
    
//MARK: Create Route Function
    @objc func createRoute() {

    
        //MARK: Maps'e Yönlendirme
        let latitude = busstoptableStop.latitude
        let longitude = busstoptableStop.longitude
        
        let regionDistance: CLLocationDistance = 1000;
        let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
        
        let placemark = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        
        mapItem.name = busstoptableStop.name
        mapItem.openInMaps(launchOptions: options)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
