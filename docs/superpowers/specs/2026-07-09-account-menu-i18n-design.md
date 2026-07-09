# Menu account, localizzazione IT/EN, rifinitura barra di ricerca — Design Spec

## Contesto

Oggi `WatchlistScreen` e `CalendarScreen` hanno, nell'AppBar, un'icona di logout diretta (`SignOutButton`) accanto alla barra di ricerca. L'utente vuole sostituirla con un'icona account che apre un menu laterale (logout, link al repo GitHub, switch lingua), aggiungere una vera localizzazione IT/EN all'app (oggi tutte le stringhe sono in italiano hardcoded), e rifinire lo stile della barra di ricerca (bordi arrotondati, meno spazio vuoto verso le icone a destra).

## Decisioni prese

1. **Copertura traduzione**: completa — tutte le stringhe utente dell'app, non solo il menu.
2. **Persistenza lingua**: locale al dispositivo (`SharedPreferences`), non per singolo account Google. È una preferenza dell'app su questo device condiviso, non del profilo utente.
3. **Lingua di default al primo avvio**: se non esiste ancora una preferenza salvata, usa italiano se la lingua di sistema del telefono è italiano, altrimenti inglese (nuova lingua di default del progetto). Una volta risolta la prima volta, il valore viene salvato subito (comportamento stabile anche se la lingua di sistema cambia in seguito).
4. **Menu laterale**: `endDrawer` (si apre da destra, coerente con la posizione dell'icona nell'AppBar), con intestazione account (foto/nome/email da `AuthService.currentUser`), voce link GitHub, switch lingua, voce logout (stessa conferma già presente in `SignOutButton`, spostata qui).
5. **Barra di ricerca**: bordo arrotondato a 24px (stesso raggio già usato altrove nel tema per bottoni/input), spaziatura ridotta verso le azioni a destra dell'AppBar.

## Inventario stringhe da estrarre

Ogni stringa utente hardcoded elencata sotto diventa una chiave ARB (`lib/l10n/app_en.arb` come template, `lib/l10n/app_it.arb` come traduzione). Le stringhe con valori interpolati (es. conteggi) diventano messaggi ICU con placeholder.

| File | Stringa/i |
|---|---|
| `lib/app.dart` | `'Episodes Tracker'` (titolo `MaterialApp`), `'Errore: $e'` (fallback notifica in-app - stringa di errore generica, riusa la chiave errore comune) |
| `lib/screens/login_screen.dart` | `'Episodes Tracker'`, `'Serie e film che segui, in un unico posto.'`, `'Accedi con Google'`, `'Accesso non riuscito: $e'` |
| `lib/screens/home_shell.dart` | `'Watchlist'`, `'Calendario'` (etichette `NavigationBar`) |
| `lib/screens/watchlist_screen.dart` | `'Serie'`, `'Film'` (tab), `'Nessuna serie in watchlist'`, `'Nessun film in watchlist'`, `'Errore: ...'`, `'{watched}/{aired} episodi visti'` |
| `lib/screens/calendar_screen.dart` | `'Errore: ...'`, `'Uscita film'` |
| `lib/screens/detail_screen.dart` | `'Errore: ...'` (×4), `'Visto'` / `'Segna come visto'`, `'Prossimo episodio'`, `'Segna visto'`, `'Sei aggiornato'`, `'Sei aggiornato con tutti gli episodi usciti'`, `'{watched}/{aired} episodi visti'`, `'Segna stagione vista'` (tooltip) |
| `lib/screens/season_episodes_screen.dart` | `'{show} - Stagione {n}'` (titolo AppBar), `'Errore: ...'` (×3), `'Segna stagione vista'` (tooltip), `'Rivisto'` (tooltip) |
| `lib/widgets/search_results_list.dart` | `'Errore: ...'`, `'Nessun risultato'` |
| `lib/widgets/sign_out_button.dart` (logica spostata in `AppDrawer`, vedi sotto) | `'Esci'` (×2, titolo dialogo + azione), `'Vuoi disconnetterti da questo account?'`, `'Annulla'` |
| `lib/updates/update_banner.dart` | `'Nuova versione disponibile'`, `'È disponibile la versione {tag}.'`, `'Chiudi'`, `'Scarica'` |
| `lib/widgets/update_indicator_button.dart` | `'Nuova versione disponibile: {tag}'` (tooltip) |
| `lib/widgets/debounced_search_field.dart` | `'Cerca serie o film...'` (hint) |

Le stringhe `'Errore: $e'`/`'Errore: ${snapshot.error}'` ripetute in più file condividono la stessa chiave ARB parametrica (`errorPrefix(String message)`), non una chiave per file. `DateFormat('yyyy-MM-dd')` in `calendar_screen.dart` non cambia: è un pattern fisso, non testo localizzato.

Nomi di show/film/episodi (dati TMDB) e i messaggi di eccezione tecnici non mostrati all'utente (es. quelli in `notification_service.dart`, `debugPrint`) restano fuori scope: non sono testo scritto dall'app.

## Dipendenze nuove

- `flutter_localizations` (SDK Flutter, già disponibile localmente col resto del framework)
- `shared_preferences` (per `LocaleController`)
- `intl` è già presente (`^0.20.3`); potrebbe richiedere un aggiustamento di versione per compatibilità con `flutter_localizations` del SDK in uso — verificato durante l'implementazione con `flutter pub get`.

`l10n.yaml` in root:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## `LocaleController` (nuovo: `lib/config/locale_controller.dart`)

