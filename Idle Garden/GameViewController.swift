//
//  GameViewController.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the garden scene
        let scene = GardenScene(size: view.bounds.size)
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        // Present the scene
        if let view = self.view as! SKView? {
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            // Debug info (remove for production)
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = false
        }
        
        // Initialize game manager
        _ = GameManager.shared
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Force portrait mode for better idle game experience
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Save game when app goes to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillResignActive() {
        // Save game state when app goes to background
        GameManager.shared.saveGame()
    }
}

// MARK: - Scene Delegate Support
extension GameViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update scene size if needed
        if let skView = view as? SKView, let scene = skView.scene {
            scene.size = view.bounds.size
        }
    }
}
