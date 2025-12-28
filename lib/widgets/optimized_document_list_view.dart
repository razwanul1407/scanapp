import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/services/scroll_position_service.dart';
import 'package:scanapp/widgets/lazy_load_thumbnail.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class OptimizedDocumentListView extends StatefulWidget {
  final String screenKey;
  final void Function(int docId)? onDocumentTap;
  final void Function(int docId, bool isFavorite)? onFavoriteTap;
  final void Function(int docId)? onDeleteTap;

  const OptimizedDocumentListView({
    super.key,
    required this.screenKey,
    this.onDocumentTap,
    this.onFavoriteTap,
    this.onDeleteTap,
  });

  @override
  State<OptimizedDocumentListView> createState() =>
      _OptimizedDocumentListViewState();
}

class _OptimizedDocumentListViewState extends State<OptimizedDocumentListView> {
  late ScrollController _scrollController;
  final ScrollPositionService _scrollService = ScrollPositionService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Restore scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedPosition = _scrollService.getScrollPosition(widget.screenKey);
      if (savedPosition != null && _scrollController.hasClients) {
        _scrollController.jumpTo(savedPosition);
      }
    });

    // Listen for pagination threshold
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Save scroll position before dispose
    if (_scrollController.hasClients) {
      _scrollService.saveScrollPosition(
          widget.screenKey, _scrollController.offset);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<DocumentsProvider>();
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Load next page when 80% scrolled
    if (currentScroll >= maxScroll * 0.8 && provider.hasNextPage) {
      provider.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer<DocumentsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.documents.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (provider.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noDocumentsFound,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: provider.documents.length + (provider.hasNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator at the end
            if (index == provider.documents.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            }

            final doc = provider.documents[index];
            final firstImagePath =
                doc.imagePaths.isNotEmpty ? doc.imagePaths.first : null;

            return _buildDocumentCard(
              context,
              doc,
              firstImagePath,
              l10n,
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    dynamic doc,
    String? thumbnailPath,
    dynamic l10n,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onDocumentTap?.call(doc.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Lazy-loaded thumbnail
              if (thumbnailPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LazyLoadThumbnail(
                    imagePath: thumbnailPath,
                    width: 80,
                    height: 80,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              const SizedBox(width: 12),

              // Document details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.pageCount} ${doc.pageCount == 1 ? l10n.page : l10n.pages}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(doc.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () =>
                        widget.onFavoriteTap?.call(doc.id, !doc.isFavorite),
                    child: Row(
                      children: [
                        Icon(
                          doc.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doc.isFavorite
                              ? l10n.removeFromFavorite
                              : l10n.addToFavorite,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => widget.onDeleteTap?.call(doc.id),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          l10n.delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
