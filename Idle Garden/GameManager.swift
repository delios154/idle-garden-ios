//
//  GameManager.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import Foundation
import SpriteKit

class GameManager: ObservableObject {
    static let shared: GameManager = {
        let instance = GameManager()
        return instance
    }()
    
    @Published var gameState: GameState
    @Published var offlineProgress: (gpEarned: Int, plantsReady: Int) = (0, 0)
    
    private var updateTimer: Timer?
    private let saveInterval: TimeInterval = 30 // Save every 30 seconds
    private var isInitialized = false
    
    private init() {
        self.gameState = SaveManager.shared.loadGame()
    }
    
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        checkOfflineProgress()
        startUpdateTimer()
    }
    
    // MARK: - Game Initialization
    
    func startUpdateTimer() {
        updateTimer?.invalidate() // Prevent multiple timers
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
        
        // Ensure the plants array is large enough
        while gameState.plants.count <= plotIndex {
            let emptySlot = PlantData(
                typeId: "",
                plantedTime: Date(),
                lastHarvestTime: nil,
                level: 0,
                isReady: false
            )
            gameState.plants.append(emptySlot)
        }
        
        gameState.plants[plotIndex] = newPlant
        return true
    }
    
    func canPlantAtPlot(_ plotIndex: Int) -> Bool {
        let maxPlots = getMaxGardenPlots()
        if plotIndex >= maxPlots || plotIndex < 0 {
            return false
        }
        
        // Check if there's already a plant at this index
        if plotIndex < gameState.plants.count {
            let plant = gameState.plants[plotIndex]
            return plant.typeId.isEmpty || plant.level == 0
        }
        
        return true
    }
    
    func isPlotEmpty(_ plotIndex: Int) -> Bool {
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
            
            // Skip empty plots
            if plant.typeId.isEmpty || plant.level == 0 {
                continue
            }
            
            guard let plantType = plant.plantType else { continue }
            
            let timeSincePlanting = Date().timeIntervalSince(plant.plantedTime)
            let adjustedGrowthTime = plantType.growthTime / getGrowthSpeedMultiplier()
            
            if timeSincePlanting >= adjustedGrowthTime && !plant.isReady {
                gameState.plants[i].isReady = true
            }
        }
    }
    
    func harvestPlant(at index: Int) -> Int {
        guard index < gameState.plants.count else { return 0 }
        
        let plant = gameState.plants[index]
        guard plant.isReady, let plantType = plant.plantType else { return 0 }
        
        let gpEarned = calculateGpEarned(for: plant, plantType: plantType)
        
        // Reset plant for next cycle
        gameState.plants[index].plantedTime = Date()
        gameState.plants[index].lastHarvestTime = Date()
        gameState.plants[index].isReady = false
        
        gameState.gardenPoints += gpEarned
        
        return gpEarned
    }
    
    func calculateGpEarned(for plant: PlantData, plantType: PlantType) -> Int {
        let baseGp = Int(Double(plantType.gpPerHour) * (plantType.growthTime / 3600.0))
        let levelMultiplier = 1.0 + (Double(plant.level - 1) * 0.1) // 10% increase per level
        let upgradeMultiplier = getGpMultiplier()
        let prestigeMultiplier = getPrestigeMultiplier()
        
        return Int(Double(baseGp) * levelMultiplier * upgradeMultiplier * prestigeMultiplier)
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
        
        saveGame()
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
        
        let autoHarvestChance = Double(autoHarvestLevel) * 0.02 // 2% chance per level per second
        
        for i in 0..<gameState.plants.count {
            if gameState.plants[i].isReady && !gameState.plants[i].typeId.isEmpty {
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
            // Don't auto-apply offline progress, let the user claim it
            gameState.lastSaveTime = Date()
        }
    }
    
    func claimOfflineProgress() {
        gameState.gardenPoints += offlineProgress.gpEarned
        
        // Mark plants as ready if they finished growing offline
        for i in 0..<gameState.plants.count {
            let plant = gameState.plants[i]
            if !plant.typeId.isEmpty && !plant.isReady {
                if let plantType = plant.plantType {
                    let timeSincePlanting = Date().timeIntervalSince(plant.plantedTime)
                    let adjustedGrowthTime = plantType.growthTime / getGrowthSpeedMultiplier()
                    
                    if timeSincePlanting >= adjustedGrowthTime {
                        gameState.plants[i].isReady = true
                    }
                }
            }
        }
        
        offlineProgress = (0, 0)
        saveGame()
    }
    
    // MARK: - Prestige System
    
    func canPrestige() -> Bool {
        return gameState.gardenPoints >= 1000000 // 1M GP required for prestige
    }
    
    func calculateWisdomPoints() -> Int {
        let gp = Double(gameState.gardenPoints)
        return max(1, Int(sqrt(gp / 1000000))) // Square root of GP/1M, minimum 1
    }
    
    func performPrestige() -> Bool {
        guard canPrestige() else { return false }
        
        let wisdomPoints = calculateWisdomPoints()
        
        // Reset game state but keep wisdom points and prestige count
        let oldWisdomPoints = gameState.wisdomPoints
        let oldPrestigeCount = gameState.prestigeCount
        gameState = GameState()
        gameState.wisdomPoints = oldWisdomPoints + wisdomPoints
        gameState.prestigeCount = oldPrestigeCount + 1
        
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
        if number >= 1_000_000_000 {
            return String(format: "%.1fB", Double(number) / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        return TimeFormatter.formatTime(timeInterval)
    }
    
    // MARK: - Plant Management Helpers
    
    func getPlantAt(_ index: Int) -> PlantData? {
        guard index >= 0 && index < gameState.plants.count else { return nil }
        let plant = gameState.plants[index]
        return plant.typeId.isEmpty ? nil : plant
    }
    
    func removePlantAt(_ index: Int) {
        guard index >= 0 && index < gameState.plants.count else { return }
        gameState.plants[index] = PlantData(typeId: "", plantedTime: Date(), lastHarvestTime: nil, level: 0, isReady: false)
    }
    
    // MARK: - Statistics
    
    func getTotalPlantsGrown() -> Int {
        return gameState.plants.filter { !$0.typeId.isEmpty && $0.level > 0 }.count
    }
    
    func getTotalGPEarned() -> Int {
        // This would need to be tracked separately in game state for accuracy
        return gameState.gardenPoints
    }
    
    // MARK: - Cleanup
    
    deinit {
        updateTimer?.invalidate()
    }
}