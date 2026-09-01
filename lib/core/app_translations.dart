import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  static const fallbackLocale = Locale('en', 'US');

  @override
  Map<String, Map<String, String>> get keys => {
    // ==========================================
    // ENGLISH
    // ==========================================
    'en_US': {
      // Settings
      'Settings': 'Settings',
      'Preferences': 'Preferences',
      'Preferred Language': 'Preferred Language',
      'Unit System': 'Unit System',
      'Metric': 'Metric',
      'Imperial': 'Imperial',
      'Metric (kg, cm)': 'Metric (kg, cm)',
      'Imperial (lbs, in)': 'Imperial (lbs, in)',
      'Permissions & Notifications': 'Permissions & Notifications',
      'Push Notifications': 'Push Notifications',
      'Receive alerts and reminders': 'Receive alerts and reminders',
      'Microphone Access': 'Microphone Access',
      'Allow voice conversations with AI coach':
          'Allow voice conversations with AI coach',

      // Dashboard
      'User': 'User',
      'General Fitness': 'General Fitness',
      'AI Health Coach': 'AI Health Coach',
      'View Full Plan': 'View Full Plan',
      'Open My Plan': 'Open My Plan',
      'Analyzing your metrics to generate today\'s personalized recommendations...':
          'Analyzing your metrics to generate today\'s personalized recommendations...',
      'Stay hydrated, maintain your diet, and complete your daily goals to keep your streak going!':
          'Stay hydrated, maintain your diet, and complete your daily goals to keep your streak going!',
      'Profile & Stats': 'Profile & Stats',
      'Streak: @streak Days | Points: @points pts':
          'Streak: @streak Days | Points: @points pts',

      // Login Screen
      'Welcome to RheaAI': 'Welcome to RheaAI',
      'Login to continue your health journey':
          'Login to continue your health journey',
      'Enter your mobile number': 'Enter your mobile number',
      'We’ll send you a secure one-time verification code':
          'We’ll send you a secure one-time verification code',
      'Send OTP': 'Send OTP',
      'Your health data stays private and secure':
          'Your health data stays private and secure',
      'Unable to send OTP': 'Unable to send OTP',
      'Unable to send OTP. Please try again.':
          'Unable to send OTP. Please try again.',
      'Something went wrong. Please try again.':
          'Something went wrong. Please try again.',

      // OTP Verification Screen
      'Verify OTP': 'Verify OTP',
      'Enter the 6-digit verification code sent to your mobile number':
          'Enter the 6-digit verification code sent to your mobile number',
      'Didn\'t receive the code?': 'Didn\'t receive the code?',
      'Resend OTP': 'Resend OTP',
      'Resend OTP in ': 'Resend OTP in ',
      'OTP Sent': 'OTP Sent',
      'A new OTP has been sent to your mobile number.':
          'A new OTP has been sent to your mobile number.',
      'Unable to resend OTP. Please try again.':
          'Unable to resend OTP. Please try again.',
      'Invalid verification code. Please try again.':
          'Invalid verification code. Please try again.',

      // Onboarding Screen
      'Your Personal Coach For': 'Your Personal Coach For',
      'Diabetes': 'Diabetes',
      'Thyroid': 'Thyroid',
      'Heart Disease': 'Heart Disease',
      'PCOS': 'PCOS',
      'Obesity': 'Obesity',
      'Diet, exercise & mental health.\nHelp when you need it.':
          'Diet, exercise & mental health.\nHelp when you need it.',
      'Let\'s Get Started': 'Let\'s Get Started',
      'By clicking, you agree to our ': 'By clicking, you agree to our ',
      'Terms of Service': 'Terms of Service',
      ' and ': ' and ',
      'Privacy Policy': 'Privacy Policy',
      'Terms & Privacy': 'Terms & Privacy',
      'Please accept the Terms of Service and Privacy Policy to continue.':
          'Please accept the Terms of Service and Privacy Policy to continue.',

      // Primary Health Goal Screen
      'What is your primary\nhealth goal?':
          'What is your primary\nhealth goal?',
      'Choose the goal that matters most to you':
          'Choose the goal that matters most to you',
      'Lose Weight': 'Lose Weight',
      'Burn fat and build a healthier body':
          'Burn fat and build a healthier body',
      'Build Muscle': 'Build Muscle',
      'Build strength and a healthier body':
          'Build strength and a healthier body',
      'Improve Fitness': 'Improve Fitness',
      'Improve fitness, stamina and overall health':
          'Improve fitness, stamina and overall health',
      'Stomach Health': 'Stomach Health',
      'Manage stomach problems and improve digestive health':
          'Manage stomach problems and improve digestive health',
      'Better Sleep': 'Better Sleep',
      'Improve your sleep and daily recovery':
          'Improve your sleep and daily recovery',
      'Manage Stress': 'Manage Stress',
      'Feel calmer and improve mental wellbeing':
          'Feel calmer and improve mental wellbeing',
      'Healthy Skin': 'Healthy Skin',
      'Reduce acne, pimples and improve skin health':
          'Reduce acne, pimples and improve skin health',
      'Hair Fall Control': 'Hair Fall Control',
      'Reduce hair fall and promote healthier hair':
          'Reduce hair fall and promote healthier hair',
      'Quit Addiction': 'Quit Addiction',
      'Break unhealthy habits and build better routines':
          'Break unhealthy habits and build better routines',
      'Sexual Wellness': 'Sexual Wellness',
      'Improve sexual health, confidence and wellbeing':
          'Improve sexual health, confidence and wellbeing',
      'Select your goal': 'Select your goal',
      'Please select a health goal to continue.':
          'Please select a health goal to continue.',
      'Next': 'Next',

      // Personal Info Screen
      'Let\'s know more\nabout you': 'Let\'s know more\nabout you',
      'This helps personalize your experience':
          'This helps personalize your experience',
      'Full Name': 'Full Name',
      'Enter your full name': 'Enter your full name',
      'Email Address': 'Email Address',
      'Enter your email id': 'Enter your email id',
      'Date of Birth': 'Date of Birth',
      'Gender': 'Gender',
      'Select': 'Select',
      'Male': 'Male',
      'Female': 'Female',
      'Other': 'Other',
      'Prefer not to say': 'Prefer not to say',
      'Height': 'Height',
      'Enter your height': 'Enter your height',
      'Weight': 'Weight',
      'Enter your weight': 'Enter your weight',
      'Please enter your full name.': 'Please enter your full name.',
      'Please enter a valid email address.':
          'Please enter a valid email address.',
      'Please select your date of birth.': 'Please select your date of birth.',
      'Please select your gender.': 'Please select your gender.',
      'Please enter your height.': 'Please enter your height.',
      'Please enter a realistic height.': 'Please enter a realistic height.',
      'Please enter your weight.': 'Please enter your weight.',
      'Please enter a realistic weight.': 'Please enter a realistic weight.',
      'Please select a valid date of birth.':
          'Please select a valid date of birth.',
      'Unable to save your information.': 'Unable to save your information.',
      'Required': 'Required',

      // Sexual Wellness Screen
      'Sexual Wellness': 'Sexual Wellness',
      'Choose your primary focus area to personalize your health journey.':
          'Choose your primary focus area to personalize your health journey.',
      'Erectile Dysfunction': 'Erectile Dysfunction',
      'Premature Ejaculation': 'Premature Ejaculation',
      'Low Desire': 'Low Desire',
      'Improve Stamina': 'Improve Stamina',
      'Save': 'Save',
      'Failed to save preference. Please try again.':
          'Failed to save preference. Please try again.',

      // Addiction Screen
      'Habit & Addiction Support': 'Habit & Addiction Support',
      'Select an area you would like guidance or structured help overcoming.':
          'Select an area you would like guidance or structured help overcoming.',
      'Porn Addiction': 'Porn Addiction',
      'Smoking Addiction': 'Smoking Addiction',
      'Tobacco': 'Tobacco',
      'Masturbation': 'Masturbation',
      'Caffeine Addiction': 'Caffeine Addiction',
    },

    // ==========================================
    // HINDI
    // ==========================================
    'hi_IN': {
      // Settings
      'Settings': 'सेटिंग्स',
      'Preferences': 'प्राथमिकताएं',
      'Preferred Language': 'पसंदीदा भाषा',
      'Unit System': 'इकाई प्रणाली',
      'Metric': 'मीट्रिक',
      'Imperial': 'इंपीरियल',
      'Metric (kg, cm)': 'मीट्रिक (किग्रा, सेमी)',
      'Imperial (lbs, in)': 'इंपीरियल (एलबीएस, इंच)',
      'Permissions & Notifications': 'अनुमतियां और सूचनाएं',
      'Push Notifications': 'पुश सूचनाएं',
      'Receive alerts and reminders': 'अलर्ट और रिमाइंडर प्राप्त करें',
      'Microphone Access': 'माइक्रोफोन पहुंच',
      'Allow voice conversations with AI coach':
          'एआई कोच के साथ वॉयस बातचीत की अनुमति दें',

      // Dashboard
      'User': 'उपयोगकर्ता',
      'General Fitness': 'सामान्य फिटनेस',
      'AI Health Coach': 'एआई स्वास्थ्य कोच',
      'View Full Plan': 'पूरी योजना देखें',
      'Open My Plan': 'मेरी योजना खोलें',
      'Analyzing your metrics to generate today\'s personalized recommendations...':
          'आज की सिफारिशें उत्पन्न करने के लिए विश्लेषण किया जा रहा है...',
      'Stay hydrated, maintain your diet, and complete your daily goals to keep your streak going!':
          'हाइड्रेटेड रहें, आहार बनाए रखें और अपने लक्ष्य पूरे करें!',
      'Profile & Stats': 'प्रोफाइल और आंकड़े',
      'Streak: @streak Days | Points: @points pts':
          'लगातार: @streak दिन | पॉइंट्स: @points',

      // Login Screen
      'Welcome to RheaAI': 'रिया एआई में आपका स्वागत है',
      'Login to continue your health journey':
          'अपनी स्वास्थ्य यात्रा जारी रखने के लिए लॉगिन करें',
      'Enter your mobile number': 'अपना मोबाइल नंबर दर्ज करें',
      'We’ll send you a secure one-time verification code':
          'हम आपको एक सुरक्षित वन-टाइम सत्यापन कोड भेजेंगे',
      'Send OTP': 'ओटीपी भेजें',
      'Your health data stays private and secure':
          'आपका स्वास्थ्य डेटा निजी और सुरक्षित रहता है',
      'Unable to send OTP': 'ओटीपी भेजने में असमर्थ',
      'Unable to send OTP. Please try again.':
          'ओटीपी भेजने में असमर्थ। कृपया पुनः प्रयास करें।',
      'Something went wrong. Please try again.':
          'कुछ गलत हो गया। कृपया पुनः प्रयास करें।',

      // OTP Verification Screen
      'Verify OTP': 'ओटीपी सत्यापित करें',
      'Enter the 6-digit verification code sent to your mobile number':
          'अपने मोबाइल नंबर पर भेजा गया 6-अंकीय सत्यापन कोड दर्ज करें',
      'Didn\'t receive the code?': 'क्या आपको कोड नहीं मिला?',
      'Resend OTP': 'ओटीपी पुनः भेजें',
      'Resend OTP in ': 'में ओटीपी पुनः भेजें ',
      'OTP Sent': 'ओटीपी भेजा गया',
      'A new OTP has been sent to your mobile number.':
          'आपके मोबाइल नंबर पर एक नया ओटीपी भेजा गया है।',
      'Unable to resend OTP. Please try again.':
          'ओटीपी पुनः भेजने में असमर्थ। कृपया पुनः प्रयास करें।',
      'Invalid verification code. Please try again.':
          'अमान्य सत्यापन कोड। कृपया पुनः प्रयास करें।',

      // Onboarding Screen
      'Your Personal Coach For': 'आपके लिए व्यक्तिगत कोच',
      'Diabetes': 'मधुमेह',
      'Thyroid': 'थायराइड',
      'Heart Disease': 'हृदय रोग',
      'PCOS': 'पीसीओएस',
      'Obesity': 'मोटापा',
      'Diet, exercise & mental health.\nHelp when you need it.':
          'आहार, व्यायाम और मानसिक स्वास्थ्य।\nजरूरत पड़ने पर सहायता।',
      'Let\'s Get Started': 'शुरू करते हैं',
      'By clicking, you agree to our ': 'क्लिक करके, आप हमारी सहमत हैं ',
      'Terms of Service': 'सेवा की शर्तों',
      ' and ': ' और ',
      'Privacy Policy': 'गोपनीयता नीति',
      'Terms & Privacy': 'शर्तें और गोपनीयता',
      'Please accept the Terms of Service and Privacy Policy to continue.':
          'जारी रखने के लिए कृपया सेवा की शर्तों और गोपनीयता नीति को स्वीकार करें।',

      // Primary Health Goal Screen
      'What is your primary\nhealth goal?':
          'आपका प्राथमिक\nस्वास्थ्य लक्ष्य क्या है?',
      'Choose the goal that matters most to you':
          'वह लक्ष्य चुनें जो आपके लिए सबसे महत्वपूर्ण हो',
      'Lose Weight': 'वजन घटाना',
      'Burn fat and build a healthier body':
          'वसा कम करें और एक स्वस्थ शरीर बनाएं',
      'Build Muscle': 'मांसपेशियां बढ़ाना',
      'Build strength and a healthier body': 'ताकत और एक स्वस्थ शरीर बनाएं',
      'Improve Fitness': 'फिटनेस में सुधार',
      'Improve fitness, stamina and overall health':
          'फिटनेस, स्टैमिना और समग्र स्वास्थ्य में सुधार करें',
      'Stomach Health': 'पेट का स्वास्थ्य',
      'Manage stomach problems and improve digestive health':
          'पेट की समस्याओं को प्रबंधित करें और पाचन स्वास्थ्य में सुधार करें',
      'Better Sleep': 'बेहतर नींद',
      'Improve your sleep and daily recovery':
          'अपनी नींद और दैनिक रिकवरी में सुधार करें',
      'Manage Stress': 'तनाव प्रबंधन',
      'Feel calmer and improve mental wellbeing':
          'शांत महसूस करें और मानसिक स्वास्थ्य में सुधार करें',
      'Healthy Skin': 'स्वस्थ त्वचा',
      'Reduce acne, pimples and improve skin health':
          'मुँहासे, फुंसी कम करें और त्वचा के स्वास्थ्य में सुधार करें',
      'Hair Fall Control': 'बाल झड़ना रोकें',
      'Reduce hair fall and promote healthier hair':
          'बालों का झड़ना कम करें और स्वस्थ बालों को बढ़ावा दें',
      'Quit Addiction': 'नशा छोड़ें',
      'Break unhealthy habits and build better routines':
          'अस्वस्थ आदतों को तोड़ें और बेहतर दिनचर्या बनाएं',
      'Sexual Wellness': 'यौन स्वास्थ्य',
      'Improve sexual health, confidence and wellbeing':
          'यौन स्वास्थ्य, आत्मविश्वास और कल्याण में सुधार करें',
      'Select your goal': 'अपना लक्ष्य चुनें',
      'Please select a health goal to continue.':
          'जारी रखने के लिए कृपया एक स्वास्थ्य लक्ष्य चुनें।',
      'Next': 'अगला',

      // Personal Info Screen
      'Let\'s know more\nabout you': 'आइए आपके बारे में\nअधिक जानें',
      'This helps personalize your experience':
          'यह आपके अनुभव को व्यक्तिगत बनाने में मदद करता है',
      'Full Name': 'पूरा नाम',
      'Enter your full name': 'अपना पूरा नाम दर्ज करें',
      'Email Address': 'ईमेल पता',
      'Enter your email id': 'अपनी ईमेल आईडी दर्ज करें',
      'Date of Birth': 'जन्म तिथि',
      'Gender': 'लिंग',
      'Select': 'चुनें',
      'Male': 'पुरुष',
      'Female': 'महिला',
      'Other': 'अन्य',
      'Prefer not to say': 'कहना पसंद नहीं है',
      'Height': 'लंबाई',
      'Enter your height': 'अपनी लंबाई दर्ज करें',
      'Weight': 'वजन',
      'Enter your weight': 'अपना वजन दर्ज करें',
      'Please enter your full name.': 'कृपया अपना पूरा नाम दर्ज करें।',
      'Please enter a valid email address.': 'कृपया एक वैध ईमेल पता दर्ज करें।',
      'Please select your date of birth.': 'कृपया अपनी जन्म तिथि चुनें।',
      'Please select your gender.': 'कृपया अपना लिंग चुनें।',
      'Please enter your height.': 'कृपया अपनी लंबाई दर्ज करें।',
      'Please enter a realistic height.': 'कृपया एक वास्तविक लंबाई दर्ज करें।',
      'Please enter your weight.': 'कृपया अपना वजन दर्ज करें।',
      'Please enter a realistic weight.': 'कृपया एक वास्तविक वजन दर्ज करें।',
      'Please select a valid date of birth.': 'कृपया एक वैध जन्म तिथि चुनें।',
      'Unable to save your information.': 'आपकी जानकारी सहेजने में असमर्थ।',
      'Required': 'आवश्यक',

      // Sexual Wellness Screen
      'Sexual Wellness': 'यौन स्वास्थ्य',
      'Choose your primary focus area to personalize your health journey.':
          'अपनी स्वास्थ्य यात्रा को व्यक्तिगत बनाने के लिए अपना मुख्य फोकस क्षेत्र चुनें।',
      'Erectile Dysfunction': 'इरेक्टाइल डिसफंक्शन',
      'Premature Ejaculation': 'शीघ्रपतन',
      'Low Desire': 'कम इच्छा',
      'Improve Stamina': 'स्टैमिना सुधारें',
      'Save': 'सहेजें',
      'Failed to save preference. Please try again.':
          'प्राथमिकता सहेजने में विफल। कृपया पुनः प्रयास करें।',

      // Addiction Screen
      'Habit & Addiction Support': 'आदत और नशा मुक्ति सहायता',
      'Select an area you would like guidance or structured help overcoming.':
          'वह क्षेत्र चुनें जिससे उबरने के लिए आप मार्गदर्शन या संरचित सहायता चाहते हैं।',
      'Porn Addiction': 'पॉर्न की लत',
      'Smoking Addiction': 'धूम्रपान की लत',
      'Tobacco': 'तंबाकू',
      'Masturbation': 'हस्तमैथुन',
      'Caffeine Addiction': 'कैफीन की लत',
    },
  };
}
