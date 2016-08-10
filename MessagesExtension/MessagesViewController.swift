//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Yun Teng on 7/19/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    var stickers: [MSSticker]!
    
    // MARK: - MessagesViewController methods
    
    override func didBecomeActive(with conversation: MSConversation) {
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        guard let conversation = activeConversation else { fatalError("Expected active conversation") }
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fileManager = FileManager.default
        let stickersURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("stickers")
        var objcBool:ObjCBool = true
        if !fileManager.fileExists(atPath: stickersURL.path, isDirectory: &objcBool) {
            do {
                try fileManager.createDirectory(at: stickersURL, withIntermediateDirectories: true, attributes: nil)
            } catch { print("Error creating stickers directory") }
        }
        let enumerator = fileManager.enumerator(atPath: stickersURL.path)
        stickers = [MSSticker]()
        while let fileName = enumerator?.nextObject() as? String {
            let fileURL = stickersURL.appendingPathComponent(fileName)
            do {
                let sticker = try MSSticker(contentsOfFileURL: fileURL, localizedDescription: fileName.replacingOccurrences(of: ".png", with: "").replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "+", with: "/"))
                stickers.append(sticker)
            } catch { print("Error creating sticker from \(fileName)") }
        }
    }
    
    // MARK: helper view controller instantiate and present methods
    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        let controller: UIViewController
        if presentationStyle == .compact {
            controller = instantiateGamesCollectionViewController(with: stickers)
        } else {
            let board = Game(message: conversation.selectedMessage) ?? Game()
            controller = instantiateBoardViewController(with: board)
        }
        
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
        
        addChildViewController(controller)
        
        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        controller.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        controller.didMove(toParentViewController: self)
    }
    
    private func instantiateGamesCollectionViewController(with stickers: [MSSticker]) -> UIViewController {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: GamesCollectionController.storyboardIdentifier) as? GamesCollectionController else { fatalError("unable to instantiate GamesCollectionController") }
        controller.stickers = stickers
        return controller
    }
    
    private func instantiateBoardViewController(with game: Game) -> UIViewController {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: BoardViewController.storyboardIdentifier) as? BoardViewController else { fatalError("unable to instantiate BoardViewController") }
        controller.game = game
        return controller
    }
}
