//
//  AchievementSystem.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import Foundation
import SpriteKit

// MARK: - Achievement Types

enum AchievementType: String, CaseIterable, Codable {
    case firstHarvest = "First Harvest"
    case firstUpgrade = "First Upgrade"
    case plantMaster = "Plant Master"
    case speedDemon = "Speed Demon"
    case millionaire = "Millionaire"
    case prestigeMaster = "Prestige Master"
    case collector = "Plant Collector"
    case timeTraveler = "Time Traveler"
    case gardener = "Green Thumb"
    case efficiency = "Efficiency Expert"
    
    var title: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .firstHarvest:
            return "Harvest your first plant"
        case .firstUpgrade:
            return "Buy your first upgrade"
        case .plantMaster:
            return "Plant 5 different types of plants"
        case .speedDemon:
            return "Reach 3x growth speed multiplier"
        case .millionaire:
            return "Earn 1,000,000 Garden Points"
        case .prestigeMaster:
            return "Perform 3 garden rebirths"
        case .collector:
            return "Unlock 10 different plant types"
        case .timeTraveler:
            return "Accumulate 12 hours of offline progress"
        case .gardener:
            return "Have 15 plants growing simultaneously"
        case .efficiency:
            return "Reach level 10 in any upgrade"
        }
    }
    
    var reward: Int {
        switch self {
        case .firstHarvest: return 5
        case .firstUpgrade: return 10
        case .plantMaster: return 25
        case .speedDemon: return 50
        case .millionaire: return 200
        case .prestigeMaster: return 100
        case .collector: return 150
        case .timeTraveler: return 75
        case .gardener: return 40
        case .efficiency: return 60
        }
    }
    
    var icon: String {
        switch self {
        case .firstHarvest: return "🌱"
        case .firstUpgrade: return "⚡"
        case .plantMaster: return "👨‍🌾"
        case .speedDemon: return "🏃‍♂️"
        case .millionaire: return "💰"
        case .prestigeMaster: return "🔄"
        case .collector: return "📚"
        case .timeTraveler: return "⏰"
        case .gardener: return "🌿"
        case .efficiency: return "🎯"
        }
    }
    
    var rarity: AchievementRarity {
        switch self {
        case .firstHarvest, .firstUpgrade:
            return .common
        case .plantMaster, .gardener, .efficiency:
            return .uncommon
        case .speedDemon, .collector, .timeTraveler:
            return .rare
        case .millionaire, .prestigeMaster:
            return .legendary
        }
    }
}

enum AchievementRarity: CaseIterable {
    case common, uncommon, rare, legendary
    
    var color: UIColor {
        switch self {
        case .common: return .systemGray
        case .uncommon: return .systemGreen
        case .rare: return .systemBlue
        case .legendary: return .systemPurple
        }
    }
    
    var borderColor: UIColor {
        switch self {
        case .common: return .systemGray2
        case .uncommon: return .systemGreen
        case .rare: return .systemBlue
        case .legendary: return .systemPurple
        }
    }
}

// MARK: - Achievement Data

struct Achievement: Codable {
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double // For progressive achievements
    
    init(type: AchievementType) {
        self.type = type
        self.isUnlocked = false
        self.unlockedDate = nil
        self.progress = 0.0
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AchievementType.self, forKey: .type)
        isUnlocked = try container.decode(Bool.self, forKey: .isUnlocked)
        unlockedDate = try container.decodeIfPresent(Date.self, forKey: .unlockedDate)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0.0
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, isUnlocked, unlockedDate, progress
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var achievements: [Achievement]
    @Published var recentlyUnlocked: [Achievement] = []
    
    private let saveKey = "Achievements"
    private var notificationQueue: [Achievement] = []
    
    private init() {
        self.achievements = AchievementType.allCases.map { Achievement(type: $0) }
        loadAchievements()
    }
    
    // MARK: - Achievement Checking
    
    func checkAchievements(gameState: GameState) {
        checkFirstHarvest(gameState: gameState)
        checkFirstUpgrade(gameState: gameState)
        checkPlantMaster(gameState: gameState)
        checkSpeedDemon(gameState: gameState)
        checkMillionaire(gameState: gameState)
        checkPrestigeMaster(gameState: gameState)
        checkCollector(gameState: gameState)
        checkTimeTraveler(gameState: gameState)
        checkGardener(gameState: gameState)
        checkEfficiency(gameState: gameState)
        
        // Process notification queue
        processNotificationQueue()
    }
    
