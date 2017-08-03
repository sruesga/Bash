//
//  User.swift
//  events
//
//  Created by Skyler Ruesga on 7/12/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import Foundation
import FirebaseAuth
import FBSDKCoreKit

struct BashNotifications {
    static let invite = NSNotification.Name(rawValue: "inviteAdded")
    static let delete = NSNotification.Name(rawValue: "deleteEvent")
    static let accept = NSNotification.Name(rawValue: "acceptedInvitation")
    static let decline = NSNotification.Name(rawValue: "declineInvitation")
    static let logout = NSNotification.Name(rawValue: "logout")
    static let refresh = NSNotification.Name(rawValue: "refresh")
    static let enableSwipe = NSNotification.Name(rawValue: "enableSwipe")
    static let disableSwipe = NSNotification.Name(rawValue: "disableSwipe")
    static let swipeRight = NSNotification.Name(rawValue: "swipeRight")
    static let swipeLeft = NSNotification.Name(rawValue: "swipeLeft")
    static let eventsLoaded = NSNotification.Name(rawValue: "eventsLoaded")
    static let walletChanged = NSNotification.Name(rawValue: "walletChanged")
    static let changedTheme = NSNotification.Name(rawValue: "changedTheme")
}

struct UserKey {
    static let id = "uid"
    static let name = "name"
    static let photo = "photoURLString"
    static let events = "events"
    static let wallet = "wallet"
}

/*
 - "uid":
 - "uid": "gMrf7HieuJHoH7fsdg"
 - "name": "Skyler Ruesga"
 - "photoURLString": "https://etc.com/kjhdf76vf8"
 - "location": [latitude, longitude]
 - "events":
 - "eventid1": true
 - "eventid2": false
 - "eventid3": false
 - "transactions":
 */


class AppUser {
    
    static var current: AppUser!
    
    var uid: String //same as their facebook id
    var name: String
    var photoURLString: String
    var events: [Event] = []
    var eventsKeys: [String: Int]!
    var wallet: Double!
    var transactions: [Transaction]!
    
    var facebookFriends: [FacebookFriend]!
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary[UserKey.id] as! String
        self.name = dictionary[UserKey.name] as! String
        self.photoURLString = dictionary[UserKey.photo] as! String
    }
    
    convenience init(user: User) {
        let userDict: [String: Any] = [UserKey.id: FBSDKAccessToken.current().userID,
                                          UserKey.name: user.displayName!,
                                          UserKey.photo: user.photoURL?.absoluteString ?? "gs://events-86286.appspot.com/default"]
        self.init(dictionary: userDict)
        
        // Adds user only if the user does not exists
        FirebaseDatabaseManager.shared.addUser(userDict: userDict)
        FirebaseDatabaseManager.shared.fetchUserEvents(userid: self.uid) { (keys: [String: Int], events: [String: Any]) in
            self.eventsKeys = keys
            for id in events.keys {
                let dict = events[id] as! [String: Any]
                self.events.append(Event(dictionary: dict))
            }
            FirebaseDatabaseManager.shared.addEventsListener()
            NotificationCenter.default.post(name: BashNotifications.eventsLoaded, object: nil)
            print("events loaded notification posted")
        }
        FirebaseDatabaseManager.shared.createWallet(id: uid) { (value: Double) in
            self.wallet = value
            FirebaseDatabaseManager.shared.addWalletListener(id: self.uid)
        }
        FacebookAPIManager.shared.getUserFriendsList { (friends: [FacebookFriend]) in
            self.facebookFriends = friends
        }
        FirebaseDatabaseManager.shared.getTransactions(id: self.uid) { (dict: [String : Any]) in
            var arr: [Transaction] = []
            for key in dict.keys {
                let transaction = Transaction(dict: dict[key] as! [String: Any])
                arr.append(transaction)
            }
            self.transactions = arr
        }
        NotificationCenter.default.addObserver(self, selector: #selector(AppUser.inviteAdded(_:)), name: BashNotifications.invite, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppUser.delete(_:)), name: BashNotifications.delete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppUser.accept(_:)), name: BashNotifications.accept, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppUser.decline(_:)), name: BashNotifications.decline, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppUser.walletChanged(_:)), name: BashNotifications.walletChanged, object: nil)
    }

    /**
     *
     * Events related functions
     *
     */
    //adds existing event to user event list
    @objc func inviteAdded(_ notification: NSNotification) {
        let event = notification.object as! Event
        self.eventsKeys[event.eventid] = InviteStatus.noResponse.rawValue
        self.events.append(event)
    }
    
    @objc func delete(_ notification: NSNotification) {
        let event = notification.object as! Event
        FirebaseDatabaseManager.shared.deleteEvent(event)
        self.removeUserFromEvent(event)
    }
    
    @objc func accept(_ notification: NSNotification) {
        let event = notification.object as! Event
        FirebaseDatabaseManager.shared.updateInvitation(for: event, withStatus: .accepted)
        event.myStatus = .accepted
        if event.cost != nil {
            let transaction = Transaction(event: event)
            self.transactions.append(transaction)
            FirebaseDatabaseManager.shared.addTransaction(transaction: transaction)
        }
    }
    
    @objc func decline(_ notification: NSNotification) {
        let event = notification.object as! Event
        FirebaseDatabaseManager.shared.updateInvitation(for: event, withStatus: .declined)
        FirebaseDatabaseManager.shared.removeTransaction(forEventID: event.eventid)
        if event.myStatus == .accepted {
            var idx: Int!
            for i in 0..<self.transactions.count {
                let transaction = self.transactions[i]
                if transaction.id == event.eventid {
                    idx = i
                    break
                }
            }
            self.transactions.remove(at: idx)
        }
        event.myStatus = .declined
    }
    
    @objc func walletChanged(_ notification: NSNotification) {
        let value = notification.object as! Double
        self.wallet = value
    }

    
    func getBasicDict() -> [String: Any] {
        let dict = [UserKey.id: self.uid,
                    UserKey.name: self.name,
                    UserKey.photo: self.photoURLString]
        return dict
    }
    
    //create event and add to user event list and event database
    func createEvent(_ eventDict: [String: Any]) -> Event {
        let event = Event(dictionary: eventDict)
        self.eventsKeys[event.eventid] = InviteStatus.accepted.rawValue
        self.events.append(event)
        FirebaseDatabaseManager.shared.createEvent(eventDict) {
            FirebaseDatabaseManager.shared.inviteGuests(event.guestlist, to: event)
        }
        return event
    }
    
    //remove event from user event list
    func removeUserFromEvent(_ event: Event) {
        FirebaseDatabaseManager.shared.removeUserFromEvent(event)
        let index = self.events.index(of: event)!
        self.events.remove(at: index)
        self.eventsKeys.removeValue(forKey: event.eventid)
    }
    
    func addToWallet(amount: Double) {
        FirebaseDatabaseManager.shared.updateWallet(id: self.uid, withValue: self.wallet + amount)
    }
}

