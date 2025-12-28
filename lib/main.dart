import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/services/database_service.dart';
import 'package:scanapp/theme/app_theme.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/providers/language_provider.dart';
import 'package:scanapp/l10n/app_localizations.dart';
import 'package:scanapp/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database in background to prevent frame skips
  DatabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DocumentsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ImageEditingProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => DocumentBuilderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp.router(
            title: 'ScanApp - Document Scanner',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            locale: languageProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLanguages
                .map((lang) => lang.locale)
                .toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final ImagePicker _picker = ImagePicker();
//   File? _image;
//   File? _croppedImage;
//   bool _isProcessing = false;

//   Future<bool> _requestCameraPermission() async {
//     final status = await Permission.camera.request();
//     if (status.isGranted) {
//       return true;
//     } else if (status.isPermanentlyDenied) {
//       await openAppSettings();
//     }
//     return false;
//   }

//   Future<bool> _requestStoragePermission() async {
//     if (Platform.isAndroid) {
//       final status = await Permission.storage.request();
//       if (status.isGranted) {
//         return true;
//       } else if (status.isPermanentlyDenied) {
//         await openAppSettings();
//       }
//       return false;
//     } else {
//       // On iOS, we only need photos permission
//       final status = await Permission.photos.request();
//       if (status.isGranted) {
//         return true;
//       } else if (status.isPermanentlyDenied) {
//         await openAppSettings();
//       }
//       return false;
//     }
//   }

//   Future<void> _showImageSourceDialog() async {
//     return showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Select Image Source"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text("Camera"),
//               onTap: () async {
//                 Navigator.pop(context);
//                 if (await _requestCameraPermission()) {
//                   _pickImage(ImageSource.camera);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Camera permission denied')),
//                   );
//                 }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text("Gallery"),
//               onTap: () async {
//                 Navigator.pop(context);
//                 if (await _requestStoragePermission()) {
//                   _pickImage(ImageSource.gallery);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Storage permission denied')),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final pickedFile = await _picker.pickImage(source: source);
//       if (pickedFile != null) {
//         final croppedFile = await ImageCropper().cropImage(
//           sourcePath: pickedFile.path,
//           aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
//           uiSettings: [
//             AndroidUiSettings(
//               toolbarTitle: 'Crop Image',
//               toolbarColor: Colors.blue,
//               toolbarWidgetColor: Colors.white,
//               initAspectRatio: CropAspectRatioPreset.original,
//               lockAspectRatio: false,
//             ),
//             IOSUiSettings(
//               title: 'Crop Image',
//               aspectRatioLockEnabled: false,
//               resetAspectRatioEnabled: true,
//             ),
//           ],
//         );

//         if (croppedFile != null) {
//           setState(() {
//             _image = File(pickedFile.path);
//             _croppedImage = File(croppedFile.path);
//           });
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick image: $e')),
//       );
//     }
//   }

//   Future<void> _createPdfAndShare() async {
//     if (_croppedImage == null) return;

//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       final pdf = pw.Document();
//       final image = pw.MemoryImage(_croppedImage!.readAsBytesSync());

//       pdf.addPage(pw.Page(
//         build: (pw.Context context) {
//           return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
//         },
//       ));

//       // Save to documents directory
//       final output = await getApplicationDocumentsDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final file = File("${output.path}/document_$timestamp.pdf");
//       await file.writeAsBytes(await pdf.save());

//       // Share the PDF
//       await Printing.sharePdf(
//         bytes: await pdf.save(),
//         filename: 'document_$timestamp.pdf',
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create PDF: $e')),
//       );
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   Future<void> _savePdfToStorage() async {
//     if (_croppedImage == null) return;

//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       // Request storage permission if not granted
//       if (!await _requestStoragePermission()) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Storage permission required to save PDF')),
//         );
//         return;
//       }

//       final pdf = pw.Document();
//       final image = pw.MemoryImage(_croppedImage!.readAsBytesSync());

//       pdf.addPage(pw.Page(
//         build: (pw.Context context) {
//           return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
//         },
//       ));

//       Directory directory;
//       if (Platform.isAndroid) {
//         directory = Directory('/storage/emulated/0/Documents');
//         if (!await directory.exists()) {
//           directory = Directory('/storage/emulated/0/Download');
//           if (!await directory.exists()) {
//             directory = await getExternalStorageDirectory() ??
//                 await getApplicationDocumentsDirectory();
//           }
//         }
//       } else {
//         directory = await getApplicationDocumentsDirectory();
//       }

//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final file = File("${directory.path}/document_$timestamp.pdf");
//       await file.writeAsBytes(await pdf.save());

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF saved to ${file.path}')),
//       );
//       _clearSelection();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save PDF: $e')),
//       );
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   void _clearSelection() {
//     setState(() {
//       _image = null;
//       _croppedImage = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('PDF Creator'),
//         actions: _croppedImage != null
//             ? [
//                 IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: _clearSelection,
//                 ),
//               ]
//             : null,
//       ),
//       body: Center(
//         child: _isProcessing
//             ? const CircularProgressIndicator()
//             : _croppedImage != null
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Image.file(_croppedImage!),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             ElevatedButton.icon(
//                               icon: const Icon(Icons.save),
//                               label: const Text('Save PDF'),
//                               onPressed: _savePdfToStorage,
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 20, vertical: 12),
//                               ),
//                             ),
//                             ElevatedButton.icon(
//                               icon: const Icon(Icons.share),
//                               label: const Text('Share PDF'),
//                               onPressed: _createPdfAndShare,
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 20, vertical: 12),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   )
//                 : Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.insert_photo,
//                         size: 100,
//                         color: Colors.blue[200],
//                       ),
//                       const SizedBox(height: 20),
//                       const Text(
//                         'No image selected',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                     ],
//                   ),
//       ),
//       floatingActionButton: _croppedImage == null
//           ? FloatingActionButton.extended(
//               onPressed: _showImageSourceDialog,
//               icon: const Icon(Icons.add_a_photo),
//               label: const Text('Add Image'),
//             )
//           : null,
//     );
//   }
// }