    private func checkFirstHarvest(gameState: GameState) {
        let achievement = getAchievement(.firstHarvest)
        if !achievement.isUnlocked && gameState.totalGpEarned > 0 {
            unlockAchievement(.firstHarvest)
        }
    }
    
    private func checkFirstUpgrade(gameState: GameState) {
        let achievement = getAchievement(.firstUpgrade)
        if !achievement.isUnlocked && !gameState.upgrades.isEmpty {
            let hasAnyUpgrade = gameState.upgrades.values.contains { $0 > 0 }
            if hasAnyUpgrade {
                unlockAchievement(.firstUpgrade)
            }
        }
    }
    
    private func checkPlantMaster(gameState: GameState) {
        let achievement = getAchievement(.plantMaster)
        if !achievement.isUnlocked {
            let uniquePlants = Set(gameState.plants.compactMap { $0.isEmpty ? nil : $0.typeId })
            let progress = Double(uniquePlants.count) / 5.0
            updateAchievementProgress(.plantMaster, progress: progress)
            
            if uniquePlants.count >= 5 {
                unlockAchievement(.plantMaster)
            }
        }
    }
    
    private func checkSpeedDemon(gameState: GameState) {
        let achievement = getAchievement(.speedDemon)
        if !achievement.isUnlocked {
            let multiplier = GameManager.shared.getGrowthSpeedMultiplier()
            let progress = (multiplier - 1.0) / 2.0 // Progress to 3x multiplier
            updateAchievementProgress(.speedDemon, progress: progress)
            
            if multiplier >= 3.0 {
                unlockAchievement(.speedDemon)
            }
        }
    }
    
    private func checkMillionaire(gameState: GameState) {
        let achievement = getAchievement(.millionaire)
        if !achievement.isUnlocked {
            let progress = Double(gameState.totalGpEarned) / 1_000_000.0
            updateAchievementProgress(.millionaire, progress: progress)
            
            if gameState.totalGpEarned >= 1_000_000 {
                unlockAchievement(.millionaire)
            }
        }
    }
    
    private func checkPrestigeMaster(gameState: GameState) {
        let achievement = getAchievement(.prestigeMaster)
        if !achievement.isUnlocked {
            let progress = Double(gameState.prestigeCount) / 3.0
            updateAchievementProgress(.prestigeMaster, progress: progress)
            
            if gameState.prestigeCount >= 3 {
                unlockAchievement(.prestigeMaster)
            }
        }
    }
    
    private func checkCollector(gameState: GameState) {
        let achievement = getAchievement(.collector)
        if !achievement.isUnlocked {
            let unlockedPlants = GameData.shared.plantTypes.filter { plantType in
                gameState.gardenPoints >= plantType.unlockRequirement
            }
            let progress = Double(unlockedPlants.count) / 10.0
            updateAchievementProgress(.collector, progress: progress)
            
            if unlockedPlants.count >= 10 {
                unlockAchievement(.collector)
            }
        }
    }
    
    private func checkTimeTraveler(gameState: GameState) {
        let achievement = getAchievement(.timeTraveler)
        if !achievement.isUnlocked {
            // This would need to be tracked separately in game state
            let offlineTime = Date().timeIntervalSince(gameState.lastSaveTime)
            let hoursOffline = offlineTime / 3600.0
            let progress = hoursOffline / 12.0
            updateAchievementProgress(.timeTraveler, progress: progress)
            
            if hoursOffline >= 12.0 {
                unlockAchievement(.timeTraveler)
            }
        }
    }
    
    private func checkGardener(gameState: GameState) {
        let achievement = getAchievement(.gardener)
        if !achievement.isUnlocked {
            let activePlants = gameState.plants.filter { !$0.isEmpty }.count
            let progress = Double(activePlants) / 15.0
            updateAchievementProgress(.gardener, progress: progress)
            
            if activePlants >= 15 {
                unlockAchievement(.gardener)
            }
        }
    }
    
    private func checkEfficiency(gameState: GameState) {
        let achievement = getAchievement(.efficiency)
        if !achievement.isUnlocked {
            let maxLevel = gameState.upgrades.values.max() ?? 0
            let progress = Double(maxLevel) / 10.0
            updateAchievementProgress(.efficiency, progress: progress)
            
            if maxLevel >= 10 {
                unlockAchievement(.efficiency)
            }
        }
    }
    
    // MARK: - Achievement Management
    
