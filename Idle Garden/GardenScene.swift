//
//  GardenScene.swift
//  Idle Garden
//
//  Created by Mohammed Almansoori on 28/07/2025.
//

import SpriteKit
import GameplayKit

class GardenScene: SKScene {
    
    // MARK: - Properties
    
    private var gameManager = GameManager.shared
    private var gardenGrid: [[GardenPlot]] = []
    private var topBar: TopBarNode?
    private var bottomToolbar: BottomToolbarNode?
    private var plantShop: PlantShopNode?
    private var upgradeMenu: UpgradeMenuNode?
    private var settingsMenu: SettingsMenuNode?
    
    // UI Elements
    private var gpLabel: SKLabelNode?
    private var seedsLabel: SKLabelNode?
    private var offlineProgressNode: OfflineProgressNode?
    
    // Constants
    private let gridSize = CGSize(width: 80, height: 80)
    private let gridSpacing: CGFloat = 10
    private let topBarHeight: CGFloat = 100
    private let bottomBarHeight: CGFloat = 120
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        setupScene()
        setupGardenGrid()
        setupUI()
        setupGameManager()
    }
    
    private func setupScene() {
        // Set up physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        // Add background
        let background = SKSpriteNode(color: .clear, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
    }
    
    private func setupGardenGrid() {
        let maxPlots = gameManager.getMaxGardenPlots()
        let gridWidth = Int(sqrt(Double(maxPlots)))
        let gridHeight = (maxPlots + gridWidth - 1) / gridWidth
        
        let totalGridWidth = CGFloat(gridWidth) * gridSize.width + CGFloat(gridWidth - 1) * gridSpacing
        let totalGridHeight = CGFloat(gridHeight) * gridSize.height + CGFloat(gridHeight - 1) * gridSpacing
        
        let startX = (size.width - totalGridWidth) / 2
        let startY = (size.height - totalGridHeight) / 2 + bottomBarHeight
        
        gardenGrid = Array(repeating: Array(repeating: GardenPlot(size: gridSize), count: gridWidth), count: gridHeight)
        
        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let plotIndex = row * gridWidth + col
                if plotIndex >= maxPlots { break }
                
                let plot = GardenPlot(size: gridSize)
                plot.position = CGPoint(
                    x: startX + CGFloat(col) * (gridSize.width + gridSpacing) + gridSize.width/2,
                    y: startY + CGFloat(row) * (gridSize.height + gridSpacing) + gridSize.height/2
                )
                plot.plotIndex = plotIndex
                plot.delegate = self
                
                gardenGrid[row][col] = plot
                addChild(plot)
                
                // Load existing plant if any
                if plotIndex < gameManager.gameState.plants.count {
                    let plantData = gameManager.gameState.plants[plotIndex]
                    if !plantData.typeId.isEmpty && plantData.level > 0 {
                        plot.setPlant(plantData)
                    }
                }
            }
        }
    }
    
    private func setupUI() {
        setupTopBar()
        setupBottomToolbar()
        setupOfflineProgress()
        setupTutorial()
    }
    
    private func setupTopBar() {
        topBar = TopBarNode(size: CGSize(width: size.width, height: topBarHeight))
        topBar?.position = CGPoint(x: size.width/2, y: size.height - topBarHeight/2)
        topBar?.delegate = self
        addChild(topBar!)
        
        // Update labels
        updateGPLabel()
        updateSeedsLabel()
    }
    
    private func setupBottomToolbar() {
        bottomToolbar = BottomToolbarNode(size: CGSize(width: size.width, height: bottomBarHeight))
        bottomToolbar?.position = CGPoint(x: size.width/2, y: bottomBarHeight/2)
        bottomToolbar?.delegate = self
        addChild(bottomToolbar!)
    }
    
    private func setupOfflineProgress() {
        offlineProgressNode = OfflineProgressNode()
        offlineProgressNode?.position = CGPoint(x: size.width/2, y: size.height/2)
        offlineProgressNode?.delegate = self
        addChild(offlineProgressNode!)
        
        // Check if there's offline progress to show
        if gameManager.offlineProgress.gpEarned > 0 || gameManager.offlineProgress.plantsReady > 0 {
            offlineProgressNode?.showOfflineProgress(gameManager.offlineProgress)
        }
    }
    
    private func setupGameManager() {
        // Observe game state changes
        gameManager.$gameState
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        updateGPLabel()
        updateSeedsLabel()
        updateGardenGrid()
    }
    
    private func updateGPLabel() {
        topBar?.updateGP(gameManager.gameState.gardenPoints)
    }
    
    private func updateSeedsLabel() {
        topBar?.updateSeeds(gameManager.gameState.seeds)
    }
    
    private func updateGardenGrid() {
        for row in gardenGrid {
            for plot in row {
                plot.updatePlant()
            }
        }
    }
    
    // MARK: - Plant Shop
    
    private func showPlantShop() {
        plantShop = PlantShopNode(size: CGSize(width: size.width * 0.9, height: size.height * 0.8))
        plantShop?.position = CGPoint(x: size.width/2, y: size.height/2)
        plantShop?.delegate = self
        plantShop?.zPosition = 100
        addChild(plantShop!)
        
        // Add dimming background
        let dimBackground = SKSpriteNode(color: .black, size: size)
        dimBackground.alpha = 0.5
        dimBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        dimBackground.zPosition = 99
        dimBackground.name = "dimBackground"
        addChild(dimBackground)
    }
    
    private func hidePlantShop() {
        plantShop?.removeFromParent()
        plantShop = nil
        childNode(withName: "dimBackground")?.removeFromParent()
    }
    
    // MARK: - Upgrade Menu
    
    private func showUpgradeMenu() {
        upgradeMenu = UpgradeMenuNode(size: CGSize(width: size.width * 0.9, height: size.height * 0.8))
        upgradeMenu?.position = CGPoint(x: size.width/2, y: size.height/2)
        upgradeMenu?.delegate = self
        upgradeMenu?.zPosition = 100
        addChild(upgradeMenu!)
        
        // Add dimming background
        let dimBackground = SKSpriteNode(color: .black, size: size)
        dimBackground.alpha = 0.5
        dimBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        dimBackground.zPosition = 99
        dimBackground.name = "dimBackground"
        addChild(dimBackground)
    }
    
    private func hideUpgradeMenu() {
        upgradeMenu?.removeFromParent()
        upgradeMenu = nil
        childNode(withName: "dimBackground")?.removeFromParent()
    }
    
    // MARK: - Achievement Menu
    
    private func showAchievementMenu() {
        let achievementMenu = AchievementMenuNode(size: CGSize(width: size.width * 0.9, height: size.height * 0.8))
        achievementMenu.position = CGPoint(x: size.width/2, y: size.height/2)
        achievementMenu.zPosition = 100
        addChild(achievementMenu)
        
        // Add dimming background
        let dimBackground = SKSpriteNode(color: .black, size: size)
        dimBackground.alpha = 0.5
        dimBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        dimBackground.zPosition = 99
        dimBackground.name = "dimBackground"
        addChild(dimBackground)
    }
    
    // MARK: - Settings Menu
    
    private func showSettingsMenu() {
        guard settingsMenu == nil else { return }
        
        settingsMenu = SettingsMenuNode(size: CGSize(width: 300, height: 400))
        settingsMenu?.position = CGPoint(x: size.width/2, y: size.height/2)
        settingsMenu?.zPosition = 1000
        settingsMenu?.delegate = self
        addChild(settingsMenu!)
        
        // Add dimming background
        let dimBackground = SKSpriteNode(color: .black, size: size)
        dimBackground.alpha = 0.5
        dimBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        dimBackground.zPosition = 999
        dimBackground.name = "settingsDimBackground"
        addChild(dimBackground)
    }
    
    private func hideSettingsMenu() {
        settingsMenu?.removeFromParent()
        settingsMenu = nil
        
        // Remove dimming background
        childNode(withName: "settingsDimBackground")?.removeFromParent()
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if touch is on UI elements
        if let topBar = topBar, topBar.contains(location) {
            return
        }
        
        if let bottomToolbar = bottomToolbar, bottomToolbar.contains(location) {
            return
        }
        
        // Check if touch is on settings menu
        if let settingsMenu = settingsMenu, settingsMenu.contains(location) {
            settingsMenu.handleTouch(location)
            return
        }
        
        // Check if touch is on a garden plot
        for row in gardenGrid {
            for plot in row {
                if plot.contains(location) {
                    plot.handleTouch()
                    return
                }
            }
        }
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // Update game manager (plant growth, etc.)
        gameManager.updateGame()
        
        // Update plant animations and timers
        for row in gardenGrid {
            for plot in row {
                plot.update(currentTime)
            }
        }
    }
}

