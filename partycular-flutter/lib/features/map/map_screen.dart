import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/event.dart';
import '../../ui/glass_panel.dart';
import '../../ui/partycular_logo.dart';
import '../event_detail/event_detail_card.dart';
import '../event_list/event_list_sheet.dart';
import '../events/event_filters.dart';
import '../events/event_formatters.dart';
import '../events/events_controller.dart';
import '../settings/settings_sheet.dart';
import 'event_clustering.dart';
import 'map_camera_animator.dart';
import 'map_providers.dart';
import 'widgets/category_bar.dart';
import 'widgets/day_picker.dart';
import 'widgets/event_markers_layer.dart';
import 'widgets/status_banner.dart';

/// The public event map: the whole app's home screen.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  static const _staleAfter = Duration(minutes: 10);
  static const _controlsHeight = 60.0;

  final _mapController = MapController();
  late final _camera = MapCameraAnimator(controller: _mapController, vsync: this);
  late final AppLifecycleListener _lifecycle;

  /// The view before an event was focused, restored when it is closed.
  ({LatLng center, double zoom})? _previousView;
  bool _mapReady = false;
  bool _offlineNoticeDismissed = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Duration get _motion => MediaQuery.disableAnimationsOf(context) ? Duration.zero : MapCameraAnimator.defaultDuration;

  void _onResume() {
    ref.read(todayProvider.notifier).refresh();
    final updatedAt = ref.read(eventsProvider).value?.updatedAt;
    final now = ref.read(clockProvider)();
    if (updatedAt == null || now.difference(updatedAt) > _staleAfter) {
      unawaited(ref.read(eventsProvider.notifier).refresh());
    }
  }

  void _selectEvent(Event event) {
    if (!_mapReady) return;
    final camera = _camera.camera;
    _previousView ??= (center: camera.center, zoom: camera.zoom);
    ref.read(selectedEventIdProvider.notifier).select(event.id);
    final zoom = math.max(camera.zoom, AppConfig.focusZoom);
    // Show the pin in the upper part of the map, clear of the detail card.
    final topInset = MediaQuery.paddingOf(context).top;
    final y = (camera.size.height * 0.32).clamp(topInset + 190, camera.size.height * 0.5);
    final target = Offset(camera.size.width / 2, y);
    unawaited(
      _camera.animateTo(
        _camera.centerPlacing(LatLng(event.latitude, event.longitude), zoom, target),
        zoom,
        duration: _motion,
      ),
    );
  }

  void _dismissSelection() {
    final hadSelection = ref.read(selectedEventIdProvider) != null;
    ref.read(selectedEventIdProvider.notifier).clear();
    final previous = _previousView;
    _previousView = null;
    if (hadSelection && previous != null && _mapReady) {
      unawaited(_camera.animateTo(previous.center, previous.zoom, duration: _motion));
    }
  }

  void _goHome() {
    _previousView = null;
    ref.read(selectedEventIdProvider.notifier).clear();
    if (_mapReady) unawaited(_camera.animateTo(AppConfig.cityCenter, AppConfig.homeZoom, duration: _motion));
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final result = await ref.read(userLocationProvider.notifier).locate();
    if (!mounted) return;
    setState(() => _locating = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case LocateResult.found:
        final position = ref.read(userLocationProvider)!;
        if (!AppConfig.cameraBounds.contains(position)) {
          messenger.showSnackBar(const SnackBar(content: Text(S.locationOutside)));
          return;
        }
        _previousView = null;
        ref.read(selectedEventIdProvider.notifier).clear();
        unawaited(_camera.animateTo(position, math.max(_camera.camera.zoom, AppConfig.focusZoom), duration: _motion));
      case LocateResult.serviceDisabled:
        messenger.showSnackBar(const SnackBar(content: Text(S.locationServiceOff)));
      case LocateResult.denied:
        messenger.showSnackBar(const SnackBar(content: Text(S.locationDenied)));
      case LocateResult.deniedForever:
        messenger.showSnackBar(
          SnackBar(
            content: const Text(S.locationDenied),
            action: SnackBarAction(label: S.openSettings, onPressed: () => unawaited(Geolocator.openAppSettings())),
          ),
        );
      case LocateResult.failed:
        messenger.showSnackBar(const SnackBar(content: Text(S.locationFailed)));
    }
  }

  Future<void> _openList() async {
    final event = await showEventListSheet(context);
    if (event != null && mounted) _selectEvent(event);
  }

  /// Zooms in until a cluster's pins separate; events sharing one venue can
  /// never separate, so those are listed instead.
  Future<void> _openCluster(EventCluster cluster) async {
    if (cluster.isSameSpot || !_mapReady) {
      final event = await showEventListSheet(context, events: cluster.events, title: cluster.events.first.venue);
      if (event != null && mounted) _selectEvent(event);
      return;
    }
    final padding = MediaQuery.paddingOf(context);
    final fitted = CameraFit.coordinates(
      coordinates: [for (final e in cluster.events) LatLng(e.latitude, e.longitude)],
      padding: EdgeInsets.fromLTRB(80, padding.top + 160, 80, padding.bottom + 160),
      maxZoom: AppConfig.maxZoom - 1,
    ).fit(_camera.camera);
    // Always zoom in at least a step, even if the fit says otherwise.
    final zoom = math.max(fitted.zoom, _camera.camera.zoom + 1);
    unawaited(_camera.animateTo(fitted.center, zoom, duration: _motion));
  }

  @override
  Widget build(BuildContext context) {
    // Changing what is shown closes the open event, like on the web.
    ref.listen(selectedRangeProvider, (_, _) => _dismissSelection());
    ref.listen(effectiveCategoryProvider, (_, _) => _dismissSelection());

    final palette = AppPalette.of(context);
    final styles = ref.watch(mapStylesProvider);
    final visible = ref.watch(visibleEventsProvider);
    final range = ref.watch(selectedRangeProvider);
    final dayTags = range.isSingleDay
        ? const <int, String>{}
        : ref.watch(visibleEventDaysProvider).map((id, day) => MapEntry(id, EventFormat.weekdayShort(day)));
    final selected = ref.watch(selectedEventProvider);
    final userLocation = ref.watch(userLocationProvider);
    final padding = MediaQuery.paddingOf(context);
    final bottom = math.max(padding.bottom, 12.0) + 14;

    return AnnotatedRegion(
      value: AppTheme.overlayStyle(palette),
      child: Scaffold(
        // The glass controls share one backdrop, so the map behind them is
        // blurred once per frame instead of once per control.
        body: BackdropGroup(
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label: S.mapLabel,
                  // The map repaints on every camera frame; this keeps those
                  // repaints from also repainting the controls above it.
                  child: RepaintBoundary(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: AppConfig.cityCenter,
                        initialZoom: AppConfig.initialZoom,
                        minZoom: AppConfig.minZoom,
                        maxZoom: AppConfig.maxZoom,
                        backgroundColor: palette.mapLand,
                        cameraConstraint: CameraConstraint.containCenter(bounds: AppConfig.cameraBounds),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onTap: (_, _) => _dismissSelection(),
                        onPointerDown: (_, _) => _camera.stop(),
                        onMapReady: () => setState(() => _mapReady = true),
                      ),
                      children: [
                        if (styles.value case final mapStyles?)
                          // Raster mode draws each tile once into an image; vector
                          // mode re-renders every tile on each frame and stutters.
                          VectorTileLayer(
                            key: ValueKey(palette.brightness),
                            theme: mapStyles.forBrightness(palette.brightness),
                            tileProviders: mapStyles.tileProviders,
                            layerMode: VectorTileLayerMode.raster,
                            maximumZoom: AppConfig.maxZoom,
                          ),
                        EventMarkersLayer(
                          events: visible,
                          selected: selected,
                          userLocation: userLocation,
                          dayTags: dayTags,
                          onSelect: _selectEvent,
                          onCluster: _openCluster,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: _TopBar(onSettings: () => showSettingsSheet(context)),
                      ),
                      const CategoryBar(),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _MapStatus(
                          styleError: styles.hasError && !styles.hasValue,
                          offlineNoticeDismissed: _offlineNoticeDismissed,
                          onDismissOffline: () => setState(() => _offlineNoticeDismissed = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: bottom + _controlsHeight + 12,
                top: padding.top + 120,
                child: Align(
                  alignment: MediaQuery.sizeOf(context).width >= 900 ? Alignment.bottomRight : Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.bottomCenter, children: [...previous, ?current]),
                      child: selected == null
                          ? const SizedBox.shrink()
                          : EventDetailCard(
                              key: ValueKey(selected.id),
                              event: selected,
                              now: ref.watch(clockProvider)(),
                              onClose: _dismissSelection,
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _ListButton(count: visible.length, onPressed: _openList),
                      ),
                    ),
                    GlassCircleButton(
                      icon: Icons.explore_outlined,
                      tooltip: S.recenter,
                      size: _controlsHeight,
                      iconSize: 28,
                      iconColor: palette.accent,
                      onPressed: _goHome,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GlassCircleButton(
                          icon: Icons.my_location_rounded,
                          tooltip: S.myLocation,
                          busy: _locating,
                          onPressed: _locate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(right: 6, bottom: math.max(padding.bottom - 14, 2), child: const _Attribution()),
              Positioned.fill(child: _LoadingCurtain(visible: styles.isLoading && !styles.hasValue)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Row(
      children: [
        if (wide)
          const GlassPanel(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [PartycularMark(size: 30), SizedBox(width: 10), PartycularWordmark(fontSize: 24)]),
          )
        else
          Semantics(label: S.appName, child: const PartycularMark(size: 40)),
        const SizedBox(width: 12),
        Expanded(
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: const DayPicker()),
          ),
        ),
        const SizedBox(width: 12),
        GlassCircleButton(icon: Icons.settings_outlined, tooltip: S.settings, size: 46, onPressed: onSettings),
      ],
    );
  }
}

/// Loading, error, offline and empty-day notices, most important first.
class _MapStatus extends ConsumerWidget {
  const _MapStatus({required this.styleError, required this.offlineNoticeDismissed, required this.onDismissOffline});

  final bool styleError;
  final bool offlineNoticeDismissed;
  final VoidCallback onDismissOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final visible = ref.watch(visibleEventsProvider);
    final nextDay = ref.watch(nextEventDayProvider);
    final singleDay = ref.watch(selectedRangeProvider.select((range) => range.isSingleDay));
    Future<void> retry() => ref.read(eventsProvider.notifier).refresh();

    final Widget? banner;
    if (styleError) {
      banner = StatusBanner(
        key: const ValueKey('style-error'),
        icon: Icons.map_outlined,
        message: S.mapFailed,
        actionLabel: S.retry,
        onAction: () => ref.invalidate(mapStylesProvider),
      );
    } else if (!events.hasValue && events.hasError) {
      banner = StatusBanner(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_rounded,
        message: S.loadFailed,
        busy: events.isLoading,
        actionLabel: events.isLoading ? null : S.retry,
        onAction: retry,
      );
    } else if (!events.hasValue) {
      banner = const StatusBanner(key: ValueKey('loading'), message: S.loadingEvents, busy: true);
    } else if (events.requireValue.isOffline && !offlineNoticeDismissed) {
      banner = StatusBanner(
        key: const ValueKey('offline'),
        icon: Icons.cloud_off_rounded,
        message: S.offlineData,
        busy: events.isLoading,
        actionLabel: events.isLoading ? null : S.retry,
        onAction: retry,
        onDismiss: onDismissOffline,
      );
    } else if (visible.isEmpty) {
      banner = StatusBanner(
        key: const ValueKey('empty'),
        message: singleDay ? S.emptyDay : S.emptyWeekend,
        actionLabel: nextDay == null ? null : S.nextEventsOn(EventFormat.day(nextDay)),
        onAction: nextDay == null ? null : () => ref.read(dayFilterProvider.notifier).selectDay(nextDay),
      );
    } else {
      banner = null;
    }

    return AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: banner ?? const SizedBox.shrink());
  }
}

class _ListButton extends StatelessWidget {
  const _ListButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: '${S.eventList}, ${S.eventCount(count)}',
      excludeSemantics: true,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, size: 21, color: p.text),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '$count',
                        key: ValueKey(count),
                        style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: p.panel.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
        child: Text(S.mapAttribution, style: TextStyle(color: p.muted, fontSize: 9)),
      ),
    );
  }
}

/// Branded cover shown until the basemap style is ready (`.map-loading`).
class _LoadingCurtain extends StatelessWidget {
  const _LoadingCurtain({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: ColoredBox(
          color: p.background,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PartycularMark(size: 64),
                const SizedBox(height: 18),
                const PartycularWordmark(fontSize: 32),
                const SizedBox(height: 14),
                Text(S.loadingMap, style: TextStyle(color: p.muted, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
