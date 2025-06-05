// lib/Dashboards/dashboard_screen.dart
import 'package:flutter/material.dart';
// import 'dart:ui'; // For ImageFilter - not strictly needed for this basic image impl.

class DashboardScreen extends StatelessWidget {
  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color accentRed = Color(0xFF680d13);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textSlightlyFaded = Colors.white54;

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ITCOURSE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        backgroundColor: surfaceDark,
        elevation: 0,
      ),
      backgroundColor: primaryDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(context), // Pass context
                _buildProgramSection(context),
                _buildWhySection(context),
                _buildFeatureSection(context),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    double heroHeight = MediaQuery.of(context).size.height * 0.75;
    if (heroHeight < 500) heroHeight = 500;

    return Container(
      height: heroHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        // color: surfaceDark, // Fallback color, can be removed if image always loads
        image: DecorationImage(
          image: const AssetImage("assets/main.png"), // <-- YOUR LOCAL IMAGE PATH
          fit: BoxFit.cover, // Ensures the image covers the container
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6), // Darken the image to make text readable
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tingkatkan Skill Kamu Bersama ITCOURSE.',
            style: TextStyle(
                fontSize: 32,
                color: textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [ // Text shadow for better readability on image
                  Shadow(blurRadius: 10.0, color: Colors.black87, offset: Offset(2, 2))
                ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Belajar online dengan kurikulum industri, mentor berpengalaman, dan komunitas solid.',
            style: TextStyle(
                fontSize: 18,
                color: textSecondary, // Ensure this has enough contrast with your image + filter
                height: 1.5,
                shadows: [ // Optional: slight shadow for subheading too
                  Shadow(blurRadius: 6.0, color: Colors.black54, offset: Offset(1,1))
                ]
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: accentRed.withOpacity(0.5),
            ),
            child: const Text(
              'Mulai Belajar Sekarang',
              style: TextStyle(fontSize: 18, color: textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ... rest of your _buildSectionTitle, _buildProgramSection, _buildProgramCard,
  // _buildWhySection, _buildFeatureSection, _buildFeatureTile, and _buildFooter methods ...
  // (These methods remain the same as in the previous response unless you want to change them too)

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, top: 10.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgramSection(BuildContext context) {
    return Container(
      color: primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSectionTitle('Program Pilihan'),
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth > 600
                  ? (constraints.maxWidth / 3 - 30)
                  : constraints.maxWidth > 450
                  ? (constraints.maxWidth / 2 - 25)
                  : constraints.maxWidth * 0.9;
              if (cardWidth < 300 && constraints.maxWidth > 600) cardWidth = 300;
              if (cardWidth < 250 && constraints.maxWidth > 450) cardWidth = 250;

              return Wrap(
                spacing: 20,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: [
                  _buildProgramCard(
                    context,
                    Icons.layers_outlined,
                    'Kelas Fullstack',
                    'Belajar Full Stack Web Developer from A to Z.',
                    Colors.amber.shade600,
                    cardWidth,
                  ),
                  _buildProgramCard(
                    context,
                    Icons.code_rounded,
                    'PZN Expert',
                    'Kuasai Skill Coding ala Startup Unicorn.',
                    Colors.lightBlue.shade400,
                    cardWidth,
                  ),
                  _buildProgramCard(
                    context,
                    Icons.laptop_chromebook_rounded,
                    'Developer Handal',
                    'Beasiswa Coding & Sertifikasi Internasional.',
                    Colors.pinkAccent.shade200,
                    cardWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, IconData icon, String title, String desc, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 6.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceDark,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhySection(BuildContext context) {
    return Container(
      color: surfaceDark,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(
        children: [
          _buildSectionTitle('Kenapa Harus Upgrade Skill?'),
          const SizedBox(height: 10),
          const Text(
            'Belajar di ITCOURSE adalah pilihan tepat untuk sukses di dunia IT. Materi dirancang oleh ahli berpengalaman, menggabungkan teori dan keterampilan praktis yang relevan dengan tren industri terkini. Cocok untuk pemula hingga profesional, ITCOURSE membantu Anda mencapai impian karier!',
            style: TextStyle(
                color: textSecondary,
                fontSize: 17,
                height: 1.7,
                letterSpacing: 0.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    return Container(
      color: primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          _buildSectionTitle('Fitur Eksklusif ITCOURSE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureTile(Icons.devices_rounded, 'Belajar Fleksibel', 'Kapan saja dan di mana saja, sesuai ritme Anda.'),
              _buildFeatureTile(Icons.support_agent_rounded, 'Mentor Terbaik', 'Dibimbing langsung oleh para ahli di industrinya.'),
              _buildFeatureTile(Icons.military_tech_rounded, 'Sertifikat Eksklusif', 'Dapatkan pengakuan resmi untuk setiap skill baru.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String desc) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange.shade400, size: 48),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 19)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: textSecondary, fontSize: 15, height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      color: surfaceDark,
      child: Center(
        child: Text('© ${DateTime.now().year} ITCOURSE. All Rights Reserved.', // Dynamic year
            style: const TextStyle(color: textSlightlyFaded, fontSize: 14)),
      ),
    );
  }
}