import 'package:flutter/material.dart';
import 'package:webnox_taskops/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'app_bar_search_filter.dart';
import 'fullscreen_toggle_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? titleWidget;
  final bool showThemeToggle;
  final VoidCallback? onThemeToggle;
  final SearchFilterConfig? searchFilterConfig;
  final bool isDesktop;
  final bool isMobile;
  final bool isSmallMobile;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.titleWidget,
    this.showThemeToggle = true,
    this.onThemeToggle,
    this.searchFilterConfig,
    this.isDesktop = false,
    this.isMobile = false,
    this.isSmallMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ??
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foregroundColor ??
                      Theme.of(context).colorScheme.onSurface,
                ),
          ),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      foregroundColor:
          foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: [
        // Search icon (expandable)
        if (searchFilterConfig != null)
          ValueListenableBuilder<bool>(
            valueListenable: searchFilterConfig!.isSearchExpanded,
            builder: (context, isExpanded, child) {
              return IconButton(
                onPressed: () {
                  if (isExpanded) {
                    // Collapse search
                    searchFilterConfig!.isSearchExpanded.value = false;
                    searchFilterConfig!.searchFocusNode?.unfocus();
                    searchFilterConfig!.setSuggestionsOverlay?.call(null);
                  } else {
                    // Expand search
                    searchFilterConfig!.isSearchExpanded.value = true;
                    searchFilterConfig!.isFilterExpanded.value = false;
                    // Focus search field after expansion
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      searchFilterConfig!.searchFocusNode?.requestFocus();
                    });
                  }
                },
                icon: Icon(
                  isExpanded ? Icons.close : Icons.search,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: isExpanded ? 'Close search' : 'Search',
              );
            },
          ),
        // Filter icon (expandable, only if filter is available)
        if (searchFilterConfig != null &&
            searchFilterConfig!.onFilterTap != null)
          ValueListenableBuilder<bool>(
            valueListenable: searchFilterConfig!.isFilterExpanded,
            builder: (context, isExpanded, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      if (isExpanded) {
                        // Collapse filter
                        searchFilterConfig!.isFilterExpanded.value = false;
                      } else {
                        // Expand filter - show filter dialog
                        searchFilterConfig!.isFilterExpanded.value =
                            false; // Don't expand, just show dialog
                        searchFilterConfig!.isSearchExpanded.value = false;
                        searchFilterConfig!.onFilterTap?.call();
                      }
                    },
                    icon: Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Filter',
                  ),
                  if (searchFilterConfig!.hasActiveFilters.value)
                    Positioned(
                      right: 8,
                      top: 8,
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
              );
            },
          ),
        if (showThemeToggle) ...[
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: onThemeToggle ?? () => themeProvider.toggleTheme(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          // Fullscreen Toggle Button
          const CompactFullscreenToggle(),
          const SizedBox(width: 8),
        ],
        if (actions != null) ...actions!,
      ],
      bottom: searchFilterConfig != null
          ? _ExpandableSearchBottom(
              searchFilterConfig: searchFilterConfig!,
              isDesktop: isDesktop,
              isMobile: isMobile,
              isSmallMobile: isSmallMobile,
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
    );
  }

  @override
  Size get preferredSize {
    // Return max size to accommodate expanded search
    // The actual size is controlled by the bottom widget
    return searchFilterConfig != null
        ? const Size.fromHeight(kToolbarHeight + 60)
        : const Size.fromHeight(kToolbarHeight);
  }
}

// Widget to handle expandable search bottom section
class _ExpandableSearchBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final SearchFilterConfig searchFilterConfig;
  final bool isDesktop;
  final bool isMobile;
  final bool isSmallMobile;

  const _ExpandableSearchBottom({
    required this.searchFilterConfig,
    required this.isDesktop,
    required this.isMobile,
    required this.isSmallMobile,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: searchFilterConfig.isSearchExpanded,
      builder: (context, isExpanded, child) {
        return PreferredSize(
          preferredSize:
              isExpanded ? const Size.fromHeight(60) : const Size.fromHeight(1),
          child: isExpanded
              ? AppBarSearchFilter(
                  config: searchFilterConfig,
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  isSmallMobile: isSmallMobile,
                )
              : Container(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

// Compact theme toggle button for use in other app bars
class CompactThemeToggle extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;

  const CompactThemeToggle({
    super.key,
    this.onPressed,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: onPressed ?? () => themeProvider.toggleTheme(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(themeProvider.isDarkMode),
              color: color ?? Theme.of(context).colorScheme.onSurface,
              size: size ?? 24,
            ),
          ),
          tooltip: themeProvider.isDarkMode
              ? 'Switch to Light Mode'
              : 'Switch to Dark Mode',
        );
      },
    );
  }
}
