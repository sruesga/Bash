//
//  EventsViewController.swift
//  events
//
//  Created by Rhian Chavez on 7/13/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import UIKit
import FoldingCell
import ImagePicker

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, imagePickerDelegate2 {

    @IBOutlet weak var tableView: UITableView!
    
    let kCloseCellHeight: CGFloat = 144
    let kOpenCellHeight: CGFloat = 466
    var events: [Event] = []
    var cellHeights: [CGFloat] = []
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.delegate = self
        tableView.dataSource = self
        //let bundle = Bundle(path: "/Users/rhianchavez11/Documents/events/events/Views")
        tableView.register(UINib(nibName: "EventsTableViewCell", bundle: nil), forCellReuseIdentifier: "eventCell")
        tableView.separatorStyle = .none
        //cellHeights = (0..<events.count).map { _ in C.CellHeight.close }
        cellHeights = (0..<6).map { _ in C.CellHeight.close }
        // Load AppUser's events
        events = AppUser.current.events
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         NotificationCenter.default.addObserver(self, selector: #selector(EventsViewController.refresh), name: BashNotifications.refresh, object: nil)

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(EventsViewController.deleteEvent(_:)), name: BashNotifications.delete, object: nil)

    }

    func refresh(_ notification: Notification) {
        let event = notification.object as! Event
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func deleteEvent(_ notification: NSNotification) {
        let event = notification.object as! Event
        let index = self.events.index(of: event)!
        self.events.remove(at: index)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // return cell to present associated with user's events 
        // which data to display is dependent on selected index of segmented control
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventsTableViewCell
        cell.event = events[indexPath.row]
        // see which data to display
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return number of events associated with user in current section
        // number will be dependent on selected index of segmented control
        //return events.count
        return self.events.count
    }
    
    fileprivate struct C {
        struct CellHeight {
            static let close: CGFloat = 144 // equal or greater foregroundView height
            static let open: CGFloat = 466 // equal or greater containerView height
        }
    }
    
    func presenter(imagePicker : ImagePickerController) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case let cell as FoldingCell = tableView.cellForRow(at: indexPath)
            else {
            return
        }
        
        for heightnum in 0..<cellHeights.count{
            if cellHeights[heightnum] == kOpenCellHeight{
                if heightnum != indexPath.row {
                    return
                }
            }
        }
        
        var duration = 0.0
        if cellHeights[indexPath.row] == kCloseCellHeight { // open cell
            cellHeights[indexPath.row] = kOpenCellHeight
            //cell.selectedAnimation(true, animated: true, completion: nil)
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
            tableView.isScrollEnabled = false
        } else {// close cell
            cellHeights[indexPath.row] = kCloseCellHeight
            //cell.selectedAnimation(false, animated: true, completion: nil)
            cell.unfold(false, animated: true, completion: nil)
            duration = 1.1
            tableView.isScrollEnabled = true
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { _ in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if case let cell as FoldingCell = cell {
            cell.backgroundColor = .clear
            if cellHeights[indexPath.row] == C.CellHeight.close {
                //cell.selectedAnimation(false, animated: false, completion:nil)
                cell.unfold(false, animated: false, completion: nil)
            } else {
                //cell.selectedAnimation(true, animated: false, completion: nil)
                cell.unfold(true, animated: false, completion: nil)
            }
        }
    }
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail"{
            let destination = segue.destination as! DetailedEventViewController
            destination.event = sender as? Event
        }
    }
    */

    
}
