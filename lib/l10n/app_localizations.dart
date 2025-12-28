import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App Name & General
      'appName': 'ScanApp',
      'exit': 'Exit',
      'exitApp': 'Exit App',
      'exitConfirmation': 'Are you sure you want to exit?',
      'cancel': 'Cancel',
      'done': 'Done',
      'delete': 'Delete',
      'share': 'Share',
      'save': 'Save',
      'reset': 'Reset',
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'back': 'Back',

      // Home Screen
      'quickActions': 'Quick Actions',
      'scanDocument': 'Scan Document',
      'scanDocumentSubtitle': 'Capture and scan a new document',
      'myDocuments': 'My Documents',
      'myDocumentsSubtitle': 'View and manage your scanned documents',
      'statistics': 'Statistics',
      'totalDocuments': 'Total Documents',
      'favorites': 'Favorites',
      'aboutScanApp': 'About ScanApp',
      'aboutDescription':
          'A powerful document scanner app that lets you capture, edit, and export documents to PDF and image formats. All your documents are stored locally on your device.',

      // Document Scanner
      'openingScanner': 'Opening scanner...',
      'preparing': 'Preparing...',
      'scanningFailed': 'Scanning failed',

      // Image Editing
      'editScan': 'Edit Scan',
      'original': 'Original',
      'autoEnhance': 'Auto',
      'magicColor': 'Magic',
      'blackWhite': 'B&W',
      'grayscale': 'Gray',
      'highContrast': 'Contrast',
      'rotateLeft': 'Rotate Left',
      'rotateRight': 'Rotate Right',

      // Document Builder
      'buildDocument': 'Build Document',
      'documentTitle': 'Document Title',
      'enterDocumentName': 'Enter document name',
      'exportFormat': 'Export Format',
      'compression': 'Compression',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'scanMorePages': 'Scan More Pages',
      'pagesAdded': 'added',
      'exportAndSave': 'Export & Save',
      'noImages': 'No images scanned yet',
      'startScanning': 'Start by scanning a document',

      // Documents List
      'searchDocuments': 'Search documents...',
      'sortByDate': 'Sort by Date',
      'sortByName': 'Sort by Name',
      'sortBySize': 'Sort by Size',
      'noDocumentsFound': 'No documents found',
      'scanYourFirstDocument': 'Scan Your First Document',
      'deleteDocument': 'Delete Document',
      'deleteConfirmation':
          'Are you sure you want to delete this document? This action cannot be undone.',
      'documentDeleted': 'Document deleted',
      'addToFavorite': 'Add to Favorite',
      'removeFromFavorite': 'Remove Favorite',
      'page': 'page',
      'pages': 'pages',

      // Sharing
      'preparingDocument': 'Preparing document...',
      'documentShared': 'Document shared successfully',
      'errorSharing': 'Error sharing document',

      // Onboarding
      'scanDocumentsTitle': 'Scan Documents',
      'scanDocumentsDesc':
          'Capture crisp, clear scans of documents, receipts, and more using your camera.',
      'editEnhanceTitle': 'Edit & Enhance',
      'editEnhanceDesc':
          'Adjust brightness, contrast, and more. Auto-enhance for perfect results every time.',
      'saveShareTitle': 'Save & Share',
      'saveShareDesc':
          'Export as PDF, PNG, or JPEG. Share instantly with anyone via email, messaging, or cloud storage.',
      'getStarted': 'Get Started',
      'next': 'Next',
      'skip': 'Skip',
    },
    'bn': {
      // App Name & General
      'appName': 'স্ক্যানঅ্যাপ',
      'exit': 'বের হন',
      'exitApp': 'অ্যাপ থেকে বের হন',
      'exitConfirmation': 'আপনি কি নিশ্চিত যে আপনি বের হতে চান?',
      'cancel': 'বাতিল',
      'done': 'সম্পন্ন',
      'delete': 'মুছুন',
      'share': 'শেয়ার',
      'save': 'সংরক্ষণ',
      'reset': 'রিসেট',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'selectLanguage': 'ভাষা নির্বাচন করুন',
      'back': 'পিছনে',

      // Home Screen
      'quickActions': 'দ্রুত অ্যাকশন',
      'scanDocument': 'ডকুমেন্ট স্ক্যান',
      'scanDocumentSubtitle': 'নতুন ডকুমেন্ট ক্যাপচার এবং স্ক্যান করুন',
      'myDocuments': 'আমার ডকুমেন্ট',
      'myDocumentsSubtitle':
          'আপনার স্ক্যান করা ডকুমেন্ট দেখুন এবং পরিচালনা করুন',
      'statistics': 'পরিসংখ্যান',
      'totalDocuments': 'মোট ডকুমেন্ট',
      'favorites': 'প্রিয়',
      'aboutScanApp': 'স্ক্যানঅ্যাপ সম্পর্কে',
      'aboutDescription':
          'একটি শক্তিশালী ডকুমেন্ট স্ক্যানার অ্যাপ যা আপনাকে ডকুমেন্ট ক্যাপচার, সম্পাদনা এবং পিডিএফ এবং ইমেজ ফরম্যাটে রপ্তানি করতে দেয়। আপনার সমস্ত ডকুমেন্ট আপনার ডিভাইসে স্থানীয়ভাবে সংরক্ষিত থাকে।',

      // Document Scanner
      'openingScanner': 'স্ক্যানার খুলছে...',
      'preparing': 'প্রস্তুত হচ্ছে...',
      'scanningFailed': 'স্ক্যানিং ব্যর্থ',

      // Image Editing
      'editScan': 'স্ক্যান সম্পাদনা',
      'original': 'মূল',
      'autoEnhance': 'অটো',
      'magicColor': 'ম্যাজিক',
      'blackWhite': 'সাদা-কালো',
      'grayscale': 'গ্রে',
      'highContrast': 'কনট্রাস্ট',
      'rotateLeft': 'বাম ঘোরান',
      'rotateRight': 'ডান ঘোরান',

      // Document Builder
      'buildDocument': 'ডকুমেন্ট তৈরি',
      'documentTitle': 'ডকুমেন্ট শিরোনাম',
      'enterDocumentName': 'ডকুমেন্টের নাম লিখুন',
      'exportFormat': 'রপ্তানি ফরম্যাট',
      'compression': 'সংকোচন',
      'high': 'উচ্চ',
      'medium': 'মাঝারি',
      'low': 'নিম্ন',
      'scanMorePages': 'আরও পৃষ্ঠা স্ক্যান',
      'pagesAdded': 'যোগ করা হয়েছে',
      'exportAndSave': 'রপ্তানি এবং সংরক্ষণ',
      'noImages': 'এখনও কোনো ছবি স্ক্যান হয়নি',
      'startScanning': 'ডকুমেন্ট স্ক্যান করে শুরু করুন',

      // Documents List
      'searchDocuments': 'ডকুমেন্ট খুঁজুন...',
      'sortByDate': 'তারিখ অনুসারে সাজান',
      'sortByName': 'নাম অনুসারে সাজান',
      'sortBySize': 'আকার অনুসারে সাজান',
      'noDocumentsFound': 'কোনো ডকুমেন্ট পাওয়া যায়নি',
      'scanYourFirstDocument': 'আপনার প্রথম ডকুমেন্ট স্ক্যান করুন',
      'deleteDocument': 'ডকুমেন্ট মুছুন',
      'deleteConfirmation':
          'আপনি কি নিশ্চিত যে আপনি এই ডকুমেন্টটি মুছে ফেলতে চান? এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
      'documentDeleted': 'ডকুমেন্ট মুছে ফেলা হয়েছে',
      'addToFavorite': 'প্রিয়তে যোগ করুন',
      'removeFromFavorite': 'প্রিয় থেকে সরান',
      'page': 'পৃষ্ঠা',
      'pages': 'পৃষ্ঠা',

      // Sharing
      'preparingDocument': 'ডকুমেন্ট প্রস্তুত হচ্ছে...',
      'documentShared': 'ডকুমেন্ট সফলভাবে শেয়ার করা হয়েছে',
      'errorSharing': 'ডকুমেন্ট শেয়ার করতে সমস্যা',

      // Onboarding
      'scanDocumentsTitle': 'ডকুমেন্ট স্ক্যান করুন',
      'scanDocumentsDesc':
          'আপনার ক্যামেরা ব্যবহার করে ডকুমেন্ট, রসিদ এবং আরও অনেক কিছুর পরিষ্কার স্ক্যান ক্যাপচার করুন।',
      'editEnhanceTitle': 'সম্পাদনা এবং উন্নত করুন',
      'editEnhanceDesc':
          'উজ্জ্বলতা, কনট্রাস্ট এবং আরও অনেক কিছু সামঞ্জস্য করুন। প্রতিবার নিখুঁত ফলাফলের জন্য অটো-এনহান্স।',
      'saveShareTitle': 'সংরক্ষণ এবং শেয়ার',
      'saveShareDesc':
          'পিডিএফ, পিএনজি বা জেপিইজি হিসাবে রপ্তানি করুন। ইমেল, মেসেজিং বা ক্লাউড স্টোরেজের মাধ্যমে তাৎক্ষণিক শেয়ার করুন।',
      'getStarted': 'শুরু করুন',
      'next': 'পরবর্তী',
      'skip': 'এড়িয়ে যান',
    },
    'hi': {
      // App Name & General
      'appName': 'स्कैनऐप',
      'exit': 'बाहर निकलें',
      'exitApp': 'ऐप से बाहर निकलें',
      'exitConfirmation': 'क्या आप निश्चित हैं कि आप बाहर निकलना चाहते हैं?',
      'cancel': 'रद्द करें',
      'done': 'हो गया',
      'delete': 'हटाएं',
      'share': 'साझा करें',
      'save': 'सहेजें',
      'reset': 'रीसेट',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'selectLanguage': 'भाषा चुनें',
      'back': 'पीछे',

      // Home Screen
      'quickActions': 'त्वरित क्रियाएं',
      'scanDocument': 'दस्तावेज़ स्कैन करें',
      'scanDocumentSubtitle': 'नया दस्तावेज़ कैप्चर और स्कैन करें',
      'myDocuments': 'मेरे दस्तावेज़',
      'myDocumentsSubtitle':
          'अपने स्कैन किए गए दस्तावेज़ देखें और प्रबंधित करें',
      'statistics': 'आंकड़े',
      'totalDocuments': 'कुल दस्तावेज़',
      'favorites': 'पसंदीदा',
      'aboutScanApp': 'स्कैनऐप के बारे में',
      'aboutDescription':
          'एक शक्तिशाली दस्तावेज़ स्कैनर ऐप जो आपको दस्तावेज़ों को कैप्चर, संपादित और पीडीएफ और इमेज फॉर्मेट में निर्यात करने देता है। आपके सभी दस्तावेज़ आपके डिवाइस पर स्थानीय रूप से संग्रहीत हैं।',

      // Document Scanner
      'openingScanner': 'स्कैनर खुल रहा है...',
      'preparing': 'तैयारी हो रही है...',
      'scanningFailed': 'स्कैनिंग विफल',

      // Image Editing
      'editScan': 'स्कैन संपादित करें',
      'original': 'मूल',
      'autoEnhance': 'ऑटो',
      'magicColor': 'मैजिक',
      'blackWhite': 'B&W',
      'grayscale': 'ग्रे',
      'highContrast': 'कंट्रास्ट',
      'rotateLeft': 'बाएं घुमाएं',
      'rotateRight': 'दाएं घुमाएं',

      // Document Builder
      'buildDocument': 'दस्तावेज़ बनाएं',
      'documentTitle': 'दस्तावेज़ शीर्षक',
      'enterDocumentName': 'दस्तावेज़ का नाम दर्ज करें',
      'exportFormat': 'निर्यात प्रारूप',
      'compression': 'संपीड़न',
      'high': 'उच्च',
      'medium': 'मध्यम',
      'low': 'निम्न',
      'scanMorePages': 'अधिक पृष्ठ स्कैन करें',
      'pagesAdded': 'जोड़ा गया',
      'exportAndSave': 'निर्यात और सहेजें',
      'noImages': 'अभी तक कोई छवि स्कैन नहीं हुई',
      'startScanning': 'दस्तावेज़ स्कैन करके शुरू करें',

      // Documents List
      'searchDocuments': 'दस्तावेज़ खोजें...',
      'sortByDate': 'तारीख के अनुसार क्रमबद्ध करें',
      'sortByName': 'नाम के अनुसार क्रमबद्ध करें',
      'sortBySize': 'आकार के अनुसार क्रमबद्ध करें',
      'noDocumentsFound': 'कोई दस्तावेज़ नहीं मिला',
      'scanYourFirstDocument': 'अपना पहला दस्तावेज़ स्कैन करें',
      'deleteDocument': 'दस्तावेज़ हटाएं',
      'deleteConfirmation':
          'क्या आप निश्चित हैं कि आप इस दस्तावेज़ को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
      'documentDeleted': 'दस्तावेज़ हटाया गया',
      'addToFavorite': 'पसंदीदा में जोड़ें',
      'removeFromFavorite': 'पसंदीदा से हटाएं',
      'page': 'पृष्ठ',
      'pages': 'पृष्ठ',

      // Sharing
      'preparingDocument': 'दस्तावेज़ तैयार हो रहा है...',
      'documentShared': 'दस्तावेज़ सफलतापूर्वक साझा किया गया',
      'errorSharing': 'दस्तावेज़ साझा करने में त्रुटि',

      // Onboarding
      'scanDocumentsTitle': 'दस्तावेज़ स्कैन करें',
      'scanDocumentsDesc':
          'अपने कैमरे का उपयोग करके दस्तावेज़ों, रसीदों और अधिक के स्पष्ट स्कैन कैप्चर करें।',
      'editEnhanceTitle': 'संपादित करें और बेहतर बनाएं',
      'editEnhanceDesc':
          'चमक, कंट्रास्ट और बहुत कुछ समायोजित करें। हर बार सही परिणामों के लिए ऑटो-एन्हांस।',
      'saveShareTitle': 'सहेजें और साझा करें',
      'saveShareDesc':
          'पीडीएफ, पीएनजी या जेपीईजी के रूप में निर्यात करें। ईमेल, मैसेजिंग या क्लाउड स्टोरेज के माध्यम से तुरंत साझा करें।',
      'getStarted': 'शुरू करें',
      'next': 'अगला',
      'skip': 'छोड़ें',
    },
    'ar': {
      // App Name & General
      'appName': 'سكان أب',
      'exit': 'خروج',
      'exitApp': 'الخروج من التطبيق',
      'exitConfirmation': 'هل أنت متأكد أنك تريد الخروج؟',
      'cancel': 'إلغاء',
      'done': 'تم',
      'delete': 'حذف',
      'share': 'مشاركة',
      'save': 'حفظ',
      'reset': 'إعادة تعيين',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'selectLanguage': 'اختر اللغة',
      'back': 'رجوع',

      // Home Screen
      'quickActions': 'إجراءات سريعة',
      'scanDocument': 'مسح المستند',
      'scanDocumentSubtitle': 'التقاط ومسح مستند جديد',
      'myDocuments': 'مستنداتي',
      'myDocumentsSubtitle': 'عرض وإدارة المستندات الممسوحة',
      'statistics': 'الإحصائيات',
      'totalDocuments': 'إجمالي المستندات',
      'favorites': 'المفضلة',
      'aboutScanApp': 'حول سكان أب',
      'aboutDescription':
          'تطبيق قوي لمسح المستندات يتيح لك التقاط المستندات وتحريرها وتصديرها إلى تنسيقات PDF والصور. يتم تخزين جميع مستنداتك محليًا على جهازك.',

      // Document Scanner
      'openingScanner': 'جاري فتح الماسح...',
      'preparing': 'جاري التحضير...',
      'scanningFailed': 'فشل المسح',

      // Image Editing
      'editScan': 'تحرير المسح',
      'original': 'الأصلي',
      'autoEnhance': 'تلقائي',
      'magicColor': 'سحري',
      'blackWhite': 'أبيض وأسود',
      'grayscale': 'رمادي',
      'highContrast': 'تباين',
      'rotateLeft': 'تدوير لليسار',
      'rotateRight': 'تدوير لليمين',

      // Document Builder
      'buildDocument': 'بناء المستند',
      'documentTitle': 'عنوان المستند',
      'enterDocumentName': 'أدخل اسم المستند',
      'exportFormat': 'تنسيق التصدير',
      'compression': 'الضغط',
      'high': 'عالي',
      'medium': 'متوسط',
      'low': 'منخفض',
      'scanMorePages': 'مسح المزيد من الصفحات',
      'pagesAdded': 'مضافة',
      'exportAndSave': 'تصدير وحفظ',
      'noImages': 'لم يتم مسح أي صور بعد',
      'startScanning': 'ابدأ بمسح مستند',

      // Documents List
      'searchDocuments': 'البحث في المستندات...',
      'sortByDate': 'ترتيب حسب التاريخ',
      'sortByName': 'ترتيب حسب الاسم',
      'sortBySize': 'ترتيب حسب الحجم',
      'noDocumentsFound': 'لم يتم العثور على مستندات',
      'scanYourFirstDocument': 'امسح مستندك الأول',
      'deleteDocument': 'حذف المستند',
      'deleteConfirmation':
          'هل أنت متأكد أنك تريد حذف هذا المستند؟ لا يمكن التراجع عن هذا الإجراء.',
      'documentDeleted': 'تم حذف المستند',
      'addToFavorite': 'إضافة إلى المفضلة',
      'removeFromFavorite': 'إزالة من المفضلة',
      'page': 'صفحة',
      'pages': 'صفحات',

      // Sharing
      'preparingDocument': 'جاري تحضير المستند...',
      'documentShared': 'تمت مشاركة المستند بنجاح',
      'errorSharing': 'خطأ في مشاركة المستند',

      // Onboarding
      'scanDocumentsTitle': 'مسح المستندات',
      'scanDocumentsDesc':
          'التقط مسحات واضحة للمستندات والإيصالات والمزيد باستخدام الكاميرا.',
      'editEnhanceTitle': 'تحرير وتحسين',
      'editEnhanceDesc':
          'اضبط السطوع والتباين والمزيد. تحسين تلقائي للحصول على نتائج مثالية في كل مرة.',
      'saveShareTitle': 'حفظ ومشاركة',
      'saveShareDesc':
          'تصدير كـ PDF أو PNG أو JPEG. شارك على الفور عبر البريد الإلكتروني أو المراسلة أو التخزين السحابي.',
      'getStarted': 'ابدأ الآن',
      'next': 'التالي',
      'skip': 'تخطي',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience getters for common strings
  String get appName => translate('appName');
  String get exit => translate('exit');
  String get exitApp => translate('exitApp');
  String get exitConfirmation => translate('exitConfirmation');
  String get cancel => translate('cancel');
  String get done => translate('done');
  String get delete => translate('delete');
  String get share => translate('share');
  String get save => translate('save');
  String get reset => translate('reset');
  String get settings => translate('settings');
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get back => translate('back');

  String get quickActions => translate('quickActions');
  String get scanDocument => translate('scanDocument');
  String get scanDocumentSubtitle => translate('scanDocumentSubtitle');
  String get myDocuments => translate('myDocuments');
  String get myDocumentsSubtitle => translate('myDocumentsSubtitle');
  String get statistics => translate('statistics');
  String get totalDocuments => translate('totalDocuments');
  String get favorites => translate('favorites');
  String get aboutScanApp => translate('aboutScanApp');
  String get aboutDescription => translate('aboutDescription');

  String get openingScanner => translate('openingScanner');
  String get preparing => translate('preparing');
  String get scanningFailed => translate('scanningFailed');

  String get editScan => translate('editScan');
  String get original => translate('original');
  String get autoEnhance => translate('autoEnhance');
  String get magicColor => translate('magicColor');
  String get blackWhite => translate('blackWhite');
  String get grayscale => translate('grayscale');
  String get highContrast => translate('highContrast');
  String get rotateLeft => translate('rotateLeft');
  String get rotateRight => translate('rotateRight');

  String get buildDocument => translate('buildDocument');
  String get documentTitle => translate('documentTitle');
  String get enterDocumentName => translate('enterDocumentName');
  String get exportFormat => translate('exportFormat');
  String get compression => translate('compression');
  String get high => translate('high');
  String get medium => translate('medium');
  String get low => translate('low');
  String get scanMorePages => translate('scanMorePages');
  String get pagesAdded => translate('pagesAdded');
  String get exportAndSave => translate('exportAndSave');
  String get noImages => translate('noImages');
  String get startScanning => translate('startScanning');

  String get searchDocuments => translate('searchDocuments');
  String get sortByDate => translate('sortByDate');
  String get sortByName => translate('sortByName');
  String get sortBySize => translate('sortBySize');
  String get noDocumentsFound => translate('noDocumentsFound');
  String get scanYourFirstDocument => translate('scanYourFirstDocument');
  String get deleteDocument => translate('deleteDocument');
  String get deleteConfirmation => translate('deleteConfirmation');
  String get documentDeleted => translate('documentDeleted');
  String get addToFavorite => translate('addToFavorite');
  String get removeFromFavorite => translate('removeFromFavorite');
  String get page => translate('page');
  String get pages => translate('pages');

  String get preparingDocument => translate('preparingDocument');
  String get documentShared => translate('documentShared');
  String get errorSharing => translate('errorSharing');

  String get scanDocumentsTitle => translate('scanDocumentsTitle');
  String get scanDocumentsDesc => translate('scanDocumentsDesc');
  String get editEnhanceTitle => translate('editEnhanceTitle');
  String get editEnhanceDesc => translate('editEnhanceDesc');
  String get saveShareTitle => translate('saveShareTitle');
  String get saveShareDesc => translate('saveShareDesc');
  String get getStarted => translate('getStarted');
  String get next => translate('next');
  String get skip => translate('skip');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'bn', 'hi', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
