//
//  UIComponents.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import SpriteKit
import UIKit

// MARK: - Garden Plot

protocol GardenPlotDelegate: AnyObject {
    func gardenPlotTapped(_ plot: GardenPlot)
}

class GardenPlot: SKSpriteNode {
    
    weak var delegate: GardenPlotDelegate?
    var plotIndex: Int = 0
    
    private var plantSprite: SKSpriteNode?
    private var progressBar: SKSpriteNode?
    private var progressBackground: SKSpriteNode?
    private var timeLabel: SKLabelNode?
    private var nameLabel: SKLabelNode?
    private var plantData: PlantData?
    
    var hasPlant: Bool {
        guard let data = plantData else { return false }
        return !data.typeId.isEmpty && data.level > 0
    }
    
    var isReady: Bool {
        return plantData?.isReady ?? false
    }
    
    init(size: CGSize) {
        super.init(texture: nil, color: .systemBrown, size: size)
        setupPlot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPlot()
    }
    
    private func setupPlot() {
        // Add border
        let border = SKShapeNode(rectOf: size)
        border.strokeColor = UIColor.gardenDarkBrown
        border.lineWidth = 2
        border.position = CGPoint.zero
        border.zPosition = 1
        addChild(border)
        
        // Add soil texture
        let soil = SKSpriteNode(color: UIColor.systemBrown.withAlphaComponent(0.7), size: CGSize(width: size.width - 4, height: size.height - 4))
        soil.position = CGPoint.zero
        soil.zPosition = 0
        addChild(soil)
        
        // Setup progress bar
        setupProgressBar()
        
        // Setup time label
        setupTimeLabel()
        
        // Add empty plot indicator
        let emptyLabel = SKLabelNode(text: "+")
        emptyLabel.fontName = "AvenirNext-Bold"
        emptyLabel.fontSize = 32
        emptyLabel.fontColor = UIColor.systemGray.withAlphaComponent(0.6)
        emptyLabel.position = CGPoint.zero
        emptyLabel.zPosition = 2
        emptyLabel.name = "emptyLabel"
        addChild(emptyLabel)
    }
    
    private func setupProgressBar() {
        let barWidth = size.width - 8
        let barHeight: CGFloat = 6
        
        // Progress background
        progressBackground = SKSpriteNode(color: UIColor.systemGray.withAlphaComponent(0.3), size: CGSize(width: barWidth, height: barHeight))
        progressBackground?.position = CGPoint(x: 0, y: -size.height/2 + 12)
        progressBackground?.zPosition = 1
        addChild(progressBackground!)
        
        // Progress bar
        progressBar = SKSpriteNode(color: .systemGreen, size: CGSize(width: 0, height: barHeight))
        progressBar?.position = CGPoint(x: -barWidth/2, y: -size.height/2 + 12)
        progressBar?.anchorPoint = CGPoint(x: 0, y: 0.5)
        progressBar?.zPosition = 2
        addChild(progressBar!)
        
        // Initially hide progress bars
        progressBackground?.isHidden = true
        progressBar?.isHidden = true
    }
    
    private func setupTimeLabel() {
        timeLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        timeLabel?.fontSize = 10
        timeLabel?.fontColor = .white
        timeLabel?.position = CGPoint(x: 0, y: size.height/2 - 15)
        timeLabel?.zPosition = 3
        timeLabel?.isHidden = true
        addChild(timeLabel!)
    }
    
    func setPlant(_ data: PlantData) {
        // Only set plant if it's not empty
        guard !data.typeId.isEmpty && data.level > 0 else {
            clearPlant()
            return
        }
        
        plantData = data
        
        // Hide empty label
        childNode(withName: "emptyLabel")?.isHidden = true
        
        // Create plant sprite
        if let plantType = data.plantType {
            // Remove old plant sprite
            plantSprite?.removeFromParent()
            
            plantSprite = SKSpriteNode(color: plantType.rarity.color, size: CGSize(width: 50, height: 50))
            plantSprite?.position = CGPoint.zero
            plantSprite?.zPosition = 3
            addChild(plantSprite!)
            
            // Add plant icon/emoji based on type
            let iconLabel = SKLabelNode(text: getPlantIcon(plantType.id))
            iconLabel.fontSize = 24
            iconLabel.position = CGPoint.zero
            iconLabel.zPosition = 1
            plantSprite?.addChild(iconLabel)
            
            // Add plant name label
            if nameLabel == nil {
                nameLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
                nameLabel?.fontSize = 8
                nameLabel?.fontColor = .white
                nameLabel?.position = CGPoint(x: 0, y: -size.height/2 - 12)
                nameLabel?.zPosition = 3
                addChild(nameLabel!)
            }
            nameLabel?.text = plantType.name
            nameLabel?.isHidden = false
            
            // Show progress elements
            progressBackground?.isHidden = false
            progressBar?.isHidden = false
            timeLabel?.isHidden = false
        }
        
        updatePlant()
    }
    
