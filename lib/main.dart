import 'package:disha_ai/app/routes/app_pages.dart';
import 'package:disha_ai/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // 1. Read the saved language from local storage
  final box = GetStorage();
  final String savedLang = box.read('preferred_language') ?? 'en';

  // 2. Determine the initial locale
  Locale initialLocale;
  switch (savedLang) {
    case 'hi':
      initialLocale = const Locale('hi', 'IN');
      break;
    default:
      initialLocale = const Locale('en', 'US');
  }

  // 3. Pass it to the app
  runApp(DishaAIApp(initialLocale: initialLocale));
}

class DishaAIApp extends StatelessWidget {
  final Locale initialLocale;

  const DishaAIApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Disha AI',
      translations: AppTranslations(),
      locale: initialLocale, // 4. Use the dynamically loaded locale here
      fallbackLocale: AppTranslations.fallbackLocale,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
