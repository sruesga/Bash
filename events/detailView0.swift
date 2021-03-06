//
//  detailView0.swift
//  events
//
//  Created by Rhian Chavez on 7/24/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import UIKit
import AlamofireImage
import GoogleMaps
import LyftSDK

class detailView0: UIView, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDescription: UILabel!
    @IBOutlet weak var topMap: GMSMapView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var lyftButton: LyftButton!
    @IBOutlet weak var directionsButton: UIButton!
    
    var guests: [String] = []
    var guestsStatus: [Int] = []
    var locationManager = CLLocationManager()
    
    @IBAction func goingTap(_ sender: UIButton) {
        AppUser.current.accept(event: event!)
        NotificationCenter.default.post(name: BashNotifications.acceptOnDetailContainer, object: event)
        NotificationCenter.default.post(name: BashNotifications.accept, object: event)
        
        self.acceptButton.isEnabled = false
        self.acceptButton.isHidden = true
        self.declineButton.isEnabled = true
        self.declineButton.backgroundColor = Colors.redDeclined
        self.declineButton.isHidden = false
        // Configure Lyft Button
        self.lyftButton.isHidden = false
        self.directionsButton.isHidden = false
    }
    
    @IBAction func notGoingTap(_ sender: UIButton) {
        AppUser.current.decline(event: event!)
        NotificationCenter.default.post(name: BashNotifications.declineOnDetailContainer, object: event)
         NotificationCenter.default.post(name: BashNotifications.decline, object: event)
        
        self.declineButton.isEnabled = false
        self.declineButton.isHidden = true
        self.acceptButton.isEnabled = true
        self.acceptButton.isHidden = false
        self.acceptButton.backgroundColor = Colors.greenAccepted
        self.lyftButton.isHidden = true
        self.directionsButton.isHidden = true
    }
    
    override func awakeFromNib() {
        // Initialization code
        self.tableView.dataSource = self
        self.tableView.delegate = self
        let bundle = Bundle(path: "events/GuestsTableViewCell.swift")
        let nib1 = UINib(nibName: "GuestsTableViewCell", bundle: bundle)
        tableView.register(nib1, forCellReuseIdentifier: "userCell")
        // Setting invitiation button colors
        acceptButton.layer.cornerRadius = 5
        acceptButton.backgroundColor = UIColor(hexString: "#FEB2A4")
        declineButton.layer.cornerRadius = 5
        declineButton.backgroundColor = UIColor(hexString: "#FEB2A4")
        tableView.separatorColor = Colors.coral
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(detailView0.changedTheme(_:)), name: BashNotifications.changedTheme, object: nil)
    }
    
    var event: Event? {
        didSet {
            if event == nil {
                return
            }
            
            Utilities.setupGoogleMap(self.topMap)
            let camera = GMSCameraPosition.camera(withLatitude: self.event!.coordinate.latitude,
                                                  longitude: self.event!.coordinate.longitude,
                                                  zoom: 14.0)
            self.topMap.camera = camera
            self.topMap.isUserInteractionEnabled = false
            
            let marker = GMSMarker()
            marker.position = self.event!.coordinate
            marker.map = self.topMap
            marker.isDraggable = false
            
            self.topMap.isHidden = false
            
            self.profileImage.layer.cornerRadius = 0.5*self.profileImage.frame.width
            self.profileImage.layer.masksToBounds = true
            
            // set orgainzer pic
            let url = URL(string: event!.organizer.photoURLString)
            self.profileImage.af_setImage(withURL: url!)
            
            // set organizerlabel as well
            self.eventTitle.text = self.event!.title
            self.eventDescription.text = self.event!.about
            
            // Extracting the ID's and their response status from guestlist
            self.guests = Array(self.event!.guestlist.keys)
            self.guestsStatus = Array(self.event!.guestlist.values)
            print(self.guests)
            print(self.guestsStatus)
            
            // Set event date
            self.eventDate.text = Utilities.getDateString(date: self.event!.date)
            
            self.tableView.reloadData()
            // Setting button colors depending on myStatus
            for guest in self.event!.guestlist {
                print("guest: \(guest)")
            }
            
            
            let pickup = self.locationManager.location?.coordinate
            let destination = self.event!.coordinate
            
            self.lyftButton.configure(rideKind: LyftSDK.RideKind.Plus, pickup: pickup!, destination: destination)
            self.lyftButton.style = LyftButtonStyle.hotPink
            
            switch self.event!.myStatus {
            case .accepted:
                self.acceptButton.isEnabled = false
                self.acceptButton.isHidden = true
                self.acceptButton.sizeToFit()
                self.declineButton.isEnabled = true
                self.declineButton.backgroundColor = Colors.redDeclined
                self.declineButton.isHidden = false
                // Configure Lyft Button
                self.lyftButton.isHidden = false
                self.directionsButton.isHidden = false
                
            case .declined:
                self.declineButton.isEnabled = false
                self.declineButton.isHidden = true
                self.declineButton.sizeToFit()
                self.acceptButton.isEnabled = true
                self.acceptButton.isHidden = false
                self.acceptButton.backgroundColor = Colors.greenAccepted
                self.lyftButton.isHidden = true
                self.directionsButton.isHidden = true
                
            case .noResponse:
                self.acceptButton.layer.cornerRadius = 5
                self.acceptButton.backgroundColor = Colors.greenAccepted
                self.declineButton.layer.cornerRadius = 5
                self.declineButton.backgroundColor = Colors.redDeclined
                self.lyftButton.isHidden = true
                self.directionsButton.isHidden = true
            }
            if event!.organizer.uid == AppUser.current.uid {
                self.acceptButton.isEnabled = false
                self.acceptButton.isUserInteractionEnabled = false
                self.acceptButton.isHidden = true
                self.declineButton.isEnabled = false
                self.declineButton.isUserInteractionEnabled = false
                self.declineButton.isHidden = true
            }
        }
    }
    
    
    
    func refresh(_ notification: Notification) {
        switch self.event!.myStatus {
        case .accepted:
            self.acceptButton.setTitle("Accepted", for: .normal)
            self.acceptButton.backgroundColor = UIColor(hexString: "#4ADB75")
            self.acceptButton.isEnabled = false
            self.acceptButton.sizeToFit()
            self.declineButton.isEnabled = false
            self.declineButton.backgroundColor = UIColor(hexString: "#95a5a6")
            
        case .declined:
            self.declineButton.setTitle("Declined", for: .normal)
            self.declineButton.backgroundColor = UIColor(hexString: "#F46E79")
            self.declineButton.isEnabled = false
            self.declineButton.sizeToFit()
            self.acceptButton.isEnabled = false
            self.acceptButton.backgroundColor = UIColor(hexString: "#95a5a6")
            
        default:
            self.acceptButton.layer.cornerRadius = 5
            self.acceptButton.backgroundColor = UIColor(hexString: "#FEB2A4")
            self.declineButton.layer.cornerRadius = 5
            self.declineButton.backgroundColor = UIColor(hexString: "#FEB2A4")
        }
        if event!.organizer.uid == AppUser.current.uid {
            self.acceptButton.isEnabled = false
            self.acceptButton.isUserInteractionEnabled = false
            self.acceptButton.isHidden = true
            self.declineButton.isEnabled = false
            self.declineButton.isUserInteractionEnabled = false
            self.declineButton.isHidden = true
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.guests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! GuestsTableViewCell
        
        switch self.guestsStatus[indexPath.row] {
        case 1:
            cell.guestResponseImage.image = UIImage(named: "not-going-1")
        case 2:
            cell.guestResponseImage.image = UIImage(named: "going-1")
        default:
            cell.guestResponseImage.image = UIImage(named: "maybe-1")
        }
        
        FirebaseDatabaseManager.shared.getSingleUser(id: self.guests[indexPath.row]) { (user: AppUser) in
            cell.nameLabel.text = user.name
            let photoURLString = user.photoURLString
            let photoURL = URL(string: photoURLString)
            cell.guestImage.af_setImage(withURL: photoURL!)
            cell.guestImage.layer.cornerRadius = 0.5*cell.guestImage.frame.width
            cell.guestImage.layer.masksToBounds = true
        }
        return cell
    }
    
    @IBAction func getDirections(_ sender: Any) {
        let destinationLongitude = self.event?.coordinate.longitude
        let destinationLatitude = self.event?.coordinate.latitude
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!))
        {
            UIApplication.shared.openURL(NSURL(string:
                "comgooglemaps://?saddr=&daddr=\(Float(destinationLatitude!)),\(Float(destinationLongitude!))&directionsmode=driving")! as URL)
        } else
        {
            NSLog("Can't use com.google.maps://");
        }    }
    
    
    func changedTheme(_ notification: NSNotification) {
        Utilities.changeTheme(forMap: self.topMap)
    }
}
