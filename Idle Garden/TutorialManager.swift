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
        case .welcome: return "🌱 Welcome to Idle Garden!"
        case .plantFirstSeed: return "🌰 Plant Your First Seed"
        case .harvestPlant: return "🌾 Harvest Your Plant"
        case .buyUpgrade: return "⚡ Buy Your First Upgrade"
        case .plantMultiple: return "🌻 Plant Multiple Crops"
        case .complete: return "🎉 Tutorial Complete!"
        }
    }
    
    var message: String {
        switch self {
        case .welcome:
            return "Welcome to your magical garden! Plants grow automatically over time, even when you're away. Let's start by planting your first seed!"
        case .plantFirstSeed:
            return "Tap on an empty garden plot (the brown squares) to open the plant shop. Choose a carrot to plant - it grows quickly and is perfect for beginners!"
        case .harvestPlant:
            return "Great! Your plant is ready when it glows yellow and shows 'Ready!'. Tap on it to harvest and earn Garden Points (GP)."
        case .buyUpgrade:
            return "Use your GP to buy upgrades! Try tapping the ⚡ Upgrade button at the bottom. The Plant Speed upgrade makes plants grow faster!"
        case .plantMultiple:
            return "Now plant multiple crops! Different plants have different growth times and rewards. Fill up your garden for maximum efficiency!"
        case .complete:
            return "You're ready to grow your garden empire! Remember to check back regularly to harvest plants, buy upgrades, and unlock new plant types. Happy gardening! 🌿✨"
        }
    }
    
    var buttonText: String {
        switch self {
        case .complete: return "Start Gardening!"
        default: return "Next"
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
    
    private var tutorialProgress: [String: Bool] {
        get {
            if let data = UserDefaults.standard.data(forKey: "TutorialProgress"),
               let progress = try? JSONDecoder().decode([String: Bool].self, from: data) {
                return progress
            }
            return [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "TutorialProgress")
            }
        }
    }
    
    private init() {}
    
    func startTutorialIfNeeded() {
        if !hasCompletedTutorial {
            currentStep = .welcome
            delegate?.showTutorialStep(currentStep)
        }
    }
    
    func nextStep() {
        // Mark current step as completed
        var progress = tutorialProgress
        progress[String(currentStep.rawValue)] = true
        tutorialProgress = progress
        
        let nextIndex = currentStep.rawValue + 1
        if nextIndex < TutorialStep.allCases.count {
            currentStep = TutorialStep(rawValue: nextIndex) ?? .complete
            delegate?.showTutorialStep(currentStep)
            
            if currentStep == .complete {
                // Give completion reward
                GameManager.shared.gameState.seeds += 10
                AchievementManager.shared.checkAchievements(gameState: GameManager.shared.gameState)
            }
        } else {
            completeTutorial()
        }
    }
    
    func completeTutorial() {
        hasCompletedTutorial = true
        delegate?.hideTutorial()
        delegate?.removeHighlight()
        
        // Award completion seeds if not already given
        if GameManager.shared.gameState.seeds < 10 {
            GameManager.shared.gameState.seeds = 10
        }
        
        // Save game state
        GameManager.shared.saveGame()
    }
    
    func skipTutorial() {
        // Show confirmation dialog
        showSkipConfirmation()
    }
    
    private func showSkipConfirmation() {
        // This would normally use a proper alert, but for integration we'll just skip
        hasCompletedTutorial = true
        delegate?.hideTutorial()
        delegate?.removeHighlight()
        
        // Still give some starting resources
        GameManager.shared.gameState.seeds += 5
        GameManager.shared.saveGame()
    }
    
    func checkStepCompletion(_ action: String) {
        guard !hasCompletedTutorial else { return }
        
        switch currentStep {
        case .plantFirstSeed:
            if action == "plant_seed" {
                // Small delay to let the plant appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.nextStep()
                }
            }
        case .harvestPlant:
            if action == "harvest_plant" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.nextStep()
                }
            }
        case .buyUpgrade:
            if action == "buy_upgrade" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.nextStep()
                }
            }
        case .plantMultiple:
            if action == "plant_multiple" {
                // Check if player has planted at least 2 plants
                let plantedCount = GameManager.shared.gameState.plants.filter { !$0.isEmpty }.count
                if plantedCount >= 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.nextStep()
                    }
                }
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
    
    func resetTutorial() {
        hasCompletedTutorial = false
        tutorialProgress = [:]
        currentStep = .welcome
    }
    
    // Check if specific step was completed
    func isStepCompleted(_ step: TutorialStep) -> Bool {
        return tutorialProgress[String(step.rawValue)] ?? false
    }
}

