# Idle Garden - iOS Game

A magical idle/incremental game where players manage a garden that grows automatically over time, even when the app is closed.

## 🎮 Game Overview

**Idle Garden** is a relaxing iOS game where players cultivate increasingly rare and valuable plants while unlocking new garden areas and magical abilities. The game features offline progress, allowing players to return to find their garden has continued growing in their absence.

### Core Features

- **🌱 Plant Growing System**: Multiple plant types with different growth times and rarity levels
- **⏰ Offline Progress**: Garden continues growing when app is closed (up to 24 hours)
- **⚡ Upgrade System**: Improve growth speed, GP generation, and garden capacity
- **🔄 Prestige System**: Garden rebirth for permanent bonuses
- **🏆 Achievement System**: Unlock achievements for various milestones
- **📱 Touch-Optimized UI**: Designed specifically for iOS devices

## 🚀 Getting Started

### Prerequisites

- Xcode 14.0 or later
- iOS 14.0 or later
- iPhone 8 or newer / iPad (any model)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/idle-garden.git
cd idle-garden
```

2. Open the project in Xcode:
```bash
open "Idle Garden.xcodeproj"
```

3. Select your target device or simulator

4. Build and run the project (⌘+R)

## 🎯 Game Mechanics

### Plant Types

| Rarity | Growth Time | GP/Hour | Examples |
|--------|-------------|---------|----------|
| Basic | 30s - 2min | 10-20 | Carrot, Tomato, Sunflower |
| Rare | 5-15min | 50-100 | Magic Flower, Golden Fruit |
| Legendary | 1-4 hours | 200-500 | Dragon Fruit, Phoenix Flower |
| Prestige | 24 hours | 1000+ | Eternal Tree |

### Upgrade System

- **Plant Speed**: Increases growth speed by 10% per level
- **GP Multiplier**: Increases earnings by 20% per level
- **Garden Plots**: Unlocks additional planting spaces
- **Auto Harvest**: Automatic harvesting with upgrade levels
- **Offline Efficiency**: Improves offline progress efficiency

### Prestige System

- Reset progress to gain Wisdom Points
- Wisdom Points provide permanent global bonuses
- Unlock special prestige-only plants
- Each rebirth increases future earnings

## 📁 Project Structure

```
Idle Garden/
├── GameModels.swift          # Core data structures and game state
├── GameManager.swift         # Main game logic and progression
├── GardenScene.swift         # Main game scene and UI
├── UIComponents.swift        # Reusable UI components
├── TutorialManager.swift     # Tutorial system
├── AchievementSystem.swift   # Achievement tracking
├── GameViewController.swift  # App entry point
└── Assets.xcassets/          # Game assets and sprites
```

### Key Classes

- **`GameManager`**: Central game logic, save/load, progression
- **`GardenScene`**: Main game interface and interaction
- **`GardenPlot`**: Individual planting spaces
- **`PlantType`**: Plant definitions and properties
- **`AchievementManager`**: Achievement tracking and rewards

## 🎨 UI Design

### Visual Style
- **Theme**: Whimsical, colorful, hand-drawn cartoon style
- **Color Palette**: Soft greens, warm earth tones, bright flower colors
- **Typography**: AvenirNext font family for readability

### Layout
- **Top Bar**: GP counter, Seeds (premium currency), settings, prestige
- **Garden Grid**: 3x3 expandable grid of planting plots
- **Bottom Toolbar**: Plant shop, upgrades, achievements
- **Modal Overlays**: Plant shop, upgrade menu, achievement display

## 💾 Save System

The game uses `UserDefaults` for local save data with automatic saving:
- Game state saved every 30 seconds
- Automatic save when app goes to background
- Offline progress calculation on app launch
- Achievement progress persistence

### Save Data Structure
```swift
struct GameState {
    var gardenPoints: Int
    var seeds: Int
    var plants: [PlantData]
    var upgrades: [String: Int]
    var lastSaveTime: Date
    var prestigeCount: Int
    var wisdomPoints: Int
}
```

## 🏆 Achievement System

8 different achievements to unlock:
- **First Harvest**: Harvest your first plant
- **First Upgrade**: Buy your first upgrade
- **Plant Master**: Plant 10 different types
- **Speed Demon**: Reach 5x growth speed
- **Millionaire**: Earn 1,000,000 GP
- **Prestige Master**: Perform 5 rebirths
- **Plant Collector**: Unlock all plant types
- **Time Traveler**: Accumulate 24h offline progress

## 🎓 Tutorial System

New players are guided through:
1. Welcome and introduction
2. Planting first seed
3. Harvesting plants
4. Buying upgrades
5. Planting multiple crops
6. Tutorial completion

## 🔧 Development

### Architecture
- **MVVM Pattern**: GameManager as ViewModel, GardenScene as View
- **Protocol-Oriented**: Delegate patterns for UI communication
- **Singleton Pattern**: GameManager and managers for global state
- **Observer Pattern**: Combine framework for reactive updates

### Performance Considerations
- Efficient plant growth calculations
- Minimal background processing
- Optimized sprite rendering
- Memory management for large gardens

### Future Enhancements
- [ ] Weather system affecting growth
- [ ] Plant breeding mechanics
- [ ] Seasonal events and limited-time plants
- [ ] Social features (friend gardens)
- [ ] Cloud save with iCloud
- [ ] Push notifications for ready plants
- [ ] In-app purchases for premium content

## 📱 Platform Support

- **iOS 14.0+**: Full feature support
- **iPhone**: Optimized for portrait orientation
- **iPad**: Universal app with larger UI elements
- **Accessibility**: VoiceOver support and dynamic text sizing

## 🎮 Monetization Strategy

### Premium Currency (Seeds)
- Earned through achievements and daily bonuses
- Used for speed boosts and premium plants
- Optional in-app purchases

### Revenue Streams
- **Ad Revenue**: Rewarded video ads (60% of revenue)
- **IAP Revenue**: Premium currency and content (40% of revenue)
- **Target ARPU**: $2-3 per month per user

## 📊 Analytics & Metrics

### Key Performance Indicators
- Day 1 Retention: 70%
- Day 7 Retention: 40%
- Day 30 Retention: 15%
- Average Session Length: 3-5 minutes
- Sessions per Day: 5-8

### Success Metrics
- User engagement and retention
- Monetization conversion rates
- Achievement completion rates
- Prestige system usage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- SpriteKit framework for 2D graphics
- Combine framework for reactive programming
- iOS Game Center for achievements
- Apple's Human Interface Guidelines for UI design

## 📞 Support

For support, email support@idlegarden.com or create an issue in this repository.

---

**Happy Gardening! 🌱✨** 