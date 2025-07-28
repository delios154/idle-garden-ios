//
//  GameModels.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import Foundation
import SpriteKit

// MARK: - Plant Types and Data

enum PlantRarity: String, CaseIterable, Codable {
    case basic = "Basic"
    case rare = "Rare"
    case legendary = "Legendary"
    case prestige = "Prestige"
    
    var color: UIColor {
        switch self {
        case .basic: return .systemGreen
        case .rare: return .systemBlue
        case .legendary: return .systemPurple
        case .prestige: return .systemOrange
        }
    }
    
    var growthTimeMultiplier: Double {
        switch self {
        case .basic: return 1.0
        case .rare: return 2.0
        case .legendary: return 4.0
        case .prestige: return 8.0
        }
    }
    
    var gpMultiplier: Int {
        switch self {
        case .basic: return 1
        case .rare: return 3
        case .legendary: return 8
        case .prestige: return 20
        }
    }
}

struct PlantType: Codable {
    let id: String
    let name: String
    let rarity: PlantRarity
    let baseGrowthTime: TimeInterval // in seconds
    let baseGpPerHour: Int
    let unlockRequirement: Int // GP required to unlock
    let spriteName: String
    
    var growthTime: TimeInterval {
        return baseGrowthTime * rarity.growthTimeMultiplier
    }
    
    var gpPerHour: Int {
        return baseGpPerHour * rarity.gpMultiplier
    }
}

struct PlantData: Codable {
    let typeId: String
    var plantedTime: Date
    var lastHarvestTime: Date?
    var level: Int
    var isReady: Bool
    
    var plantType: PlantType? {
        return GameData.shared.plantTypes.first { $0.id == typeId }
    }
    
    var timeUntilReady: TimeInterval {
        guard let type = plantType, !typeId.isEmpty, level > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(plantedTime)
        let adjustedGrowthTime = type.growthTime / GameManager.shared.getGrowthSpeedMultiplier()
        return max(0, adjustedGrowthTime - elapsed)
    }
    
    var progressPercentage: Double {
        guard let type = plantType, !typeId.isEmpty, level > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(plantedTime)
        let adjustedGrowthTime = type.growthTime / GameManager.shared.getGrowthSpeedMultiplier()
        return min(1.0, max(0.0, elapsed / adjustedGrowthTime))
    }
    
    var isEmpty: Bool {
        return typeId.isEmpty || level == 0
    }
}

// MARK: - Game State

struct GameState: Codable {
    var gardenPoints: Int
    var seeds: Int // Premium currency
    var plants: [PlantData]
    var upgrades: [String: Int] // upgradeId: level
    var lastSaveTime: Date
    var totalPlayTime: TimeInterval
    var prestigeCount: Int
    var wisdomPoints: Int
    var totalGpEarned: Int // Track lifetime GP earned
    var totalPlantsGrown: Int // Track total plants grown
    
    init() {
        self.gardenPoints = 10 // Start with some GP for first plant
        self.seeds = 5 // Start with some seeds
        self.plants = []
        self.upgrades = [:]
        self.lastSaveTime = Date()
        self.totalPlayTime = 0
        self.prestigeCount = 0
        self.wisdomPoints = 0
        self.totalGpEarned = 0
        self.totalPlantsGrown = 0
    }
}

// MARK: - Upgrade System

enum UpgradeType: String, CaseIterable, Codable {
    case plantSpeed = "Plant Speed"
    case gpMultiplier = "GP Multiplier"
    case gardenPlots = "Garden Plots"
    case autoHarvest = "Auto Harvest"
    case offlineEfficiency = "Offline Efficiency"
    
    var baseCost: Int {
        switch self {
        case .plantSpeed: return 50
        case .gpMultiplier: return 100
        case .gardenPlots: return 500
        case .autoHarvest: return 2000
        case .offlineEfficiency: return 300
        }
    }
    
    var maxLevel: Int {
        switch self {
        case .plantSpeed: return 50
        case .gpMultiplier: return 25
        case .gardenPlots: return 20
        case .autoHarvest: return 10
        case .offlineEfficiency: return 15
        }
    }
    
    var costMultiplier: Double {
        switch self {
        case .plantSpeed: return 1.3
        case .gpMultiplier: return 1.8
        case .gardenPlots: return 2.5
        case .autoHarvest: return 2.2
        case .offlineEfficiency: return 1.6
        }
    }
    
    var description: String {
        switch self {
        case .plantSpeed: return "Makes plants grow faster"
        case .gpMultiplier: return "Increases GP earned from harvests"
        case .gardenPlots: return "Unlocks additional garden plots"
        case .autoHarvest: return "Automatically harvests ready plants"
        case .offlineEfficiency: return "Improves offline progress efficiency"
        }
    }
}

// MARK: - Game Data Manager

class GameData {
    static let shared = GameData()
    
