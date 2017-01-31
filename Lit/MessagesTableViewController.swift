//
//  MessagesTableViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift
import UIKit

class MessagesViewController: UITableViewController, StoreSubscriber {

    let cellIdentifier = "conversationCell"
    
    var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor(white: 0.08, alpha: 1.0)
        
        tableView.tableFooterView = UIView()
        
        conversations = getNonEmptyConversations()
        conversations.sort(by: { $0 > $1 })
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
        
        conversations = getNonEmptyConversations()
        conversations.sort(by: { $0 > $1 })
        tableView.reloadData()
        
    }
    
    func checkForExistingConversation(partner_uid:String) -> Conversation? {
        for conversation in conversations {
            if conversation.getPartnerId() == partner_uid {
                return conversation
            }
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationViewCell
        print("WUT")
        cell.conversation = conversations[indexPath.item]
        return cell
    }
    
}
