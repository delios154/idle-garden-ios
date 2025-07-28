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
    private var timeLabel: SKLabelNode?
    private var plantData: PlantData?
    
    var hasPlant: Bool {
        return plantData != nil && !plantData!.typeId.isEmpty && plantData!.level > 0
    }
    
    var isReady: Bool {
        return plantData?.isReady ?? false
    }
    
    init(size: CGSize) {
        super.init(texture: nil, color: .brown, size: size)
        setupPlot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPlot()
    }
    
    private func setupPlot() {
        // Add border
        let border = SKShapeNode(rectOf: size)
        border.strokeColor = .darkBrown
        border.lineWidth = 2
        border.position = CGPoint.zero
        addChild(border)
        
        // Add soil texture
        let soil = SKSpriteNode(color: .brown, size: CGSize(width: size.width - 4, height: size.height - 4))
        soil.position = CGPoint.zero
        addChild(soil)
        
        // Setup progress bar
        setupProgressBar()
        
        // Setup time label
        setupTimeLabel()
    }
    
    private func setupProgressBar() {
        let barWidth = size.width - 8
        let barHeight: CGFloat = 4
        
        progressBar = SKSpriteNode(color: .green, size: CGSize(width: barWidth, height: barHeight))
        progressBar?.position = CGPoint(x: -size.width/2 + 4, y: -size.height/2 + 8) // Left aligned under the box
        progressBar?.anchorPoint = CGPoint(x: 0, y: 0.5)
        addChild(progressBar!)
    }
    
    private func setupTimeLabel() {
        timeLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        timeLabel?.fontSize = 12
        timeLabel?.fontColor = .white
        timeLabel?.position = CGPoint(x: 0, y: size.height/2 - 15)
        timeLabel?.zPosition = 1
        addChild(timeLabel!)
    }
    
    func setPlant(_ data: PlantData) {
        plantData = data
        
        // Create plant sprite
        if let plantType = data.plantType {
            plantSprite = SKSpriteNode(color: plantType.rarity.color, size: CGSize(width: 40, height: 40))
            plantSprite?.position = CGPoint.zero
            plantSprite?.zPosition = 1
            addChild(plantSprite!)
            
            // Add plant name label
            let nameLabel = SKLabelNode(text: plantType.name)
            nameLabel.fontName = "AvenirNext-Regular"
            nameLabel.fontSize = 10
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: 0, y: -size.height/2 - 15)
            nameLabel.zPosition = 1
            addChild(nameLabel)
        }
        
        updatePlant()
    }
    
    func updatePlant() {
        guard let data = plantData, let plantType = data.plantType else { return }
        
        // Sync with GameManager's plant data to get the latest state
        if plotIndex >= 0 && plotIndex < GameManager.shared.gameState.plants.count {
            let gameManagerPlant = GameManager.shared.gameState.plants[plotIndex]
            plantData = gameManagerPlant
        }
        
        let progress = data.progressPercentage
        let timeRemaining = data.timeUntilReady
        
        // Update progress bar
        let barWidth = size.width - 8
        progressBar?.size.width = barWidth * CGFloat(progress)
        
        // Update time label and plant appearance
        if data.isReady {
            timeLabel?.text = "Ready!"
            timeLabel?.fontColor = .yellow
            plantSprite?.color = .yellow
            
            // Add a pulsing animation for ready plants
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            plantSprite?.run(SKAction.repeatForever(pulse), withKey: "pulse")
        } else {
            timeLabel?.text = GameManager.shared.formatTime(timeRemaining)
            timeLabel?.fontColor = .white
            plantSprite?.color = plantType.rarity.color
            plantSprite?.removeAction(forKey: "pulse")
        }
    }
    
    func harvestPlant() {
        // Add harvest animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        run(sequence)
        
        // Update plant data from GameManager to stay in sync
        if plotIndex >= 0 && plotIndex < GameManager.shared.gameState.plants.count {
            let updatedPlantData = GameManager.shared.gameState.plants[plotIndex]
            plantData = updatedPlantData
        }
        
        updatePlant()
    }
    
    func clearPlant() {
        plantSprite?.removeFromParent()
        plantSprite = nil
        plantData = nil
        progressBar?.size.width = 0
        timeLabel?.text = ""
        
        // Remove all child nodes except border and soil
        children.forEach { child in
            if child != children.first && child != children.last {
                child.removeFromParent()
            }
        }
    }
    
    func handleTouch() {
        delegate?.gardenPlotTapped(self)
    }
    
    func update(_ currentTime: TimeInterval) {
        updatePlant()
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
        super.init(texture: nil, color: .darkGreen, size: size)
        setupTopBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTopBar()
    }
    
    private func setupTopBar() {
        // GP Label
        gpLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gpLabel?.fontSize = 24
        gpLabel?.fontColor = .white
        gpLabel?.position = CGPoint(x: -size.width/2 + 100, y: 0)
        addChild(gpLabel!)
        
        // Seeds Label
        seedsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        seedsLabel?.fontSize = 20
        seedsLabel?.fontColor = .yellow
        seedsLabel?.position = CGPoint(x: -size.width/2 + 100, y: -25)
        addChild(seedsLabel!)
        
        // Settings Button
        settingsButton = SKSpriteNode(color: .gray, size: CGSize(width: 40, height: 40))
        settingsButton?.position = CGPoint(x: size.width/2 - 30, y: 0)
        settingsButton?.name = "settingsButton"
        addChild(settingsButton!)
        
        let settingsIcon = SKLabelNode(text: "⚙️")
        settingsIcon.fontSize = 20
        settingsIcon.position = CGPoint.zero
        settingsButton?.addChild(settingsIcon)
        
        // Prestige Button
        prestigeButton = SKSpriteNode(color: .purple, size: CGSize(width: 80, height: 40))
        prestigeButton?.position = CGPoint(x: size.width/2 - 120, y: 0)
        prestigeButton?.name = "prestigeButton"
        addChild(prestigeButton!)
        
        let prestigeLabel = SKLabelNode(text: "Rebirth")
        prestigeLabel.fontName = "AvenirNext-Bold"
        prestigeLabel.fontSize = 14
        prestigeLabel.fontColor = .white
        prestigeLabel.position = CGPoint.zero
        prestigeButton?.addChild(prestigeLabel)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    func updateGP(_ gp: Int) {
        gpLabel?.text = "GP: \(GameManager.shared.formatNumber(gp))"
    }
    
    func updateSeeds(_ seeds: Int) {
        seedsLabel?.text = "Seeds: \(seeds)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if settingsButton?.contains(location) == true {
            delegate?.settingsButtonTapped()
        } else if prestigeButton?.contains(location) == true {
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
        super.init(texture: nil, color: .darkGreen, size: size)
        setupToolbar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupToolbar()
    }
    
    private func setupToolbar() {
        let buttonSize = CGSize(width: 80, height: 80)
        let _: CGFloat = 20
        
        // Plant Button
        plantButton = SKSpriteNode(color: .green, size: buttonSize)
        plantButton?.position = CGPoint(x: -size.width/2 + 60, y: 0)
        plantButton?.name = "plantButton"
        addChild(plantButton!)
        
        let plantIcon = SKLabelNode(text: "🌱")
        plantIcon.fontSize = 30
        plantIcon.position = CGPoint.zero
        plantButton?.addChild(plantIcon)
        
        let plantLabel = SKLabelNode(text: "Plant")
        plantLabel.fontName = "AvenirNext-Regular"
        plantLabel.fontSize = 12
        plantLabel.fontColor = .white
        plantLabel.position = CGPoint(x: 0, y: -50)
        plantButton?.addChild(plantLabel)
        
        // Upgrade Button
        upgradeButton = SKSpriteNode(color: .blue, size: buttonSize)
        upgradeButton?.position = CGPoint(x: 0, y: 0)
        upgradeButton?.name = "upgradeButton"
        addChild(upgradeButton!)
        
        let upgradeIcon = SKLabelNode(text: "⚡")
        upgradeIcon.fontSize = 30
        upgradeIcon.position = CGPoint.zero
        upgradeButton?.addChild(upgradeIcon)
        
        let upgradeLabel = SKLabelNode(text: "Upgrade")
        upgradeLabel.fontName = "AvenirNext-Regular"
        upgradeLabel.fontSize = 12
        upgradeLabel.fontColor = .white
        upgradeLabel.position = CGPoint(x: 0, y: -50)
        upgradeButton?.addChild(upgradeLabel)
        
        // Achievements Button
        achievementsButton = SKSpriteNode(color: .orange, size: buttonSize)
        achievementsButton?.position = CGPoint(x: size.width/2 - 60, y: 0)
        achievementsButton?.name = "achievementsButton"
        addChild(achievementsButton!)
        
        let achievementsIcon = SKLabelNode(text: "🏆")
        achievementsIcon.fontSize = 30
        achievementsIcon.position = CGPoint.zero
        achievementsButton?.addChild(achievementsIcon)
        
        let achievementsLabel = SKLabelNode(text: "Achievements")
        achievementsLabel.fontName = "AvenirNext-Regular"
        achievementsLabel.fontSize = 12
        achievementsLabel.fontColor = .white
        achievementsLabel.position = CGPoint(x: 0, y: -50)
        achievementsButton?.addChild(achievementsLabel)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if plantButton?.contains(location) == true {
            delegate?.plantButtonTapped()
        } else if upgradeButton?.contains(location) == true {
            delegate?.upgradeButtonTapped()
        } else if achievementsButton?.contains(location) == true {
            delegate?.achievementsButtonTapped()
        }
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
        // Title
        let titleLabel = SKLabelNode(text: "Plant Shop")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 30)
        addChild(titleLabel)
        
        // Close button
        closeButton = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
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
        scrollView?.position = CGPoint(x: 0, y: size.height/2 - 80)
        addChild(scrollView!)
        
        let availablePlants = GameData.shared.getAvailablePlants(for: GameManager.shared.gameState.gardenPoints)
        let buttonHeight: CGFloat = 80
        let spacing: CGFloat = 10
        
        for (index, plantType) in availablePlants.enumerated() {
            let button = createPlantButton(plantType)
            button.position = CGPoint(x: 0, y: -CGFloat(index) * (buttonHeight + spacing))
            button.name = "plant_\(plantType.id)"
            scrollView?.addChild(button)
        }
    }
    
    private func createPlantButton(_ plantType: PlantType) -> SKSpriteNode {
        let button = SKSpriteNode(color: plantType.rarity.color, size: CGSize(width: size.width - 40, height: 80))
        
        // Plant icon (different icons for different rarities)
        let icon = SKLabelNode(text: getPlantIcon(for: plantType.rarity))
        icon.fontSize = 24
        icon.position = CGPoint(x: -button.size.width/2 + 40, y: 5)
        button.addChild(icon)
        
        // Plant name
        let nameLabel = SKLabelNode(text: plantType.name)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: -button.size.width/2 + 80, y: 20)
        button.addChild(nameLabel)
        
        // Growth time and rarity
        let timeLabel = SKLabelNode(text: "\(GameManager.shared.formatTime(plantType.growthTime)) • \(plantType.rarity.rawValue)")
        timeLabel.fontName = "AvenirNext-Regular"
        timeLabel.fontSize = 11
        timeLabel.fontColor = .white
        timeLabel.position = CGPoint(x: -button.size.width/2 + 80, y: 5)
        button.addChild(timeLabel)
        
        // GP earned per harvest (more useful than GP/hour)
        let baseGp = Double(plantType.gpPerHour) * plantType.growthTime / 3600.0
        let gpPerHarvest = max(1, Int(baseGp))
        let harvestLabel = SKLabelNode(text: "Harvest: +\(GameManager.shared.formatNumber(gpPerHarvest)) GP")
        harvestLabel.fontName = "AvenirNext-Regular"
        harvestLabel.fontSize = 11
        harvestLabel.fontColor = .yellow
        harvestLabel.position = CGPoint(x: -button.size.width/2 + 80, y: -10)
        button.addChild(harvestLabel)
        
        // GP per hour (smaller, secondary info)
        let gpLabel = SKLabelNode(text: "\(plantType.gpPerHour) GP/h")
        gpLabel.fontName = "AvenirNext-Regular"
        gpLabel.fontSize = 10
        gpLabel.fontColor = .lightGray
        gpLabel.position = CGPoint(x: button.size.width/2 - 60, y: 10)
        button.addChild(gpLabel)
        
        // Unlock requirement
        let unlockLabel = SKLabelNode(text: "Unlocks at \(GameManager.shared.formatNumber(plantType.unlockRequirement)) GP")
        unlockLabel.fontName = "AvenirNext-Regular"
        unlockLabel.fontSize = 9
        unlockLabel.fontColor = .lightGray
        unlockLabel.position = CGPoint(x: button.size.width/2 - 60, y: -5)
        button.addChild(unlockLabel)
        
        return button
    }
    
    private func getPlantIcon(for rarity: PlantRarity) -> String {
        switch rarity {
        case .basic: return "🌱"
        case .rare: return "🌸"
        case .legendary: return "⭐"
        case .prestige: return "💎"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if closeButton?.contains(location) == true {
            delegate?.plantShopClosed()
        } else {
            // Check for plant selection
            let nodes = nodes(at: location)
            for node in nodes {
                if let name = node.name, name.hasPrefix("plant_") {
                    let plantId = String(name.dropFirst(6))
                    if let plantType = GameData.shared.getPlantType(by: plantId) {
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
        // Title
        let titleLabel = SKLabelNode(text: "Upgrades")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 30)
        addChild(titleLabel)
        
        // Close button
        closeButton = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
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
        let buttonHeight: CGFloat = 80
        let spacing: CGFloat = 10
        
        for (index, upgradeType) in UpgradeType.allCases.enumerated() {
            let button = createUpgradeButton(upgradeType)
            button.position = CGPoint(x: 0, y: size.height/2 - 80 - CGFloat(index) * (buttonHeight + spacing))
            button.name = "upgrade_\(upgradeType.rawValue)"
            addChild(button)
        }
    }
    
    private func createUpgradeButton(_ upgradeType: UpgradeType) -> SKSpriteNode {
        let button = SKSpriteNode(color: .blue, size: CGSize(width: size.width - 40, height: 80))
        
        // Upgrade name
        let nameLabel = SKLabelNode(text: upgradeType.rawValue)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: -button.size.width/2 + 80, y: 20)
        button.addChild(nameLabel)
        
        // Current level
        let currentLevel = GameManager.shared.getUpgradeLevel(upgradeType)
        let levelLabel = SKLabelNode(text: "Level: \(currentLevel)/\(upgradeType.maxLevel)")
        levelLabel.fontName = "AvenirNext-Regular"
        levelLabel.fontSize = 12
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: -button.size.width/2 + 80, y: 0)
        button.addChild(levelLabel)
        
        // Cost
        let cost = GameManager.shared.calculateUpgradeCost(upgradeType, level: currentLevel)
        let costLabel = SKLabelNode(text: "Cost: \(GameManager.shared.formatNumber(cost)) GP")
        costLabel.fontName = "AvenirNext-Regular"
        costLabel.fontSize = 12
        costLabel.fontColor = .white
        costLabel.position = CGPoint(x: -button.size.width/2 + 80, y: -20)
        button.addChild(costLabel)
        
        // Buy button
        let buyButton = SKSpriteNode(color: .green, size: CGSize(width: 60, height: 30))
        buyButton.position = CGPoint(x: button.size.width/2 - 40, y: 0)
        buyButton.name = "buy_\(upgradeType.rawValue)"
        button.addChild(buyButton)
        
        let buyLabel = SKLabelNode(text: "Buy")
        buyLabel.fontName = "AvenirNext-Bold"
        buyLabel.fontSize = 12
        buyLabel.fontColor = .white
        buyLabel.position = CGPoint.zero
        buyButton.addChild(buyLabel)
        
        return button
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if closeButton?.contains(location) == true {
            delegate?.upgradeMenuClosed()
        } else {
            // Check for upgrade purchase
            let nodes = nodes(at: location)
            for node in nodes {
                if let name = node.name, name.hasPrefix("buy_") {
                    let upgradeName = String(name.dropFirst(4))
                    if let upgradeType = UpgradeType(rawValue: upgradeName) {
                        delegate?.upgradePurchased(upgradeType)
                        return
                    }
                }
            }
        }
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
        super.init(texture: nil, color: .darkGreen, size: size)
        setupSettingsMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSettingsMenu()
    }
    
    private func setupSettingsMenu() {
        // Title
        titleLabel = SKLabelNode(text: "Settings")
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 28
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: 0, y: size.height/2 - 50)
        addChild(titleLabel!)
        
        // Close button
        closeButton = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
        closeButton?.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton?.name = "closeButton"
        addChild(closeButton!)
        
        let closeLabel = SKLabelNode(text: "✕")
        closeLabel.fontSize = 20
        closeLabel.fontColor = .white
        closeLabel.position = CGPoint.zero
        closeLabel.name = "closeButton"
        closeButton?.addChild(closeLabel)
        
        // Reset Game Button
        resetButton = SKSpriteNode(color: .red, size: CGSize(width: 200, height: 50))
        resetButton?.position = CGPoint(x: 0, y: 50)
        resetButton?.name = "resetButton"
        addChild(resetButton!)
        
        let resetLabel = SKLabelNode(text: "Reset Game")
        resetLabel.fontName = "AvenirNext-Bold"
        resetLabel.fontSize = 18
        resetLabel.fontColor = .white
        resetLabel.position = CGPoint.zero
        resetButton?.addChild(resetLabel)
        
        // Sound Toggle Button
        soundButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 50))
        soundButton?.position = CGPoint(x: 0, y: -20)
        soundButton?.name = "soundButton"
        addChild(soundButton!)
        
        let soundLabel = SKLabelNode(text: "Sound: ON")
        soundLabel.fontName = "AvenirNext-Bold"
        soundLabel.fontSize = 18
        soundLabel.fontColor = .white
        soundLabel.position = CGPoint.zero
        soundLabel.name = "soundLabel"
        soundButton?.addChild(soundLabel)
        
        // Notifications Toggle Button
        notificationsButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 50))
        notificationsButton?.position = CGPoint(x: 0, y: -90)
        notificationsButton?.name = "notificationsButton"
        addChild(notificationsButton!)
        
        let notificationsLabel = SKLabelNode(text: "Notifications: ON")
        notificationsLabel.fontName = "AvenirNext-Bold"
        notificationsLabel.fontSize = 18
        notificationsLabel.fontColor = .white
        notificationsLabel.position = CGPoint.zero
        notificationsLabel.name = "notificationsLabel"
        notificationsButton?.addChild(notificationsLabel)
        
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if close button was tapped
        if let closeButton = closeButton, closeButton.contains(location) {
            delegate?.settingsMenuClosed()
            return
        }
        
        // Check if reset button was tapped
        if let resetButton = resetButton, resetButton.contains(location) {
            delegate?.resetGameTapped()
            return
        }
        
        // Check if sound button was tapped
        if let soundButton = soundButton, soundButton.contains(location) {
            delegate?.toggleSoundTapped()
            return
        }
        
        // Check if notifications button was tapped
        if let notificationsButton = notificationsButton, notificationsButton.contains(location) {
            delegate?.toggleNotificationsTapped()
            return
        }
    }
    
    func handleTouch(_ location: CGPoint) {
        // Check if close button was tapped
        if let closeButton = closeButton, closeButton.contains(location) {
            delegate?.settingsMenuClosed()
            return
        }
        
        // Check if reset button was tapped
        if let resetButton = resetButton, resetButton.contains(location) {
            delegate?.resetGameTapped()
            return
        }
        
        // Check if sound button was tapped
        if let soundButton = soundButton, soundButton.contains(location) {
            delegate?.toggleSoundTapped()
            return
        }
        
        // Check if notifications button was tapped
        if let notificationsButton = notificationsButton, notificationsButton.contains(location) {
            delegate?.toggleNotificationsTapped()
            return
        }
    }
    
    func updateSoundLabel(_ isOn: Bool) {
        if let soundLabel = soundButton?.childNode(withName: "soundLabel") as? SKLabelNode {
            soundLabel.text = "Sound: \(isOn ? "ON" : "OFF")"
        }
    }
    
    func updateNotificationsLabel(_ isOn: Bool) {
        if let notificationsLabel = notificationsButton?.childNode(withName: "notificationsLabel") as? SKLabelNode {
            notificationsLabel.text = "Notifications: \(isOn ? "ON" : "OFF")"
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
        guard !isVisible else { return }
        isVisible = true
        
        // Background
        background = SKSpriteNode(color: .black, size: CGSize(width: 300, height: 200))
        background?.alpha = 0.9
        background?.position = CGPoint.zero
        addChild(background!)
        
        // Title
        let titleLabel = SKLabelNode(text: "Welcome Back!")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 60)
        addChild(titleLabel)
        
        // Progress info
        let gpLabel = SKLabelNode(text: "GP Earned: \(GameManager.shared.formatNumber(progress.gpEarned))")
        gpLabel.fontName = "AvenirNext-Regular"
        gpLabel.fontSize = 16
        gpLabel.fontColor = .yellow
        gpLabel.position = CGPoint(x: 0, y: 20)
        addChild(gpLabel)
        
        let plantsLabel = SKLabelNode(text: "Plants Ready: \(progress.plantsReady)")
        plantsLabel.fontName = "AvenirNext-Regular"
        plantsLabel.fontSize = 16
        plantsLabel.fontColor = .green
        plantsLabel.position = CGPoint(x: 0, y: -10)
        addChild(plantsLabel)
        
        // Claim button
        let claimButton = SKSpriteNode(color: .green, size: CGSize(width: 120, height: 40))
        claimButton.position = CGPoint(x: 0, y: -50)
        claimButton.name = "claimButton"
        addChild(claimButton)
        
        let claimLabel = SKLabelNode(text: "Claim")
        claimLabel.fontName = "AvenirNext-Bold"
        claimLabel.fontSize = 16
        claimLabel.fontColor = .white
        claimLabel.position = CGPoint.zero
        claimButton.addChild(claimLabel)
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    func hide() {
        removeAllChildren()
        isVisible = false
        isUserInteractionEnabled = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "claimButton" {
                delegate?.offlineProgressClaimed()
                hide()
                return
            }
        }
        
        // Tap anywhere to close
        delegate?.offlineProgressClosed()
        hide()
    }
}

// MARK: - Color Extensions

extension SKColor {
    static let darkGreen = SKColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
    static let darkBrown = SKColor(red: 0.4, green: 0.2, blue: 0.0, alpha: 1.0)
} 