    private func getPlantIcon(_ plantId: String) -> String {
        switch plantId {
        case "carrot": return "🥕"
        case "tomato": return "🍅"
        case "flower", "sunflower": return "🌻"
        case "magic_flower": return "🌺"
        case "golden_fruit": return "🥇"
        case "crystal_rose": return "🌹"
        case "dragon_fruit": return "🐲"
        case "phoenix_flower": return "🔥"
        case "star_plant": return "⭐"
        case "eternal_tree": return "🌳"
        default: return "🌱"
        }
    }
    
    func updatePlant() {
        guard let data = plantData, 
              !data.typeId.isEmpty, 
              data.level > 0,
              let plantType = data.plantType else { 
            return 
        }
        
        // Sync with GameManager's plant data to get the latest state
        if plotIndex >= 0 && plotIndex < GameManager.shared.gameState.plants.count {
            let gameManagerPlant = GameManager.shared.gameState.plants[plotIndex]
            if !gameManagerPlant.typeId.isEmpty && gameManagerPlant.level > 0 {
                plantData = gameManagerPlant
            }
        }
        
        let progress = data.progressPercentage
        let timeRemaining = data.timeUntilReady
        
        // Update progress bar
        let barWidth = size.width - 8
        progressBar?.size.width = barWidth * CGFloat(min(1.0, max(0.0, progress)))
        
        // Update time label and plant appearance
        if data.isReady {
            timeLabel?.text = "Ready!"
            timeLabel?.fontColor = .systemYellow
            progressBar?.color = .systemYellow
            
            // Add a pulsing animation for ready plants
            if plantSprite?.action(forKey: "pulse") == nil {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                plantSprite?.run(SKAction.repeatForever(pulse), withKey: "pulse")
            }
            
            // Add glow effect
            plantSprite?.color = .systemYellow
            plantSprite?.colorBlendFactor = 0.3
        } else {
            timeLabel?.text = GameManager.shared.formatTime(timeRemaining)
            timeLabel?.fontColor = .white
            progressBar?.color = .systemGreen
            plantSprite?.removeAction(forKey: "pulse")
            
            // Remove glow effect
            plantSprite?.color = plantType.rarity.color
            plantSprite?.colorBlendFactor = 0.0
        }
    }
    
    func harvestPlant() {
        // Add harvest animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        run(sequence)
        
        // Add particle effect for harvest
        addHarvestEffect()
        
        // Update plant data from GameManager to stay in sync
        if plotIndex >= 0 && plotIndex < GameManager.shared.gameState.plants.count {
            let updatedPlantData = GameManager.shared.gameState.plants[plotIndex]
            if !updatedPlantData.typeId.isEmpty && updatedPlantData.level > 0 {
                plantData = updatedPlantData
            }
        }
        
        updatePlant()
    }
    
    private func addHarvestEffect() {
        // Create simple particle effect
        for _ in 0..<5 {
            let particle = SKLabelNode(text: "✨")
            particle.fontSize = 16
            particle.position = position
            particle.zPosition = 10
            
            let randomX = CGFloat.random(in: -30...30)
            let randomY = CGFloat.random(in: 10...40)
            
            let move = SKAction.moveBy(x: randomX, y: randomY, duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.8)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([group, remove])
            
            parent?.addChild(particle)
            particle.run(sequence)
        }
    }
    
    func clearPlant() {
        plantSprite?.removeFromParent()
        plantSprite = nil
        plantData = nil
        
        // Reset progress bar
        progressBar?.size.width = 0
        progressBackground?.isHidden = true
        progressBar?.isHidden = true
        
        // Clear labels
        timeLabel?.text = ""
        timeLabel?.isHidden = true
        nameLabel?.isHidden = true
        
        // Show empty indicator
        childNode(withName: "emptyLabel")?.isHidden = false
    }
    