    let plantTypes: [PlantType] = [
        // Basic Plants - Quick growth, low rewards
        PlantType(id: "carrot", name: "Carrot", rarity: .basic, baseGrowthTime: 15, baseGpPerHour: 8, unlockRequirement: 0, spriteName: "carrot"),
        PlantType(id: "tomato", name: "Tomato", rarity: .basic, baseGrowthTime: 30, baseGpPerHour: 12, unlockRequirement: 50, spriteName: "tomato"),
        PlantType(id: "sunflower", name: "Sunflower", rarity: .basic, baseGrowthTime: 45, baseGpPerHour: 15, unlockRequirement: 150, spriteName: "sunflower"),
        PlantType(id: "lettuce", name: "Lettuce", rarity: .basic, baseGrowthTime: 60, baseGpPerHour: 20, unlockRequirement: 300, spriteName: "lettuce"),
        
        // Rare Plants - Medium growth, good rewards
        PlantType(id: "magic_flower", name: "Magic Flower", rarity: .rare, baseGrowthTime: 120, baseGpPerHour: 30, unlockRequirement: 1000, spriteName: "magic_flower"),
        PlantType(id: "golden_fruit", name: "Golden Fruit", rarity: .rare, baseGrowthTime: 180, baseGpPerHour: 45, unlockRequirement: 2500, spriteName: "golden_fruit"),
        PlantType(id: "crystal_rose", name: "Crystal Rose", rarity: .rare, baseGrowthTime: 300, baseGpPerHour: 60, unlockRequirement: 5000, spriteName: "crystal_rose"),
        PlantType(id: "rainbow_tulip", name: "Rainbow Tulip", rarity: .rare, baseGrowthTime: 420, baseGpPerHour: 80, unlockRequirement: 10000, spriteName: "rainbow_tulip"),
        
        // Legendary Plants - Long growth, high rewards
        PlantType(id: "dragon_fruit", name: "Dragon Fruit", rarity: .legendary, baseGrowthTime: 900, baseGpPerHour: 120, unlockRequirement: 25000, spriteName: "dragon_fruit"),
        PlantType(id: "phoenix_flower", name: "Phoenix Flower", rarity: .legendary, baseGrowthTime: 1800, baseGpPerHour: 200, unlockRequirement: 50000, spriteName: "phoenix_flower"),
        PlantType(id: "star_plant", name: "Star Plant", rarity: .legendary, baseGrowthTime: 3600, baseGpPerHour: 300, unlockRequirement: 100000, spriteName: "star_plant"),
        PlantType(id: "moon_blossom", name: "Moon Blossom", rarity: .legendary, baseGrowthTime: 5400, baseGpPerHour: 450, unlockRequirement: 200000, spriteName: "moon_blossom"),
        
        // Prestige Plants - Very long growth, massive rewards
        PlantType(id: "eternal_tree", name: "Eternal Tree", rarity: .prestige, baseGrowthTime: 14400, baseGpPerHour: 800, unlockRequirement: 500000, spriteName: "eternal_tree"),
        PlantType(id: "cosmic_vine", name: "Cosmic Vine", rarity: .prestige, baseGrowthTime: 28800, baseGpPerHour: 1500, unlockRequirement: 1000000, spriteName: "cosmic_vine")
    ]
    
    private init() {}
    
    func getPlantType(by id: String) -> PlantType? {
        return plantTypes.first { $0.id == id }
    }
    
    func getAvailablePlants(for gp: Int) -> [PlantType] {
        return plantTypes.filter { $0.unlockRequirement <= gp }
    }
    
    func getPlantsByRarity(_ rarity: PlantRarity) -> [PlantType] {
        return plantTypes.filter { $0.rarity == rarity }
    }
    
    func getNextPlantToUnlock(currentGp: Int) -> PlantType? {
        let locked = plantTypes.filter { $0.unlockRequirement > currentGp }
        return locked.min { $0.unlockRequirement < $1.unlockRequirement }
    }
}

// MARK: - Statistics Manager

class GameStatistics {
    static let shared = GameStatistics()
    private init() {}
    
    func getPlayTime() -> TimeInterval {
        // This would be calculated based on session tracking
        return GameManager.shared.gameState.totalPlayTime
    }
    
    func getLifetimeGP() -> Int {
        return GameManager.shared.gameState.totalGpEarned
    }
    
    func getTotalPlantsGrown() -> Int {
        return GameManager.shared.gameState.totalPlantsGrown
    }
    
    func getAverageGpPerHour() -> Double {
        let playTime = getPlayTime()
        guard playTime > 0 else { return 0 }
        return Double(getLifetimeGP()) / (playTime / 3600.0)
    }
    
    func getCurrentPlantsCount() -> Int {
        return GameManager.shared.gameState.plants.filter { !$0.isEmpty }.count
    }
    
    func getReadyPlantsCount() -> Int {
        return GameManager.shared.gameState.plants.filter { $0.isReady && !$0.isEmpty }.count
    }
}