    private func unlockAchievement(_ type: AchievementType) {
        guard let index = achievements.firstIndex(where: { $0.type == type }) else { return }
        guard !achievements[index].isUnlocked else { return }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        achievements[index].progress = 1.0
        
        // Add to recently unlocked
        recentlyUnlocked.append(achievements[index])
        
        // Award seeds
        let reward = type.reward
        GameManager.shared.gameState.seeds += reward
        
        // Add to notification queue
        notificationQueue.append(achievements[index])
        
        // Save achievements
        saveAchievements()
        
        print("Achievement unlocked: \(type.title)")
    }
    
    private func updateAchievementProgress(_ type: AchievementType, progress: Double) {
        guard let index = achievements.firstIndex(where: { $0.type == type }) else { return }
        guard !achievements[index].isUnlocked else { return }
        
        let clampedProgress = min(1.0, max(0.0, progress))
        if clampedProgress > achievements[index].progress {
            achievements[index].progress = clampedProgress
            saveAchievements()
        }
    }
    
    private func getAchievement(_ type: AchievementType) -> Achievement {
        return achievements.first { $0.type == type } ?? Achievement(type: type)
    }
    
    func getUnlockedCount() -> Int {
        return achievements.filter { $0.isUnlocked }.count
    }
    
    func getTotalCount() -> Int {
        return achievements.count
    }
    
    func getProgress() -> Double {
        return Double(getUnlockedCount()) / Double(getTotalCount())
    }
    
    func getAchievementsByRarity(_ rarity: AchievementRarity) -> [Achievement] {
        return achievements.filter { $0.type.rarity == rarity }
    }
    
    // MARK: - Notification System
    
    private func processNotificationQueue() {
        guard !notificationQueue.isEmpty else { return }
        
        // Process one notification at a time to avoid overlap
        let achievement = notificationQueue.removeFirst()
        showAchievementNotification(achievement)
    }
    
    private func showAchievementNotification(_ achievement: Achievement) {
        // Find the scene to show notification
        guard let scene = findActiveScene() else { return }
        
        let notification = AchievementNotification()
        notification.position = CGPoint(x: scene.size.width/2, y: scene.size.height - 100)
        notification.zPosition = 2000
        scene.addChild(notification)
        
        notification.showAchievement(achievement)
    }
    
    private func findActiveScene() -> SKScene? {
        // This is a helper to find the active scene
        // In a real implementation, you might store a reference to the scene
        return nil // Would be implemented properly in the actual app
    }
    
    // MARK: - Save/Load
    
    private func saveAchievements() {
        do {
            let data = try JSONEncoder().encode(achievements)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save achievements: \(error)")
        }
    }
    
    private func loadAchievements() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let loadedAchievements = try JSONDecoder().decode([Achievement].self, from: data)
            
            // Merge with current achievements to handle new achievements added in updates
            for loadedAchievement in loadedAchievements {
                if let index = achievements.firstIndex(where: { $0.type == loadedAchievement.type }) {
                    achievements[index] = loadedAchievement
                }
            }
        } catch {
            print("Failed to load achievements: \(error)")
            achievements = AchievementType.allCases.map { Achievement(type: $0) }
        }
    }
    
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
    
    func resetAchievements() {
        achievements = AchievementType.allCases.map { Achievement(type: $0) }
        recentlyUnlocked.removeAll()
        notificationQueue.removeAll()
        saveAchievements()
    }
}

// MARK: - Achievement UI Components

class AchievementNotification: SKNode {
    
    private var background: SKShapeNode?
    private var iconLabel: SKLabelNode?
    private var titleLabel: SKLabelNode?
    private var rewardLabel: SKLabelNode?
    
    func showAchievement(_ achievement: Achievement) {
        removeAllChildren()
        
        let cardSize = CGSize(width: 300, height: 80)
        
        // Background with rarity color
        background = SKShapeNode(rectOf: cardSize, cornerRadius: 15)
        background?.fillColor = achievement.type.rarity.color.withAlphaComponent(0.9)
        background?.strokeColor = achievement.type.rarity.borderColor
        background?.lineWidth = 2
        background?.position = CGPoint.zero
        background?.zPosition = 1
        addChild(background!)
        
        // Achievement unlocked label
        let unlockedLabel = SKLabelNode(text: "🎉 Achievement Unlocked!")
        unlockedLabel.fontName = "AvenirNext-Bold"
        unlockedLabel.fontSize = 12
        unlockedLabel.fontColor = .white
        unlockedLabel.position = CGPoint(x: 0, y: 20)
        unlockedLabel.zPosition = 2
        addChild(unlockedLabel)
        
        // Icon
        iconLabel = SKLabelNode(text: achievement.type.icon)
        iconLabel?.fontSize = 24
        iconLabel?.position = CGPoint(x: -100, y: -5)
        iconLabel?.verticalAlignmentMode = .center
        iconLabel?.horizontalAlignmentMode = .center
        iconLabel?.zPosition = 2
        addChild(iconLabel!)
        
        // Title
        titleLabel = SKLabelNode(text: achievement.type.title)
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 14
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: -20, y: 0)
        titleLabel?.zPosition = 2
        addChild(titleLabel!)
        