    func handleTouch() {
        // Add touch feedback
        let touchFeedback = SKAction.sequence([
            SKAction.scale(to: 0.95, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        run(touchFeedback)
        
        delegate?.gardenPlotTapped(self)
    }
    
    func update(_ currentTime: TimeInterval) {
        // Only update if we have a plant
        if hasPlant {
            updatePlant()
        }
    }
}

// MARK: - Top Bar

protocol TopBarDelegate: AnyObject {
    func settingsButtonTapped()
    func prestigeButtonTapped()
}

class TopBarNode: SKSpriteNode {
    
    weak var delegate: TopBarDelegate?
    
    private var gpLabel: SKLabelNode?
    private var seedsLabel: SKLabelNode?
    private var settingsButton: SKSpriteNode?
    private var prestigeButton: SKSpriteNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: UIColor.systemGreen.withAlphaComponent(0.8), size: size)
        setupTopBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTopBar()
    }
    
    private func setupTopBar() {
        // GP Icon and Label
        let gpIcon = SKLabelNode(text: "🌿")
        gpIcon.fontSize = 20
        gpIcon.position = CGPoint(x: -size.width/2 + 30, y: 10)
        addChild(gpIcon)
        
        gpLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gpLabel?.fontSize = 18
        gpLabel?.fontColor = .white
        gpLabel?.horizontalAlignmentMode = .left
        gpLabel?.position = CGPoint(x: -size.width/2 + 55, y: 10)
        addChild(gpLabel!)
        
        // Seeds Icon and Label
        let seedsIcon = SKLabelNode(text: "🌰")
        seedsIcon.fontSize = 16
        seedsIcon.position = CGPoint(x: -size.width/2 + 30, y: -15)
        addChild(seedsIcon)
        
        seedsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        seedsLabel?.fontSize = 14
        seedsLabel?.fontColor = .systemYellow
        seedsLabel?.horizontalAlignmentMode = .left
        seedsLabel?.position = CGPoint(x: -size.width/2 + 55, y: -15)
        addChild(seedsLabel!)
        
        // Settings Button
        settingsButton = SKSpriteNode(color: UIColor.systemGray.withAlphaComponent(0.8), size: CGSize(width: 44, height: 44))
        settingsButton?.position = CGPoint(x: size.width/2 - 30, y: 0)
        settingsButton?.name = "settingsButton"
        addChild(settingsButton!)
        
        let settingsIcon = SKLabelNode(text: "⚙️")
        settingsIcon.fontSize = 24
        settingsIcon.position = CGPoint.zero
        settingsButton?.addChild(settingsIcon)
        
        // Prestige Button
        prestigeButton = SKSpriteNode(color: UIColor.systemPurple.withAlphaComponent(0.8), size: CGSize(width: 80, height: 44))
        prestigeButton?.position = CGPoint(x: size.width/2 - 100, y: 0)
        prestigeButton?.name = "prestigeButton"
        addChild(prestigeButton!)
        
        let prestigeLabel = SKLabelNode(text: "🔄 Rebirth")
        prestigeLabel.fontName = "AvenirNext-Bold"
        prestigeLabel.fontSize = 12
        prestigeLabel.fontColor = .white
        prestigeLabel.position = CGPoint.zero
        prestigeButton?.addChild(prestigeLabel)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    func updateGP(_ gp: Int) {
        gpLabel?.text = "\(GameManager.shared.formatNumber(gp))"
    }
    
    func updateSeeds(_ seeds: Int) {
        seedsLabel?.text = "\(seeds)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if settingsButton?.contains(location) == true {
            // Add button feedback
            settingsButton?.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            delegate?.settingsButtonTapped()
        } else if prestigeButton?.contains(location) == true {
            // Add button feedback
            prestigeButton?.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            delegate?.prestigeButtonTapped()
        }
    }
}

// MARK: - Bottom Toolbar

protocol BottomToolbarDelegate: AnyObject {
    func plantButtonTapped()
    func upgradeButtonTapped()
    func achievementsButtonTapped()
}

class BottomToolbarNode: SKSpriteNode {
    
    weak var delegate: BottomToolbarDelegate?
    
