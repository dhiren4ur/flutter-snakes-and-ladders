# 🎮 First-Time Game Rules Popup - Complete Integration Guide

## What You're Getting

A beautiful popup dialog that shows basic game rules to new players when they start the game for the first time. It includes:
- ✅ Eye-catching design with gradient background
- ✅ Close button (X) in top-right corner
- ✅ 5 quick rule sections with icons
- ✅ "Got It! Let's Play" button
- ✅ Only shows once (uses SharedPreferences)
- ✅ Can be manually shown again

---

## 📋 STEP-BY-STEP INTEGRATION

### **Step 1: Add SharedPreferences Dependency**

Open `pubspec.yaml` and add:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  google_mobile_ads: ^5.0.0
  shared_preferences: ^2.2.2  # ADD THIS LINE
```

**Then run:**
```bash
flutter pub get
```

---

### **Step 2: Copy game_rules_dialog.dart to Your Project**

Save the file as: `lib/game_rules_dialog.dart`

```
your_project/
├── lib/
│   ├── main.dart
│   ├── game_screen.dart
│   ├── game_mode_screen.dart
│   ├── game_rules_dialog.dart  ← ADD THIS FILE
│   ├── models.dart
│   ├── constants.dart
│   └── ...
```

---

### **Step 3: Modify game_screen.dart**

**Add imports at the top:**
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'game_rules_dialog.dart';
```

**Find the `initState()` method and add the popup check:**

```dart
@override
void initState() {
  super.initState();
  initializePawnImages();
  initializeAnimations();
  startNewGame();
  
  // ADD THIS: Show rules popup for first-time players
  _showRulesDialogIfFirstTime();
}
```

**Add this new method to your GameScreenState class:**

```dart
// Show rules dialog only on first game launch
Future<void> _showRulesDialogIfFirstTime() async {
  // Wait a moment for the game screen to fully load
  await Future.delayed(const Duration(milliseconds: 500));
  
  final prefs = await SharedPreferences.getInstance();
  final hasSeenRules = prefs.getBool('has_seen_game_rules') ?? false;
  
  if (!hasSeenRules && mounted) {
    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const GameRulesDialog(),
    );
    
    // Mark as seen
    await prefs.setBool('has_seen_game_rules', true);
  }
}
```

---

### **Step 4: (OPTIONAL) Add Manual "Show Rules" Button**

If you want players to manually view rules again, add a button in your AppBar:

**In game_screen.dart AppBar:**

```dart
appBar: AppBar(
  title: Text(
    'SNAKES & LADDERS',
    style: GoogleFonts.acme(fontSize: 14, color: Colors.white),
  ),
  backgroundColor: Colors.grey[900],
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.pause, color: Colors.white),
    onPressed: () {
      setState(() {
        showPauseMenu = !showPauseMenu;
      });
    },
  ),
  actions: [
    // ADD THIS: Manual rules button
    IconButton(
      icon: const Icon(Icons.help_outline, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const GameRulesDialog(),
        );
      },
      tooltip: 'Game Rules',
    ),
    IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: showResetConfirmation,
      tooltip: 'Restart Game',
    ),
  ],
),
```

---

### **Step 5: (OPTIONAL) Reset First-Time Flag for Testing**

To test the popup again, add a reset method:

```dart
// FOR TESTING ONLY - Remove in production
Future<void> _resetFirstTimeFlag() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('has_seen_game_rules');
  print('First-time flag reset');
}
```

Call it from anywhere to reset:
```dart
_resetFirstTimeFlag();
```

---

## 🎨 WHAT THE POPUP LOOKS LIKE

### Header
- Icon: Help icon (amber background)
- Title: "Quick Game Rules"
- Close Button: X icon (top-right)

### Content (5 sections)
1. **Goal** 🎯 - Be first to get all 4 pawns to square 100
2. **How to Play** 🎲 - Roll dice, select pawn, any roll enters
3. **Special Squares** ⭐ - Ladders, snakes, gold mines, holes
4. **Hit Opponents** 🥊 - Send opponents back to base
5. **Winning** 🏆 - First to finish all pawns wins

### Footer
- Button: "Got It! Let's Play" (amber button)

---

## 📋 COMPLETE CODE EXAMPLE

### game_screen.dart modifications:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';  // ADD THIS
import 'constants.dart';
import 'models.dart';
import 'ad_manager.dart';
import 'game_rules_dialog.dart';  // ADD THIS