// MARK: - Save System

class SaveManager {
    static let shared = SaveManager()
    
    private let saveKey = "IdleGardenSave"
    private let backupSaveKey = "IdleGardenBackup"
    
    private init() {}
    
    func saveGame(_ gameState: GameState) {
        do {
            // Create backup of current save
            if let currentData = UserDefaults.standard.data(forKey: saveKey) {
                UserDefaults.standard.set(currentData, forKey: backupSaveKey)
            }
            
            // Save new data
            let data = try JSONEncoder().encode(gameState)
            UserDefaults.standard.set(data, forKey: saveKey)
            
            print("Game saved successfully")
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    func loadGame() -> GameState {
        // Try to load main save first
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let gameState = try JSONDecoder().decode(GameState.self, from: data)
                print("Game loaded successfully")
                return gameState
            } catch {
                print("Failed to load main save: \(error)")
                
                // Try backup save
                if let backupData = UserDefaults.standard.data(forKey: backupSaveKey) {
                    do {
                        let gameState = try JSONDecoder().decode(GameState.self, from: backupData)
                        print("Loaded from backup save")
                        return gameState
                    } catch {
                        print("Failed to load backup save: \(error)")
                    }
                }
            }
        }
        
        print("Creating new game state")
        return GameState()
    }
    
    func calculateOfflineProgress(gameState: GameState) -> (gpEarned: Int, plantsReady: Int) {
        let now = Date()
        let timeDiff = now.timeIntervalSince(gameState.lastSaveTime)
        let maxOfflineTime: TimeInterval = 24 * 3600 // 24 hours max
        
        // Don't calculate progress for very short periods or future dates
        guard timeDiff > 30 && timeDiff < maxOfflineTime * 2 else {
            return (0, 0)
        }
        
        let effectiveOfflineTime = min(timeDiff, maxOfflineTime)
        let offlineEfficiency = 0.8 // Default offline efficiency
        
        var totalGpEarned = 0
        var plantsReady = 0
        
        for plant in gameState.plants {
            guard !plant.isEmpty, let plantType = plant.plantType else { continue }
            
            let timeSincePlanting = now.timeIntervalSince(plant.plantedTime)
            let adjustedGrowthTime = plantType.growthTime // Use base growth time for offline calculation
            
            if timeSincePlanting >= adjustedGrowthTime {
                // Calculate how many harvest cycles occurred
                let cycles = Int(effectiveOfflineTime / adjustedGrowthTime)
                if cycles > 0 {
                    let gpPerCycle = calculateBaseGpEarned(for: plant, plantType: plantType)
                    totalGpEarned += Int(Double(cycles * gpPerCycle) * offlineEfficiency)
                    plantsReady += 1
                }
            }
        }
        
        return (totalGpEarned, plantsReady)
    }
    
    private func calculateBaseGpEarned(for plant: PlantData, plantType: PlantType) -> Int {
        let baseGp = plantType.gpPerHour * Int(plantType.growthTime) / 3600
        let levelMultiplier = 1.0 + (Double(plant.level - 1) * 0.1) // 10% increase per level
        return Int(Double(baseGp) * levelMultiplier)
    }
    
    func exportSave() -> String? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        return data.base64EncodedString()
    }
    
    func importSave(from base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String) else { return false }
        
        do {
            // Validate the data can be decoded
            _ = try JSONDecoder().decode(GameState.self, from: data)
            
            // Save as main save
            UserDefaults.standard.set(data, forKey: saveKey)
            return true
        } catch {
            print("Failed to import save: \(error)")
            return false
        }
    }
    
    func deleteSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: backupSaveKey)
    }
}

// MARK: - Game Configuration

struct GameConfig {
    static let maxPlants = 100
    static let maxOfflineHours = 24
    static let autoSaveInterval: TimeInterval = 30
    static let updateInterval: TimeInterval = 1.0
    
    // Balance constants
    static let prestigeRequirement = 1_000_000
    static let maxWisdomPoints = 100
    static let seedsFromAchievements = true
    
    // UI Constants
    static let animationDuration: TimeInterval = 0.3
    static let feedbackDuration: TimeInterval = 0.1
    
    // Debug settings
    static let showDebugInfo = false
    static let fastGrowth = false // For testing
    static let unlockAllPlants = false // For testing
}

// MARK: - Extensions

extension Date {
    func timeAgo() -> String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

extension PlantData {
    mutating func reset() {
        self.plantedTime = Date()
        self.lastHarvestTime = Date()
        self.isReady = false
    }
    
    var canHarvest: Bool {
        return isReady && !isEmpty
    }
    
    var timeToReadyString: String {
        if isReady {
            return "Ready!"
        } else {
            return TimeFormatter.formatTime(timeUntilReady)
        }
    }
}

// MARK: - Time Formatter Utility

struct TimeFormatter {
    static func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}