        // Reward
        rewardLabel = SKLabelNode(text: "+\(achievement.type.reward) 🌰")
        rewardLabel?.fontName = "AvenirNext-Regular"
        rewardLabel?.fontSize = 12
        rewardLabel?.fontColor = .systemYellow
        rewardLabel?.position = CGPoint(x: -20, y: -18)
        rewardLabel?.zPosition = 2
        addChild(rewardLabel!)
        
        // Animation sequence
        alpha = 0
        position.x -= 50
        
        let slideIn = SKAction.moveBy(x: 50, y: 0, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let entrance = SKAction.group([slideIn, fadeIn])
        
        let wait = SKAction.wait(forDuration: 3.0)
        
        let slideOut = SKAction.moveBy(x: 50, y: 0, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let exit = SKAction.group([slideOut, fadeOut])
        
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([entrance, wait, exit, remove])
        
        run(sequence)
    }
}

// MARK: - Achievement Menu

class AchievementMenuNode: SKSpriteNode {
    
    private var closeButton: SKSpriteNode?
    private var scrollView: SKNode?
    private var filterButtons: [SKSpriteNode] = []
    private var currentFilter: AchievementRarity? = nil
    
    init(size: CGSize) {
        super.init(texture: nil, color: .clear, size: size)
        setupAchievementMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAchievementMenu()
    }
    
    private func setupAchievementMenu() {
        // Background
        let background = SKShapeNode(rectOf: size, cornerRadius: 20)
        background.fillColor = .white
        background.strokeColor = UIColor.systemGray.withAlphaComponent(0.3)
        background.lineWidth = 2
        background.position = CGPoint.zero
        addChild(background)
        
        // Title
        let titleLabel = SKLabelNode(text: "🏆 Achievements")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 40)
        addChild(titleLabel)
        
        // Progress
        let progress = AchievementManager.shared.getProgress()
        let progressLabel = SKLabelNode(text: "\(AchievementManager.shared.getUnlockedCount())/\(AchievementManager.shared.getTotalCount()) (\(Int(progress * 100))%)")
        progressLabel.fontName = "AvenirNext-Regular"
        progressLabel.fontSize = 16
        progressLabel.fontColor = .systemGray
        progressLabel.position = CGPoint(x: 0, y: size.height/2 - 70)
        addChild(progressLabel)
        
        // Close button
        closeButton = SKSpriteNode(color: .systemRed, size: CGSize(width: 44, height: 44))
        closeButton?.position = CGPoint(x: size.width/2 - 30, y: size.height/2 - 30)
        closeButton?.name = "closeButton"
        addChild(closeButton!)
        
        // Add rounded corners to close button
        let closeShape = SKShapeNode(rectOf: closeButton!.size, cornerRadius: 8)
        closeShape.fillColor = .systemRed
        closeShape.strokeColor = .clear
        closeShape.position = CGPoint.zero
        closeButton?.addChild(closeShape)
        
        let closeIcon = SKLabelNode(text: "✕")
        closeIcon.fontSize = 20
        closeIcon.fontColor = .white
        closeIcon.position = CGPoint.zero
        closeIcon.verticalAlignmentMode = .center
        closeIcon.horizontalAlignmentMode = .center
        closeIcon.zPosition = 1
        closeButton?.addChild(closeIcon)
        
        // Filter buttons
        setupFilterButtons()
        