    private var plantButton: SKSpriteNode?
    private var upgradeButton: SKSpriteNode?
    private var achievementsButton: SKSpriteNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: UIColor.systemGreen.withAlphaComponent(0.8), size: size)
        setupToolbar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupToolbar()
    }
    
    private func setupToolbar() {
        let buttonSize = CGSize(width: 70, height: 70)
        let buttonSpacing = size.width / 4
        
        // Plant Button
        plantButton = createToolbarButton(
            color: .systemGreen,
            icon: "🌱",
            text: "Plant",
            position: CGPoint(x: -buttonSpacing, y: 0),
            name: "plantButton"
        )
        addChild(plantButton!)
        
        // Upgrade Button
        upgradeButton = createToolbarButton(
            color: .systemBlue,
            icon: "⚡",
            text: "Upgrade",
            position: CGPoint(x: 0, y: 0),
            name: "upgradeButton"
        )
        addChild(upgradeButton!)
        
        // Achievements Button
        achievementsButton = createToolbarButton(
            color: .systemOrange,
            icon: "🏆",
            text: "Achievements",
            position: CGPoint(x: buttonSpacing, y: 0),
            name: "achievementsButton"
        )
        addChild(achievementsButton!)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func createToolbarButton(color: UIColor, icon: String, text: String, position: CGPoint, name: String) -> SKSpriteNode {
        let button = SKSpriteNode(color: color.withAlphaComponent(0.8), size: CGSize(width: 70, height: 70))
        button.position = position
        button.name = name
        
        // Add corner radius effect with shape
        let roundedShape = SKShapeNode(rectOf: button.size, cornerRadius: 10)
        roundedShape.fillColor = color.withAlphaComponent(0.8)
        roundedShape.strokeColor = .clear
        roundedShape.position = CGPoint.zero
        button.addChild(roundedShape)
        
        // Icon
        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 28
        iconLabel.position = CGPoint(x: 0, y: 8)
        iconLabel.zPosition = 1
        button.addChild(iconLabel)
        
        // Text
        let textLabel = SKLabelNode(text: text)
        textLabel.fontName = "AvenirNext-Regular"
        textLabel.fontSize = 10
        textLabel.fontColor = .white
        textLabel.position = CGPoint(x: 0, y: -25)
        textLabel.zPosition = 1
        button.addChild(textLabel)
        
        return button
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check which button was tapped and add feedback
        if plantButton?.contains(location) == true {
            addButtonFeedback(plantButton!)
            delegate?.plantButtonTapped()
        } else if upgradeButton?.contains(location) == true {
            addButtonFeedback(upgradeButton!)
            delegate?.upgradeButtonTapped()
        } else if achievementsButton?.contains(location) == true {
            addButtonFeedback(achievementsButton!)
            delegate?.achievementsButtonTapped()
        }
    }
    
    private func addButtonFeedback(_ button: SKSpriteNode) {
        button.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }
}

// MARK: - Plant Shop

protocol PlantShopDelegate: AnyObject {
    func plantSelected(_ plantType: PlantType)
    func plantShopClosed()
}

class PlantShopNode: SKSpriteNode {
    
