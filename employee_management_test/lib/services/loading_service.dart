import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ⏳ Global Loading Service
/// 
/// Provides centralized loading state management using ChangeNotifier:
/// - Show/Hide loading overlay globally
/// - Customizable loading message
/// - Prevent user interaction during loading
/// 
/// Setup in main.dart:
/// ```dart
/// runApp(
///   ChangeNotifierProvider(
///     create: (_) => LoadingService(),
///     child: MyApp(),
///   ),
/// );
/// ```
/// 
/// Usage:
/// ```dart
/// // Show loading
/// context.read<LoadingService>().show('Đang xử lý...');
/// 
/// // Hide loading
/// context.read<LoadingService>().hide();
/// ```
class LoadingService extends ChangeNotifier {
  bool _isLoading = false;
  String _loadingMessage = 'Đang tải...';

  /// Get current loading state
  bool get isLoading => _isLoading;

  /// Get current loading message
  String get loadingMessage => _loadingMessage;

  /// Show loading overlay
  /// 
  /// @param message - Optional loading message (default: "Đang tải...")
  void show([String message = 'Đang tải...']) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Hide loading overlay
  void hide() {
    _isLoading = false;
    _loadingMessage = 'Đang tải...';
    notifyListeners();
  }

  /// Execute async operation with loading overlay
  /// 
  /// Automatically shows loading at start and hides when done.
  /// 
  /// @param operation - Async function to execute
  /// @param message - Loading message
  /// @returns Result of the operation
  /// 
  /// Example:
  /// ```dart
  /// final data = await loadingService.execute(
  ///   () => apiService.fetchData(),
  ///   message: 'Đang tải dữ liệu...',
  /// );
  /// ```
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String message = 'Đang xử lý...',
  }) async {
    try {
      show(message);
      final result = await operation();
      return result;
    } finally {
      hide();
    }
  }
}

/// 🎨 Global Loading Overlay Widget
/// 
/// Display a full-screen loading indicator with optional message.
/// Use this in MaterialApp's builder to show loading globally.
/// 
/// Usage in main.dart:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return Stack(
///       children: [
///         child!,
///         Consumer<LoadingService>(
///           builder: (context, loading, _) {
///             return loading.isLoading
///                 ? const GlobalLoadingOverlay()
///                 : const SizedBox.shrink();
///           },
///         ),
///       ],
///     );
///   },
/// );
/// ```
class GlobalLoadingOverlay extends StatelessWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Access loading service directly (avoid Consumer to prevent rebuild)
    // Note: This widget is already inside Consumer in MaterialApp builder
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Consumer<LoadingService>(
                  builder: (context, loading, _) {
                    return Text(
                      loading.loadingMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎨 Consumer Widget for LoadingService
/// 
/// Convenience widget to avoid importing Provider everywhere.
/// 
/// Usage:
/// ```dart
/// LoadingConsumer(
///   builder: (context, isLoading, message) {
///     return isLoading
///         ? CircularProgressIndicator()
///         : MyWidget();
///   },
/// );
/// ```
class LoadingConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, bool isLoading, String message) builder;

  const LoadingConsumer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingService>(
      builder: (context, loading, _) {
        return builder(context, loading.isLoading, loading.loadingMessage);
      },
    );
  }
}

/// Extension methods for easy access to LoadingService
extension LoadingServiceExtension on BuildContext {
  /// Get LoadingService without listening to changes
  LoadingService get loading => read<LoadingService>();

  /// Show loading overlay
  void showLoading([String message = 'Đang tải...']) {
    read<LoadingService>().show(message);
  }

  /// Hide loading overlay
  void hideLoading() {
    read<LoadingService>().hide();
  }
}
