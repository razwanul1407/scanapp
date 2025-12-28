# ScanApp - Modern Document Scanner & PDF Converter

A feature-rich Flutter document scanning application with support for image processing, PDF generation, QR/barcode scanning, and local document management.

## Architecture Overview

### 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point with Provider setup
├── services/                 # Business logic layer
│   ├── camera_service.dart   # Camera operations
│   ├── database_service.dart # Isar database operations
│   ├── image_processor.dart  # Image adjustments (isolate-based)
│   ├── image_service.dart    # Image picking & edge detection
│   ├── pdf_service.dart      # PDF generation & export
│   └── permission_service.dart # Permission handling (Android 13+)
├── providers/                # Provider state management
│   ├── camera_provider.dart  # Camera state
│   ├── documents_provider.dart # Documents CRUD & search
│   ├── document_builder_provider.dart # Multi-page PDF builder
│   └── image_editing_provider.dart # Image editing state
├── models/                   # Isar data models
│   └── scanned_document.dart # Document structure
├── screens/                  # UI screens (to be built)
│   ├── home_screen.dart      # Main dashboard
│   ├── splash_screen.dart    # App splash
│   ├── onboarding_screen.dart (TODO)
│   ├── camera_scanner_screen.dart (TODO)
│   ├── image_editing_screen.dart (TODO)
│   ├── documents_list_screen.dart (TODO)
│   └── document_builder_screen.dart (TODO)
├── widgets/                  # Reusable UI components
│   ├── custom_buttons.dart   # Button styles & variants
│   ├── permission_dialogs.dart # Permission request dialogs
│   └── (TODO: more custom widgets)
└── theme/
    └── app_theme.dart        # Material Design 3 theming
```

---

## 🚀 Tech Stack (Latest - Jan 2025)

### Core Dependencies

- **Flutter**: v3.10+ with Material Design 3
- **Dart**: v3.5.2+

### Key Packages

| Package                | Version  | Purpose                                       |
| ---------------------- | -------- | --------------------------------------------- |
| **provider**           | ^6.1.0   | State management                              |
| **camera**             | ^0.11.3  | Real-time camera feed                         |
| **mobile_scanner**     | ^7.1.4   | QR/barcode scanning                           |
| **edge_detection**     | ^1.1.3   | Document boundary detection                   |
| **image**              | ^4.5.4   | Image processing (brightness, contrast, etc.) |
| **pdf**                | ^3.11.3  | PDF generation with multi-page support        |
| **isar**               | ^3.1.0+1 | Local database (NoSQL, fastest)               |
| **permission_handler** | ^12.0.1  | Permissions (Android 13+ compliant)           |
| **go_router**          | ^14.x    | Navigation (ready for implementation)         |
| **share_plus**         | ^10.1.4  | Share files via system share sheet            |
| **path_provider**      | ^2.1.0   | App directory access                          |

### Dev Dependencies

- **isar_generator** | ^3.1.0+1 | Generate Isar models
- **build_runner** | ^2.4.0 | Code generation

---

## 🎨 UI/UX Design

### Material Design 3 Implementation

- **Primary Color**: `#1F77F5` (Modern Blue)
- **Secondary**: `#7C3AED` (Purple)
- **Tertiary**: `#06B6D4` (Cyan)
- **Dark Mode Support**: Full light/dark theme support with system preference detection

### Custom Components

- **CustomButtons**: Primary, Secondary, Icon buttons with loading states
- **PermissionDialogs**: Beautiful permission request and settings dialogs
- **Material Design 3 Theming**: Rounded corners, proper spacing, smooth animations

---

## 📱 Platform Configurations

### Android (`android/app/src/main/AndroidManifest.xml`)

- ✅ `android.permission.CAMERA` - Camera access
- ✅ `android.permission.READ_MEDIA_IMAGES` - Gallery (Android 13+)
- ✅ `android.permission.READ_EXTERNAL_STORAGE` - Fallback for Android 12-
- ✅ `android.permission.WRITE_EXTERNAL_STORAGE` - Document saving (Android 12-)
- ✅ `android.permission.INTERNET` - Future cloud features

### iOS (`ios/Runner/Info.plist`)

- ✅ `NSCameraUsageDescription` - Camera permission
- ✅ `NSPhotoLibraryUsageDescription` - Photo library read access
- ✅ `NSPhotoLibraryAddUsageDescription` - Photo library write access
- ✅ `UIFileSharingEnabled` - Document sharing
- ✅ `LSSupportsOpeningDocumentsInPlace` - Document handling

---

## 💾 Local Database (Isar)

### ScannedDocument Model

```dart
@collection
class ScannedDocument {
  Id id = Isar.autoIncrement;
  late String title;
  late DateTime createdAt;
  late DateTime updatedAt;
  late List<String> imagePaths;      // Local file paths
  late String? thumbnailPath;
  late List<String> tags;            // For search/categorization
  late String? notes;
  late int pageCount;
  late int fileSize;
  late bool isFavorite;
  late String? lastExportFormat;     // 'pdf', 'jpg', 'png'
}
```

### Database Operations

- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Full-text search by title, tags, notes
- ✅ Favorite documents filtering
- ✅ Tag-based organization
- ✅ Sorting (by date, name, file size)

