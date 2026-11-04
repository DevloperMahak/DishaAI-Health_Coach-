import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';

/// RheaAI Help & Support.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const Color _gold = AppColors.primary;
  static const Color _background = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _muted = AppColors.textSecondary;
  static const Color _border = AppColors.border;

  // ============================================================
  // OFFICIAL RHEAAI SUPPORT CONTACTS
  // ============================================================

  static const String _supportEmail = 'help@rheaai.com';

  static const String _supportPhone = '9340633599';

  static const String _supportPhoneDisplay = '+91 9340633599';

  static const String _supportPhoneDial = '+919340633599';

  static const String _appVersion = '1.0.0';

  // ============================================================
  // LEGAL DOCUMENT URLS
  // ============================================================

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/privacy',
  );

  static final Uri _termsConditionsUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/terms',
  );

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _faqSectionKey = GlobalKey();

  String _selectedCategory = 'All';

  static const List<_HelpCategory> _categories = [
    _HelpCategory('All', Icons.grid_view_rounded),
    _HelpCategory('Getting Started', Icons.rocket_launch_outlined),
    _HelpCategory('Account & Profile', Icons.person_outline_rounded),
    _HelpCategory('AI Health Coach', Icons.auto_awesome_outlined),
    _HelpCategory('Health Tracking', Icons.favorite_border_rounded),
    _HelpCategory('Expert Consultation', Icons.medical_services_outlined),
    _HelpCategory('Payments', Icons.credit_card_outlined),
    _HelpCategory('Notifications', Icons.notifications_none_rounded),
    _HelpCategory('Technical Issues', Icons.build_outlined),
  ];

  static const List<_Faq> _faqs = [
    _Faq(
      'Getting Started',
      'What is RheaAI?',
      'RheaAI is an AI-powered health coaching app that supports your wellness journey with health tracking, personalized guidance, and healthy-habit tools.',
    ),
    _Faq(
      'Getting Started',
      'How do I get started?',
      'Sign in with your mobile number, verify your OTP, and complete your onboarding and health profile.',
    ),
    _Faq(
      'Account & Profile',
      'How can I update my health profile?',
      'Open your profile and edit the available personal or health details. Save your changes when finished.',
    ),
    _Faq(
      'Account & Profile',
      'I am not receiving an OTP. What should I do?',
      'Check your mobile number and network connection, wait briefly, then request a new OTP. If the issue continues, contact support.',
    ),
    _Faq(
      'AI Health Coach',
      'How can I talk to RheaAI?',
      'Open the AI Health Coach feature and use the available conversation or voice-call controls.',
    ),
    _Faq(
      'AI Health Coach',
      'Why is the AI voice call not working?',
      'Check your internet connection and microphone permission. Close and reopen the call screen. If the issue persists, report the problem.',
    ),
    _Faq(
      'AI Health Coach',
      'Can RheaAI diagnose medical conditions?',
      'No. RheaAI provides general wellness information and is not a substitute for a qualified healthcare professional.',
    ),
    _Faq(
      'Health Tracking',
      'How can I track my progress?',
      'Use the dashboard and progress features to review the health information and activities available in your account.',
    ),
    _Faq(
      'Health Tracking',
      'Why is some health information missing?',
      'Make sure the relevant data has been entered or synced, and that the app has the required permissions where applicable.',
    ),
    _Faq(
      'Expert Consultation',
      'How can I contact a health expert?',
      'Open the Experts section, review an expert’s details and availability, and follow the available enquiry or consultation steps.',
    ),
    _Faq(
      'Expert Consultation',
      'Why is an expert shown as offline?',
      'An offline expert may not be available to respond or accept new consultations at that time. Please check again later.',
    ),
    _Faq(
      'Payments',
      'What should I do if a payment fails?',
      'Check whether your payment was deducted and whether the transaction was confirmed. If you were charged without receiving the service, contact support with the transaction reference. Never share your OTP or card PIN.',
    ),
    _Faq(
      'Payments',
      'How can I request payment assistance?',
      'Use Report an Issue, select Payments, and include the transaction reference and a description of the problem. Resolution depends on the applicable payment policy.',
    ),
    _Faq(
      'Notifications',
      'Why am I not receiving reminders?',
      'Check notification permissions, battery restrictions, and your reminder settings. Some reminders may depend on device background restrictions.',
    ),
    _Faq(
      'Technical Issues',
      'What should I do if the app crashes?',
      'Restart the app, check for updates, and confirm your internet connection. If the problem continues, report the issue with the steps to reproduce it.',
    ),
  ];

  List<_Faq> get _visibleFaqs {
    if (_selectedCategory == 'All') return _faqs;
    return _faqs.where((faq) => faq.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAnswers() {
    // Add a slight delay (100ms) so the UI fully finishes dropping
    // the unselected items and recalculates its new total height.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final targetContext = _faqSectionKey.currentContext;
      if (targetContext == null) return;

      // Now that the height has settled, ensureVisible will calculate
      // the exact target offset and clamp it safely.
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.04, // Leaves a nice 4% breathing room at the top
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectCategory(String name) {
    setState(() {
      _selectedCategory = name;
    });
    _scrollToAnswers();
  }

  String _encodeQuery(Map<String, String> values) => values.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');

  // ============================================================
  // OPEN SUPPORT EMAIL
  // ============================================================

  Future<void> _openEmail({
    String subject = 'RheaAI Support',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: _encodeQuery({'subject': subject, 'body': body}),
    );

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('No email application available');
      }
    } catch (e) {
      debugPrint('RHEAAI SUPPORT EMAIL ERROR: $e');

      await Clipboard.setData(const ClipboardData(text: _supportEmail));

      if (!mounted) return;

      Get.snackbar(
        'Email App Unavailable',
        '$_supportEmail copied to clipboard.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _surface,
        colorText: Colors.white,
        icon: const Icon(Icons.content_copy_rounded, color: _gold),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ============================================================
  // CALL SUPPORT
  // ============================================================

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _supportPhoneDial);

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Phone dialer unavailable');
      }
    } catch (e) {
      debugPrint('RHEAAI SUPPORT CALL ERROR: $e');

      await Clipboard.setData(const ClipboardData(text: _supportPhoneDial));

      if (!mounted) return;

      Get.snackbar(
        'Phone Dialer Unavailable',
        '$_supportPhoneDisplay copied to clipboard.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _surface,
        colorText: Colors.white,
        icon: const Icon(Icons.content_copy_rounded, color: _gold),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _openReport({bool feedback = false}) {
    Get.bottomSheet<void>(
      _SupportForm(
        feedback: feedback,
        onSubmit: (category, subject, description) => _openEmail(
          subject: 'RheaAI ${feedback ? 'Feedback' : 'Issue'}: $subject',
          body:
              'Category: $category\n\nDescription:\n$description\n\nApp version: $_appVersion\n',
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ============================================================
  // OPEN LIVE LEGAL DOCUMENT
  // ============================================================

  Future<void> _openLegal(String title, Uri url) async {
    if (!mounted) return;

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Unable to open $title');
      }
    } catch (e) {
      debugPrint('RHEAAI LEGAL URL ERROR ($title): $e');

      if (!mounted) return;

      Get.snackbar(
        'Unable to open $title',
        'Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _surface,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: _gold),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 370 ? 15.0 : 20.0;
    final faqs = _visibleFaqs;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _gold,
          ),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(padding, 12, padding, 40),
              children: [
                _hero(),
                const SizedBox(height: 32),
                _sectionHeader(
                  'Browse help topics',
                  'Choose a category to find relevant answers',
                ),
                const SizedBox(height: 16),
                _categoryGrid(),
                const SizedBox(height: 32),
                Container(
                  key: _faqSectionKey,
                  child: _sectionHeader(
                    'Frequently asked questions',
                    '${faqs.length} answers available',
                  ),
                ),
                const SizedBox(height: 16),
                if (faqs.isEmpty)
                  _emptyState()
                else
                  ...faqs.map((faq) => _faqTile(faq)),
                const SizedBox(height: 24),
                _supportCard(),
                const SizedBox(height: 32),
                _sectionHeader(
                  'Privacy, terms & safety',
                  'Review how RheaAI works and protects your information',
                ),
                const SizedBox(height: 16),

                // ==================================================
                // PRIVACY POLICY - LIVE LINK
                // ==================================================
                _legalCard(
                  title: 'Privacy Policy',
                  subtitle:
                      'Learn how your personal and health information is handled.',
                  icon: Icons.verified_user_outlined,
                  onTap: () => _openLegal('Privacy Policy', _privacyPolicyUrl),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // TERMS & CONDITIONS - LIVE LINK
                // ==================================================
                _legalCard(
                  title: 'Terms & Conditions',
                  subtitle:
                      'Understand the rules and conditions for using RheaAI.',
                  icon: Icons.description_outlined,
                  onTap: () =>
                      _openLegal('Terms & Conditions', _termsConditionsUrl),
                ),

                const SizedBox(height: 12),

                _legalCard(
                  title: 'Medical Disclaimer',
                  subtitle:
                      'Important information about AI-powered wellness guidance.',
                  icon: Icons.health_and_safety_outlined,
                  onTap: _showDisclaimer,
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'RheaAI  •  Here for your wellness journey',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Version $_appVersion',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A2208), Color(0xFF151515), Color(0xFF0D0D0D)],
      ),
      border: Border.all(color: _gold.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _gold.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: _gold,
                size: 32,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_rounded, color: _gold, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'RheaAI Care',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'We’re here to help.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore answers, get assistance, and feel confident throughout your wellness journey.',
          style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
      ),
    ],
  );

  Widget _categoryGrid() => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 540 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 116,
        ),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final selected = item.name == _selectedCategory;
          return GestureDetector(
            onTap: () => _selectCategory(item.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? _gold.withOpacity(0.12) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _gold : _border.withOpacity(0.4),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: selected ? _gold : Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _gold : Colors.white,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _faqTile(_Faq faq) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('${faq.category}-${faq.question}'),
          iconColor: _gold,
          collapsedIconColor: _muted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          title: Text(
            faq.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border.withOpacity(0.5)),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, color: _muted, size: 42),
        SizedBox(height: 16),
        Text(
          'No questions in this category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          'Try selecting a different category.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    ),
  );

  // ============================================================
  // SUPPORT CONTACT TILE
  // ============================================================

  Widget _supportContactTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _gold, size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _gold,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUPPORT CARD
  // ============================================================

  Widget _supportCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF5A4916).withOpacity(0.6)),
    ),
    child: Column(
      children: [
        // ========================================================
        // SUPPORT ICON
        // ========================================================
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.headset_mic_rounded, color: _gold, size: 32),
        ),

        const SizedBox(height: 16),

        const Text(
          'Still need assistance?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Our support team is here to help you with your RheaAI experience.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // CONTACT DETAILS
        // ========================================================
        _supportContactTile(
          icon: Icons.call_outlined,
          title: 'Call Support',
          value: _supportPhoneDisplay,
          onTap: _callSupport,
        ),

        const SizedBox(height: 12),

        _supportContactTile(
          icon: Icons.email_outlined,
          title: 'Email Support',
          value: _supportEmail,
          onTap: () => _openEmail(),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // CONTACT SUPPORT BUTTON
        // ========================================================
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openEmail(),
            icon: const Icon(Icons.mail_outline_rounded, size: 20),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ========================================================
        // REPORT ISSUE & FEEDBACK
        // ========================================================
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                'Report Issue',
                Icons.report_problem_outlined,
                () => _openReport(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _outlineButton(
                'Feedback',
                Icons.rate_review_outlined,
                () => _openReport(feedback: true),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _outlineButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: _gold,
      side: BorderSide(color: const Color(0xFF5A4916).withOpacity(0.6)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
  );

  Widget _legalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: _gold, size: 16),
          ],
        ),
      ),
    ),
  );

  void _showDisclaimer() => Get.dialog<void>(
    AlertDialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: _gold, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Medical Disclaimer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: const SingleChildScrollView(
        child: Text(
          'RheaAI provides general health and wellness information for educational purposes only. It does not provide medical diagnoses or replace advice, diagnosis, or treatment from a qualified healthcare professional.\n\nDo not ignore professional medical advice because of information provided by the app. In a medical emergency, contact your local emergency services immediately.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Understood',
            style: TextStyle(
              color: _gold,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HelpCategory {
  final String name;
  final IconData icon;

  const _HelpCategory(this.name, this.icon);
}

class _Faq {
  final String category;
  final String question;
  final String answer;

  const _Faq(this.category, this.question, this.answer);
}

class _SupportForm extends StatefulWidget {
  final bool feedback;

  final Future<void> Function(
    String category,
    String subject,
    String description,
  )
  onSubmit;

  const _SupportForm({
    super.key,
    required this.feedback,
    required this.onSubmit,
  });

  @override
  State<_SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends State<_SupportForm> {
  static const Color _gold = AppColors.primary;

  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();

  String _category = 'Technical Issues';
  bool _busy = false;

  static const _issueCategories = [
    'Technical Issues',
    'Login / OTP',
    'AI Voice Call',
    'Health Tracking',
    'Expert Consultation',
    'Payments',
    'Other',
  ];

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 650,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF171717),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.feedback ? 'Send Feedback' : 'Report an Issue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your message will open in your email app for review before sending.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!widget.feedback) ...[
                      DropdownButtonFormField<String>(
                        value: _category,
                        dropdownColor: const Color(0xFF252525),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: _decoration('Issue Category'),
                        items: _issueCategories
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _category = value ?? _category),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _subject,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      decoration: _decoration(
                        widget.feedback ? 'Feedback Subject' : 'Issue Subject',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Please enter a subject'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 1500,
                      decoration: _decoration(
                        'Describe ${widget.feedback ? 'your feedback' : 'the problem'}',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().length < 10)
                          ? 'Please enter at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                setState(() => _busy = true);

                                try {
                                  await widget.onSubmit(
                                    widget.feedback ? 'Feedback' : _category,
                                    _subject.text.trim(),
                                    _description.text.trim(),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _busy = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _busy ? 'Opening email...' : 'Continue to Email',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    counterStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: const Color(0xFF222222),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF363636)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _gold, width: 1.5),
    ),
  );
}