class GameScreen extends StatefulWidget {
  final List<String> playerNames;
  const GameScreen({required this.playerNames});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // ... existing variables ...

  @override
  void initState() {
    super.initState();
    initializePawnImages();
    initializeAnimations();
    startNewGame();
    
    // ADD THIS LINE
    _showRulesDialogIfFirstTime();
  }

  // ADD THIS METHOD
  Future<void> _showRulesDialogIfFirstTime() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenRules = prefs.getBool('has_seen_game_rules') ?? false;
    
    if (!hasSeenRules && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const GameRulesDialog(),
      );
      
      await prefs.setBool('has_seen_game_rules', true);
    }
  }

  // ... rest of your code ...
}
```

---

## ✅ TESTING CHECKLIST

After integration:

- [ ] Add shared_preferences to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Copy game_rules_dialog.dart to lib/
- [ ] Add imports to game_screen.dart
- [ ] Add _showRulesDialogIfFirstTime() method
- [ ] Call it in initState()
- [ ] Run the app
- [ ] Verify popup appears on first launch
- [ ] Close popup with X button
- [ ] Restart app - popup should NOT appear again
- [ ] Test manual "Show Rules" button (if added)

---

## 🎮 BEHAVIOR

### First Time Launch:
1. User opens game screen
2. Wait 500ms (game loads)
3. Popup appears automatically
4. User reads rules
5. User clicks "Got It! Let's Play" or X button
6. Popup closes
7. Flag saved to SharedPreferences

### Subsequent Launches:
1. User opens game screen
2. Check SharedPreferences
3. Flag found = true
4. No popup shown
5. User plays normally

### Manual Show:
1. User clicks help icon (if added)
2. Popup appears
3. User can view rules anytime

---

## 🔧 CUSTOMIZATION OPTIONS

### Change Popup Timing
```dart
// Current: 500ms delay
await Future.delayed(const Duration(milliseconds: 500));

// Change to 1 second:
await Future.delayed(const Duration(seconds: 1));

// No delay:
// Remove the Future.delayed line
```

### Change Colors
In `game_rules_dialog.dart`:
```dart
// Current gradient
gradient: const LinearGradient(
  colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],  // Blue
),

// Change to purple:
gradient: const LinearGradient(
  colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],  // Purple
),

// Change to green:
gradient: const LinearGradient(
  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],  // Green
),
```

### Disable Auto-Show (Always Manual)
```dart
// Comment out in initState():
// _showRulesDialogIfFirstTime();

// Only accessible via help button
```

### Show Popup Every Time (No SharedPreferences)
```dart
Future<void> _showRulesDialogIfFirstTime() async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Remove SharedPreferences check
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const GameRulesDialog(),
    );
  }
}
```

---

## 🐛 TROUBLESHOOTING

### Issue: Popup not appearing
**Solution:**
1. Check SharedPreferences is installed
2. Verify imports are correct
3. Ensure _showRulesDialogIfFirstTime() is called in initState()
4. Try resetting the flag (see Step 5)

### Issue: "shared_preferences not found"
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Popup appears every time
**Solution:**
- Check that setBool() is being called
- Verify key matches: 'has_seen_game_rules'

### Issue: Dialog doesn't close
**Solution:**
- Ensure Navigator.of(context).pop() is in button
- Check barrierDismissible is true (allows tap outside to close)

---

## 📊 FILE SIZES

- game_rules_dialog.dart: ~5 KB
- SharedPreferences adds: ~200 KB to app

Total impact: Minimal (~205 KB)

---

## 🚀 DEPLOYMENT

### For Production:
1. Remove any test reset functions
2. Keep the auto-show on first launch
3. Add manual help button for returning players
4. Update version code (see previous guide)

### Release Notes:
```
Version 1.0.3
- Added first-time game rules popup
- New players see quick guide on first launch
- Help button added to view rules anytime
```

---

## 📝 SUMMARY

**What You Did:**
1. ✅ Added SharedPreferences dependency
2. ✅ Created game_rules_dialog.dart widget
3. ✅ Modified game_screen.dart to show popup
4. ✅ Popup shows once for new players
5. ✅ Optional manual button to view rules

**User Experience:**
- New players: See rules automatically
- Returning players: No popup
- All players: Can view rules via help button

**Implementation Time:** 10-15 minutes

---

**You're done! Test it now and see the popup in action!** 🎉
