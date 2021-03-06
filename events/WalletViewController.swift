//
//  WalletViewController.swift
//  events
//
//  Created by Xiu Chen on 7/25/17.
//  Copyright © 2017 fbu-rsx. All rights reserved.
//

import UIKit
import AlamofireImage
import XLPagerTabStrip

class WalletViewController: UIViewController, IndicatorInfoProvider, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var walletImage: UIImageView!
    @IBOutlet weak var walletAmount: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting dataSource and delegate
        tableView.dataSource = self
        tableView.delegate = self
        
        // Registering the cell xib file with tableview
        let bundle = Bundle(path: "/Users/xiuchen/Desktop/events/events/PaymentTableViewCell.swift")
        let nib = UINib(nibName: "PaymentTableViewCell", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: "PaymentCell")
        
        walletAmount.text = String(format: "%.2F", AppUser.current.wallet)

        // Gradient
        let coral = UIColor(hexString: "#FEB2A4")
        let lightBlue = UIColor(hexString: "#8CDEDC")
        infoView.gradientLayer.colors = [lightBlue.cgColor, coral.cgColor]
        infoView.gradientLayer.gradient = GradientPoint.bottomTop.draw()
        
        tableView.allowsSelection = false
        tableView.separatorColor = Colors.coral
        NotificationCenter.default.addObserver(self, selector: #selector(WalletViewController.walletChanged(_:)), name: BashNotifications.walletChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    func walletChanged(_ notification: NSNotification) {
        let value = notification.object as! Double
        walletAmount.text = String(format: "%.2f", value)
    }

    override func viewDidAppear(_ animated: Bool) {
        walletAnimation()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return AppUser.current.transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath) as! PaymentTableViewCell
        cell.transaction = AppUser.current.transactions[indexPath.row]
        return cell
    }
    
    func walletAnimation () {
        UIView.animate(withDuration: 1, delay: 0.25, options: [.autoreverse, .repeat], animations: {
            self.walletImage.frame.origin.y -= 8
        })
        self.walletImage.frame.origin.y += 8
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        //return IndicatorInfo(title: "Wallet", image: UIImage(named: "wallet"))
        return IndicatorInfo(title: "Wallet")
    }


}

// Gradient UIColor extension
extension UIColor {
    convenience init(_ hex: UInt) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

typealias GradientType = (x: CGPoint, y: CGPoint)

enum GradientPoint {
    case leftRight
    case rightLeft
    case topBottom
    case bottomTop
    case topLeftBottomRight
    case bottomRightTopLeft
    case topRightBottomLeft
    case bottomLeftTopRight
    
    func draw() -> GradientType {
        switch self {
        case .leftRight:
            return (x: CGPoint(x: 0, y: 0.5), y: CGPoint(x: 1, y: 0.5))
        case .rightLeft:
            return (x: CGPoint(x: 1, y: 0.5), y: CGPoint(x: 0, y: 0.5))
        case .topBottom:
            return (x: CGPoint(x: 0.5, y: 0), y: CGPoint(x: 0.5, y: 1))
        case .bottomTop:
            return (x: CGPoint(x: 0.5, y: 1), y: CGPoint(x: 0.5, y: 0))
        case .topLeftBottomRight:
            return (x: CGPoint(x: 0, y: 0), y: CGPoint(x: 1, y: 1))
        case .bottomRightTopLeft:
            return (x: CGPoint(x: 1, y: 1), y: CGPoint(x: 0, y: 0))
        case .topRightBottomLeft:
            return (x: CGPoint(x: 1, y: 0), y: CGPoint(x: 0, y: 1))
        case .bottomLeftTopRight:
            return (x: CGPoint(x: 0, y: 1), y: CGPoint(x: 1, y: 0))
        }
    }
}

class GradientLayer : CAGradientLayer {
    var gradient: GradientType? {
        didSet {
            startPoint = gradient?.x ?? CGPoint.zero
            endPoint = gradient?.y ?? CGPoint.zero
        }
    }
}

class GradientView: UIView {
    override public class var layerClass: Swift.AnyClass {
        get {
            return GradientLayer.self
        }
    }
}

protocol GradientViewProvider {
    associatedtype GradientViewType
}

extension GradientViewProvider where Self: UIView, Self.GradientViewType: CAGradientLayer {
    var gradientLayer: Self.GradientViewType {
        return layer as! Self.GradientViewType
    }
}

extension UIView: GradientViewProvider {
    typealias GradientViewType = GradientLayer
}
