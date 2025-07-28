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
            return "Plant 10 different types of plants"
        case .speedDemon:
            return "Reach 5x growth speed multiplier"
        case .millionaire:
            return "Earn 1,000,000 Garden Points"
        case .prestigeMaster:
            return "Perform 5 garden rebirths"
        case .collector:
            return "Unlock all plant types"
        case .timeTraveler:
            return "Accumulate 24 hours of offline progress"
        }
    }
    
    var reward: Int {
        switch self {
        case .firstHarvest: return 10
        case .firstUpgrade: return 25
        case .plantMaster: return 100
        case .speedDemon: return 250
        case .millionaire: return 1000
        case .prestigeMaster: return 500
        case .collector: return 750
        case .timeTraveler: return 300
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
        }
    }
}

// MARK: - Achievement Data

struct Achievement: Codable {
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    init(type: AchievementType) {
        self.type = type
        self.isUnlocked = false
        self.unlockedDate = nil
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var achievements: [Achievement]
    @Published var recentlyUnlocked: [Achievement] = []
    
    private let saveKey = "Achievements"
    
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
    }
    
    private func checkFirstHarvest(gameState: GameState) {
        let achievement = getAchievement(.firstHarvest)
        if !achievement.isUnlocked && gameState.gardenPoints > 0 {
            unlockAchievement(.firstHarvest)
        }
    }
    
    private func checkFirstUpgrade(gameState: GameState) {
        let achievement = getAchievement(.firstUpgrade)
        if !achievement.isUnlocked && !gameState.upgrades.isEmpty {
            unlockAchievement(.firstUpgrade)
        }
    }
    
    private func checkPlantMaster(gameState: GameState) {
        let achievement = getAchievement(.plantMaster)
        if !achievement.isUnlocked {
            let uniquePlants = Set(gameState.plants.map { $0.typeId })
            if uniquePlants.count >= 10 {
                unlockAchievement(.plantMaster)
            }
        }
    }
    
    private func checkSpeedDemon(gameState: GameState) {
        let achievement = getAchievement(.speedDemon)
        if !achievement.isUnlocked {
            let speedLevel = gameState.upgrades[UpgradeType.plantSpeed.rawValue] ?? 0
            if speedLevel >= 10 { // 10 levels = 2x speed, 20 levels = 3x speed, etc.
                unlockAchievement(.speedDemon)
            }
        }
    }
    
    private func checkMillionaire(gameState: GameState) {
        let achievement = getAchievement(.millionaire)
        if !achievement.isUnlocked && gameState.gardenPoints >= 1_000_000 {
            unlockAchievement(.millionaire)
        }
    }
    
    private func checkPrestigeMaster(gameState: GameState) {
        let achievement = getAchievement(.prestigeMaster)
        if !achievement.isUnlocked && gameState.prestigeCount >= 5 {
            unlockAchievement(.prestigeMaster)
        }
    }
    
    private func checkCollector(gameState: GameState) {
        let achievement = getAchievement(.collector)
        if !achievement.isUnlocked {
            let unlockedPlants = GameData.shared.plantTypes.filter { plantType in
                gameState.gardenPoints >= plantType.unlockRequirement
            }
            if unlockedPlants.count >= GameData.shared.plantTypes.count {
                unlockAchievement(.collector)
            }
        }
    }
    
    private func checkTimeTraveler(gameState: GameState) {
        let achievement = getAchievement(.timeTraveler)
        if !achievement.isUnlocked {
            // This would need to be tracked separately in game state
            // For now, we'll use a placeholder
            let offlineTime = Date().timeIntervalSince(gameState.lastSaveTime)
            if offlineTime >= 24 * 3600 { // 24 hours
                unlockAchievement(.timeTraveler)
            }
        }
    }
    
    // MARK: - Achievement Management
    
    private func unlockAchievement(_ type: AchievementType) {
        guard let index = achievements.firstIndex(where: { $0.type == type }) else { return }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        
        // Add to recently unlocked
        recentlyUnlocked.append(achievements[index])
        
        // Award seeds
        let reward = type.reward
        GameManager.shared.gameState.seeds += reward
        
        // Save achievements
        saveAchievements()
        
        // Show notification
        showAchievementNotification(achievements[index])
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
            achievements = try JSONDecoder().decode([Achievement].self, from: data)
        } catch {
            print("Failed to load achievements: \(error)")
            achievements = AchievementType.allCases.map { Achievement(type: $0) }
        }
    }
    
    // MARK: - UI
    
    private func showAchievementNotification(_ achievement: Achievement) {
        // This would be implemented in the UI layer
        print("Achievement Unlocked: \(achievement.type.title)")
    }
    
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
}

// MARK: - Achievement UI

class AchievementNotification: SKNode {
    
    private var background: SKSpriteNode?
    private var iconLabel: SKLabelNode?
    private var titleLabel: SKLabelNode?
    private var rewardLabel: SKLabelNode?
    
