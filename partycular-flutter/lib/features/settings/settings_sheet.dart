import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/time/calendar_day.dart';
import '../../ui/links.dart';
import '../../ui/partycular_logo.dart';
import '../events/events_controller.dart';
import 'theme_controller.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const SettingsSheet(),
);

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final preference = ref.watch(themePreferenceProvider);
    final events = ref.watch(eventsProvider);
    final updatedAt = events.value?.updatedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(S.mapAppearance),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemePreference>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: p.accent,
                selectedForegroundColor: p.onAccent,
                backgroundColor: p.panel2,
                foregroundColor: p.text,
                side: BorderSide(color: p.border),
                minimumSize: const Size(0, 46),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemePreference.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text(S.themeLight),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text(S.themeDark),
                ),
                ButtonSegment(
                  value: ThemePreference.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text(S.themeSystem),
                ),
              ],
              selected: {preference},
              onSelectionChanged: (selection) => ref.read(themePreferenceProvider.notifier).set(selection.first),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionTitle(S.data),
          Row(
            children: [
              Expanded(
                child: Text(
                  updatedAt == null
                      ? S.neverUpdated
                      : S.updatedAt(DateFormat('d. M. y, HH:mm', 'sk').format(inBratislava(updatedAt))),
                  style: TextStyle(color: p.muted, fontSize: 13.5),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: events.isLoading ? null : () => ref.read(eventsProvider.notifier).refresh(),
                icon: events.isLoading
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(S.refresh),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _SectionTitle(S.aboutTitle),
          const Row(children: [PartycularMark(size: 36), SizedBox(width: 10), PartycularWordmark(fontSize: 22)]),
          const SizedBox(height: 12),
          Text(S.aboutText, style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => openExternal(context, AppConfig.apiBaseUri),
            icon: const Icon(Icons.public_rounded, size: 18),
            label: const Text(S.website),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => openExternal(context, Uri.https('www.openstreetmap.org', '/copyright')),
            child: Text(S.mapAttribution, style: TextStyle(color: p.muted, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
