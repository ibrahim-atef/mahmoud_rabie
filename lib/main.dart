import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
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
          onNavigationRequest: (NavigationRequest request) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
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