        // Achievement list
        setupAchievementList()
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func setupFilterButtons() {
        let rarities: [AchievementRarity?] = [nil, .common, .uncommon, .rare, .legendary]
        let buttonWidth: CGFloat = 60
        let spacing: CGFloat = 10
        let totalWidth = CGFloat(rarities.count) * buttonWidth + CGFloat(rarities.count - 1) * spacing
        let startX = -totalWidth / 2
        
        for (index, rarity) in rarities.enumerated() {
            let button = SKSpriteNode(color: rarity?.color ?? .systemGray, size: CGSize(width: buttonWidth, height: 30))
            button.position = CGPoint(x: startX + CGFloat(index) * (buttonWidth + spacing), y: size.height/2 - 110)
            button.name = "filter_\(rarity?.hashValue ?? -1)"
            addChild(button)
            
            // Add rounded corners
            let shape = SKShapeNode(rectOf: button.size, cornerRadius: 6)
            shape.fillColor = rarity?.color ?? .systemGray
            shape.strokeColor = .clear
            shape.position = CGPoint.zero
            button.addChild(shape)
            
            let label = SKLabelNode(text: rarity == nil ? "All" : String(describing: rarity!).capitalized)
            label.fontName = "AvenirNext-Regular"
            label.fontSize = 10
            label.fontColor = .white
            label.position = CGPoint.zero
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 1
            button.addChild(label)
            
            filterButtons.append(button)
        }
    }
    
    private func setupAchievementList() {
        // Calculate available space for achievements
        let topMargin: CGFloat = 150 // Space for title, progress, and filter buttons
        let bottomMargin: CGFloat = 20
        let availableHeight = size.height - topMargin - bottomMargin
        
        scrollView = SKNode()
        scrollView?.position = CGPoint(x: 0, y: size.height/2 - topMargin)
        addChild(scrollView!)
        
        let achievements = getFilteredAchievements()
        let buttonHeight: CGFloat = 70
        let spacing: CGFloat = 10
        
        // Create a container to hold all achievements
        let container = SKNode()
        scrollView?.addChild(container)
        
        for (index, achievement) in achievements.enumerated() {
            let button = createAchievementButton(achievement)
            button.position = CGPoint(x: 0, y: -CGFloat(index) * (buttonHeight + spacing))
            container.addChild(button)
        }
        
        // Calculate total content height
        let totalContentHeight = CGFloat(achievements.count) * (buttonHeight + spacing) - spacing
        
        // If content is taller than available space, enable scrolling
        if totalContentHeight > availableHeight {
            // Store scroll info for touch handling
            scrollView?.name = "scrollView"
            scrollView?.userData = NSMutableDictionary()
            scrollView?.userData?.setValue(totalContentHeight, forKey: "contentHeight")
            scrollView?.userData?.setValue(availableHeight, forKey: "visibleHeight")
        }
    }
    
    private func getFilteredAchievements() -> [Achievement] {
        let allAchievements = AchievementManager.shared.achievements
        
        if let filter = currentFilter {
            return allAchievements.filter { $0.type.rarity == filter }
        } else {
            return allAchievements
        }
    }
    
    private func createAchievementButton(_ achievement: Achievement) -> SKSpriteNode {
        let buttonColor = achievement.isUnlocked ? achievement.type.rarity.color : UIColor.systemGray
        let button = SKSpriteNode(color: buttonColor.withAlphaComponent(0.8), size: CGSize(width: size.width - 60, height: 70))
        
        // Background shape
        let shape = SKShapeNode(rectOf: button.size, cornerRadius: 12)
        shape.fillColor = buttonColor.withAlphaComponent(0.8)
        shape.strokeColor = achievement.type.rarity.borderColor.withAlphaComponent(0.6)
        shape.lineWidth = achievement.isUnlocked ? 2 : 1
        shape.position = CGPoint.zero
        button.addChild(shape)
        
        // Icon
        let icon = SKLabelNode(text: achievement.type.icon)
        icon.fontSize = 32
        icon.position = CGPoint(x: -button.size.width/2 + 40, y: 0)
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        icon.zPosition = 1
        if !achievement.isUnlocked {
            icon.alpha = 0.5
        }
        button.addChild(icon)
        
        // Title
        let title = SKLabelNode(text: achievement.type.title)
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 16
        title.fontColor = .white
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -button.size.width/2 + 70, y: 15)
        title.zPosition = 1
        button.addChild(title)
        
        // Description
        let description = SKLabelNode(text: achievement.type.description)
        description.fontName = "AvenirNext-Regular"
        description.fontSize = 12
        description.fontColor = .white
        description.horizontalAlignmentMode = .left
        description.position = CGPoint(x: -button.size.width/2 + 70, y: -5)
        description.zPosition = 1
        button.addChild(description)
        
