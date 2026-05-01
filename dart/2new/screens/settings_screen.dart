
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEffects = true;
  bool backgroundMusic = true;
  bool animations = true;
  bool vibration = true;
  double gameSpeed = 1.0;
  int selectedTheme = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildAudioSection(),
            const SizedBox(height: 24),
            _buildGameplaySection(),
            const SizedBox(height: 24),
            _buildDisplaySection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return _buildSettingsCard(
      title: 'Audio Settings',
      icon: Icons.volume_up,
      iconColor: AppColors.info,
      children: [
        _buildSwitchTile(
          title: 'Sound Effects',
          subtitle: 'Dice roll, move sounds',
          value: soundEffects,
          onChanged: (value) => setState(() => soundEffects = value),
        ),
        _buildSwitchTile(
          title: 'Background Music',
          subtitle: 'Ambient game music',
          value: backgroundMusic,
          onChanged: (value) => setState(() => backgroundMusic = value),
        ),
      ],
    );
  }

  Widget _buildGameplaySection() {
    return _buildSettingsCard(
      title: 'Gameplay Settings',
      icon: Icons.gamepad,
      iconColor: AppColors.success,
      children: [
        _buildSwitchTile(
          title: 'Animations',
          subtitle: 'Pawn movement animations',
          value: animations,
          onChanged: (value) => setState(() => animations = value),
        ),
        _buildSwitchTile(
          title: 'Vibration',
          subtitle: 'Haptic feedback',
          value: vibration,
          onChanged: (value) => setState(() => vibration = value),
        ),
        const SizedBox(height: 16),
        _buildSliderTile(
          title: 'Game Speed',
          subtitle: 'Animation and AI speed',
          value: gameSpeed,
          min: 0.5,
          max: 2.0,
          divisions: 3,
          onChanged: (value) => setState(() => gameSpeed = value),
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return _buildSettingsCard(
      title: 'Display Settings',
      icon: Icons.palette,
      iconColor: AppColors.warning,
      children: [
        _buildThemeSelector(),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsCard(
      title: 'About',
      icon: Icons.info,
      iconColor: AppColors.primaryLight,
      children: [
        _buildInfoTile(
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.info_outline,
        ),
        _buildInfoTile(
          title: 'Developer',
          subtitle: 'Professional Game Studio',
          icon: Icons.code,
        ),
        _buildActionTile(
          title: 'Rate This Game',
          subtitle: 'Help us improve',
          icon: Icons.star,
          onTap: () => _showComingSoon('Rate Game'),
        ),
        _buildActionTile(
          title: 'Share with Friends',
          subtitle: 'Spread the fun',
          icon: Icons.share,
          onTap: () => _showComingSoon('Share Game'),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppStyles.heading3,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: AppStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${min}x',
              style: AppStyles.bodySmall,
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surface,
              ),
            ),
            Text(
              '${max}x',
              style: AppStyles.bodySmall,
            ),
          ],
        ),
        Center(
          child: Text(
            '${value.toStringAsFixed(1)}x',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final themes = [
      {'name': 'Dark Blue', 'color': AppColors.primary},
      {'name': 'Purple', 'color': AppColors.primaryLight},
      {'name': 'Green', 'color': AppColors.success},
      {'name': 'Orange', 'color': AppColors.warning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Color',
          style: AppStyles.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your preferred color theme',
          style: AppStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: themes.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> theme = entry.value;
            bool isSelected = selectedTheme == index;
            
            return GestureDetector(
              onTap: () => setState(() => selectedTheme = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme['color'] : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme['color'],
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Text(
                  theme['name'],
                  style: AppStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : theme['color'],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: AppColors.primaryLight,
      ),
      title: Text(
        title,
        style: AppStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodySmall,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: AppColors.primaryLight,
      ),
      title: Text(
        title,
        style: AppStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textMuted,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Coming Soon',
          style: AppStyles.heading3,
        ),
        content: Text(
          '$feature feature will be available in the next update!',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
