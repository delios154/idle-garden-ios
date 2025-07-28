//
//  TutorialManager.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import SpriteKit
import Foundation

enum TutorialStep: Int, CaseIterable {
    case welcome = 0
    case plantFirstSeed = 1
    case harvestPlant = 2
    case buyUpgrade = 3
    case plantMultiple = 4
    case complete = 5
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to Idle Garden!"
        case .plantFirstSeed: return "Plant Your First Seed"
        case .harvestPlant: return "Harvest Your Plant"
        case .buyUpgrade: return "Buy Your First Upgrade"
        case .plantMultiple: return "Plant Multiple Crops"
        case .complete: return "Tutorial Complete!"
        }
    }
    
    var message: String {
        switch self {
        case .welcome:
            return "Welcome to your magical garden! Plants grow automatically over time, even when you're away. Let's get started!"
        case .plantFirstSeed:
            return "Tap on an empty garden plot to open the plant shop. Choose a carrot to plant - it grows quickly!"
        case .harvestPlant:
            return "Great! Your plant is ready. Tap on it to harvest and earn Garden Points (GP)."
        case .buyUpgrade:
            return "Use your GP to buy upgrades. Try the Plant Speed upgrade to make plants grow faster!"
        case .plantMultiple:
            return "Now plant more crops! Different plants have different growth times and earn different amounts of GP."
        case .complete:
            return "You're ready to grow your garden! Remember to check back regularly to harvest your plants and buy upgrades."
        }
    }
}

protocol TutorialManagerDelegate: AnyObject {
    func showTutorialStep(_ step: TutorialStep)
    func hideTutorial()
    func highlightElement(_ element: String)
    func removeHighlight()
}

class TutorialManager {
    static let shared = TutorialManager()
    
    weak var delegate: TutorialManagerDelegate?
    private var currentStep: TutorialStep = .welcome
    private var hasCompletedTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: "TutorialCompleted") }
        set { UserDefaults.standard.set(newValue, forKey: "TutorialCompleted") }
    }
    
    private init() {}
    
    func startTutorialIfNeeded() {
        if !hasCompletedTutorial {
            currentStep = .welcome
            delegate?.showTutorialStep(currentStep)
        }
    }
    
    func nextStep() {
        let nextIndex = currentStep.rawValue + 1
        if nextIndex < TutorialStep.allCases.count {
            currentStep = TutorialStep(rawValue: nextIndex) ?? .complete
            delegate?.showTutorialStep(currentStep)
        } else {
            completeTutorial()
        }
    }
    
    func completeTutorial() {
        hasCompletedTutorial = true
        delegate?.hideTutorial()
    }
    
    func skipTutorial() {
        hasCompletedTutorial = true
        delegate?.hideTutorial()
    }
    
    func checkStepCompletion(_ action: String) {
        switch currentStep {
        case .plantFirstSeed:
            if action == "plant_seed" {
                nextStep()
            }
        case .harvestPlant:
            if action == "harvest_plant" {
                nextStep()
            }
        case .buyUpgrade:
            if action == "buy_upgrade" {
                nextStep()
            }
        case .plantMultiple:
            if action == "plant_multiple" {
                nextStep()
            }
        default:
            break
        }
    }
    
    func getCurrentStep() -> TutorialStep {
        return currentStep
    }
    
    func isTutorialActive() -> Bool {
        return !hasCompletedTutorial
    }
}

// MARK: - Tutorial UI

class TutorialOverlay: SKNode {
    
    weak var delegate: TutorialManagerDelegate?
    private var background: SKSpriteNode?
    private var titleLabel: SKLabelNode?
    private var messageLabel: SKLabelNode?
    private var nextButton: SKSpriteNode?
    private var skipButton: SKSpriteNode?
    private var highlightNode: SKShapeNode?
    
