class AppLinksModel {
  final String privacyPolicyUrl;
  final String termsUrl;
  final String helpSupportUrl;
  final String supportEmail;

  const AppLinksModel({
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.helpSupportUrl,
    required this.supportEmail,
  });

  factory AppLinksModel.fromJson(Map<String, dynamic> json) {
    return AppLinksModel(
      privacyPolicyUrl: json['privacy_policy_url']?.toString() ?? '',
      termsUrl: json['terms_url']?.toString() ?? '',
      helpSupportUrl: json['help_support_url']?.toString() ?? '',
      supportEmail: json['support_email']?.toString() ?? '',
    );
  }

  const AppLinksModel.empty()
    : privacyPolicyUrl = '',
      termsUrl = '',
      helpSupportUrl = '',
      supportEmail = '';

  bool get hasPrivacyPolicy => privacyPolicyUrl.trim().isNotEmpty;

  bool get hasTerms => termsUrl.trim().isNotEmpty;

  bool get hasHelpSupport => helpSupportUrl.trim().isNotEmpty;

  bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
}
