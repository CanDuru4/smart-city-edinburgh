//
//  SettingsTableViewCell.swift
//  Asis
//
//  Created by Can Duru on 11.08.2022.
//

//MARK: Import
import UIKit

class SettingsTableViewCell: UITableViewCell {
    static let identifer = "settingsTableViewCell"
    
//MARK: Set Up
    var titleLabel:UILabel!
    var imagePlace: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    
//MARK: Select Function
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    

    
//MARK: Load
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: BusStopTableViewCellSetup.identifer)
        configureViews()
    }
    
    
    
//MARK: Variable Features
    func configureViews(){
        
        //MARK: Title Label Features
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .systemGray
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        self.addSubview(titleLabel)
        
        //MARK: Image Features
        imagePlace = UIImageView()
        imagePlace.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imagePlace)
    

        
        //MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: imagePlace.trailingAnchor, constant: 10),
            
            //MARK: Image Constraints
            imagePlace.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            imagePlace.widthAnchor.constraint(equalToConstant: 30),
            imagePlace.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            imagePlace.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