        // Progress or completion
        if achievement.isUnlocked {
            let completedLabel = SKLabelNode(text: "✓ Completed")
            completedLabel.fontName = "AvenirNext-Bold"
            completedLabel.fontSize = 12
            completedLabel.fontColor = .systemGreen
            completedLabel.horizontalAlignmentMode = .left
            completedLabel.position = CGPoint(x: -button.size.width/2 + 70, y: -20)
            completedLabel.zPosition = 1
            button.addChild(completedLabel)
            
            // Reward
            let reward = SKLabelNode(text: "+\(achievement.type.reward) 🌰")
            reward.fontName = "AvenirNext-Regular"
            reward.fontSize = 12
            reward.fontColor = .systemYellow
            reward.position = CGPoint(x: button.size.width/2 - 60, y: 0)
            reward.zPosition = 1
            button.addChild(reward)
        } else {
            // Progress bar for progressive achievements
            if achievement.progress > 0 {
                let progressBG = SKSpriteNode(color: UIColor.systemGray.withAlphaComponent(0.3), 
                                            size: CGSize(width: 100, height: 4))
                progressBG.position = CGPoint(x: -button.size.width/2 + 120, y: -20)
                progressBG.zPosition = 1
                button.addChild(progressBG)
                
                let progressFill = SKSpriteNode(color: .systemBlue, 
                                              size: CGSize(width: 100 * CGFloat(achievement.progress), height: 4))
                progressFill.anchorPoint = CGPoint(x: 0, y: 0.5)
                progressFill.position = CGPoint(x: -50, y: 0)
                progressFill.zPosition = 2
                progressBG.addChild(progressFill)
                
                let progressText = SKLabelNode(text: "\(Int(achievement.progress * 100))%")
                progressText.fontName = "AvenirNext-Regular"
                progressText.fontSize = 10
                progressText.fontColor = .white
                progressText.position = CGPoint(x: button.size.width/2 - 60, y: -20)
                progressText.zPosition = 1
                button.addChild(progressText)
            }
            
        // Lock icon
        if !achievement.isUnlocked {
            let lock = SKLabelNode(text: "🔒")
            lock.fontSize = 20
            lock.position = CGPoint(x: button.size.width/2 - 30, y: 10)
            lock.verticalAlignmentMode = .center
            lock.horizontalAlignmentMode = .center
            lock.zPosition = 1
            button.addChild(lock)
        }
        }
        
        return button
    }
    
    private var lastTouchLocation: CGPoint?
    private var isScrolling = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchLocation = location
        
        // Check for close button first
        if let closeButton = closeButton, closeButton.contains(location) {
            closeButton.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])) {
                self.removeFromParent()
            }
            return
        }
        
        // Check for filter buttons
        let nodes = nodes(at: location)
        for node in nodes {
            if let name = node.name, name.hasPrefix("filter_") {
                handleFilterSelection(node)
                return
            }
        }
        
        // Check if touch is in scroll area
        if let scrollView = scrollView, scrollView.contains(location) {
            isScrolling = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isScrolling, let scrollView = scrollView else { return }
        
        let location = touch.location(in: self)
        guard let lastLocation = lastTouchLocation else { return }
        
        let deltaY = location.y - lastLocation.y
        let currentY = scrollView.position.y
        let newY = currentY + deltaY
        
        // Get scroll constraints
        if let userData = scrollView.userData,
           let contentHeight = userData["contentHeight"] as? CGFloat,
           let visibleHeight = userData["visibleHeight"] as? CGFloat {
            
            let maxY = size.height/2 - 150 // Top limit
            let minY = maxY - (contentHeight - visibleHeight) // Bottom limit
            
            scrollView.position.y = max(minY, min(maxY, newY))
        }
        
        lastTouchLocation = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
        lastTouchLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrolling = false
        lastTouchLocation = nil
    }
    
    private func handleFilterSelection(_ node: SKNode) {
        // Visual feedback
        node.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Parse filter from node name
        if let name = node.name {
            let components = name.components(separatedBy: "_")
            if components.count > 1, let hashValue = Int(components[1]) {
                // Convert hash value back to rarity
                if hashValue == -1 {
                    currentFilter = nil // All
                } else {
                    currentFilter = AchievementRarity.allCases.first { $0.hashValue == hashValue }
                }
                
                // Refresh achievement list
                refreshAchievementList()
            }
        }
    }
    
    private func refreshAchievementList() {
        // Remove old achievement list
        scrollView?.removeAllChildren()
        
        // Recreate achievement list with new filter
        setupAchievementList()
    }
}