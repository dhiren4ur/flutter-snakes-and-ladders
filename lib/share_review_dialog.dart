import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Beautiful Share & Review Dialog matching your game's design
void showShareAndReviewDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade700, Colors.blueGrey.shade900],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Love the Game?',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Description text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Help us grow! Share with friends or leave a 5-star review.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Share Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share with Friends',
                  colors: [Colors.cyan.shade400, Colors.blue.shade500],
                  onPressed: () {
                    _shareApp();
                    Navigator.pop(context);
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Rate Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildActionButton(
                  icon: Icons.star,
                  label: 'Rate on Play Store',
                  colors: [Colors.amber.shade400, Colors.orange.shade500],
                  onPressed: () {
                    _openPlayStore();
                    Navigator.pop(context);
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Not Now Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

/// Build action button with gradient
Widget _buildActionButton({
  required IconData icon,
  required String label,
  required List<Color> colors,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Share app via social media
void _shareApp() {
  Share.share(
    '🎮 Check out Snakes & Ladders: Twisted! 🎲\n\nA fun and addictive board game with amazing graphics and gameplay. Download now from Google Play Store!\n\nhttps://play.google.com/store/apps/details?id=com.devdhiren.snakes_ladders',
    subject: 'Snakes & Ladders: Twisted - Amazing Game!',
  );
}

/// Open Play Store for rating
void _openPlayStore() async {
  final String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.devdhiren.snakes_ladders';
  
  if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
    await launchUrl(
      Uri.parse(playStoreUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