    func showTutorialStep(_ step: TutorialStep) {
        removeAllChildren()
        
        // Dimming background
        background = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 1000))
        background?.alpha = 0.7
        background?.position = CGPoint.zero
        addChild(background!)
        
        // Tutorial card
        let card = SKSpriteNode(color: .white, size: CGSize(width: 300, height: 200))
        card.position = CGPoint(x: 0, y: 0)
        card.zPosition = 10
        addChild(card)
        
        // Title
        titleLabel = SKLabelNode(text: step.title)
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 18
        titleLabel?.fontColor = .black
        titleLabel?.position = CGPoint(x: 0, y: 60)
        titleLabel?.zPosition = 11
        addChild(titleLabel!)
        
        // Message
        messageLabel = SKLabelNode(text: step.message)
        messageLabel?.fontName = "AvenirNext-Regular"
        messageLabel?.fontSize = 14
        messageLabel?.fontColor = .black
        messageLabel?.position = CGPoint(x: 0, y: 20)
        messageLabel?.zPosition = 11
        messageLabel?.preferredMaxLayoutWidth = 280
        messageLabel?.numberOfLines = 0
        addChild(messageLabel!)
        
        // Next button
        nextButton = SKSpriteNode(color: .green, size: CGSize(width: 80, height: 30))
        nextButton?.position = CGPoint(x: 0, y: -40)
        nextButton?.zPosition = 11
        nextButton?.name = "nextButton"
        addChild(nextButton!)
        
        let nextLabel = SKLabelNode(text: "Next")
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontSize = 14
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint.zero
        nextButton?.addChild(nextLabel)
        
        // Skip button
        skipButton = SKSpriteNode(color: .gray, size: CGSize(width: 60, height: 25))
        skipButton?.position = CGPoint(x: 0, y: -80)
        skipButton?.zPosition = 11
        skipButton?.name = "skipButton"
        addChild(skipButton!)
        
        let skipLabel = SKLabelNode(text: "Skip")
        skipLabel.fontName = "AvenirNext-Regular"
        skipLabel.fontSize = 12
        skipLabel.fontColor = .white
        skipLabel.position = CGPoint.zero
        skipButton?.addChild(skipLabel)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    func hide() {
        removeAllChildren()
        isUserInteractionEnabled = false
    }
    
    func highlightElement(_ elementName: String) {
        // Remove previous highlight
        highlightNode?.removeFromParent()
        
        // Create highlight effect
        highlightNode = SKShapeNode(rectOf: CGSize(width: 100, height: 100), cornerRadius: 10)
        highlightNode?.strokeColor = .yellow
        highlightNode?.lineWidth = 3
        highlightNode?.position = CGPoint.zero
        highlightNode?.zPosition = 5
        addChild(highlightNode!)
        
        // Add pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        highlightNode?.run(SKAction.repeatForever(pulse))
    }
    
    func removeHighlight() {
        highlightNode?.removeFromParent()
        highlightNode = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "nextButton" {
                TutorialManager.shared.nextStep()
                return
            } else if node.name == "skipButton" {
                TutorialManager.shared.skipTutorial()
                return
            }
        }
    }
}

// MARK: - Tutorial Integration

extension GardenScene: TutorialManagerDelegate {
    
    func setupTutorial() {
        let tutorialOverlay = TutorialOverlay()
        tutorialOverlay.delegate = self
        tutorialOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        tutorialOverlay.zPosition = 1000
        addChild(tutorialOverlay)
        
        TutorialManager.shared.delegate = self
        TutorialManager.shared.startTutorialIfNeeded()
    }
    
    func showTutorialStep(_ step: TutorialStep) {
        // Find tutorial overlay and show step
        if let overlay = childNode(withName: "tutorialOverlay") as? TutorialOverlay {
            overlay.showTutorialStep(step)
        }
        
        // Highlight relevant elements based on step
        switch step {
        case .plantFirstSeed:
            highlightElement("garden_plot")
        case .harvestPlant:
            highlightElement("ready_plant")
        case .buyUpgrade:
            highlightElement("upgrade_button")
        case .plantMultiple:
            highlightElement("plant_button")
        default:
            removeHighlight()
        }
    }
    
    func hideTutorial() {
        if let overlay = childNode(withName: "tutorialOverlay") as? TutorialOverlay {
            overlay.hide()
        }
        removeHighlight()
    }
    
    func highlightElement(_ element: String) {
        if let overlay = childNode(withName: "tutorialOverlay") as? TutorialOverlay {
            overlay.highlightElement(element)
        }
    }
    
    func removeHighlight() {
        if let overlay = childNode(withName: "tutorialOverlay") as? TutorialOverlay {
            overlay.removeHighlight()
        }
    }
} 