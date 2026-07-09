# Episode Tracking Advanced Features — Design Spec

## Contesto

L'MVP (Piano 1, completo) copre il nucleo essenziale: watchlist, visto/non visto per episodio, calendario uscite, notifiche. L'utente ha chiesto di avvicinare ulteriormente il tracking episodi a quello dell'originale TV Time, aggiungendo quattro funzionalità individuate nell'inventario di Fase 1: rewatch, segna-stagione-vista, contatori di avanzamento, prossimo episodio da vedere.

## Decisioni prese

1. **Rewatch**: flag booleano `rewatched` per episodio (non un contatore di visioni). Un episodio è: non visto (nessun documento) → visto (documento esiste, `rewatched: false`) → rivisto (`rewatched: true`).
2. **Segna stagione vista**: marca solo gli episodi già usciti (data di uscita passata), esclude quelli futuri.
3. **Posizionamento contatori/prossimo episodio**: sia sulla card della watchlist (contatore) sia nella schermata di dettaglio (contatore + sezione "prossimo episodio").
4. **Interazione UI per rewatch**: checkbox invariata per visto/non visto + icona separata per rewatch, abilitata solo se l'episodio è già visto.

## Modifiche allo schema dati

`users/{uid}/watched_episodes/{showId}_{season}_{episode}` guadagna un campo:
```
rewatched: bool  (default assente = false; presente e true = rivisto)
```
Nessuna migrazione necessaria: i documenti esistenti senza questo campo sono trattati come `rewatched: false`.

## Modifiche al layer dati

### `WatchedRepository` (lib/data/firestore/watched_repository.dart)

- `watchedEpisodeIdsForShow(int showId)` cambia tipo di ritorno da `Stream<Set<WatchedEpisodeId>>` a `Stream<Map<WatchedEpisodeId, bool>>` (id → rewatched). **Breaking change** verso l'unico consumer esistente, `SeasonEpisodesScreen`, che va aggiornato in questo stesso lavoro.
- Nuovo: `Future<void> setEpisodeRewatched(WatchedEpisodeId id, bool rewatched)` — aggiorna solo il campo `rewatched` con merge, senza toccare `watchedAt`.
- Nuovo: `Future<void> markSeasonWatched(int showId, int seasonNumber, List<int> episodeNumbers)` — scrittura in batch (`WriteBatch`) di tutti gli episodi passati, singola operazione atomica invece di N scritture individuali. Il chiamante è responsabile di filtrare solo gli episodi già usciti prima di passarli.

### Nuovo: `lib/data/show_progress.dart`

```
class ShowProgress {
  final int watchedCount;
  final int airedCount;
  final Episode? nextToWatch; // null se l'utente è aggiornato con tutto
}

Future<ShowProgress> computeShowProgress({
  required TmdbClient tmdbClient,
  required WatchedRepository watchedRepository,
  required TvShowDetails show,
})
```

Implementazione: scarica in parallelo (con `fetchOrNull`, stessa resilienza per-episodio già in uso altrove nel progetto) la lista episodi di ogni stagione elencata in `show.seasons` (che già esclude la stagione 0/Specials), filtra agli episodi con data di uscita non nulla e non futura, incrocia con `watchedEpisodeIdsForShow(show.id)`, calcola i tre valori. Il "prossimo episodio" è il primo, in ordine stagione/episodio, tra quelli usciti-ma-non-visti.

**Costo di rete accettato**: una chiamata TMDB per ogni stagione di ogni show in watchlist, ogni volta che la schermata watchlist o dettaglio viene costruita. Accettabile per liste personali di dimensioni normali (poche decine di show); non ottimizzato con cache, coerente con l'approccio "nessuna ottimizzazione prematura" già seguito nel resto del progetto per un'app a 2-3 utenti.

## Modifiche UI

### `SeasonEpisodesScreen`
- Ogni riga: `CheckboxListTile` (invariata, visto/non visto) + `IconButton` con icona rewatch (↻) a fianco, abilitato solo se l'episodio è visto, che chiama `setEpisodeRewatched`.
- Nuova azione in `AppBar`: "Segna stagione vista" — filtra gli episodi già caricati (già ha le date di uscita da TMDB) a quelli con `airDate` non nullo e non futuro, chiama `markSeasonWatched` con i relativi numeri di episodio.

### `WatchlistScreen` (tab Serie)
- Il sottotitolo della card, oggi `"N stagioni • Stato"`, diventa `"X/Y episodi visti"` dove X/Y vengono da `computeShowProgress`. Se il calcolo è ancora in corso, mostrare uno stato di caricamento minimale (es. il vecchio sottotitolo o uno shimmer) piuttosto che bloccare l'intera card.

### `DetailScreen` (solo `MediaType.tv`)
- Nuova sezione "Prossimo episodio" tra il pulsante watchlist e l'elenco stagioni: se `nextToWatch` non è nullo, mostra nome/numero/data dell'episodio con un pulsante "Segna visto" che chiama direttamente `markEpisodeWatched`; se nullo, un messaggio tipo "Sei aggiornato". Mostra anche il contatore `X/Y episodi visti` accanto o sotto il titolo dello show.

## Testing

- `WatchedRepository`: test aggiornati per il nuovo tipo di ritorno di `watchedEpisodeIdsForShow`; nuovi test per `setEpisodeRewatched` (imposta e rimuove il flag) e `markSeasonWatched` (marca solo gli episodi passati come argomento, verifica che sia una singola operazione batch tramite lo stato finale dei documenti).
- `computeShowProgress`: test unitari con `TmdbClient` mockato (pattern `MockClient` già in uso) e `WatchedRepository` su `FakeFirebaseFirestore`, casi: nessun episodio visto, tutti visti, alcuni visti con "prossimo episodio" corretto, show con episodi futuri esclusi dal conteggio.
- `SeasonEpisodesScreen`: se ragionevole, test widget per l'azione "segna stagione vista" (verifica che episodi futuri non vengano inclusi).

## Fuori scope

- Contatore di visioni multiple (solo booleano rewatch, non un numero)
- Ottimizzazione/caching delle chiamate TMDB per il calcolo dell'avanzamento
- Statistiche aggregate cross-show (es. "totale episodi visti quest'anno") — non richiesto
