//
//  HowToGoSearchTableViewController.swift
//  Asis
//
//  Created by Can Duru on 15.08.2022.
//

import UIKit
import MapKit

class HowToGoSearchTableCellSetup: UITableViewCell {
    
//MARK: Set Up
    static let identifer = "HowToGoTableViewCell"
    
    var titleLabel:UILabel!
    var detailLabel:UILabel!
    var goButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    

//MARK: Select Cell Function
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
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        self.addSubview(titleLabel)
        
        
        //MARK: Subtitle
        detailLabel = UILabel()
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabel)
    
        //MARK: Button
        goButton = UIButton()
        goButton.setTitle((String(localized: "goButton")), for: .normal)
        goButton.setTitleColor(.black, for: .normal)
        goButton.backgroundColor = .systemBlue
        goButton.translatesAutoresizingMaskIntoConstraints = false
        goButton.layer.cornerRadius = 5
        goButton.layer.masksToBounds = true
        self.addSubview(goButton)
        goButton.addTarget(self, action: #selector(goPlace), for: .touchUpInside)


        

//MARK: Constraints
        NSLayoutConstraint.activate([
            
            
            //MARK: Title Constraints
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: goButton.leadingAnchor, constant: -5),
            
            //MARK: Subtitle Constraints
            detailLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            detailLabel.trailingAnchor.constraint(equalTo: goButton.leadingAnchor, constant: -5),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            detailLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
            
            //MARK: Go Button Constraints
            goButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            goButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            goButton.widthAnchor.constraint(equalToConstant: 100)

        ])
        
    }
    
    @objc func goPlace() {
        
    }
        
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