    weak var delegate: PlantShopDelegate?
    private var scrollView: SKNode?
    private var closeButton: SKSpriteNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: .white, size: size)
        setupPlantShop()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPlantShop()
    }
    
    private func setupPlantShop() {
        // Add rounded corners
        let background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = .white
        background.strokeColor = UIColor.systemGray.withAlphaComponent(0.3)
        background.lineWidth = 2
        background.position = CGPoint.zero
        addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(text: "🌱 Plant Shop")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 40)
        addChild(titleLabel)
        
        // Close button
        closeButton = SKSpriteNode(color: .systemRed, size: CGSize(width: 44, height: 44))
        closeButton?.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton?.name = "closeButton"
        addChild(closeButton!)
        
        let closeIcon = SKLabelNode(text: "✕")
        closeIcon.fontSize = 20
        closeIcon.fontColor = .white
        closeIcon.position = CGPoint.zero
        closeButton?.addChild(closeIcon)
        
        // Plant list
        setupPlantList()
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func setupPlantList() {
        scrollView = SKNode()
        scrollView?.position = CGPoint(x: 0, y: size.height/2 - 100)
        addChild(scrollView!)
        
        let availablePlants = GameData.shared.getAvailablePlants(for: GameManager.shared.gameState.gardenPoints)
        let buttonHeight: CGFloat = 70
        let spacing: CGFloat = 10
        
        for (index, plantType) in availablePlants.enumerated() {
            let button = createPlantButton(plantType)
            button.position = CGPoint(x: 0, y: -CGFloat(index) * (buttonHeight + spacing))
            button.name = "plant_\(plantType.id)"
            scrollView?.addChild(button)
        }
    }
    
    private func createPlantButton(_ plantType: PlantType) -> SKSpriteNode {
        let button = SKSpriteNode(color: plantType.rarity.color.withAlphaComponent(0.8), size: CGSize(width: size.width - 60, height: 70))
        
        // Add rounded corners
        let shape = SKShapeNode(rectOf: button.size, cornerRadius: 10)
        shape.fillColor = plantType.rarity.color.withAlphaComponent(0.8)
        shape.strokeColor = .clear
        shape.position = CGPoint.zero
        button.addChild(shape)
        
        // Plant icon
        let icon = SKLabelNode(text: getPlantIcon(plantType.id))
        icon.fontSize = 32
        icon.position = CGPoint(x: -button.size.width/2 + 40, y: 0)
        icon.zPosition = 1
        button.addChild(icon)
        
        // Plant info container
        let infoContainer = SKNode()
        infoContainer.position = CGPoint(x: -button.size.width/2 + 80, y: 0)
        infoContainer.zPosition = 1
        button.addChild(infoContainer)
        
        // Plant name
        let nameLabel = SKLabelNode(text: plantType.name)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: 0, y: 15)
        infoContainer.addChild(nameLabel)
        
        // Rarity
        let rarityLabel = SKLabelNode(text: plantType.rarity.rawValue)
        rarityLabel.fontName = "AvenirNext-Regular"
        rarityLabel.fontSize = 12
        rarityLabel.fontColor = .white
        rarityLabel.horizontalAlignmentMode = .left
        rarityLabel.position = CGPoint(x: 0, y: 0)
        infoContainer.addChild(rarityLabel)
        
        // Growth time
        let timeLabel = SKLabelNode(text: "⏱ \(GameManager.shared.formatTime(plantType.growthTime))")
        timeLabel.fontName = "AvenirNext-Regular"
        timeLabel.fontSize = 10
        timeLabel.fontColor = .white
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: 0, y: -15)
        infoContainer.addChild(timeLabel)
        
        // GP per hour - right side
        let gpLabel = SKLabelNode(text: "\(GameManager.shared.formatNumber(plantType.gpPerHour))\nGP/h")
        gpLabel.fontName = "AvenirNext-Bold"
        gpLabel.fontSize = 12
        gpLabel.fontColor = .white
        gpLabel.numberOfLines = 2
        gpLabel.position = CGPoint(x: button.size.width/2 - 40, y: 0)
        gpLabel.zPosition = 1
        button.addChild(gpLabel)
        
        return button
    }
    
    private func getPlantIcon(_ plantId: String) -> String {
        switch plantId {
        case "carrot": return "🥕"
        case "tomato": return "🍅"
        case "flower", "sunflower": return "🌻"
        case "magic_flower": return "🌺"
        case "golden_fruit": return "🥇"
        case "crystal_rose": return "🌹"
        case "dragon_fruit": return "🐲"
        case "phoenix_flower": return "🔥"
        case "star_plant": return "⭐"
        case "eternal_tree": return "🌳"
        default: return "🌱"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if closeButton?.contains(location) == true {
            // Add button feedback
            closeButton?.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            delegate?.plantShopClosed()
        } else {
            // Check for plant selection
            let nodes = nodes(at: location)
            for node in nodes {
                if let name = node.name, name.hasPrefix("plant_") {
                    let plantId = String(name.dropFirst(6))
                    if let plantType = GameData.shared.getPlantType(by: plantId) {
                        // Add selection feedback
                        node.run(SKAction.sequence([
                            SKAction.scale(to: 0.95, duration: 0.1),
                            SKAction.scale(to: 1.0, duration: 0.1)
                        ]))
                        delegate?.plantSelected(plantType)
                        return
                    }
                }
            }
        }
    }
}

// MARK: - Upgrade Menu

protocol UpgradeMenuDelegate: AnyObject {
    func upgradePurchased(_ upgradeType: UpgradeType)
    func upgradeMenuClosed()
}

class UpgradeMenuNode: SKSpriteNode {
    
