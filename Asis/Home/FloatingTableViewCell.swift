//
//  FloatingTableViewCell.swift
//  Asis
//
//  Created by Can Duru on 17.08.2022.
//

//MARK: Import
import UIKit

class FloatingTableViewCell: UITableViewCell {
    
//MARK: Set Up
    static let identifer = "stopTableViewCell"
    var titleLabel:UILabel!
    var detailLabel_howlong:UILabel!
    var detailLabel_services:UILabel!
    var imagePlace: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
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
            titleLabel.numberOfLines = 0
            titleLabel.textColor = .systemGray
            titleLabel.font = titleLabel.font.withSize(30)
            titleLabel.font = UIFont.systemFont(ofSize: 20)
            self.addSubview(titleLabel)
            
            
            //MARK: Subtitle
            detailLabel_services = UILabel()
            detailLabel_services.numberOfLines = 0
            detailLabel_services.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(detailLabel_services)
            
            //MARK: Subtitle_2
            detailLabel_howlong = UILabel()
            detailLabel_howlong.numberOfLines = 0
            detailLabel_howlong.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(detailLabel_howlong)
            
            //MARK: Image
            imagePlace = UIImageView()
            imagePlace.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(imagePlace)
        
            

            //MARK: Constraints
            NSLayoutConstraint.activate([
                
                
                //MARK: Title Constraints
                titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
                titleLabel.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
                titleLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -5),
                
                //MARK: Image Constraints
                imagePlace.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
                imagePlace.widthAnchor.constraint(equalToConstant: 30),
                imagePlace.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                imagePlace.heightAnchor.constraint(equalToConstant: 50),
                
                //MARK: Subtitle Constraints
                detailLabel_howlong.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
                detailLabel_howlong.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
                detailLabel_howlong.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
                detailLabel_howlong.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -5),
                
                detailLabel_services.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
                detailLabel_services.topAnchor.constraint(equalTo: detailLabel_howlong.bottomAnchor, constant: 5),
                detailLabel_services.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
                detailLabel_services.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -5),
                detailLabel_services.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10)
            ])
            
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
