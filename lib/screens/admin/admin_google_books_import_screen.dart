import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import '../../models/training_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/google_books_service.dart';
import '../../services/training_service.dart';
import '../../theme/locale_controller.dart';
import '../../utils/admin_palette.dart';
import '../../utils/content_language.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';

class AdminGoogleBooksImportScreen extends StatefulWidget {
  final bool embedded;
  final int initialTabIndex;

  const AdminGoogleBooksImportScreen({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminGoogleBooksImportScreen> createState() =>
      _AdminGoogleBooksImportScreenState();
}

class _AdminGoogleBooksImportScreenState
    extends State<AdminGoogleBooksImportScreen> {
  final TextEditingController _searchController = TextEditingController();

  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final TrainingService _trainingService = TrainingService();

  bool _isSearching = false;
  bool _isImporting = false;
  bool _hasSearched = false;
  String? _searchError;
  String _importingBookId = '';

  List<TrainingModel> _results = [];

  String _selectedDomain = 'Informatique';
  String _selectedLanguage = '';

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  final List<String> _domains = const [
    'Informatique',
    'Mathematiques',
    'Medecine',
    'Droit',
    'Commerce',
    'Architecture',
    'Biologie',
    'Physique',
    'Chimie',
    'Langues',
  ];

  final List<String> _languages = const ['', 'fr', 'ar', 'en'];

  String _languageLabel(String value) {
    return switch (value) {
      '' => _l10n.uiAll,
      'fr' => _l10n.languageFrench,
      'ar' => _l10n.languageArabic,
      _ => _l10n.languageEnglish,
    };
  }

  DropdownMenuItem<String> _buildDropdownItem({
    required String value,
    required String label,
  }) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  List<Widget> _buildSelectedDropdownItems(
    List<String> values,
    String Function(String value) labelBuilder,
  ) {
    return values
        .map(
          (value) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labelBuilder(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  Widget _buildImportButton({
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isImporting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(112, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      child: Text(busy ? _l10n.uiImporting : _l10n.uiImport),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ContentLanguage.normalizeCode(
      LocaleController.activeLanguageCode,
      fallback: '',
    );
    Future.microtask(() async {
      if (!mounted) {
        return;
      }

      await context.read<TrainingProvider>().fetchTrainings();
    });
  }

  Future<void> _syncLibraryState() async {
    await Future.wait([
      context.read<TrainingProvider>().fetchTrainings(),
      context.read<AdminProvider>().loadModerationData(),
    ]);
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      context.showAppSnackBar(
        _l10n.uiEnterASearchQueryToContinue,
        title: _l10n.uiSearchRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
    });

    try {
      final results = await _googleBooksService.searchBooks(
        query: '$query $_selectedDomain',
        langRestrict: _selectedLanguage,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _searchError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message =
          'Something went wrong while searching books. Please try again.';
      setState(() {
        _results = [];
        _searchError = message;
      });

      context.showAppSnackBar(
        _l10n.uiSearchFailedValue(e),
        title: _l10n.uiSearchUnavailable,
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _importBook(TrainingModel book) async {
    final adminId = context.read<AuthProvider>().userModel?.uid ?? '';

    if (adminId.isEmpty) {
      context.showAppSnackBar(
        _l10n.uiAdminUserNotFound,
        title: _l10n.uiImportUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importingBookId = book.id;
    });

    try {
      await _trainingService.importGoogleBook(
        book: book,
        adminId: adminId,
        domain: _selectedDomain,
        sourceLanguage: _selectedLanguage.isNotEmpty
            ? _selectedLanguage
            : book.sourceLanguage,
      );

      if (!mounted) {
        return;
      }

      await _syncLibraryState();

      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        _l10n.uiValueImportedSuccessfully(book.title),
        title: _l10n.uiImportComplete,
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        _l10n.uiImportFailedValue(e),
        title: _l10n.uiImportUnavailable,
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importingBookId = '';
        });
      }
    }
  }

  Future<void> _toggleFeatured(TrainingModel training) async {
    final provider = context.read<TrainingProvider>();
    final error = await provider.updateFeaturedStatus(
      trainingId: training.id,
      isFeatured: !training.isFeatured,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      await _syncLibraryState();
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        training.isFeatured
            ? _l10n.uiResourceRemovedFromFeatured
            : _l10n.uiResourceFeatured,
        title: _l10n.uiFeaturedListUpdated,
        type: training.isFeatured
            ? AppFeedbackType.removed
            : AppFeedbackType.success,
        icon: training.isFeatured ? Icons.star_border_rounded : null,
      );
      return;
    }

    context.showAppSnackBar(
      error,
      title: _l10n.updateUnavailableTitle,
      type: AppFeedbackType.error,
    );
  }

  Future<void> _deleteTraining(TrainingModel training) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.uiDeleteResource),
            content: Text(
              _l10n.uiDeleteValueFromFirestoreThisActionCannotBeUndone(
                training.title,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AppLocalizations.of(context)!.cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  _l10n.uiDelete,
                  style: AppTypography.product(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    final error = await context.read<TrainingProvider>().deleteTraining(
      training.id,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      await _syncLibraryState();
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _l10n.uiValueDeleted(training.title),
        title: _l10n.uiResourceDeleted,
        type: AppFeedbackType.removed,
        icon: Icons.delete_outline_rounded,
      );
      return;
    }

    context.showAppSnackBar(
      error,
      title: _l10n.uiDeleteUnavailable,
      type: AppFeedbackType.error,
    );
  }

  Future<void> _openLink(String link) async {
    if (link.trim().isEmpty) {
      context.showAppSnackBar(
        _l10n.uiThisResultDoesNotIncludeAnExternalLink,
        title: _l10n.uiLinkUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      context.showAppSnackBar(
        _l10n.uiThisLinkIsNotValid,
        title: _l10n.uiLinkUnavailable,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      context.showAppSnackBar(
        _l10n.uiWeCouldNotOpenThisLinkRightNow,
        title: _l10n.uiOpenUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  Widget _buildBookCover(TrainingModel book, {double width = 60}) {
    final height = width * 1.5;

    if (book.thumbnail.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AdminPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.menu_book_rounded, color: AdminPalette.textMuted),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: book.thumbnail,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AdminPalette.surfaceMuted,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: AdminPalette.surfaceMuted,
          child: Icon(
            Icons.broken_image_outlined,
            color: AdminPalette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingThumbnail(TrainingModel training) {
    final isVideo = training.type == 'video';
    final width = isVideo ? 96.0 : 56.0;
    final height = isVideo ? 54.0 : 84.0;
    final placeholderIcon = isVideo
        ? Icons.play_circle_outline_rounded
        : Icons.menu_book_rounded;

    if (training.thumbnail.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AdminPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(placeholderIcon, color: AdminPalette.textMuted),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: training.thumbnail,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AdminPalette.surfaceMuted,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: AdminPalette.surfaceMuted,
          child: Icon(
            Icons.broken_image_outlined,
            color: AdminPalette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdminSurface(
        child: Column(
          children: [
            AdminSectionHeader(
              eyebrow: _l10n.uiGoogleBooks,
              title: _l10n.uiImportBooks,
              subtitle: _l10n
                  .uiUseATopicDomainOrLanguageFilterToBringInCuratedBooksForReview,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _l10n.uiSearchBooksForExampleAlgorithms,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDomain,
              isExpanded: true,
              selectedItemBuilder: (context) =>
                  _buildSelectedDropdownItems(_domains, (value) => value),
              decoration: InputDecoration(
                labelText: _l10n.uiDomain,
                border: const OutlineInputBorder(),
              ),
              items: _domains
                  .map((item) => _buildDropdownItem(value: item, label: item))
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedDomain = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              isExpanded: true,
              selectedItemBuilder: (context) =>
                  _buildSelectedDropdownItems(_languages, _languageLabel),
              decoration: InputDecoration(
                labelText: _l10n.uiLanguage,
                border: const OutlineInputBorder(),
              ),
              items: _languages
                  .map(
                    (item) => _buildDropdownItem(
                      value: item,
                      label: _languageLabel(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchBooks,
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? _l10n.uiSearching : _l10n.uiSearch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoadingBody(
          density: AppLoadingDensity.compact,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
        ),
      );
    }

    if (!_hasSearched) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.menu_book_rounded,
          title: _l10n.uiStartWithAGoogleBooksSearch,
          message: _l10n
              .uiUseATopicDomainOrLanguageFilterToBringInCuratedBooksForReview,
        ),
      );
    }

    if (_searchError != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.error_outline_rounded,
          title: _l10n.uiSearchFailed,
          message: _searchError!,
          action: FilledButton.icon(
            onPressed: _searchBooks,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retryLabel),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AdminEmptyState(
          icon: Icons.search_off_rounded,
          title: _l10n.uiNoBooksMatchThisSearch,
          message: _l10n
              .uiTryABroaderQueryOrChangeTheLanguageAndDomainFiltersBeforeSearchingAgain,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final book = _results[index];
          final isImportingBook = _importingBookId == book.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSearchResultCard(
              book: book,
              isImportingBook: isImportingBook,
            ),
          );
        }, childCount: _results.length),
      ),
    );
  }

  Widget _buildManageTab(TrainingProvider provider) {
    final books = provider.trainings
        .where((training) => training.source == 'google_books')
        .toList();

    if (provider.isLoading && books.isEmpty) {
      return const AppLoadingView(
        density: AppLoadingDensity.compact,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      );
    }

    if (provider.errorMessage != null && books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AdminEmptyState(
            icon: Icons.error_outline_rounded,
            title: _l10n.uiBookLibraryUnavailable,
            message: provider.errorMessage!,
            action: FilledButton.icon(
              onPressed: provider.fetchTrainings,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retryLabel),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchTrainings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  eyebrow: _l10n.uiLibrary,
                  title: _l10n.uiManageImportedBooks,
                  subtitle: _l10n
                      .uiThisWorkspaceIsDedicatedToGoogleBooksImportsSoBookCurationStaysFocused,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AdminPill(
                      label: '${books.length} imported books',
                      color: AdminPalette.info,
                      icon: Icons.menu_book_rounded,
                    ),
                    AdminPill(
                      label:
                          '${books.where((book) => book.isFeatured).length} featured',
                      color: AdminPalette.accent,
                      icon: Icons.star_rounded,
                    ),
                    AdminPill(
                      label: provider.isLoading
                          ? _l10n.uiSyncing
                          : _l10n.uiSynced,
                      color: provider.isLoading
                          ? AdminPalette.warning
                          : AdminPalette.success,
                      icon: provider.isLoading
                          ? Icons.sync_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (books.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 60),
              child: AdminEmptyState(
                icon: Icons.menu_book_rounded,
                title: _l10n.uiNoBooksImportedYet,
                message: _l10n
                    .uiImportAFewGoogleBooksResultsFirstThenManageFeaturing,
              ),
            )
          else
            ...books.map((training) {
              final isBusy = provider.isTrainingBusy(training.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildManageResourceCard(
                  training: training,
                  isBusy: isBusy,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard({
    required TrainingModel book,
    required bool isImportingBook,
  }) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.product(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          book.authors.isNotEmpty ? book.authors.join(', ') : book.provider,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.product(
            color: AdminPalette.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        if (book.description.trim().isNotEmpty)
          Text(
            book.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              color: AdminPalette.textSecondary,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminPill(label: _l10n.uiBookLabel, color: AdminPalette.info),
            if (book.language.trim().isNotEmpty)
              AdminPill(
                label: book.language.toUpperCase(),
                color: AdminPalette.success,
              ),
            if (book.domain.trim().isNotEmpty)
              AdminPill(label: book.domain, color: AdminPalette.activity),
          ],
        ),
      ],
    );

    final infoRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookCover(book),
        const SizedBox(width: 12),
        Expanded(child: details),
      ],
    );

    return AdminSurface(
      radius: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final importButton = _buildImportButton(
            busy: isImportingBook,
            onPressed: () => _importBook(book),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoRow,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: importButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: infoRow),
              const SizedBox(width: 12),
              importButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildManageResourceCard({
    required TrainingModel training,
    required bool isBusy,
  }) {
    return AdminSurface(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrainingThumbnail(training),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            training.title,
                            style: AppTypography.product(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isBusy)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      training.authors.isNotEmpty
                          ? training.authors.join(', ')
                          : training.provider,
                      style: AppTypography.product(
                        color: AdminPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AdminChip(
                          label: training.type.toUpperCase(),
                          color: AdminPalette.info,
                        ),
                        if (training.domain.trim().isNotEmpty)
                          _AdminChip(
                            label: training.domain,
                            color: AdminPalette.activity,
                          ),
                        if (training.isFeatured)
                          _AdminChip(
                            label: _l10n.uiFeatured,
                            color: Colors.amber.shade800,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInlineActionRow([
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _toggleFeatured(training),
              icon: Icon(
                training.isFeatured
                    ? Icons.star_outline_rounded
                    : Icons.star_rounded,
                size: 15,
              ),
              label: Text(
                training.isFeatured ? _l10n.uiUnfeature : _l10n.uiFeature,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: _inlineActionStyle(AdminPalette.textPrimary),
            ),
            OutlinedButton.icon(
              onPressed: isBusy || training.displayLink.trim().isEmpty
                  ? null
                  : () => _openLink(training.displayLink),
              icon: const Icon(Icons.open_in_new, size: 15),
              label: Text(
                AppLocalizations.of(context)!.uiOpen,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: _inlineActionStyle(AdminPalette.textPrimary),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => _deleteTraining(training),
              icon: const Icon(Icons.delete_outline, size: 15),
              label: Text(
                AppLocalizations.of(context)!.uiDelete,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: _inlineActionStyle(AdminPalette.danger),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInlineActionRow(List<Widget> actions) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(child: actions[index]),
          if (index < actions.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  ButtonStyle _inlineActionStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      minimumSize: const Size(0, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      textStyle: AppTypography.product(
        fontSize: 12.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TrainingProvider>();
    final tabBar = TabBar(
      labelColor: AdminPalette.primary,
      indicatorColor: AdminPalette.primary,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(text: l10n.uiSearch),
        Tab(text: l10n.uiManage),
      ],
    );
    final tabBarView = TabBarView(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AdminSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSectionHeader(
                        eyebrow: l10n.uiStudio,
                        title: l10n.uiBookImportWorkspace,
                        subtitle: l10n
                            .uiSearchAndImportBooksInOneContinuousFlowInsteadOf,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AdminPill(
                            label: '${_results.length} results',
                            color: AdminPalette.info,
                            icon: Icons.manage_search_rounded,
                          ),
                          AdminPill(
                            label: _selectedDomain,
                            color: AdminPalette.activity,
                          ),
                          AdminPill(
                            label: _languageLabel(_selectedLanguage),
                            color: AdminPalette.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSearchForm()),
            _buildSearchResults(),
          ],
        ),
        _buildManageTab(provider),
      ],
    );

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      child: Builder(
        builder: (context) {
          if (widget.embedded) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AdminPalette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminPalette.border),
                    ),
                    child: tabBar,
                  ),
                ),
                Expanded(child: tabBarView),
              ],
            );
          }

          return Scaffold(
            backgroundColor: AdminPalette.background,
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.uiImportGoogleBooks),
              backgroundColor: AdminPalette.surface,
              foregroundColor: AdminPalette.textPrimary,
              bottom: tabBar,
            ),
            body: AdminShellBackground(child: tabBarView),
          );
        },
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AdminChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