    weak var delegate: UpgradeMenuDelegate?
    private var closeButton: SKSpriteNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: .white, size: size)
        setupUpgradeMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUpgradeMenu()
    }
    
    private func setupUpgradeMenu() {
        // Add rounded corners
        let background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = .white
        background.strokeColor = UIColor.systemGray.withAlphaComponent(0.3)
        background.lineWidth = 2
        background.position = CGPoint.zero
        addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(text: "⚡ Upgrades")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 40)
        addChild(titleLabel)
        
        // Close button
        closeButton = SKSpriteNode(color: .systemRed, size: CGSize(width: 44, height: 44))
        closeButton?.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton?.name = "closeButton"
        addChild(closeButton!)
        
        let closeIcon = SKLabelNode(text: "✕")
        closeIcon.fontSize = 20
        closeIcon.fontColor = .white
        closeIcon.position = CGPoint.zero
        closeButton?.addChild(closeIcon)
        
        // Upgrade list
        setupUpgradeList()
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func setupUpgradeList() {
        let buttonHeight: CGFloat = 90
        let spacing: CGFloat = 15
        let startY = size.height/2 - 100
        
        for (index, upgradeType) in UpgradeType.allCases.enumerated() {
            let button = createUpgradeButton(upgradeType)
            button.position = CGPoint(x: 0, y: startY - CGFloat(index) * (buttonHeight + spacing))
            button.name = "upgrade_\(upgradeType.rawValue)"
            addChild(button)
        }
    }
    
    private func createUpgradeButton(_ upgradeType: UpgradeType) -> SKSpriteNode {
        let currentLevel = GameManager.shared.getUpgradeLevel(upgradeType)
        let canAfford = GameManager.shared.canAffordUpgrade(upgradeType)
        let maxLevel = currentLevel >= upgradeType.maxLevel
        
        let buttonColor: UIColor = maxLevel ? .systemGray : (canAfford ? .systemBlue : .systemRed)
        
        let button = SKSpriteNode(color: buttonColor.withAlphaComponent(0.8), size: CGSize(width: size.width - 60, height: 90))
        
        // Add rounded corners
        let shape = SKShapeNode(rectOf: button.size, cornerRadius: 15)
        shape.fillColor = buttonColor.withAlphaComponent(0.8)
        shape.strokeColor = .clear
        shape.position = CGPoint.zero
        button.addChild(shape)
        
        // Upgrade icon
        let icon = getUpgradeIcon(upgradeType)
        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 32
        iconLabel.position = CGPoint(x: -button.size.width/2 + 40, y: 0)
        iconLabel.zPosition = 1
        button.addChild(iconLabel)
        
        // Info container
        let infoContainer = SKNode()
        infoContainer.position = CGPoint(x: -button.size.width/2 + 80, y: 0)
        infoContainer.zPosition = 1
        button.addChild(infoContainer)
        
        // Upgrade name
        let nameLabel = SKLabelNode(text: upgradeType.rawValue)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: 0, y: 20)
        infoContainer.addChild(nameLabel)
        
        // Current level
        let levelText = maxLevel ? "MAX LEVEL" : "Level: \(currentLevel)/\(upgradeType.maxLevel)"
        let levelLabel = SKLabelNode(text: levelText)
        levelLabel.fontName = "AvenirNext-Regular"
        levelLabel.fontSize = 14
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: 0, y: 0)
        infoContainer.addChild(levelLabel)
        
        // Cost or status
        if maxLevel {
            let maxLabel = SKLabelNode(text: "Fully Upgraded!")
            maxLabel.fontName = "AvenirNext-Bold"
            maxLabel.fontSize = 12
            maxLabel.fontColor = .systemYellow
            maxLabel.horizontalAlignmentMode = .left
            maxLabel.position = CGPoint(x: 0, y: -20)
            infoContainer.addChild(maxLabel)
        } else {
            let cost = GameManager.shared.calculateUpgradeCost(upgradeType, level: currentLevel)
            let costLabel = SKLabelNode(text: "🌿 \(GameManager.shared.formatNumber(cost))")
            costLabel.fontName = "AvenirNext-Regular"
            costLabel.fontSize = 12
            costLabel.fontColor = canAfford ? .white : .systemRed
            costLabel.horizontalAlignmentMode = .left
            costLabel.position = CGPoint(x: 0, y: -20)
            infoContainer.addChild(costLabel)
        }
        
        // Buy button
        if !maxLevel {
            let buyButton = SKSpriteNode(color: canAfford ? .systemGreen : .systemGray, 
                                       size: CGSize(width: 60, height: 35))
            buyButton.position = CGPoint(x: button.size.width/2 - 40, y: 0)
            buyButton.name = "buy_\(upgradeType.rawValue)"
            buyButton.zPosition = 1
            button.addChild(buyButton)
            
            let buyShape = SKShapeNode(rectOf: buyButton.size, cornerRadius: 8)
            buyShape.fillColor = canAfford ? .systemGreen : .systemGray
            buyShape.strokeColor = .clear
            buyShape.position = CGPoint.zero
            buyButton.addChild(buyShape)
            
            let buyLabel = SKLabelNode(text: canAfford ? "BUY" : "NEED GP")
            buyLabel.fontName = "AvenirNext-Bold"
            buyLabel.fontSize = 12
            buyLabel.fontColor = .white
            buyLabel.position = CGPoint.zero
            buyLabel.zPosition = 1
            buyButton.addChild(buyLabel)
        }
        
        return button
    }
    
    private func getUpgradeIcon(_ upgradeType: UpgradeType) -> String {
        switch upgradeType {
        case .plantSpeed: return "🏃‍♂️"
        case .gpMultiplier: return "💰"
        case .gardenPlots: return "🏡"
        case .autoHarvest: return "🤖"
        case .offlineEfficiency: return "😴"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if closeButton?.contains(location) == true {
            closeButton?.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            delegate?.upgradeMenuClosed()
        } else {
            // Check for upgrade purchase
            let nodes = nodes(at: location)
            for node in nodes {
                if let name = node.name, name.hasPrefix("buy_") {
                    let upgradeName = String(name.dropFirst(4))
                    if let upgradeType = UpgradeType(rawValue: upgradeName) {
                        // Add purchase feedback
                        node.run(SKAction.sequence([
                            SKAction.scale(to: 0.9, duration: 0.1),
                            SKAction.scale(to: 1.0, duration: 0.1)
                        ]))
                        delegate?.upgradePurchased(upgradeType)
                        
                        // Refresh the upgrade list to show new state
                        refreshUpgradeList()
                        return
                    }
                }
            }
        }
    }
    
    private func refreshUpgradeList() {
        // Remove old upgrade buttons
        children.forEach { child in
            if let name = child.name, name.hasPrefix("upgrade_") {
                child.removeFromParent()
            }
        }
        
        // Recreate upgrade list
        setupUpgradeList()
    }
}

