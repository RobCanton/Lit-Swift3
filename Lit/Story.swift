//
//  Story.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-20.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

enum UserStoryState {
    case notLoaded, loadingItemInfo, itemInfoLoaded, loadingContent, contentLoaded
}

protocol StoryProtocol {
    func stateChange(_ state: UserStoryState)
}

class UserStory: ItemDelegate {
    fileprivate var user_id:String
    fileprivate var postKeys:[String]
    fileprivate var date:Date
    
    
    var delegate:StoryProtocol?

    var items:[StoryItem]?
    var state:UserStoryState = .notLoaded
        {
        didSet {
            delegate?.stateChange(state)
        }
    }
    
    init(user_id:String, postKeys:[String], timestamp:Double) {
        self.user_id = user_id
        self.postKeys = postKeys
        self.date  = Date(timeIntervalSince1970: timestamp/1000)
    }
    
    func getUserId() -> String {
        return user_id
    }
    
    func getPostKeys() -> [String] {
        return postKeys
    }
    
    func getDate() -> Date {
        return date
    }
    
    func hasViewedAll() -> Bool {
        guard let _items = self.items else { return false }
        for item in _items {
            if !item.hasViewed() {
                return false
            }
        }
        
        return true
    }
    
    
    
    
    func determineState() {
        if needsDownload() {
            if items == nil {
                state = .notLoaded
            } else {
                state = .itemInfoLoaded
            }
        } else {
            state = .contentLoaded
        }
    }
    
    /**
     # downloadItems
     Download the full data and create a Story Item for each post key.
     
     * Successful download results set state to ItemInfoLoaded
     * If data already downloaded sets state to ContentLoaded

    */
    func downloadItems() {
        if state == .notLoaded {
            state = .loadingItemInfo
            UploadService.downloadStory(postKeys: postKeys, completion: { items in
                
                self.items = items.sorted(by: {
                    return $0 < $1
                })
                self.state = .itemInfoLoaded
                if !self.needsDownload() {
                    self.state = .contentLoaded
                }

            })
        } else if items != nil {
            if !self.needsDownload() {
                self.state = .contentLoaded
            }
        }
    }
    
    func needsDownload() -> Bool {
        if items != nil {
            for item in items! {
                if item.needsDownload() {
                    return true
                }
            }
            return false
        }
        return true
    }
    
    
    func itemDownloaded() {
        if !needsDownload() {
            self.state = .contentLoaded
        }
    }
    
    func downloadStory() {
        if items != nil {
            state = .loadingContent
            for item in items! {
                item.delegate = self
                item.download()
            }
        }
    }
    

    
    func printDescription() {
        print("USER STORY: \(user_id)")
        
        for key in postKeys {
            print(" * \(key)")
        }
        
        print("\n")
    }
}

func < (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedAscending
}

func > (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedDescending
}

func == (lhs: UserStory, rhs: UserStory) -> Bool {
    return lhs.date.compare(rhs.date) == .orderedSame
}

//func findStoryByUserID(uid:String, stories:[Story]) -> Int? {
//    for i in 0 ..< stories.count {
//        if stories[i].author_uid == uid {
//            return i
//        }
//    }
//    return nil
//}
//
//func sortStoryItems(items:[StoryItem]) -> [Story] {
//    var stories = [Story]()
//    for item in items {
//        if let index = findStoryByUserID(item.getAuthorId(), stories: stories) {
//            stories[index].addItem(item)
//        } else {
//            let story = Story(author_uid: item.getAuthorId())
//            story.addItem(item)
//            stories.append(story)
//        }
//    }
//    
//    return stories
//}

//func < (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedAscending
//}
//
//func == (lhs: Story, rhs: Story) -> Bool {
//    let lhs_item = lhs.getMostRecentItem()!
//    let rhs_item = rhs.getMostRecentItem()!
//    return lhs_item.dateCreated.compare(rhs_item.dateCreated) == .OrderedSame
//}
