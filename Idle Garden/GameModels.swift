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
        case .rare: return 3.0
        case .legendary: return 8.0
        case .prestige: return 15.0
        }
    }
    
    var gpPerHour: Int {
        switch self {
        case .basic: return 10
        case .rare: return 50
        case .legendary: return 200
        case .prestige: return 1000
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
        return baseGpPerHour * rarity.gpPerHour / 10
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
        guard let type = plantType else { return 0 }
        let elapsed = Date().timeIntervalSince(plantedTime)
        return max(0, type.growthTime - elapsed)
    }
    
    var progressPercentage: Double {
        guard let type = plantType else { return 0 }
        let elapsed = Date().timeIntervalSince(plantedTime)
        return min(1.0, elapsed / type.growthTime)
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
    
    init() {
        self.gardenPoints = 0
        self.seeds = 0
        self.plants = []
        self.upgrades = [:]
        self.lastSaveTime = Date()
        self.totalPlayTime = 0
        self.prestigeCount = 0
        self.wisdomPoints = 0
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
        case .plantSpeed: return 100
        case .gpMultiplier: return 200
        case .gardenPlots: return 500
        case .autoHarvest: return 1000
        case .offlineEfficiency: return 300
        }
    }
    
    var maxLevel: Int {
        switch self {
        case .plantSpeed: return 20
        case .gpMultiplier: return 15
        case .gardenPlots: return 10
        case .autoHarvest: return 5
        case .offlineEfficiency: return 10
        }
    }
    
    var costMultiplier: Double {
        switch self {
        case .plantSpeed: return 1.5
        case .gpMultiplier: return 2.0
        case .gardenPlots: return 3.0
        case .autoHarvest: return 2.5
        case .offlineEfficiency: return 1.8
        }
    }
}

// MARK: - Game Data Manager

class GameData {
    static let shared = GameData()
    