// MARK: - GardenPlot Delegate

extension GardenScene: GardenPlotDelegate {
    func gardenPlotTapped(_ plot: GardenPlot) {
        if plot.hasPlant {
            if plot.isReady {
                let gpEarned = gameManager.harvestPlant(at: plot.plotIndex)
                plot.harvestPlant()
                
                // Show floating GP text
                showFloatingGP(gpEarned, at: plot.position)
                
                // Update UI to reflect new GP total
                updateUI()
            }
        } else {
            // Show plant shop to plant something
            showPlantShop()
        }
    }
    
    private func showFloatingGP(_ gp: Int, at position: CGPoint) {
        let gpText = SKLabelNode(text: "+\(gameManager.formatNumber(gp))")
        gpText.fontName = "AvenirNext-Bold"
        gpText.fontSize = 24
        gpText.fontColor = .yellow
        gpText.position = position
        gpText.zPosition = 50
        addChild(gpText)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
        
        gpText.run(sequence)
    }
}

// MARK: - TopBar Delegate

extension GardenScene: TopBarDelegate {
    func settingsButtonTapped() {
        showSettingsMenu()
    }
    
    func prestigeButtonTapped() {
        if gameManager.canPrestige() {
            let wisdomPoints = gameManager.calculateWisdomPoints()
            // Show prestige confirmation dialog
            showPrestigeConfirmation(wisdomPoints: wisdomPoints)
        }
    }
    
