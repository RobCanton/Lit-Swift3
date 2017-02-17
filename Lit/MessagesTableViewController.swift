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
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        
        
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
        
        cell.conversation = conversations[indexPath.item]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        prepareConverstaionForPresentation(conversation: conversations[indexPath.row])
    }
    
    func prepareConverstaionForPresentation(conversation:Conversation) {
        if let user = conversation.getPartner() {
            presentConversation(conversation: conversation, user: user)
        } else {
            UserService.getUser(conversation.getPartnerId(), completion: { user in
                if user != nil {
                    self.presentConversation(conversation: conversation, user: user!)
                }
            })
        }
    }
    
    func presentConversation(conversation:Conversation, user:User) {
        loadImageUsingCacheWithURL(user.getImageUrl(), completion: { image, fromCache in
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            controller.conversation = conversation
            controller.partnerImage = image
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.pushViewController(controller, animated: true)
        })
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! ConversationViewCell
            let name = cell.usernameLabel.text!
            
            let actionSheet = UIAlertController(title: "Delete conversation with \(name)?", message: "Further messages from \(name) will be muted until you reply.", preferredStyle: .alert)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            }
            
            actionSheet.addAction(cancelActionButton)
            
            let saveActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .destructive)
            { action -> Void in
                let partner = self.conversations[indexPath.row].getPartnerId()
                let uid = mainStore.state.userState.uid
                
                let userRef = UserService.ref.child("users/conversations/\(uid)/\(partner)")
                
                userRef.removeValue(completionBlock: { error, ref in
                    mainStore.dispatch(RemoveConversation(index: indexPath.row))
                })
            }
            actionSheet.addAction(saveActionButton)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
}