// MARK: - Tutorial UI

class TutorialOverlay: SKNode {
    
    weak var delegate: TutorialManagerDelegate?
    private var background: SKSpriteNode?
    private var cardBackground: SKShapeNode?
    private var titleLabel: SKLabelNode?
    private var messageLabel: SKLabelNode?
    private var nextButton: SKSpriteNode?
    private var skipButton: SKSpriteNode?
    private var highlightNode: SKShapeNode?
    private var progressDots: [SKShapeNode] = []
    
    private let cardSize = CGSize(width: 320, height: 280)
    
    func showTutorialStep(_ step: TutorialStep) {
        removeAllChildren()
        
        // Semi-transparent background
        background = SKSpriteNode(color: .black, size: CGSize(width: 2000, height: 2000))
        background?.alpha = 0.7
        background?.position = CGPoint.zero
        background?.zPosition = 0
        addChild(background!)
        
        // Tutorial card with rounded corners
        cardBackground = SKShapeNode(rectOf: cardSize, cornerRadius: 20)
        cardBackground?.fillColor = .white
        cardBackground?.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
        cardBackground?.lineWidth = 3
        cardBackground?.position = CGPoint(x: 0, y: 0)
        cardBackground?.zPosition = 10
        addChild(cardBackground!)
        
        // Title with icon
        titleLabel = SKLabelNode(text: step.title)
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 20
        titleLabel?.fontColor = .black
        titleLabel?.position = CGPoint(x: 0, y: 80)
        titleLabel?.zPosition = 11
        addChild(titleLabel!)
        
        // Message with word wrap
        createMessageLabel(step.message)
        
        // Progress dots
        createProgressDots(currentStep: step)
        
        // Buttons
        createButtons(step: step)
        
        // Entrance animation
        alpha = 0
        setScale(0.8)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let group = SKAction.group([fadeIn, scaleUp])
        run(group)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func createMessageLabel(_ message: String) {
        // Create multi-line message
        let maxWidth: CGFloat = cardSize.width - 40
        let words = message.split(separator: " ")
        var lines: [String] = []
        var currentLine = ""
        
        for word in words {
            let testLine = currentLine.isEmpty ? String(word) : currentLine + " " + String(word)
            
            // Estimate line width (rough approximation)
            if testLine.count * 8 > Int(maxWidth) && !currentLine.isEmpty {
                lines.append(currentLine)
                currentLine = String(word)
            } else {
                currentLine = testLine
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        // Create labels for each line
        let lineHeight: CGFloat = 18
        let totalHeight = CGFloat(lines.count) * lineHeight
        let startY: CGFloat = totalHeight / 2
        
        for (index, line) in lines.enumerated() {
            let lineLabel = SKLabelNode(text: line)
            lineLabel.fontName = "AvenirNext-Regular"
            lineLabel.fontSize = 14
            lineLabel.fontColor = .darkGray
            lineLabel.position = CGPoint(x: 0, y: startY - CGFloat(index) * lineHeight)
            lineLabel.zPosition = 11
            lineLabel.numberOfLines = 0
            addChild(lineLabel)
        }
    }
    
    private func createProgressDots(currentStep: TutorialStep) {
        progressDots.removeAll()
        let totalSteps = TutorialStep.allCases.count - 1 // Exclude complete step
        let dotSize: CGFloat = 8
        let spacing: CGFloat = 16
        let totalWidth = CGFloat(totalSteps) * dotSize + CGFloat(totalSteps - 1) * spacing
        let startX = -totalWidth / 2
        
        for i in 0..<totalSteps {
            let dot = SKShapeNode(circleOfRadius: dotSize / 2)
            let isCompleted = i < currentStep.rawValue
            let isCurrent = i == currentStep.rawValue
            
            if isCompleted {
                dot.fillColor = .systemGreen
                dot.strokeColor = .systemGreen
            } else if isCurrent {
                dot.fillColor = .systemBlue
                dot.strokeColor = .systemBlue
            } else {
                dot.fillColor = .systemGray3
                dot.strokeColor = .systemGray3
            }
            
            dot.position = CGPoint(x: startX + CGFloat(i) * (dotSize + spacing), y: -80)
            dot.zPosition = 11
            addChild(dot)
            progressDots.append(dot)
        }
    }
    
    private func createButtons(step: TutorialStep) {
        // Next/Complete button
        nextButton = SKSpriteNode(color: .systemBlue, size: CGSize(width: 120, height: 40))
        nextButton?.position = CGPoint(x: 0, y: -115)
        nextButton?.zPosition = 11
        nextButton?.name = "nextButton"
        addChild(nextButton!)
        
        let nextShape = SKShapeNode(rectOf: nextButton!.size, cornerRadius: 12)
        nextShape.fillColor = .systemBlue
        nextShape.strokeColor = .clear
        nextShape.position = CGPoint.zero
        nextButton?.addChild(nextShape)
        
        let nextLabel = SKLabelNode(text: step.buttonText)
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontSize = 16
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint.zero
        nextLabel.zPosition = 1
        nextButton?.addChild(nextLabel)
        
        // Skip button (except on complete step)
        if step != .complete {
            skipButton = SKSpriteNode(color: .systemGray, size: CGSize(width: 80, height: 30))
            skipButton?.position = CGPoint(x: 0, y: -150)
            skipButton?.zPosition = 11
            skipButton?.name = "skipButton"
            addChild(skipButton!)
            
            let skipShape = SKShapeNode(rectOf: skipButton!.size, cornerRadius: 8)
            skipShape.fillColor = .systemGray
            skipShape.strokeColor = .clear
            skipShape.position = CGPoint.zero
            skipButton?.addChild(skipShape)
            
            let skipLabel = SKLabelNode(text: "Skip Tutorial")
            skipLabel.fontName = "AvenirNext-Regular"
            skipLabel.fontSize = 12
            skipLabel.fontColor = .white
            skipLabel.position = CGPoint.zero
            skipLabel.zPosition = 1
            skipButton?.addChild(skipLabel)
        }
    }
    
    func hide() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.run { [weak self] in
            self?.removeAllChildren()
            self?.isUserInteractionEnabled = false
        }
        let sequence = SKAction.sequence([group, remove])
        run(sequence)
        
        removeHighlight()
    }
    
    func highlightElement(_ elementName: String) {
        // Remove previous highlight
        highlightNode?.removeFromParent()
        
        // Create highlight effect based on element type
        var highlightSize = CGSize(width: 100, height: 100)
        var highlightColor = UIColor.systemYellow
        
        switch elementName {
        case "garden_plot":
            highlightSize = CGSize(width: 90, height: 90)
            highlightColor = .systemGreen
        case "ready_plant":
            highlightSize = CGSize(width: 90, height: 90)
            highlightColor = .systemYellow
        case "upgrade_button":
            highlightSize = CGSize(width: 80, height: 80)
            highlightColor = .systemBlue
        case "plant_button":
            highlightSize = CGSize(width: 80, height: 80)
            highlightColor = .systemGreen
        default:
            break
        }
        
        highlightNode = SKShapeNode(rectOf: highlightSize, cornerRadius: 10)
        highlightNode?.strokeColor = highlightColor
        highlightNode?.fillColor = .clear
        highlightNode?.lineWidth = 4
        highlightNode?.position = CGPoint(x: 0, y: -200) // Position would be set by delegate
        highlightNode?.zPosition = 5
        highlightNode?.alpha = 0.8
        
        // Add pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        highlightNode?.run(SKAction.repeatForever(pulse))
        
        // Add glow effect
        let fadeIn = SKAction.fadeIn(withDuration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let glow = SKAction.sequence([fadeIn, fadeOut])
        highlightNode?.run(SKAction.repeatForever(glow))
        
        addChild(highlightNode!)
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
                // Add button feedback
                node.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])) {
                    TutorialManager.shared.nextStep()
                }
                return
            } else if node.name == "skipButton" {
                // Add button feedback
                node.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])) {
                    TutorialManager.shared.skipTutorial()
                }
                return
            }
        }
    }
}