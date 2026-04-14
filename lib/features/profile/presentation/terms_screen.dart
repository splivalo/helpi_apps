import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';

/// Fetches privacy-policy HTML from helpi.social and renders it natively.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  static const String url = 'https://helpi.social/pravila-privatnosti/';

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String? _html;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http.get(Uri.parse(TermsScreen.url));
      if (!mounted) return;
      if (response.statusCode == 200) {
        // Extract only the <article> or <main> content, fallback to <body>
        final body = response.body;
        final extracted = _extractContent(body);
        setState(() {
          _html = extracted;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Extracts the main article content from the full HTML page.
  String _extractContent(String html) {
    // Try <article>…</article> first
    final articleMatch =
        RegExp(r'<article[^>]*>([\s\S]*?)</article>').firstMatch(html);
    if (articleMatch != null) return articleMatch.group(1)!;

    // Try <main>…</main>
    final mainMatch =
        RegExp(r'<main[^>]*>([\s\S]*?)</main>').firstMatch(html);
    if (mainMatch != null) return mainMatch.group(1)!;

    // Try .entry-content (WordPress)
    final entryMatch =
        RegExp(r'<div[^>]*class="[^"]*entry-content[^"]*"[^>]*>([\s\S]*?)</div>\s*(?:</div>|<footer)')
            .firstMatch(html);
    if (entryMatch != null) return entryMatch.group(1)!;

    // Fallback: content between <body> tags
    final bodyMatch =
        RegExp(r'<body[^>]*>([\s\S]*?)</body>').firstMatch(html);
    if (bodyMatch != null) return bodyMatch.group(1)!;

    return html;
  }

  Future<void> _onTapUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.termsOfUseTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.termsLoadError,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchContent,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: HtmlWidget(
                    _html ?? '',
                    onTapUrl: (url) {
                      _onTapUrl(url);
                      return true;
                    },
                    textStyle: theme.textTheme.bodyMedium,
                  ),
                ),
    );
  }
}
