import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bible_provider.dart';
import '../../../services/bible_service.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final provider = context.read<BibleProvider>();
      // Access the service through the provider's private service field
      // For now, we'll do a simple search through loaded chapters
      final results = await _performSearch(query);
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
    }
  }

  Future<List<SearchResult>> _performSearch(String query) async {
    // Simplified search for demonstration
    // In production, you'd use a proper search service
    final results = <SearchResult>[];
    final provider = context.read<BibleProvider>();

    // Search current chapter for now
    if (provider.currentChapter != null && provider.currentBook != null) {
      for (final verse in provider.currentChapter!.verses) {
        if (verse.text.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            bookName: provider.currentBook!.name,
            chapter: provider.currentChapter!.number,
            verse: verse.number,
            text: verse.text,
            query: query,
          ));
        }
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search Bible...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _results = []);
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        _search(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Results
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textDarkSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _controller.text.isEmpty
                                    ? 'Enter text to search'
                                    : 'No results found',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textDarkSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return _buildSearchResult(context, result);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(BuildContext context, SearchResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Highlight the query in the text
    final queryLower = result.query.toLowerCase();
    final textLower = result.text.toLowerCase();
    final index = textLower.indexOf(queryLower);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final provider = context.read<BibleProvider>();
          final book = provider.books.firstWhere(
            (b) => b.name == result.bookName,
          );
          provider.loadChapter(book, result.chapter);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.reference,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : AppColors.textDark,
                    height: 1.5,
                  ),
                  children: _buildHighlightedText(result.text, result.query),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String text, String query) {
    final spans = <TextSpan>[];
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    int start = 0;
    int index = textLower.indexOf(queryLower, start);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ));

      start = index + query.length;
      index = textLower.indexOf(queryLower, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}
