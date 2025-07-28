//
//  GameManager.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import Foundation
import SpriteKit

class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var gameState: GameState
    @Published var offlineProgress: (gpEarned: Int, plantsReady: Int) = (0, 0)
    
    private var updateTimer: Timer?
    private let saveInterval: TimeInterval = 30 // Save every 30 seconds
    
    private init() {
        self.gameState = SaveManager.shared.loadGame()
        checkOfflineProgress()
        startUpdateTimer()
    }
    
    // MARK: - Game Initialization
    
    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    func updateGame() {
        updatePlants()
        checkForAutoHarvest()
        
        // Check achievements
        AchievementManager.shared.checkAchievements(gameState: gameState)
        
        // Auto-save periodically
        if Date().timeIntervalSince(gameState.lastSaveTime) >= saveInterval {
            saveGame()
        }
    }
    
    // MARK: - Plant Management
    
    func plantSeed(_ plantType: PlantType, at plotIndex: Int) -> Bool {
        guard canPlantAtPlot(plotIndex) else { return false }
        
        let newPlant = PlantData(
            typeId: plantType.id,
            plantedTime: Date(),
            lastHarvestTime: nil,
            level: 1,
            isReady: false
        )
        
        // Ensure plants array is large enough to accommodate the plot index
        while gameState.plants.count <= plotIndex {
            gameState.plants.append(PlantData(typeId: "", plantedTime: Date(), lastHarvestTime: nil, level: 0, isReady: false))
        }
        
        gameState.plants[plotIndex] = newPlant
        return true
    }
    
    func canPlantAtPlot(_ plotIndex: Int) -> Bool {
        let maxPlots = getMaxGardenPlots()
        guard plotIndex < maxPlots && plotIndex >= 0 else { return false }
        
        // Check if plot is empty (either no plant at index or invalid plant)
        if plotIndex >= gameState.plants.count {
            return true
        }
        
        let plant = gameState.plants[plotIndex]
        return plant.typeId.isEmpty || plant.level == 0
    }
    
    func getMaxGardenPlots() -> Int {
        let basePlots = 9 // 3x3 grid
        let upgradeLevel = gameState.upgrades[UpgradeType.gardenPlots.rawValue] ?? 0
        return basePlots + (upgradeLevel * 3) // Each upgrade adds 3 plots
    }
    
    func updatePlants() {
        for i in 0..<gameState.plants.count {
            let plant = gameState.plants[i]
            guard !plant.typeId.isEmpty, 
                  plant.level > 0,
                  let plantType = plant.plantType else { continue }
            
            let timeSincePlanting = Date().timeIntervalSince(plant.plantedTime)
            let growthTime = plantType.growthTime
            
            if timeSincePlanting >= growthTime && !plant.isReady {
                gameState.plants[i].isReady = true
            }
        }
    }
    
    func harvestPlant(at index: Int) -> Int {
        guard index < gameState.plants.count else { return 0 }
        
        let plant = gameState.plants[index]
        guard plant.isReady, 
              !plant.typeId.isEmpty, 
              plant.level > 0,
              let plantType = plant.plantType else { return 0 }
        
        let gpEarned = calculateGpEarned(for: plant, plantType: plantType)
        
        // Reset plant for next cycle
        gameState.plants[index].plantedTime = Date()
        gameState.plants[index].lastHarvestTime = Date()
        gameState.plants[index].isReady = false
        
        gameState.gardenPoints += gpEarned
        
        return gpEarned
    }
    
    func calculateGpEarned(for plant: PlantData, plantType: PlantType) -> Int {
        let baseGp = Double(plantType.gpPerHour) * plantType.growthTime / 3600.0
        let levelMultiplier = 1.0 + (Double(plant.level - 1) * 0.1) // 10% increase per level
        let upgradeMultiplier = getGpMultiplier()
        
        let finalGp = baseGp * levelMultiplier * upgradeMultiplier
        return max(1, Int(finalGp)) // Ensure at least 1 GP is earned
    }
    
    // MARK: - Upgrade System
    
    func canAffordUpgrade(_ upgradeType: UpgradeType) -> Bool {
        let currentLevel = gameState.upgrades[upgradeType.rawValue] ?? 0
        let cost = calculateUpgradeCost(upgradeType, level: currentLevel)
        return gameState.gardenPoints >= cost && currentLevel < upgradeType.maxLevel
    }
    
    func calculateUpgradeCost(_ upgradeType: UpgradeType, level: Int) -> Int {
        let baseCost = upgradeType.baseCost
        let multiplier = pow(upgradeType.costMultiplier, Double(level))
        return Int(Double(baseCost) * multiplier)
    }
    
    func purchaseUpgrade(_ upgradeType: UpgradeType) -> Bool {
        guard canAffordUpgrade(upgradeType) else { return false }
        
        let currentLevel = gameState.upgrades[upgradeType.rawValue] ?? 0
        let cost = calculateUpgradeCost(upgradeType, level: currentLevel)
        
        gameState.gardenPoints -= cost
        gameState.upgrades[upgradeType.rawValue] = currentLevel + 1
        
        return true
    }
    
    func getUpgradeLevel(_ upgradeType: UpgradeType) -> Int {
        return gameState.upgrades[upgradeType.rawValue] ?? 0
    }
    
    // MARK: - Upgrade Effects
    
    func getGrowthSpeedMultiplier() -> Double {
        let level = getUpgradeLevel(.plantSpeed)
        return 1.0 + (Double(level) * 0.1) // 10% faster per level
    }
    
    func getGpMultiplier() -> Double {
        let level = getUpgradeLevel(.gpMultiplier)
        return 1.0 + (Double(level) * 0.2) // 20% more GP per level
    }
    
    func getOfflineEfficiency() -> Double {
        let level = getUpgradeLevel(.offlineEfficiency)
        let baseEfficiency = 0.8
        let bonus = Double(level) * 0.02 // 2% bonus per level
        return min(1.0, baseEfficiency + bonus)
    }
    
    // MARK: - Auto Harvest
    
    func checkForAutoHarvest() {
        let autoHarvestLevel = getUpgradeLevel(.autoHarvest)
        guard autoHarvestLevel > 0 else { return }
        
        let autoHarvestChance = Double(autoHarvestLevel) * 0.1 // 10% chance per level
        
        for i in 0..<gameState.plants.count {
            if gameState.plants[i].isReady {
                if Double.random(in: 0...1) < autoHarvestChance {
                    _ = harvestPlant(at: i)
                }
            }
        }
    }
    
    // MARK: - Offline Progress
    
    func checkOfflineProgress() {
        let progress = SaveManager.shared.calculateOfflineProgress(gameState: gameState)
        offlineProgress = progress
        
        if progress.gpEarned > 0 || progress.plantsReady > 0 {
            gameState.gardenPoints += progress.gpEarned
            gameState.lastSaveTime = Date()
        }
    }
    
    func claimOfflineProgress() {
        gameState.gardenPoints += offlineProgress.gpEarned
        offlineProgress = (0, 0)
        saveGame()
    }
    
    // MARK: - Prestige System
    
    func canPrestige() -> Bool {
        return gameState.gardenPoints >= 1000000 // 1M GP required for prestige
    }
    
    func calculateWisdomPoints() -> Int {
        let gp = Double(gameState.gardenPoints)
        return Int(sqrt(gp / 1000000)) // Square root of GP/1M
    }
    
    func performPrestige() -> Bool {
        guard canPrestige() else { return false }
        
        let wisdomPoints = calculateWisdomPoints()
        
        // Reset game state but keep wisdom points
        let oldWisdomPoints = gameState.wisdomPoints
        gameState = GameState()
        gameState.wisdomPoints = oldWisdomPoints + wisdomPoints
        gameState.prestigeCount += 1
        
        saveGame()
        return true
    }
    
    func getPrestigeMultiplier() -> Double {
        return 1.0 + (Double(gameState.wisdomPoints) * 0.1) // 10% bonus per wisdom point
    }
    
    func resetGame() {
        // Reset all game state to initial values
        gameState = GameState()
        saveGame()
    }
    
    // MARK: - Save System
    
    func saveGame() {
        gameState.lastSaveTime = Date()
        SaveManager.shared.saveGame(gameState)
    }
    
    func loadGame() {
        gameState = SaveManager.shared.loadGame()
        checkOfflineProgress()
    }
    
    // MARK: - Utility Functions
    
    func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        updateTimer?.invalidate()
    }
} 