    private func showPrestigeConfirmation(wisdomPoints: Int) {
        let alert = UIAlertController(
            title: "Garden Rebirth",
            message: "Reset your garden to gain \(wisdomPoints) Wisdom Points? This will permanently boost your growth speed and earnings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rebirth", style: .destructive) { _ in
            if self.gameManager.performPrestige() {
                self.resetGarden()
            }
        })
        
        // Present alert from view controller
        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    private func resetGarden() {
        // Clear all plots
        for row in gardenGrid {
            for plot in row {
                plot.clearPlant()
            }
        }
        
        // Update UI
        updateUI()
    }
}

// MARK: - BottomToolbar Delegate

extension GardenScene: BottomToolbarDelegate {
    func plantButtonTapped() {
        showPlantShop()
    }
    
    func upgradeButtonTapped() {
        showUpgradeMenu()
    }
    
    func achievementsButtonTapped() {
        showAchievementMenu()
    }
}

// MARK: - PlantShop Delegate

extension GardenScene: PlantShopDelegate {
    func plantSelected(_ plantType: PlantType) {
        hidePlantShop()
        
        // Find first empty plot
        for row in gardenGrid {
            for plot in row {
                if !plot.hasPlant && gameManager.canPlantAtPlot(plot.plotIndex) {
                    if gameManager.plantSeed(plantType, at: plot.plotIndex) {
                        let plantData = gameManager.gameState.plants[plot.plotIndex]
                        plot.setPlant(plantData)
                        return
                    }
                }
            }
        }
    }
    
    func plantShopClosed() {
        hidePlantShop()
    }
}

// MARK: - UpgradeMenu Delegate

extension GardenScene: UpgradeMenuDelegate {
    func upgradePurchased(_ upgradeType: UpgradeType) {
        if gameManager.purchaseUpgrade(upgradeType) {
            // Update garden grid if garden plots were upgraded
            if upgradeType == .gardenPlots {
                updateGardenGrid()
            }
        }
    }
    
    func upgradeMenuClosed() {
        hideUpgradeMenu()
    }
}

// MARK: - OfflineProgress Delegate

extension GardenScene: OfflineProgressDelegate {
    func offlineProgressClaimed() {
        gameManager.claimOfflineProgress()
        updateUI()
    }
    
    func offlineProgressClosed() {
        offlineProgressNode?.hide()
    }
}

// MARK: - Settings Menu Delegate

extension GardenScene: SettingsMenuDelegate {
    func settingsMenuClosed() {
        hideSettingsMenu()
    }
    
    func resetGameTapped() {
        let alert = UIAlertController(
            title: "Reset Game",
            message: "Are you sure you want to reset your progress? This cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.gameManager.resetGame()
            self.resetGarden()
            self.updateUI()
            self.hideSettingsMenu()
        })
        
        // Present alert from view controller
        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    func toggleSoundTapped() {
        // TODO: Implement sound toggle
        print("Sound toggle tapped")
    }
    
    func toggleNotificationsTapped() {
        // TODO: Implement notifications toggle
        print("Notifications toggle tapped")
    }
}

// MARK: - Combine Support

import Combine

private var cancellables = Set<AnyCancellable>() 