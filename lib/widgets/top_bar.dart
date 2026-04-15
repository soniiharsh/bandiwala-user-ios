import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/profile_page.dart';
import '../models/app_user.dart';
import '../screens/location_picker_page.dart';
import '../screens/search_page.dart';
import '../core/theme/theme.dart';
import '../core/navigation/app_page_route.dart';

const Color _kYellow = AppColors.primary;

// ─── TopBar ───────────────────────────────────────────────────────────────────
// Displays active address from provider. Tap search → SearchPage.

class TopBar extends ConsumerWidget {
  final Function(SavedAddress)? onAddressChanged;
  final SavedAddress? activeAddress;

  const TopBar({super.key, this.onAddressChanged, this.activeAddress});

  void _showLocationPicker(BuildContext context) async {
    final result = await Navigator.push<SavedAddress>(
      context,
      AppPageRoute(
        type: PageTransitionType.slideUp,
        builder: (_) => LocationPickerPage(
          activeAddress: activeAddress,
          onLocationSelected: (loc) => onAddressChanged?.call(loc),
        ),
      ),
    );
    if (result != null) onAddressChanged?.call(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAddr = activeAddress != null;
    final topLabel = hasAddr
        ? activeAddress!.shortLabel
        : 'Set delivery address';
    final displayText = hasAddr
        ? activeAddress!.geolocation
        : 'Tap to choose location';

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: location + profile ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  hasAddr
                      ? Icons.location_on_rounded
                      : Icons.location_off_outlined,
                  color: hasAddr ? _kYellow : Colors.grey.shade400,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLocationPicker(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                topLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ],
                        ),
                        Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasAddr
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar (tap → SearchPage) ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                AppPageRoute(builder: (_) => const SearchPage()),
              ),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _kYellow, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Search for food items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
