import 'package:flutter/material.dart';

/// Configuration for search and filter functionality in app bar
class SearchFilterConfig {
  final TextEditingController searchController;
  final ValueNotifier<String> searchQuery;
  final ValueNotifier<bool> hasActiveFilters;
  final VoidCallback? onFilterTap;
  final String hintText;
  
  // Callback for when search text changes - each screen implements its own logic
  final void Function(String query)? onSearchChanged;
  
  // Optional: For search suggestions (used by Home and Kanban screens)
  final List<String> Function(String query)? getSearchSuggestions;
  final ValueNotifier<bool>? showSuggestions;
  final FocusNode? searchFocusNode;
  final GlobalKey? searchBarKey;
  final OverlayEntry? Function(BuildContext, GlobalKey, List<String>, TextEditingController, ValueNotifier<String>, ValueNotifier<bool>?, FocusNode?, bool)? showSuggestionsOverlay;
  // Callback to set the overlay entry (replaces Ref pattern)
  final void Function(OverlayEntry?)? setSuggestionsOverlay;
  final int activeFilterCount;
  
  // State for expandable search/filter
  final ValueNotifier<bool> isSearchExpanded;
  final ValueNotifier<bool> isFilterExpanded;

  SearchFilterConfig({
    required this.searchController,
    required this.searchQuery,
    required this.hasActiveFilters,
    this.onFilterTap,
    this.hintText = 'Search...',
    this.onSearchChanged, // Screen-specific search handler
    this.getSearchSuggestions, // Optional: for suggestions
    this.showSuggestions,
    this.searchFocusNode,
    this.searchBarKey,
    this.showSuggestionsOverlay,
    this.setSuggestionsOverlay,
    this.activeFilterCount = 0,
    ValueNotifier<bool>? isSearchExpanded,
    ValueNotifier<bool>? isFilterExpanded,
  }) : isSearchExpanded = isSearchExpanded ?? ValueNotifier<bool>(false),
       isFilterExpanded = isFilterExpanded ?? ValueNotifier<bool>(false);
}

/// Common search and filter bar widget for app bar
class AppBarSearchFilter extends StatelessWidget {
  final SearchFilterConfig config;
  final bool isDesktop;
  final bool isMobile;
  final bool isSmallMobile;

  const AppBarSearchFilter({
    super.key,
    required this.config,
    required this.isDesktop,
    required this.isMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isSmallMobile) {
      return _buildSmallMobileSearchFilter(context);
    } else {
      return _buildDesktopTabletSearchFilter(context);
    }
  }

  Widget _buildSmallMobileSearchFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              key: config.searchBarKey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor ??
                    Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.5) ??
                        Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: config.searchController,
                      focusNode: config.searchFocusNode,
                      onChanged: (value) {
                        // Update the search query notifier
                        config.searchQuery.value = value;
                        
                        // Call screen-specific search handler if provided
                        if (config.onSearchChanged != null) {
                          config.onSearchChanged!(value);
                        }
                        
                        // Handle suggestions if available (for Home/Kanban screens)
                        if (config.getSearchSuggestions != null &&
                            config.setSuggestionsOverlay != null &&
                            config.searchBarKey != null &&
                            config.showSuggestionsOverlay != null) {
                          final suggestions = config.getSearchSuggestions!(value);
                          // Remove existing overlay if any
                          final currentOverlay = config.setSuggestionsOverlay;
                          if (currentOverlay != null) {
                            // We need to track the overlay, but since we're using a callback,
                            // we'll let the screen handle removal
                          }
                          if (value.isNotEmpty && suggestions.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (config.searchBarKey!.currentContext != null) {
                                final overlay = config.showSuggestionsOverlay!(
                                  context,
                                  config.searchBarKey!,
                                  suggestions,
                                  config.searchController,
                                  config.searchQuery,
                                  config.showSuggestions,
                                  config.searchFocusNode,
                                  isSmallMobile,
                                );
                                config.setSuggestionsOverlay!(overlay);
                              }
                            });
                          } else {
                            config.setSuggestionsOverlay!(null);
                          }
                        }
                        if (config.showSuggestions != null) {
                          config.showSuggestions!.value =
                              value.isNotEmpty &&
                              (config.getSearchSuggestions?.call(value) ?? []).isNotEmpty;
                        }
                      },
                      onSubmitted: (_) {
                        if (config.showSuggestions != null) {
                          config.showSuggestions!.value = false;
                        }
                        config.setSuggestionsOverlay?.call(null);
                        // Optionally collapse search on submit (uncomment if desired)
                        // config.isSearchExpanded.value = false;
                      },
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: config.hintText,
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.5) ??
                              Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (config.onFilterTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: config.onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      size: 20,
                    ),
                    if (config.hasActiveFilters.value)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTabletSearchFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: config.searchBarKey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor ??
                        Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5) ??
                            Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: config.searchController,
                          focusNode: config.searchFocusNode,
                          onChanged: (value) {
                            // Update the search query notifier
                            config.searchQuery.value = value;
                            
                            // Call screen-specific search handler if provided
                            if (config.onSearchChanged != null) {
                              config.onSearchChanged!(value);
                            }
                            
                            // Handle suggestions if available (for Home/Kanban screens)
                            if (config.getSearchSuggestions != null &&
                                config.setSuggestionsOverlay != null &&
                                config.searchBarKey != null &&
                                config.showSuggestionsOverlay != null) {
                              final suggestions = config.getSearchSuggestions!(value);
                              // Remove existing overlay if any
                              config.setSuggestionsOverlay!(null);
                              if (value.isNotEmpty && suggestions.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (config.searchBarKey!.currentContext != null) {
                                    final overlay = config.showSuggestionsOverlay!(
                                      context,
                                      config.searchBarKey!,
                                      suggestions,
                                      config.searchController,
                                      config.searchQuery,
                                      config.showSuggestions,
                                      config.searchFocusNode,
                                      isSmallMobile,
                                    );
                                    config.setSuggestionsOverlay!(overlay);
                                  }
                                });
                              } else {
                                config.setSuggestionsOverlay!(null);
                              }
                            }
                            if (config.showSuggestions != null) {
                              config.showSuggestions!.value =
                                  value.isNotEmpty &&
                                  (config.getSearchSuggestions?.call(value) ?? []).isNotEmpty;
                            }
                          },
                          onSubmitted: (_) {
                            if (config.showSuggestions != null) {
                              config.showSuggestions!.value = false;
                            }
                            config.setSuggestionsOverlay?.call(null);
                            // Optionally collapse search on submit (uncomment if desired)
                            // config.isSearchExpanded.value = false;
                          },
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: config.hintText,
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.5) ??
                                  Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (config.onFilterTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: config.onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          size: 20,
                        ),
                        if (config.hasActiveFilters.value)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (config.hasActiveFilters.value && config.activeFilterCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${config.activeFilterCount}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

