import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bible_provider.dart';
import '../../../models/bible_models.dart';

class BookSelector extends StatelessWidget {
  const BookSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<BibleProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Book',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Books list
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark
                        ? AppColors.textSecondary
                        : AppColors.textDarkSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Old Testament'),
                      Tab(text: 'New Testament'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBookList(
                          context,
                          provider,
                          provider.books.take(39).toList(),
                        ),
                        _buildBookList(
                          context,
                          provider,
                          provider.books.skip(39).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(
    BuildContext context,
    BibleProvider provider,
    List<BibleBook> books,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = provider.currentBook?.name == book.name;

        return ListTile(
          title: Text(
            book.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          subtitle: Text('${book.totalChapters} chapters'),
          trailing: isSelected
              ? const Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: () {
            provider.loadChapter(book, 1);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