    func showAchievement(_ achievement: Achievement) {
        removeAllChildren()
        
        // Background
        background = SKSpriteNode(color: .purple, size: CGSize(width: 280, height: 80))
        background?.position = CGPoint.zero
        background?.zPosition = 1000
        addChild(background!)
        
        // Icon
        iconLabel = SKLabelNode(text: achievement.type.icon)
        iconLabel?.fontSize = 30
        iconLabel?.position = CGPoint(x: -100, y: 0)
        iconLabel?.zPosition = 1001
        addChild(iconLabel!)
        
        // Title
        titleLabel = SKLabelNode(text: achievement.type.title)
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 16
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: 0, y: 10)
        titleLabel?.zPosition = 1001
        addChild(titleLabel!)
        
        // Reward
        rewardLabel = SKLabelNode(text: "+\(achievement.type.reward) Seeds")
        rewardLabel?.fontName = "AvenirNext-Regular"
        rewardLabel?.fontSize = 12
        rewardLabel?.fontColor = .yellow
        rewardLabel?.position = CGPoint(x: 0, y: -10)
        rewardLabel?.zPosition = 1001
        addChild(rewardLabel!)
        
        // Animation
        alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        run(sequence)
    }
}

// MARK: - Achievement Menu

protocol AchievementMenuDelegate: AnyObject {
    func achievementMenuClosed()
}

class AchievementMenuNode: SKSpriteNode {
    
    weak var delegate: AchievementMenuDelegate?
    private var closeButton: SKSpriteNode?
    private var scrollView: SKNode?
    
    init(size: CGSize) {
        super.init(texture: nil, color: .white, size: size)
        setupAchievementMenu()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAchievementMenu()
    }
    
    private func setupAchievementMenu() {
        // Title
        let titleLabel = SKLabelNode(text: "Achievements")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: 0, y: size.height/2 - 30)
        addChild(titleLabel)
        
        // Progress
        let progress = AchievementManager.shared.getProgress()
        let progressLabel = SKLabelNode(text: "\(AchievementManager.shared.getUnlockedCount())/\(AchievementManager.shared.getTotalCount()) (\(Int(progress * 100))%)")
        progressLabel.fontName = "AvenirNext-Regular"
        progressLabel.fontSize = 16
        progressLabel.fontColor = .black
        progressLabel.position = CGPoint(x: 0, y: size.height/2 - 60)
        addChild(progressLabel)
        
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
        
        // Achievement list
        setupAchievementList()
        
        // Add touch handling
        isUserInteractionEnabled = true
    }
    
    private func setupAchievementList() {
        scrollView = SKNode()
        scrollView?.position = CGPoint(x: 0, y: size.height/2 - 100)
        addChild(scrollView!)
        
        let buttonHeight: CGFloat = 60
        let spacing: CGFloat = 10
        
        for (index, achievement) in AchievementManager.shared.achievements.enumerated() {
            let button = createAchievementButton(achievement)
            button.position = CGPoint(x: 0, y: -CGFloat(index) * (buttonHeight + spacing))
            scrollView?.addChild(button)
        }
    }
    
    private func createAchievementButton(_ achievement: Achievement) -> SKSpriteNode {
        let button = SKSpriteNode(color: achievement.isUnlocked ? .green : .gray, size: CGSize(width: size.width - 40, height: 60))
        
        // Icon
        let icon = SKLabelNode(text: achievement.type.icon)
        icon.fontSize = 24
        icon.position = CGPoint(x: -button.size.width/2 + 40, y: 0)
        button.addChild(icon)
        
        // Title
        let title = SKLabelNode(text: achievement.type.title)
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 16
        title.fontColor = .white
        title.position = CGPoint(x: -button.size.width/2 + 80, y: 10)
        button.addChild(title)
        
        // Description
        let description = SKLabelNode(text: achievement.type.description)
        description.fontName = "AvenirNext-Regular"
        description.fontSize = 12
        description.fontColor = .white
        description.position = CGPoint(x: -button.size.width/2 + 80, y: -10)
        button.addChild(description)
        
        // Reward
        let reward = SKLabelNode(text: "+\(achievement.type.reward) Seeds")
        reward.fontName = "AvenirNext-Regular"
        reward.fontSize = 12
        reward.fontColor = .yellow
        reward.position = CGPoint(x: button.size.width/2 - 60, y: 0)
        button.addChild(reward)
        
        // Lock icon if not unlocked
        if !achievement.isUnlocked {
            let lock = SKLabelNode(text: "🔒")
            lock.fontSize = 20
            lock.position = CGPoint(x: button.size.width/2 - 20, y: 0)
            button.addChild(lock)
        }
        
        return button
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if closeButton?.contains(location) == true {
            delegate?.achievementMenuClosed()
        }
    }
} 