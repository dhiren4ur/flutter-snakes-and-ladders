import 'package:audioplayers/audioplayers.dart';

/// Audio management system for Snakes & Ladders game
/// Background music plays ONLY on game board
/// FIXED: Properly handles multiple game sessions without disposal issues
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  // Audio players - will be recreated if disposed
  AudioPlayer? _backgroundMusic;
  AudioPlayer? _sfxPlayer;

  // State flags
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;

  /// Initialize audio system
  Future<void> init() async {
    try {
      // Create new players if they don't exist or were disposed
      _backgroundMusic = AudioPlayer();
      _sfxPlayer = AudioPlayer();

      await _backgroundMusic!.setVolume(0.3);
      await _sfxPlayer!.setVolume(0.6);

      // ========== CRITICAL: Set background music to loop ==========
      await _backgroundMusic!.setReleaseMode(ReleaseMode.loop);

      _initialized = true;
      print('✅ AudioManager initialized');
    } catch (e) {
      print('❌ AudioManager init error: $e');
      _initialized = false;
    }
  }

  /// Play background music (looping)
  Future<void> playBackgroundMusic() async {
    if (!_initialized || _backgroundMusic == null) {
      print('⚠️ Cannot play background music: initialized=$_initialized, player=${_backgroundMusic != null}');
      return;
    }

    if (!_musicEnabled) return;

    try {
      // Stop any existing playback first
      await _backgroundMusic!.stop();

      // Play background music on loop
      await _backgroundMusic!.play(
        AssetSource('audio/background_music.mp3'),
        volume: 0.3,
      );
      print('✅ Background music playing (looped)');
    } catch (e) {
      print('❌ Error playing background music: $e');
    }
  }

  /// Stop background music - DON'T dispose, just stop
  Future<void> stopBackgroundMusic() async {
    if (_backgroundMusic == null) return;

    try {
      await _backgroundMusic!.stop();
      print('✅ Background music stopped');
    } catch (e) {
      print('❌ Error stopping background music: $e');
    }
  }

  /// Toggle background music on/off
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_initialized || _backgroundMusic == null || !_musicEnabled) return;

    try {
      await _backgroundMusic!.resume();
      print('✅ Background music resumed');
    } catch (e) {
      print('❌ Error resuming music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (_backgroundMusic == null) return;

    try {
      await _backgroundMusic!.pause();
      print('✅ Background music paused');
    } catch (e) {
      print('❌ Error pausing music: $e');
    }
  }

  // ========== SOUND EFFECTS ==========

  /// Dice roll sound effect
  Future<void> playDiceRoll() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/dice_roll.mp3'));
    } catch (e) {
      print('❌ Error playing dice roll: $e');
    }
  }

  /// Ladder climb sound effect
  Future<void> playLadderClimb() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/ladder_climb.mp3'));
    } catch (e) {
      print('❌ Error playing ladder climb: $e');
    }
  }

  /// Snake slide sound effect
  Future<void> playSnakeSlide() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/snake_slide.mp3'));
    } catch (e) {
      print('❌ Error playing snake slide: $e');
    }
  }

  /// Gold mine sound effect
  Future<void> playGoldMine() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/gold_mine.mp3'));
    } catch (e) {
      print('❌ Error playing gold mine: $e');
    }
  }

  /// Win celebration sound effect
  Future<void> playWinCracker() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/win_cracker.mp3'));
    } catch (e) {
      print('❌ Error playing win cracker: $e');
    }
  }

  /// Game start sound
  Future<void> playGameStart() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/game_start.mp3'));
      print('✅ Game start sound played');
    } catch (e) {
      print('❌ Error playing game start: $e');
    }
  }

  /// Game exit sound
  Future<void> playGameExit() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/game_exit.mp3'));
      print('✅ Game exit sound played');
    } catch (e) {
      print('❌ Error playing game exit: $e');
    }
  }

  /// Hit opponent pawn sound effect
  Future<void> playHitOpponent() async {
    if (!_initialized || _sfxPlayer == null || !_sfxEnabled) return;

    try {
      await _sfxPlayer!.play(AssetSource('audio/hit_opponent.mp3'));
      print('✅ Hit opponent sound played');
    } catch (e) {
      print('❌ Error playing hit opponent: $e');
    }
  }

  // ========== CONTROL METHODS ==========

  /// Toggle sound effects on/off
  void toggleSFX() {
    _sfxEnabled = !_sfxEnabled;
  }

  /// Check if music is enabled
  bool isMusicEnabled() => _musicEnabled;

  /// Check if SFX is enabled
  bool isSFXEnabled() => _sfxEnabled;

  /// Enable music
  void enableMusic() {
    _musicEnabled = true;
  }

  /// Disable music
  void disableMusic() {
    _musicEnabled = false;
  }

  /// Enable sound effects
  void enableSFX() {
    _sfxEnabled = true;
  }

  /// Disable sound effects
  void disableSFX() {
    _sfxEnabled = false;
  }

  /// Stop all audio
  Future<void> stopAll() async {
    try {
      await _backgroundMusic?.stop();
      await _sfxPlayer?.stop();
      print('✅ All audio stopped');
    } catch (e) {
      print('❌ Error stopping all audio: $e');
    }
  }

  /// Clean up for leaving game board - STOP but DON'T dispose
  Future<void> cleanup() async {
    print('🔄 Cleaning up AudioManager...');

    try {
      // Stop all audio
      await _backgroundMusic?.stop();
      await _sfxPlayer?.stop();

      // Dispose old players
      await _backgroundMusic?.dispose();
      await _sfxPlayer?.dispose();

      // Clear references
      _backgroundMusic = null;
      _sfxPlayer = null;
      _initialized = false;

      print('✅ AudioManager cleaned up successfully');
    } catch (e) {
      print('❌ Error cleaning up audio: $e');
    }
  }

  /// Dispose everything (only call when app closes)
  Future<void> dispose() async {
    await cleanup();
  }
}
