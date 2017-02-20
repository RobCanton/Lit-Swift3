//
//  UserSearchViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-04.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class UserSearchViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    var searchBarActive:Bool = false
    
    var activityIndicator:UIActivityIndicatorView!

    var userIds = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenToSearchResults()
        searchBar.becomeFirstResponder()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToSearchResults()
    }
    
    func listenToSearchResults() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/responses/user_search/\(uid)")
        
        ref.observe(.value, with: { snapshot in
            if snapshot.exists() {
                self.activityIndicator.stopAnimating()
                var uids = [String]()
                if let failed = snapshot.value as? Bool {
 
                } else {
                    let dict = snapshot.value as! [String:Any]
                    for (key, _) in dict {
                        uids.append(key)
                    }

                }
            
                self.userIds = uids
                self.tableView.reloadData()
                ref.removeValue()
            }
        })
    }
    
    func stopListeningToSearchResults() {
        let uid = mainStore.state.userState.uid
        let ref = UserService.ref.child("api/responses/user_search/\(uid)")
        ref.removeAllObservers()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        let nib2 = UINib(nibName: "UserViewCell", bundle: nil)
        tableView.register(nib2, forCellReuseIdentifier: "UserCell")
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,y: 0,width: tableView!.frame.width,height: 160))
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        
        searchBar.delegate = self
        searchBar.showsCancelButton    = false
        searchBar.keyboardAppearance   = .dark
        searchBar.searchBarStyle       = UISearchBarStyle.minimal
        searchBar.tintColor            = UIColor.white
        searchBar.setTextColor(color: UIColor.white)
        searchBar.delegate = self
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x:0,y:0,width:50,height:50))
        activityIndicator.activityIndicatorViewStyle = .white
        activityIndicator.center = CGPoint(x:UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 4 - 25)
        tableView.addSubview(activityIndicator)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let text = searchText.lowercased()
        searchBar.text = text
        
        if text.characters.count > 0 {
            // user did type something, check our datasource for text that looks the same
            let uid = mainStore.state.userState.uid
            let ref = UserService.ref.child("api/requests/user_search/\(uid)")
            ref.setValue(searchBar.text)
            self.activityIndicator.startAnimating()
        } else {
            self.userIds = [String]()
            self.tableView.reloadData()
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
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    }
    func cancelSearching(){
        self.searchBarActive = false
        self.searchBar.resignFirstResponder()
        self.searchBar.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIds.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserViewCell
        cell.followButton.isEnabled = false
        cell.followButton.alpha = 0.0
        cell.setupUser(uid: userIds[indexPath.item])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = UserProfileViewController()
        controller.uid = userIds[indexPath.row]
        self.navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
