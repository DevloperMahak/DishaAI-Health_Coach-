import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:disha_ai/features/profile/presentation/controllers/app_links_controller.dart';

class AboutRheaAiScreen extends StatelessWidget {
  const AboutRheaAiScreen({super.key});

  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFC400);
  static const Color _primaryText = Color(0xFFF5F5F5);
  static const Color _secondaryText = Color(0xFFAAAAAA);
  static const Color _border = Color(0xFF303030);

  // IMPORTANT: Change this to the real RheaAI logo asset in your project.
  // The asset must also be included under flutter/assets in pubspec.yaml.
  static const String _logoAsset = 'assets/images/rheaai_logo.png';

  // ============================================================
  // OFFICIAL RHEAAI LEGAL URLS
  // ============================================================

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/privacy',
  );

  static final Uri _termsConditionsUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/terms',
  );

  AppLinksController get _appLinksController {
    if (Get.isRegistered<AppLinksController>()) {
      return Get.find<AppLinksController>();
    }
    return Get.put(AppLinksController());
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // OPEN LIVE LEGAL DOCUMENT
  // ============================================================

  Future<void> _openLegal({required String title, required Uri url}) async {
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        Get.snackbar(
          'Unable to open $title',
          'Please check your internet connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _surface,
          colorText: _primaryText,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: _gold),
        );
      }
    } catch (e) {
      debugPrint('OPEN LEGAL URL ERROR ($title): $e');

      Get.snackbar(
        'Unable to open $title',
        'Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _surface,
        colorText: _primaryText,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline_rounded, color: _gold),
      );
    }
  }

  // ============================================================
  // PRIVACY POLICY
  // ============================================================

  void _openPrivacyPolicy() {
    _openLegal(title: 'Privacy Policy', url: _privacyPolicyUrl);
  }

  // ============================================================
  // TERMS & CONDITIONS
  // ============================================================

  void _openTerms() {
    _openLegal(title: 'Terms & Conditions', url: _termsConditionsUrl);
  }

  // Contact Support still uses the support email supplied by your API.
  // ============================================================
  // CONTACT SUPPORT - OFFICIAL RHEAAI EMAIL
  // ============================================================

  Future<void> _contactSupport(BuildContext context) async {
    try {
      const String supportEmail = 'help@rheaai.com';

      final uri = Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: 'subject=${Uri.encodeComponent('RheaAI App Support')}',
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showMessage(context, 'Unable to open your email app.');
      }
    } catch (e) {
      debugPrint('CONTACT SUPPORT ERROR: $e');

      if (context.mounted) {
        _showMessage(context, 'Unable to contact support. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _primaryText,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'About RheaAI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('ABOUT YOUR AI HEALTH COACH'),
                  const SizedBox(height: 12),
                  _buildDescriptionCard(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('WHAT YOU CAN DO'),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Personalized Wellness',
                    description:
                        'Get wellness guidance tailored to your health goals and preferences.',
                  ),
                  _buildFeatureCard(
                    icon: Icons.insights_rounded,
                    title: 'Health Progress',
                    description:
                        'Track your daily habits and monitor your wellness progress over time.',
                  ),
                  _buildFeatureCard(
                    icon: Icons.smart_toy_outlined,
                    title: 'AI Health Assistance',
                    description:
                        'Explore health-related information and receive AI-powered wellness support.',
                  ),
                  _buildFeatureCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Daily Wellness Goals',
                    description:
                        'Build healthier routines with reminders, check-ins, and personalized goals.',
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('LEGAL & SUPPORT'),
                  const SizedBox(height: 12),
                  _buildLinkCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Learn how your information is handled',
                    onTap: _openPrivacyPolicy,
                  ),
                  _buildLinkCard(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Read the terms of using RheaAI',
                    onTap: _openTerms,
                  ),
                  _buildLinkCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact Support',
                    subtitle: 'Get help with the app',
                    onTap: () => _contactSupport(context),
                  ),
                  const SizedBox(height: 30),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 94,
            height: 94,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _gold.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: _gold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'RheaAI',
            style: TextStyle(
              color: _gold,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Personal AI Health Coach',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Small steps. Healthier habits. A better you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: _gold),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'WELLNESS POWERED BY AI',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: _gold,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
    ),
  );

  Widget _buildDescriptionCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    child: const Text(
      'RheaAI is designed to help you take a more active role '
      'in your everyday wellness journey. From tracking your '
      'habits to exploring personalized guidance, RheaAI brings '
      'your wellness tools together in one place.\n\n'
      'Our goal is to make building healthier routines simpler, '
      'more accessible, and easier to maintain.',
      style: TextStyle(color: _secondaryText, fontSize: 13, height: 1.8),
    ),
  );

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _gold, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(icon, color: _gold, size: 23),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _secondaryText,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildFooter() => Center(
    child: Column(
      children: [
        Container(height: 1, width: 55, color: _gold.withValues(alpha: 0.55)),
        const SizedBox(height: 18),
        const Text(
          'Made with care for your wellness',
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 8),
        const Text(
          'RheaAI',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'AI wellness guidance is not a substitute for professional medical advice.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondaryText, fontSize: 10, height: 1.6),
        ),
      ],
    ),
  );
}