// MARK: - Settings Menu

protocol SettingsMenuDelegate: AnyObject {
    func settingsMenuClosed()
    func resetGameTapped()
    func toggleSoundTapped()
    func toggleNotificationsTapped()
}

class SettingsMenuNode: SKSpriteNode {
    
    weak var delegate: SettingsMenuDelegate?
    
    private var titleLabel: SKLabelNode?
    private var closeButton: SKSpriteNode?
    private var resetButton: SKSpriteNode?
    private var soundButton: SKSpriteNode?
    private var notificationsButton: SKSpriteNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: UIColor.systemGray.withAlphaComponent(0.95), size: size)
        setupSettingsMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSettingsMenu()
    }
    
    private func setupSettingsMenu() {
        // Add rounded corners
        let background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = UIColor.systemGray.withAlphaComponent(0.95)
        background.strokeColor = UIColor.systemGray.withAlphaComponent(0.3)
        background.lineWidth = 2
        background.position = CGPoint.zero
        addChild(background)
        
        // Title
        titleLabel = SKLabelNode(text: "⚙️ Settings")
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 24
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: 0, y: size.height/2 - 40)
        addChild(titleLabel!)
        
        // Close button
        closeButton = SKSpriteNode(color: .systemRed, size: CGSize(width: 44, height: 44))
        closeButton?.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton?.name = "closeButton"
        addChild(closeButton!)
        
        let closeLabel = SKLabelNode(text: "✕")
        closeLabel.fontSize = 20
        closeLabel.fontColor = .white
        closeLabel.position = CGPoint.zero
        closeButton?.addChild(closeLabel)
        
        // Create menu buttons
        createSettingsButtons()
        
        isUserInteractionEnabled = true
    }
    
    private func createSettingsButtons() {
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 20
        
        // Sound Toggle Button
        soundButton = createSettingsButton(
            text: "🔊 Sound: ON",
            color: .systemBlue,
            position: CGPoint(x: 0, y: 60),
            name: "soundButton"
        )
        addChild(soundButton!)
        
        // Notifications Toggle Button
        notificationsButton = createSettingsButton(
            text: "🔔 Notifications: ON",
            color: .systemBlue,
            position: CGPoint(x: 0, y: 0),
            name: "notificationsButton"
        )
        addChild(notificationsButton!)
        
        // Reset Game Button
        resetButton = createSettingsButton(
            text: "🔄 Reset Game",
            color: .systemRed,
            position: CGPoint(x: 0, y: -60),
            name: "resetButton"
        )
        addChild(resetButton!)
    }
    
    private func createSettingsButton(text: String, color: UIColor, position: CGPoint, name: String) -> SKSpriteNode {
        let button = SKSpriteNode(color: color.withAlphaComponent(0.8), size: CGSize(width: 220, height: 50))
        button.position = position
        button.name = name
        
        // Add rounded corners
        let shape = SKShapeNode(rectOf: button.size, cornerRadius: 12)
        shape.fillColor = color.withAlphaComponent(0.8)
        shape.strokeColor = .clear
        shape.position = CGPoint.zero
        button.addChild(shape)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 16
        label.fontColor = .white
        label.position = CGPoint.zero
        label.zPosition = 1
        label.name = "\(name)Label"
        button.addChild(label)
        
        return button
    }
    
    func handleTouch(_ location: CGPoint) {
        let touchedNode = atPoint(location)
        
        // Add feedback for button touches
        if let button = touchedNode.parent as? SKSpriteNode {
            button.run(SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }
        
        switch touchedNode.name {
        case "closeButton":
            delegate?.settingsMenuClosed()
        case "resetButton":
            delegate?.resetGameTapped()
        case "soundButton":
            delegate?.toggleSoundTapped()
            updateSoundLabel(true) // This would be dynamic based on actual sound state
        case "notificationsButton":
            delegate?.toggleNotificationsTapped()
            updateNotificationsLabel(true) // This would be dynamic based on actual notification state
        default:
            break
        }
    }
    
    func updateSoundLabel(_ isOn: Bool) {
        if let soundLabel = soundButton?.childNode(withName: "soundButtonLabel") as? SKLabelNode {
            soundLabel.text = "🔊 Sound: \(isOn ? "ON" : "OFF")"
        }
    }
    
    func updateNotificationsLabel(_ isOn: Bool) {
        if let notificationsLabel = notificationsButton?.childNode(withName: "notificationsButtonLabel") as? SKLabelNode {
            notificationsLabel.text = "🔔 Notifications: \(isOn ? "ON" : "OFF")"
        }
    }
}

