//
//  SideMenuüTableViewCell.swift
//  Asis
//
//  Created by Can Duru on 13.08.2022.
//

//MARK: Import
import UIKit

class SideMenuTableViewCell: UITableViewCell {

//MARK: Set Up
    static let identifer = "menuTableViewCell"
    var titleLabel:UILabel!
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
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = -1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        
        //MARK: Image
        imagePlace = UIImageView()
        imagePlace.clipsToBounds = true
        imagePlace.contentMode = UIView.ContentMode.scaleAspectFit
        imagePlace.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imagePlace)
        
   

//MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Title Constraints
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor),
        
            //MARK: Image Constraints
            imagePlace.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1),
            imagePlace.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            imagePlace.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            imagePlace.widthAnchor.constraint(equalToConstant: 100)
        ])
        
    }

    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