    let plantTypes: [PlantType] = [
        // Basic Plants
        PlantType(id: "carrot", name: "Carrot", rarity: .basic, baseGrowthTime: 30, baseGpPerHour: 10, unlockRequirement: 0, spriteName: "carrot"),
        PlantType(id: "tomato", name: "Tomato", rarity: .basic, baseGrowthTime: 60, baseGpPerHour: 15, unlockRequirement: 50, spriteName: "tomato"),
        PlantType(id: "flower", name: "Sunflower", rarity: .basic, baseGrowthTime: 120, baseGpPerHour: 20, unlockRequirement: 100, spriteName: "sunflower"),
        PlantType(id: "lettuce", name: "Lettuce", rarity: .basic, baseGrowthTime: 25, baseGpPerHour: 8, unlockRequirement: 25, spriteName: "lettuce"),
        PlantType(id: "potato", name: "Potato", rarity: .basic, baseGrowthTime: 90, baseGpPerHour: 25, unlockRequirement: 150, spriteName: "potato"),
        PlantType(id: "corn", name: "Corn", rarity: .basic, baseGrowthTime: 150, baseGpPerHour: 30, unlockRequirement: 200, spriteName: "corn"),
        
        // Rare Plants
        PlantType(id: "magic_flower", name: "Magic Flower", rarity: .rare, baseGrowthTime: 300, baseGpPerHour: 50, unlockRequirement: 500, spriteName: "magic_flower"),
        PlantType(id: "golden_fruit", name: "Golden Fruit", rarity: .rare, baseGrowthTime: 600, baseGpPerHour: 75, unlockRequirement: 1000, spriteName: "golden_fruit"),
        PlantType(id: "crystal_rose", name: "Crystal Rose", rarity: .rare, baseGrowthTime: 900, baseGpPerHour: 100, unlockRequirement: 2000, spriteName: "crystal_rose"),
        PlantType(id: "silver_vine", name: "Silver Vine", rarity: .rare, baseGrowthTime: 450, baseGpPerHour: 60, unlockRequirement: 750, spriteName: "silver_vine"),
        PlantType(id: "mystic_herb", name: "Mystic Herb", rarity: .rare, baseGrowthTime: 720, baseGpPerHour: 85, unlockRequirement: 1500, spriteName: "mystic_herb"),
        PlantType(id: "rainbow_tulip", name: "Rainbow Tulip", rarity: .rare, baseGrowthTime: 540, baseGpPerHour: 70, unlockRequirement: 1200, spriteName: "rainbow_tulip"),
        PlantType(id: "enchanted_berry", name: "Enchanted Berry", rarity: .rare, baseGrowthTime: 660, baseGpPerHour: 80, unlockRequirement: 1800, spriteName: "enchanted_berry"),
        
        // Legendary Plants
        PlantType(id: "dragon_fruit", name: "Dragon Fruit", rarity: .legendary, baseGrowthTime: 3600, baseGpPerHour: 200, unlockRequirement: 5000, spriteName: "dragon_fruit"),
        PlantType(id: "phoenix_flower", name: "Phoenix Flower", rarity: .legendary, baseGrowthTime: 7200, baseGpPerHour: 300, unlockRequirement: 10000, spriteName: "phoenix_flower"),
        PlantType(id: "star_plant", name: "Star Plant", rarity: .legendary, baseGrowthTime: 14400, baseGpPerHour: 500, unlockRequirement: 20000, spriteName: "star_plant"),
        PlantType(id: "cosmic_lily", name: "Cosmic Lily", rarity: .legendary, baseGrowthTime: 5400, baseGpPerHour: 250, unlockRequirement: 7500, spriteName: "cosmic_lily"),
        PlantType(id: "void_orchid", name: "Void Orchid", rarity: .legendary, baseGrowthTime: 9000, baseGpPerHour: 350, unlockRequirement: 15000, spriteName: "void_orchid"),
        PlantType(id: "celestial_bonsai", name: "Celestial Bonsai", rarity: .legendary, baseGrowthTime: 10800, baseGpPerHour: 400, unlockRequirement: 18000, spriteName: "celestial_bonsai"),
        PlantType(id: "time_blossom", name: "Time Blossom", rarity: .legendary, baseGrowthTime: 12600, baseGpPerHour: 450, unlockRequirement: 25000, spriteName: "time_blossom"),
        
        // Prestige Plants
        PlantType(id: "eternal_tree", name: "Eternal Tree", rarity: .prestige, baseGrowthTime: 86400, baseGpPerHour: 1000, unlockRequirement: 50000, spriteName: "eternal_tree"),
        PlantType(id: "world_seed", name: "World Seed", rarity: .prestige, baseGrowthTime: 43200, baseGpPerHour: 800, unlockRequirement: 35000, spriteName: "world_seed"),
        PlantType(id: "infinity_bloom", name: "Infinity Bloom", rarity: .prestige, baseGrowthTime: 64800, baseGpPerHour: 900, unlockRequirement: 40000, spriteName: "infinity_bloom"),
        PlantType(id: "genesis_plant", name: "Genesis Plant", rarity: .prestige, baseGrowthTime: 108000, baseGpPerHour: 1200, unlockRequirement: 75000, spriteName: "genesis_plant"),
        PlantType(id: "divine_sapling", name: "Divine Sapling", rarity: .prestige, baseGrowthTime: 129600, baseGpPerHour: 1500, unlockRequirement: 100000, spriteName: "divine_sapling")
    ]
    
    private init() {}
    
    func getPlantType(by id: String) -> PlantType? {
        return plantTypes.first { $0.id == id }
    }
    
    func getAvailablePlants(for gp: Int) -> [PlantType] {
        return plantTypes.filter { $0.unlockRequirement <= gp }
    }
}

// MARK: - Save System

class SaveManager {
    static let shared = SaveManager()
    
    private let saveKey = "IdleGardenSave"
    
    private init() {}
    
    func saveGame(_ gameState: GameState) {
        do {
            let data = try JSONEncoder().encode(gameState)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    func loadGame() -> GameState {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return GameState()
        }
        
        do {
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            return gameState
        } catch {
            print("Failed to load game: \(error)")
            return GameState()
        }
    }
    
    func calculateOfflineProgress(gameState: GameState) -> (gpEarned: Int, plantsReady: Int) {
        let now = Date()
        let timeDiff = now.timeIntervalSince(gameState.lastSaveTime)
        let maxOfflineTime: TimeInterval = 24 * 3600 // 24 hours
        
        let _ = min(timeDiff, maxOfflineTime)
        let offlineEfficiency = 0.8 // 80% efficiency when offline
        
        var totalGpEarned = 0
        var plantsReady = 0
        
        for plant in gameState.plants {
            guard let plantType = plant.plantType else { continue }
            
            let timeSincePlanting = now.timeIntervalSince(plant.plantedTime)
            let growthTime = plantType.growthTime
            
            if timeSincePlanting >= growthTime {
                let cycles = Int(timeSincePlanting / growthTime)
                let gpPerCycle = plantType.gpPerHour * Int(growthTime) / 3600
                totalGpEarned += cycles * gpPerCycle * Int(offlineEfficiency)
                plantsReady += 1
            }
        }
        
        return (totalGpEarned, plantsReady)
    }
} 