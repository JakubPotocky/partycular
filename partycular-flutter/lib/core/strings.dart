/// User-facing Slovak copy. The product is Slovak-only, like the web app;
/// keeping every string here makes a later move to ARB localisation simple.
abstract final class S {
  static const appName = 'PARTYCULAR';
  static const appTagline = 'Živá mapa koncertov, párty, kina a kultúry v Bratislave.';

  // Loading and status.
  static const loadingMap = 'Načítavam mapu Bratislavy…';
  static const loadingEvents = 'Načítavam eventy…';
  static const loadFailed = 'Eventy sa nepodarilo načítať.';
  static const offlineData = 'Si offline – zobrazujem naposledy uložené eventy.';
  static const retry = 'Skúsiť znova';
  static const mapFailed = 'Mapu sa nepodarilo načítať. Skontroluj pripojenie.';
  static const emptyDay = 'Na tento deň zatiaľ nemáme eventy.';
  static const emptyWeekend = 'Na tento víkend zatiaľ nemáme eventy.';
  static String nextEventsOn(String day) => 'Najbližšie: $day';
  static const close = 'Zavrieť';

  // Day picker.
  static const today = 'Dnes';
  static const tomorrow = 'Zajtra';
  static const weekend = 'Víkend';
  static const thisWeekend = 'Tento víkend';
  static const calendar = 'Kalendár';
  static const pickDate = 'Vybrať dátum';
  static const daysWithEvents = 'Dni s eventami';
  static const previousMonth = 'Predchádzajúci mesiac';
  static const nextMonth = 'Nasledujúci mesiac';
  static const weekdaysShort = ['Po', 'Ut', 'St', 'Št', 'Pi', 'So', 'Ne'];

  // Categories.
  static const allCategories = 'Všetko';

  // Map controls.
  static const recenter = 'Zobraziť mapu Bratislavy';
  static const myLocation = 'Moja poloha';
  static const eventList = 'Zoznam eventov';
  static const settings = 'Nastavenia';
  static const mapLabel = 'Mapa eventov Bratislavy';
  static const locationDenied = 'Bez povolenia polohy ťa nevieme ukázať na mape. Povoľ ho v nastaveniach.';
  static const locationServiceOff = 'Zapni si polohové služby a skús znova.';
  static const locationFailed = 'Polohu sa nepodarilo zistiť.';
  static const locationOutside = 'Si mimo Bratislavy – mapu necháme pri eventoch.';
  static const openSettings = 'Nastavenia';

  // Event detail.
  static const eventDetail = 'Detail eventu';
  static const eventPage = 'Stránka akcie';
  static const tickets = 'Vstupenky';
  static const navigate = 'Navigovať';
  static const share = 'Zdieľať';
  static const info = 'Info';
  static const priceUnknown = 'Cena neuvedená';
  static const liveNow = 'Práve prebieha';
  static const linkFailed = 'Odkaz sa nepodarilo otvoriť.';
  static const showPhoto = 'Zobraziť fotografiu';

  // Event list.
  static String eventCount(int count) => switch (count) {
    1 => '1 event',
    >= 2 && <= 4 => '$count eventy',
    _ => '$count eventov',
  };

  // Settings.
  static const mapAppearance = 'Vzhľad mapy';
  static const themeLight = 'Svetlý';
  static const themeDark = 'Tmavý';
  static const themeSystem = 'Systém';
  static const data = 'Údaje';
  static const refresh = 'Obnoviť';
  static const neverUpdated = 'Eventy ešte neboli načítané.';
  static String updatedAt(String time) => 'Aktualizované $time';
  static const aboutTitle = 'O aplikácii';
  static const aboutText =
      'PARTYCULAR ukazuje párty, koncerty, kino a kultúru v Bratislave. '
      'Program a dostupnosť si vždy over u organizátora.';
  static const website = 'partycular.eu';
  static const mapAttribution = 'OpenFreeMap © OpenMapTiles · © OpenStreetMap';
}
