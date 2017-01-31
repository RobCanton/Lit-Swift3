//
//  HomeViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState

    
    @IBOutlet weak var tableView: UITableView!
    
    var locations = [Location]()
    var filteredLocations = [Location]()
    
    var searchBarActive:Bool = false
    var searchBar:UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        tableView.backgroundColor = UIColor.black
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "LocationTableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "locationCell")
        
        tableView.separatorColor = UIColor(white: 0.1, alpha: 1.0)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.tableHeaderView = nil
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        locations = state.locations
        locations.sort(by: {
            if $0.getVisitorsCount() == $1.getVisitorsCount() {
                return $0.getDistance()! < $1.getDistance()!
            }
            
            return $0.getVisitorsCount() > $1.getVisitorsCount()
        })
        
        for i in 0 ..< locations.count {
            let location = locations[i]
            if location.isActive() {
                locations.remove(at: i)
                locations.insert(location, at: 0)
            }
            
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBarActive {
            return filteredLocations.count;
        }
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath as IndexPath) as! LocationTableCell
        var location:Location!
        if (searchBarActive) {
            location = filteredLocations[indexPath.item]
        } else {
            location = locations[indexPath.item]
        }
        cell.setCellLocation(location)
        
        return cell
    }
    
    var selectedLocationPath:IndexPath?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        selectedLocationPath = indexPath as IndexPath?
        self.performSegue(withIdentifier: "showLocation", sender: self)

    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath:
        IndexPath) {
        let parallaxCell = cell as! LocationTableCell
        parallaxCell.setImageViewOffSet(tableView, indexPath: indexPath as IndexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        setCellAlphas()
    }
    
    func setCellAlphas() {
        if let _ = self.tableView.indexPathsForVisibleRows, (self.tableView.indexPathsForVisibleRows?.count)! > 0 {
            var count = 0
            for indexPath in self.tableView.indexPathsForVisibleRows! {
                let cell = self.tableView.cellForRow(at: indexPath) as! LocationTableCell
                cell.setImageViewOffSet(tableView, indexPath: indexPath)
                
                if count == tableView.indexPathsForVisibleRows!.count - 1 {
                    let rectOfCellInTableView = tableView.rectForRow(at: indexPath)
                    
                    let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: tableView.superview)
                    let cellY = rectOfCellInSuperview.origin.y
                    let bottomPoint = self.tableView.frame.height - rectOfCellInSuperview.height
                    
                    let alpha = 1 - (cellY - bottomPoint) / rectOfCellInSuperview.height
                    cell.alpha = max(0,alpha)
                }
                count += 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocation" {
            if let controller = segue.destination as? LocationViewController {
                controller.location = locations[selectedLocationPath!.row]
            }
        }
    }
}
