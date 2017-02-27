//
//  HomeViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import ZoomTransitioning

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState

    
    @IBOutlet weak var tableView: UITableView!
    
    var locations = [Location]()
    var filteredLocations = [Location]()
    
    var searchBarActive:Bool = false
    var searchBar:UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        setCellAlphas()
        
        searchBar = UISearchBar()

        searchBar.placeholder = "Search Nearby"
        searchBar.delegate = self
        
        searchBar.keyboardAppearance   = .dark
        searchBar.searchBarStyle       = UISearchBarStyle.minimal
        searchBar.tintColor            = UIColor.white
        searchBar.barTintColor         = UIColor(white: 0.05, alpha: 1.0)
        searchBar.setTextColor(color: UIColor.white)
    
        self.navigationItem.titleView = searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if let tabBar = self.tabBarController as? MasterTabBarController {
            tabBar.setTabBarVisible(_visible: true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    func newState(state: AppState) {
        var templocations = state.locations
        templocations.sort(by: {
            if $0.getVisitorsCount() == $1.getVisitorsCount() {
                return $0.getDistance()! < $1.getDistance()!
            }
            
            return $0.getVisitorsCount() > $1.getVisitorsCount()
        })
        
        var activeLocations = [Location]()
        for i in 0 ..< templocations.count {
            let location = templocations[i]
            if location.isActive() {
                templocations.remove(at: i)
                templocations.insert(location, at: 0)
                activeLocations.append(location)
            }
        }
        
        activeLocations.sort(by: {
            if $0.getVisitorsCount() == $1.getVisitorsCount() {
                return $0.getDistance()! < $1.getDistance()!
            }
            
            return $0.getVisitorsCount() > $1.getVisitorsCount()
        })
        
        for _ in 0..<activeLocations.count {
            templocations.remove(at: 0)
        }
        
        templocations.insert(contentsOf: activeLocations, at: 0)
        
        locations = templocations
        tableView.reloadData()
        setCellAlphas()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 236
        
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
        cell.setCellLocation(location: location)
        
        return cell
    }
    
    var selectedLocationPath:IndexPath?
    var selectedImageView:UIImageView!
    
    var topHalf:UIImageView?
    var botHalf:UIImageView?
    var midSection:UIImageView?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLocationPath = indexPath
        let cell = tableView.cellForRow(at: selectedLocationPath!) as! LocationTableCell
        selectedImageView = cell.backgroundImage
        let controller = LocationViewController()
        guard let indexPath = selectedLocationPath else {return}
        var location:Location
        if (searchBarActive) {
            location = filteredLocations[indexPath.item]
            cancelSearching()
        } else {
            location = locations[indexPath.item]
        }
        controller.location = location
        self.navigationController?.pushViewController(controller, animated: true)
        //self.performSegue(withIdentifier: "showLocation", sender: self)
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
                if let cell = self.tableView.cellForRow(at: indexPath) as?  LocationTableCell {
                cell.setImageViewOffSet(tableView, indexPath: indexPath)
                
                if count == tableView.indexPathsForVisibleRows!.count - 1 {
                    let rectOfCellInTableView = tableView.rectForRow(at: indexPath)
                    
                    let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: tableView.superview)
                    let cellY = rectOfCellInSuperview.origin.y
                    let bottomPoint = self.tableView.frame.height - rectOfCellInSuperview.height
                    
                    let alpha = 1 - (cellY - bottomPoint) / rectOfCellInSuperview.height
                    cell.alpha = max(0,alpha)
                }
                }
                count += 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocation" {
            if let controller = segue.destination as? LocationViewController {
                guard let indexPath = selectedLocationPath else {return}
                var location:Location
                if (searchBarActive) {
                    location = filteredLocations[indexPath.item]
                    cancelSearching()
                } else {
                    location = locations[indexPath.item]
                }
                controller.location = location
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool{
        get {
            return false
        }
    }
}

extension HomeViewController: ZoomTransitionSourceDelegate {
    
    func transitionSourceImageView() -> UIImageView {
        return selectedImageView
    }
    
    func transitionSourceImageViewFrame(forward forward: Bool) -> CGRect {
        let navHeight = navigationController!.navigationBar.frame.height + 20.0
        var bounds = selectedImageView.convert(selectedImageView.bounds, to: view)
        var rect = CGRect(x: bounds.origin.x, y: bounds.origin.y + navHeight, width: bounds.width, height: bounds.height)
        return rect
    }
    
    func transitionSourceWillBegin() {
        selectedImageView.isHidden = true
    }
    
    func transitionSourceDidEnd() {
        selectedImageView.isHidden = false
    }
    
    func transitionSourceDidCancel() {
        selectedImageView.isHidden = false
    }
    
    func transitionSourceTopLayoutHeight() -> CGFloat{
        return navigationController!.navigationBar.frame.height + 20.0
    }
    
    func transitionSourceBottomLayoutHeight() -> CGFloat{
        return tabBarController!.tabBar.frame.height
    }
    
    func transitionSourceCellFrame() -> CGRect {
        let cell = tableView.cellForRow(at: selectedLocationPath!)!
        return cell.convert(cell.bounds, to: view)
    }
    
    func createTopHalf() -> UIImageView? {

        let cell = tableView.cellForRow(at: selectedLocationPath!)!
        let bounds = cell.convert(cell.bounds, to: view)
        let topLayout = transitionSourceTopLayoutHeight()
        let snapshot = view.snapshot(of: CGRect(x: 0,
                                                y: 0,
                                                width: view.frame.width,
                                                height: bounds.origin.y))
        self.topHalf = snapshot
        return snapshot
    }
    
    func getTopHalf() -> UIImageView? {
        return topHalf
    }
    
    func createBottomHalf() -> UIImageView? {
        
        let cell = tableView.cellForRow(at: selectedLocationPath!)!
        let bounds = cell.convert(cell.bounds, to: view)
        let bottomStart = bounds.origin.y  + bounds.height
        let snapshot = view.snapshot(of: CGRect(x: 0,
                                                y: bottomStart,
                                                width: view.frame.width,
                                                height: view.frame.height - bottomStart))
        self.botHalf = snapshot
        return snapshot
    }
    
    func getBottomHalf() -> UIImageView? {
        return botHalf
    }
    
    func createMidSection() -> UIImageView? {
        let cell = tableView.cellForRow(at: selectedLocationPath!)!
        let bounds = cell.convert(cell.bounds, to: view)
        var imageBounds = selectedImageView.convert(selectedImageView.bounds, to: view)
        
        
        let snapshot = view.snapshot(of: CGRect(x: 0, y: imageBounds.origin.y + imageBounds.height, width: view.frame.width, height: bounds.height - imageBounds.height))
        
        self.midSection = snapshot
        return snapshot
    }
    
    func getMidSection() -> UIImageView? {
        return midSection
    }
    

    func cleanUp() {
        topHalf = nil
        botHalf = nil
    }
}

extension HomeViewController: UISearchBarDelegate {
    // MARK: Search
    func filterContentForSearchText(searchText:String){
        self.filteredLocations = locations.filter({ (location:Location) -> Bool in
            return location.getName().localizedCaseInsensitiveContains(searchText)
            
            //.containsIgnoringCase(searchText)
        })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // user did type something, check our datasource for text that looks the same
        if searchText.characters.count > 0 {
            // search and reload data source
            self.searchBarActive    = true
            self.filterContentForSearchText(searchText: searchText)
            self.tableView?.contentOffset = CGPoint(x: 0, y: 0)
            self.tableView?.reloadData()
        }else{
            // if text lenght == 0
            // we will consider the searchbar is not active
            self.searchBarActive = false
            self.tableView?.reloadData()
        }
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearching()
        self.tableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // we used here to set self.searchBarActive = YES
        // but we'll not do that any more... it made problems
        // it's better to set self.searchBarActive = YES when user typed something
        self.searchBar.setShowsCancelButton(true, animated: true)
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // this method is being called when search btn in the keyboard tapped
        // we set searchBarActive = NO
        // but no need to reloadCollectionView
        //self.searchBarActive = false
        //self.searchBar.setShowsCancelButton(false, animated: false)
    }
    func cancelSearching(){
        self.searchBar.setShowsCancelButton(false, animated: true)
        self.searchBarActive = false
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
    }
}

extension UIView {
    
    /// Create snapshot
    ///
    /// - parameter rect: The `CGRect` of the portion of the view to return. If `nil` (or omitted),
    ///                   return snapshot of the whole view.
    ///
    /// - returns: Returns `UIImage` of the specified portion of the view.
    
    func snapshot(of rect: CGRect? = nil) -> UIImageView? {
        // snapshot entire view
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let wholeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // if no `rect` provided, return image of whole view
        
        guard let image = wholeImage, let rect = rect else { return nil }
        
        // otherwise, grab specified `rect` of image
        
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
        let screenshot = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        let view = UIImageView(frame: rect)
        view.image = screenshot
        return view
    }
    
}
