//
//  BoardViewController.swift
//  Chess
//
//  Created by Yun Teng on 7/19/16.
//  Copyright © 2016 yunskicentral. All rights reserved.
//

import UIKit
import SpriteKit

class BoardViewController: UIViewController {
    static let storyboardIdentifier = "BoardViewController"
    var scene: BoardScene!
    var game: Game!
    @IBOutlet var moveButton: UIButton!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        get { return true }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if game.isComplete {
            moveButton.isEnabled = false
        }
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        scene = BoardScene(size: skView.bounds.size, with: game)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        print("PRESENT BOARD")
    }
    
    @IBAction func makeMove(_ sender: UIButton) {
    }
}
