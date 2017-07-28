//
//  ViewController.swift
//  events
//
//  Created by Skyler Ruesga on 7/10/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import OAuthSwift
import FBSDKLoginKit
import AlamofireImage

struct Colors {
    static let coral = UIColor(hexString: "#EF5B5B")
    static let lightBlue = UIColor(hexString: "#B6E7EF")
    static let green = UIColor(hexString: "#4CB6BE")
    static let orange = UIColor(hexString: "#FF9D00")
    static let greenAccepted =  UIColor(hexString: "4ADB75")
    static let redDecline = UIColor(hexString: "ED5E63")
//    static let grayPending =
}

struct PreferenceKeys {
    static let savedItems = "savedItems"
}


protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

protocol LoadEventsDelegate: class {
    func fetchEvents(completion: @escaping () -> Void)
}

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    static var mapAnnotations: [MKAnnotationView] = []
    
    // Search Variable Instantiations
    var resultSearchController: UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
    
    // Creates an instance of Core Location class
    var locationManager = (UIApplication.shared.delegate as! AppDelegate).locationManager
    var events: [Event] = []
    
    var delegate: LoadEventsDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Displays user's current location
        self.mapView.showsUserLocation = true
        // Allows user's location tracking
        self.mapView.setUserTrackingMode(.follow, animated: true)
        
        // SEARCH
        // Programmatically instantiating the locationSearchTable TableViewController
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        // Programatically embedding the search bar in Navigation Controller
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search"
        navigationItem.titleView = resultSearchController?.searchBar
        // NavBar does not disappear when search results are shown
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        // When search bar is selected, modal overlay has a semi-transparent overlay
        resultSearchController?.dimsBackgroundDuringPresentation = true
        // Limit the overlap area just to View Controller, not blocking the Navigation bar
        definesPresentationContext = true
        
        // Ask for Authorization from the User
        self.delegate = AppUser.current
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        delegate.fetchEvents() {
            self.loadAllEvents()
            self.removeOldRegions()
            print("MapViewController Events: \(self.events)")
        }
        CreateEventMaster.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.inviteAdded(_:)), name: BashNotifications.invite, object: nil)
        
        // Automatically zooms to the user's location upon VC loading
        //        guard let coordinate = self.mapView.userLocation.location?.coordinate else { return }
        //        let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
        //        self.mapView.setRegion(region, animated: true)
    }
    
    func inviteAdded(_ notification: NSNotification) {
        let event = notification.object as! Event
        self.add(event: event)
        saveAllEvents()
        print("invited added")
        print("Invite events: \(self.events)")
        
        // Pop-Up alert when others first invite you to an event
        
        let alertController = UIAlertController(title: "You've Been Invited!", message: "\(event.eventname)", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Show More Details", style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.tabBarController?.selectedIndex = 2
        })
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    @IBAction func onZoomtoCurrent(_ sender: Any) {
        mapView.zoomToUserLocation()
    }
    
    /**
     *
     * Functions for Geofencing
     *
     */
    
    // MARK: Add an event to the mapView
    func add(event: Event) {
        self.events.append(event)
        mapView.addAnnotation(event)
        addRadiusOverlay(forEvent: event)
    }
    
    func remove(event: Event) {
        if let indexInArray = events.index(of: event) {
            events.remove(at: indexInArray)
        }
        mapView.removeAnnotation(event)
        removeRadiusOverlay(forEvent: event)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forEvent event: Event) {
        mapView.add(MKCircle(center: event.coordinate, radius: event.radius))
    }
    
    func removeRadiusOverlay(forEvent event: Event) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        for overlay in mapView.overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == event.coordinate.latitude && coord.longitude == event.coordinate.longitude && circleOverlay.radius == event.radius {
                mapView.remove(circleOverlay)
                break
            }
        }
    }
    
    func region(withEvent event: Event) -> CLCircularRegion {
        // 1
        let region = CLCircularRegion(center: event.coordinate, radius: event.radius, identifier: event.eventid)
        // 2
        region.notifyOnEntry = true
        region.notifyOnExit = true
        //        region.notifyOnEntry = (geotification.eventType == .onEntry)
        //        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(event: Event) {
        // 1
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle:"Warning", message: "Your event is saved but will only be activated once you grant us permission to access the device location.")
        }
        // 3
        let region = self.region(withEvent: event)
        // 4
        locationManager.startMonitoring(for: region)
    }
    
    
    func stopMonitoring(event: Event) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == event.eventid else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func loadAllEvents() {
        for event in AppUser.current.events {
            add(event: event)
        }
        saveAllEvents()
    }
    
    func removeOldRegions() {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion else { continue }
            guard AppUser.current.eventsKeys[circularRegion.identifier] != nil else { continue }
            print("Deleted region: \(circularRegion.identifier)")
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func saveAllEvents() {
        var items: [Data] = []
        for event in self.events {
            let item = NSKeyedArchiver.archivedData(withRootObject: event)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferenceKeys.savedItems)
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myEvent"
        if let event = annotation as? Event {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                let data = try! Data(contentsOf: event.organizerURL)
                let image = UIImage(data: data)!
                annotationView?.image =  image.af_imageRoundedIntoCircle()
                annotationView?.canShowCallout = true
                let frame = annotationView!.frame
                annotationView?.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 35.0, height: 35.0)
                // Check button on annotation callout
                let checkInButton = UIButton(type: .custom)
                checkInButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                checkInButton.setImage(UIImage(named: "CheckInEvent")!, for: .normal)
                // Remove button on annotation callout
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteEvent")!, for: .normal)
                if event.organizerID == AppUser.current.uid {
                    annotationView?.leftCalloutAccessoryView = removeButton
                } else {
                    annotationView?.rightCalloutAccessoryView = checkInButton
                }
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var event: Event!
        for e in events {
            if e.coordinate.latitude == overlay.coordinate.latitude &&
                e.coordinate.longitude == overlay.coordinate.longitude {
                event = e
                break
            }
        }
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.5
            let color: UIColor!
            switch event.myStatus {
            case .accepted:
                color = Colors.green
            case .declined:
                color = Colors.coral
            default:
                color = Colors.orange
            }
            circleRenderer.strokeColor = color
            circleRenderer.fillColor = color.withAlphaComponent(0.3)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete event
        let event = view.annotation as! Event
        if control == view.leftCalloutAccessoryView {
            stopMonitoring(event: event)
            remove(event: event)
            NotificationCenter.default.post(name: BashNotifications.delete, object: event)
        } else {
            startMonitoring(event: event)
            NotificationCenter.default.post(name: BashNotifications.accept, object: event)
        }
        saveAllEvents()
    }
    
}

extension MapViewController: CreateEventMasterDelegate {
    func createNewEvent(_ dict: [String: Any]) {
        guard let radius = dict[EventKey.radius] as? Double, radius < locationManager.maximumRegionMonitoringDistance else { return }
        print("CREATING NEW EVENT")
        let event = AppUser.current.createEvent(dict)
        add(event: event)
        startMonitoring(event: event)
        saveAllEvents()
        print("new event added")
        CreateEventMaster.shared.clear()
    }
}

// SEARCH extension
extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city), \(state)"
        }
        // Custom pin view
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "placeholder")
        annotationView.image = UIImage(named: "placeholder.png")
        mapView.addAnnotation(annotationView.annotation!)
        
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}
