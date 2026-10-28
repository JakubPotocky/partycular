# PARTYCULAR — Flutter app

Phone app for the PARTYCULAR live event map of Bratislava. It is a native counterpart to the public map of the web app in `../partycular2` and reads the same API (`https://partycular.eu/api/events`). The UI is Slovak, and every date uses Bratislava time.

## Features

**Same as the web map**
- Full-screen vector map of Bratislava, using the same OpenFreeMap style and the same light and dark recolouring.
- Event pins matching the web: colour ring, cropped photo or initials, short label. The selected pin rises and points at the venue.
- Day picker with **Dnes / Zajtra / Víkend / Kalendár**. The Slovak month calendar marks days that have events. Overnight events appear on every day they run.
- Detail card with category, date and time, venue, **Vstupenky**, **Stránka akcie**, price and tag chips, and an expandable **Info** section.
- Light and dark appearance, saved on the device (dark by default, as on the web). The compass button recenters on Bratislava.

**New in the app**
- Overlapping pins merge into count bubbles. Tapping one zooms in until the pins separate, or lists the events if they share a venue.
- A list of the day's events, with pull-to-refresh.
- **Víkend** preset: Friday to Sunday on one map (from today once the weekend has started). Pins carry a Pi/So/Ne tag, the list is split by day, and the calendar highlights the whole weekend.
- Category filter. It appears only when events span two or more categories.
- My location, Navigovať (Google Maps directions) and Zdieľať (native share sheet).
- "Práve prebieha" badge for events happening now. Events without an end time are assumed to run four hours.
- Offline mode: the last response is cached, and a notice shows when the app falls back to it.
- When the chosen day is empty, a link jumps to the next day with events.
- Full-screen photo viewer with pinch-to-zoom.
- A System appearance option. Events refresh when the app returns to the foreground after 10 minutes.

## Project layout

```
lib/
  main.dart, app.dart        bootstrap (prefs, Slovak date data), MaterialApp
  core/                      config, Slovak strings, theme tokens, Bratislava calendar, root providers
  data/                      Event model, API client, offline cache, repository, map style builder
  features/
    events/                  events controller, filters (day, category, selection), formatters
    map/                     map screen, camera animation, clustering, pins and overlays
    event_detail/            detail card, photo viewer
    event_list/              day list sheet
    calendar/                month calendar and its sheet
    settings/                appearance preference and settings sheet
  ui/                        shared widgets: glass panel, logo, event image, link helpers
tool/render_app_icon_test.dart   renders launcher icon sources from the vector logo
```

State management uses Riverpod 3. Logic that has to match the web lives in pure functions with tests, ported from the web app's `lib/events.ts` and `tests/date-filter.mjs`:
- day filtering
- clustering
- parsing
- formatting

**Map performance.** A few deliberate choices keep panning smooth:
- The basemap uses `vector_map_tiles` in **raster** mode, where each tile is drawn once into an image. Vector mode redraws every tile on each frame.
- Clustering snaps to quarter zoom steps. The markers layer hands `MarkerLayer` the same instance between steps, so pins are not rebuilt or re-projected while panning.
- Each pin sits in a `RepaintBoundary`, and so does the map.
- The glass controls share one `BackdropGroup`, so the map behind them is blurred once per frame.

**Time zones.** Bratislava follows the EU daylight-saving rule, which is computed directly in `core/time/calendar_day.dart`. The `timezone` package was dropped because its database does not initialise on the web.

## Running

```sh
flutter pub get
flutter run                      # attached device or emulator
flutter test                     # unit and widget tests
flutter analyze
```

| Setting | How |
|---|---|
| Backend URL | `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android emulator to a local `npm run dev`) |
| App icons | `flutter test tool/render_app_icon_test.dart && dart run flutter_launcher_icons` |

**Web builds** need the API to send CORS headers, which `partycular.eu` does not currently do. Without them the web app can't load events. Native Android and iOS builds are not affected.

## Platform notes

- **Android:** INTERNET and location permissions are declared. The launch screen and adaptive icon use `#17232E`. Package id: `eu.partycular.partycular`.
- **iOS:** Slovak is the development region, and the location purpose string is in Slovak. iOS builds need macOS with Xcode.
- **Not included:** the `/admin` editor. Events are still managed on the web.