```dart
class LocaleController extends ValueNotifier<Locale> {
  static const _prefsKey = 'locale';

  LocaleController._(super.initial);

  static Future<LocaleController> load({
    required SharedPreferences prefs,
    required Locale deviceLocale,
  }) async {
    final saved = prefs.getString(_prefsKey);
    final resolved = saved != null
        ? Locale(saved)
        : (deviceLocale.languageCode == 'it' ? const Locale('it') : const Locale('en'));
    if (saved == null) {
      await prefs.setString(_prefsKey, resolved.languageCode);
    }
    return LocaleController._(resolved);
  }

  Future<void> setLocale(Locale locale, SharedPreferences prefs) async {
    value = locale;
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
```

`main.dart` costruisce `SharedPreferences.getInstance()` e `LocaleController.load(...)` prima di `runApp`, passando sia il controller sia l'istanza di `SharedPreferences` a `EpisodesTrackerApp` (stesso pattern con cui oggi vengono passati `authService`/`notificationService`).

`EpisodesTrackerApp` (già `StatefulWidget`) avvolge `MaterialApp` in un `ValueListenableBuilder<Locale>` sul `LocaleController`, impostando `MaterialApp.locale`, `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`.

## `AppDrawer` (nuovo: `lib/widgets/app_drawer.dart`)

```dart
class AppDrawer extends StatelessWidget {
  final AuthService authService;
  final LocaleController localeController;
  final SharedPreferences prefs;
}
```

Contenuto:
- `UserAccountsDrawerHeader`: `accountName` = `authService.currentUser?.displayName`, `accountEmail` = `...?.email`, `currentAccountPicture` = `CircleAvatar(backgroundImage: NetworkImage(photoURL))` con fallback a un'icona persona se `photoURL` è nullo.
- `ListTile` (icona `Icons.code`, testo localizzato "Progetto GitHub"): `onTap` → `launchUrl(Uri.parse('https://github.com/mauronofrio/EpisodesTracker'), mode: LaunchMode.externalApplication)`.
- Riga lingua: `SwitchListTile` (o due `ChoiceChip`/`RadioListTile`) "Italiano"/"English", stato da `localeController.value.languageCode == 'it'`, `onChanged` → `localeController.setLocale(...)`.
- `ListTile` (icona `Icons.logout`, testo "Esci"/"Sign out"): stessa logica di conferma oggi in `SignOutButton._confirmAndSignOut` (`AlertDialog` con Annulla/Esci), poi `authService.signOut()`.

`SignOutButton` come widget standalone viene rimosso; la sua logica di conferma diventa una funzione condivisa (es. `Future<void> confirmAndSignOut(BuildContext, AuthService)` in `app_drawer.dart` o file dedicato) richiamata dalla voce di menu.

## Modifiche ad AppBar (`WatchlistScreen`, `CalendarScreen`)

- `actions`: `[UpdateIndicatorButton(), _AccountButton()]` dove `_AccountButton` è un `IconButton(icon: Icons.account_circle, onPressed: () => Scaffold.of(context).openEndDrawer())`.
- `Scaffold(endDrawer: AppDrawer(...), ...)`.
- `AppBar(titleSpacing: 8, ...)` (default Flutter ~16) per stringere lo spazio tra la barra di ricerca e le azioni.

## Modifiche a `DebouncedSearchField`

`border: InputBorder.none` → `border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)`; eventuale riduzione di `contentPadding` orizzontale per stringere ulteriormente lo spazio, rifinita durante il test visivo sul device (l'utente verifica lui stesso su schermo fisico, come da preferenza già stabilita in questa sessione).

## Error handling / edge case

- `authService.currentUser` teoricamente non dovrebbe mai essere `null` quando `AppDrawer` è raggiungibile (entrambe le schermate che lo usano sono dietro l'auth-gate in `app.dart`), ma `UserAccountsDrawerHeader` gestisce comunque valori nulli con fallback ("—"/icona vuota) invece di andare in errore.
- `photoURL` nullo (account senza foto profilo Google) → fallback a `CircleAvatar` con icona persona invece di `NetworkImage`.
- Fallimento nel salvataggio della preferenza lingua su `SharedPreferences` (raro, ma possibile su storage pieno): il cambio lingua resta comunque attivo in-memory per la sessione corrente (l'`onChanged` aggiorna prima `value`, poi tenta il salvataggio); non blocca l'interazione.

## Testing

- `LocaleController`: test unitari per la risoluzione al primo avvio (device it → it, device altro → en), persistenza esplicita (`setLocale` seguito da un nuovo `load` che rilegge lo stesso valore), usando `SharedPreferences.setMockInitialValues`.
- `AppDrawer`: widget test che verifica intestazione con dati utente mock, presenza delle tre voci, che il tap su logout apra il dialogo di conferma esistente, che il tap sullo switch lingua chiami `setLocale` con la lingua opposta. Il tap sul link GitHub non viene verificato a fondo (nessun test esistente nel progetto verifica l'esito reale di `launchUrl`, stesso limite già presente per il pulsante "Scarica" degli aggiornamenti) — si verifica solo che il tile sia presente e tappabile.
- Localizzazione: non si scrive un test per ogni singola stringa in entrambe le lingue (sproporzionato); un paio di widget test rappresentativi (es. login screen, empty state watchlist) verificano che `AppLocalizations.of(context)!.chiave` risolva valori diversi sotto `MaterialApp(locale: Locale('it'))` vs `Locale('en')`. La copertura sulle altre schermate si affida a `flutter analyze` (nessuna stringa hardcoded rimasta) e al test visivo manuale dell'utente sul device, come da workflow già stabilito in questa sessione.

## Fuori scope

- Traduzione dei nomi di show/film/episodi (dati TMDB, non testo dell'app).
- Preferenza lingua per singolo account Google (Firestore) — resta locale al dispositivo.
- Altre lingue oltre IT/EN.
