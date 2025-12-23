import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:screen_protector/screen_protector.dart';

void main() {
  runApp(const MrMahmoudRabieApp());
}

class MrMahmoudRabieApp extends StatelessWidget {
  const MrMahmoudRabieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr Mahmoud Rabie - Spring Series',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasLoadedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _initializeScreenProtector();
  }

  /// Initialize screen protection on Android/iOS
  Future<void> _initializeScreenProtector() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🛡️ Enabling Android screen protection...');
        await ScreenProtector.protectDataLeakageOn();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🛡️ Enabling iOS screenshot prevention...');
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {
      debugPrint('❌ ScreenProtector init error: $e');
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Configure Android WebView settings for YouTube video playback
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingProgress = 0.0;
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingProgress = 1.0;
              _isLoading = false;
              _hasLoadedSuccessfully = true;
              _errorMessage = null; // Clear any previous errors
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Only show error if the page hasn't loaded successfully
            // Filter out common non-critical errors that don't affect the main page
            if (!_hasLoadedSuccessfully &&
                !error.description.contains('ERR_NAME_NOT_RESOLVED') &&
                !error.description.contains('ERR_CONNECTION_REFUSED') &&
                !error.description.contains('ERR_INTERNET_DISCONNECTED')) {
              setState(() {
                _errorMessage = 'خطأ في تحميل الصفحة: ${error.description}';
                _isLoading = false;
              });
            }
            debugPrint('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            debugPrint('🧭 Navigation request: $url');

            // Check if URL is a PDF file
            if (url.toLowerCase().endsWith('.pdf') ||
                url.toLowerCase().contains('.pdf?') ||
                url.toLowerCase().contains('.pdf#')) {
              debugPrint('📄 PDF detected, starting download: $url');
              if (mounted) {
                await _downloadPdf(context, url);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://mr-mahmoud-rabie.com/'));

    _controller = controller;
  }

  void _refreshWebView() {
    setState(() {
      _loadingProgress = 0.0;
      _isLoading = true;
      _errorMessage = null;
      _hasLoadedSuccessfully = false;
    });
    _controller.reload();
  }

  /// Request storage permission with dialog
  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      // iOS doesn't need explicit storage permission for app documents
      return true;
    }

    // Always show dialog first to ask user for permission
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.folder, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'صلاحية التخزين',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'يحتاج التطبيق إلى صلاحية الوصول إلى التخزين لتحميل الملفات إلى مجلد التنزيلات.\n\n'
            'هل تريد السماح بالوصول إلى التخزين؟',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'موافق',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء التحميل - الصلاحية مطلوبة'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    // Check if permission is already granted
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      debugPrint('✅ Storage permission already granted');
      return true;
    }

    // Check manage external storage for Android 11+
    var manageStorageStatus = await Permission.manageExternalStorage.status;
    if (manageStorageStatus.isGranted) {
      debugPrint('✅ Manage external storage permission already granted');
      return true;
    }

    // Check if permission is permanently denied
    final isPermanentlyDenied = storageStatus.isPermanentlyDenied ||
        manageStorageStatus.isPermanentlyDenied;

    // If permanently denied, show dialog to open settings
    if (isPermanentlyDenied) {
      if (mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'صلاحية مرفوضة',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'تم رفض صلاحية التخزين مسبقاً.\n\n'
                'يجب السماح بها من إعدادات التطبيق.\n\n'
                'هل تريد فتح الإعدادات الآن؟',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'فتح الإعدادات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          final opened = await openAppSettings();
          if (!opened && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن فتح الإعدادات'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
      return false;
    }

    // Request storage permission first
    debugPrint('📝 Requesting storage permission...');
    storageStatus = await Permission.storage.request();
    debugPrint('📝 Storage permission status: ${storageStatus.name}');

    // Wait a bit and check again (sometimes there's a delay)
    if (!storageStatus.isGranted) {
      await Future.delayed(const Duration(milliseconds: 500));
      storageStatus = await Permission.storage.status;
      debugPrint(
        '📝 Storage permission status after delay: ${storageStatus.name}',
      );
    }

    if (storageStatus.isGranted) {
      debugPrint('✅ Storage permission granted');
      return true;
    }

    // Try manage external storage for Android 11+ (API 30+)
    debugPrint('📝 Requesting manage external storage permission...');
    manageStorageStatus = await Permission.manageExternalStorage.request();
    debugPrint(
      '📝 Manage external storage status: ${manageStorageStatus.name}',
    );

    // Wait a bit and check again
    if (!manageStorageStatus.isGranted) {
      await Future.delayed(const Duration(milliseconds: 500));
      manageStorageStatus = await Permission.manageExternalStorage.status;
      debugPrint(
        '📝 Manage external storage status after delay: ${manageStorageStatus.name}',
      );
    }

    if (manageStorageStatus.isGranted) {
      debugPrint('✅ Manage external storage permission granted');
      return true;
    }

    // Check if permanently denied after request
    if (storageStatus.isPermanentlyDenied ||
        manageStorageStatus.isPermanentlyDenied) {
      if (mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'صلاحية مرفوضة',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'تم رفض الصلاحية.\n\n'
                'يجب السماح بها من إعدادات التطبيق.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'فتح الإعدادات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // If still not granted, but not permanently denied, try to continue anyway
    // (Android 10+ allows app-specific directories without permission)
    debugPrint('⚠️ Permission not granted, but trying to continue...');
    return true; // Try anyway - might work with app-specific directory
  }

  /// Download PDF file from URL
  Future<void> _downloadPdf(BuildContext context, String url) async {
    if (!mounted) return;

    try {
      // Request storage permission first with dialog
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) {
        return;
      }

      // Show download started message after permission granted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('بدأ التحميل...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Get download directory - try public Downloads folder first, fallback to app directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        // First, try to use public Downloads folder
        bool canUsePublicDownloads = false;

        try {
          // Get external storage directory to extract root path
          final externalStorage = await getExternalStorageDirectory();
          if (externalStorage != null) {
            // Extract root path (everything before /Android/data)
            // Example: /storage/emulated/0/Android/data/com.spring.series/files
            // Result: /storage/emulated/0
            final rootPath = externalStorage.path.split('/Android')[0];
            final publicDownloads = Directory('$rootPath/Download');
            debugPrint(
                '📁 Trying public Downloads directory: ${publicDownloads.path}');

            // Ensure directory exists
            if (!await publicDownloads.exists()) {
              await publicDownloads.create(recursive: true);
            }

            // Test write access
            try {
              final testFile = File('${publicDownloads.path}/.test');
              await testFile.writeAsString('test');
              await testFile.delete();
              debugPrint('✅ Can write to public Downloads directory');
              downloadDir = publicDownloads;
              canUsePublicDownloads = true;
            } catch (e) {
              debugPrint('⚠️ Cannot write to public Downloads: $e');
              // Try alternative public path
              try {
                final altDownloads = Directory('/storage/emulated/0/Download');
                if (!await altDownloads.exists()) {
                  await altDownloads.create(recursive: true);
                }
                final testFile = File('${altDownloads.path}/.test');
                await testFile.writeAsString('test');
                await testFile.delete();
                debugPrint('✅ Can write to alternative Downloads path');
                downloadDir = altDownloads;
                canUsePublicDownloads = true;
              } catch (e2) {
                debugPrint('⚠️ Cannot write to alternative Downloads: $e2');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error accessing public Downloads: $e');
        }

        // If can't use public Downloads, use app-specific directory
        if (!canUsePublicDownloads) {
          debugPrint('📁 Using app-specific directory as fallback');
          final appDir = await getApplicationDocumentsDirectory();
          downloadDir = Directory('${appDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          debugPrint('📁 Using app directory: ${downloadDir.path}');
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, use application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${appDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      }

      // Extract filename from URL
      final uri = Uri.parse(url);
      String fileName = path.basename(uri.path);
      if (fileName.isEmpty || !fileName.toLowerCase().endsWith('.pdf')) {
        // Generate filename if not found
        fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      // Decode URL-encoded filename
      try {
        fileName = Uri.decodeComponent(fileName);
      } catch (e) {
        debugPrint('⚠️ Could not decode filename: $e');
      }

      if (downloadDir == null) {
        throw Exception('لا يمكن تحديد مجلد التحميل');
      }

      final filePath = path.join(downloadDir.path, fileName);

      // Download file using dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('📥 Download progress: $progress%');
          }
        },
      );

      // Verify file was saved
      final savedFile = File(filePath);
      if (!await savedFile.exists()) {
        throw Exception('الملف لم يُحفظ بشكل صحيح');
      }

      final fileSize = await savedFile.length();
      debugPrint('✅ File saved: $filePath (Size: $fileSize bytes)');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final isPublicDownloads = Platform.isAndroid &&
            (downloadDir.path.contains('/Download') ||
                downloadDir.path.contains('/storage/emulated'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ تم التحميل بنجاح',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isPublicDownloads
                        ? 'تم الحفظ في مجلد التنزيلات'
                        : 'تم الحفظ في مجلد التطبيق',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      debugPrint('✅ File downloaded successfully: $filePath');
    } catch (e) {
      debugPrint('❌ Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تحميل الملف: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Disable screen protection when leaving
    if (defaultTargetPlatform == TargetPlatform.android) {
      ScreenProtector.protectDataLeakageOff();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      ScreenProtector.preventScreenshotOff();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the app bar completely for full-screen website view
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshWebView();
          },
          child: Stack(
            children: [
              // WebView - full screen
              WebViewWidget(controller: _controller),

              // Loading Progress Bar - only show when actually loading
              if (_isLoading && _loadingProgress < 1.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    minHeight: 3,
                  ),
                ),

              // Error Message - only show if there's a real error and page hasn't loaded
              if (_errorMessage != null && !_hasLoadedSuccessfully)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[600],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshWebView,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