// MARK: - Offline Progress

protocol OfflineProgressDelegate: AnyObject {
    func offlineProgressClaimed()
    func offlineProgressClosed()
}

class OfflineProgressNode: SKNode {
    
    weak var delegate: OfflineProgressDelegate?
    private var background: SKSpriteNode?
    private var isVisible = false
    
    func showOfflineProgress(_ progress: (gpEarned: Int, plantsReady: Int)) {
        guard !isVisible && (progress.gpEarned > 0 || progress.plantsReady > 0) else { return }
        isVisible = true
        
        // Background with rounded corners
        let bgShape = SKShapeNode(rectOf: CGSize(width: 320, height: 220), cornerRadius: 20)
        bgShape.fillColor = UIColor.systemPurple.withAlphaComponent(0.95)
        bgShape.strokeColor = .white
        bgShape.lineWidth = 3
        bgShape.position = CGPoint.zero
        addChild(bgShape)
        
        // Title
        let titleLabel = SKLabelNode(text: "🌙 Welcome Back!")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 70)
        addChild(titleLabel)
        
        // Progress info
        let gpLabel = SKLabelNode(text: "🌿 GP Earned: \(GameManager.shared.formatNumber(progress.gpEarned))")
        gpLabel.fontName = "AvenirNext-Regular"
        gpLabel.fontSize = 16
        gpLabel.fontColor = .systemYellow
        gpLabel.position = CGPoint(x: 0, y: 30)
        addChild(gpLabel)
        
        let plantsLabel = SKLabelNode(text: "🌱 Plants Ready: \(progress.plantsReady)")
        plantsLabel.fontName = "AvenirNext-Regular"
        plantsLabel.fontSize = 16
        plantsLabel.fontColor = .systemGreen
        plantsLabel.position = CGPoint(x: 0, y: 0)
        addChild(plantsLabel)
        
        // Claim button
        let claimButton = SKSpriteNode(color: .systemGreen, size: CGSize(width: 140, height: 45))
        claimButton.position = CGPoint(x: 0, y: -50)
        claimButton.name = "claimButton"
        addChild(claimButton)
        
        let claimShape = SKShapeNode(rectOf: claimButton.size, cornerRadius: 12)
        claimShape.fillColor = .systemGreen
        claimShape.strokeColor = .clear
        claimShape.position = CGPoint.zero
        claimButton.addChild(claimShape)
        
        let claimLabel = SKLabelNode(text: "🎁 CLAIM")
        claimLabel.fontName = "AvenirNext-Bold"
        claimLabel.fontSize = 18
        claimLabel.fontColor = .white
        claimLabel.position = CGPoint.zero
        claimLabel.zPosition = 1
        claimButton.addChild(claimLabel)
        
        // Add entrance animation
        alpha = 0
        setScale(0.8)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let group = SKAction.group([fadeIn, scaleUp])
        run(group)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    func hide() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.run { [weak self] in
            self?.removeAllChildren()
            self?.isVisible = false
            self?.isUserInteractionEnabled = false
        }
        let sequence = SKAction.sequence([group, remove])
        run(sequence)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "claimButton" {
                // Add button feedback
                node.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                delegate?.offlineProgressClaimed()
                return
            }
        }
        
        // Tap anywhere else to close
        delegate?.offlineProgressClosed()
    }
}

// MARK: - Color Extensions

extension UIColor {
    static let gardenDarkGreen = UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
    static let gardenDarkBrown = UIColor(red: 0.4, green: 0.2, blue: 0.0, alpha: 1.0)
}