---

## 🔄 State Management with Provider

### Providers Created

1. **DocumentsProvider**

   - Manages scanned documents list
   - Search & filter functionality
   - Favorite document management
   - CRUD operations

2. **ImageEditingProvider**

   - Brightness, contrast, saturation adjustments
   - Grayscale toggle
   - Image rotation
   - Auto-enhance functionality

3. **DocumentBuilderProvider**

   - Multi-image management
   - Image reordering
   - Export format selection
   - Document title & metadata

4. **CameraProvider**
   - Camera initialization & lifecycle
   - Flash control
   - Camera switching (front/back)
   - Scan mode management (document/QR)

---

## 📸 Services Layer

### CameraService

- Real-time camera feed management
- Front/back camera switching
- Flash toggle
- Picture capture & saving to local storage

### ImageProcessor (Isolate-based)

- **Non-blocking Operations**: Uses Dart isolates to prevent UI jank
- Brightness adjustment
- Contrast enhancement
- Saturation control
- Grayscale conversion
- Image rotation (90°, 180°, 270°)
- Auto-enhance (intelligent brightness & contrast)

### PDFService

- Single & multi-page PDF generation
- Image export (PNG, JPEG with quality control)
- Direct file sharing via system share sheet
- Smart directory handling (Android Documents/Downloads)

### PermissionService (Android 13+ Compliant)

- Camera permission
- Photos/Gallery permission (READ_MEDIA_IMAGES on Android 13+)
- Storage permission (with Android version detection)
- Settings redirect for permanently denied permissions

### DatabaseService

- Isar database initialization
- CRUD operations
- Advanced querying (search, filter, sort)
- Tag management

---

## 🎯 Next Steps (Features to Build)

### Phase 1 - Core Screens (Medium Priority)

1. **Onboarding Screen**

   - 3-slide feature overview
   - Permission explanation
   - Start scanning CTA

2. **Camera Scanner Screen**

   - Real-time camera feed with edge overlay
   - Document/QR dual mode toggle
   - Auto-capture vs manual tap
   - Flash control
   - Camera switch button

3. **Image Editing Screen**

   - Brightness/Contrast/Saturation sliders
   - Real-time preview (before/after)
   - Auto-enhance button
   - Rotation controls
   - Crop editor with perspective correction

4. **Document Builder Screen**

   - Add/remove pages
   - Page reordering via drag-drop
   - Export format selection
   - Document title input
   - Preview before export

5. **Documents List Screen**
   - Grid/list view toggle
   - Search bar
   - Sort options (date, name, size)
   - Delete/favorite/rename actions
   - Quick share buttons

### Phase 2 - Advanced Features (Low Priority)

- OCR text extraction
- Cloud backup (Firebase/Dropbox)
- Document annotations
- Batch scanning
- Advanced filters (sepia, blur, etc.)
- Document templates

---

## ✅ Quality Checklist

- ✅ Latest packages (as of Jan 2025)
- ✅ Material Design 3 implementation
- ✅ Provider state management
- ✅ Local database (Isar)
- ✅ Android 13+ compliant permissions
- ✅ iOS app permissions configured
- ✅ Image processing with isolates (non-blocking)
- ✅ PDF multi-page support
- ✅ Custom Material Design 3 theme
- ✅ Error handling framework
- ⏳ Screens UI (in progress)

---

## 🚨 Known Issues & TODOs

1. **Edge Detection**: Currently returns null placeholder - needs native implementation via `edge_detection` package
2. **Screens**: UI screens are skeleton/placeholder implementations (home_screen.dart, splash_screen.dart)
3. **Print Statements**: Using `print()` for debugging - should replace with proper logging in production
4. **Go Router**: Navigation structure ready but not fully implemented
5. **Deprecated Methods**: Using deprecated Flutter color methods (`.withOpacity()` → `.withValues()` needed for newer Flutter)

---

## 🔧 How to Build & Run

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.5.2+
- Android SDK 24+ (or iOS 12.0+)

### Setup

```bash
cd scanapp
flutter pub get
flutter pub run build_runner build  # Generate Isar models
flutter run                         # Run app
```

### Code Generation

```bash
# Generate/regenerate Isar models
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Project Statistics

- **Total Files Created/Modified**: 20+
- **Lines of Code**: ~3,500+
- **Providers**: 4
- **Services**: 6
- **Models**: 1 (ScannedDocument)
- **Custom Widgets**: 2+
- **Packages Integrated**: 20+

---

## 🎓 Architecture Benefits

✅ **Provider Pattern**: Lightweight, easy to test, good for local-only apps  
✅ **Service Layer**: Clean separation of concerns  
✅ **Isolates**: Non-blocking image processing  
✅ **Isar Database**: Fast local storage with advanced queries  
✅ **Material Design 3**: Modern, consistent UI across platforms  
✅ **Type Safety**: Dart null safety throughout  
✅ **Android 13+ Ready**: Scoped storage & new permission model

---

**Version**: 1.0.0-beta  
**Status**: Core infrastructure complete ✅ | UI screens pending ⏳  
**Last Updated**: December 2025
