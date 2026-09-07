# TECH_SPEC.md — Specyfikacja Techniczna

> Status: v1 kompletny, gotowy do przekazania jako kontekst dla implementacji.

## 1. Stack i struktura projektu Godot

**Silnik:** Godot 4.x, najnowsza stabilna wersja w dniu startu implementacji (do sprawdzenia na godotengine.org — nie pinujemy tu konkretnego numeru, żeby nie zdezaktualizować specyfikacji).

**Język:** GDScript (decyzja: mimo dużego doświadczenia w C#, świadomie wybrane GDScript — szybszy start przy małym doświadczeniu z Godotem, natywna integracja z edytorem i frameworkiem testowym GUT, opisanym w sekcji 7).

**Proponowana struktura folderów:**
```
res://
  core/                  # czysta logika gry — class_name, BEZ "extends Node", w pełni testowalna bez sceny/edytora
    grid.gd
    track_segment.gd
    simulation_engine.gd
    level_data.gd
    win_condition/
      base_win_condition.gd
      delivery_win_condition.gd
      color_match_win_condition.gd
      min_segments_bonus.gd
  levels/                # definicje poziomów (format ustalony w sekcji 4)
  scenes/                # warstwa prezentacji — sceny/węzły Godota
    Main.tscn
    GridView.tscn
    TrainView.tscn
    HUD.tscn
  tests/                 # testy GUT, struktura odzwierciedla core/
    test_grid.gd
    test_simulation_engine.gd
    ...
  assets/                # placeholder grafika teraz, pixel art w przyszłości
```

**Konwencje:** `snake_case` dla plików i zmiennych/funkcji GDScript, `PascalCase` dla nazw klas (`class_name`) i węzłów sceny — zgodnie ze standardowym stylem Godota.

**Instalacja GUT:** ręcznie, przez pobranie release'u z repo GUT (github.com/bitwes/Gut) i skopiowanie do `addons/gut/` — NIE przez UI Asset Library w edytorze (środowisko Claude Code działa headless, bez GUI edytora). Wersję GUT dobrać pod zainstalowaną wersję Godota (sprawdzić tabelę kompatybilności w repo GUT).

**`.gitignore`:** repo powinno ignorować katalog `.godot/` (lokalny cache edytora, nie commitujemy).

## 2. Model danych

**Siatka:** komórki adresowane jako `Vector2i(x, y)`, zakres 0..9 w obu osiach (plansza 10×10).

**Podstawowe struktury (v1 — obejmuje poziomy 1-4, bez narzędzi):**
- **Cell** — pozycja `(x, y)` na siatce
- **TrackPiece** — umieszczony w komórce, zdefiniowany przez to, które dwie z czterech krawędzi komórki (N/E/S/W) łączy (prosty odcinek / zakręt wynika z wyboru krawędzi)
- **Station** — `Cell` + kolor/typ + rola (`source` / `destination`)
- **Obstacle** — komórka oznaczona jako zablokowana (nie można na niej postawić toru)
- **Train** — stacja startowa, stacja docelowa, kolor/typ (musi się zgadzać ze stacją docelową przy warunku "dopasowanie po kolorze")

**Struktury dla narzędzi (modelowane teraz koncepcyjnie, implementacja odłożona do poziomów, w których się pojawiają — patrz sekcja 5):**
- **Skrzyżowanie** — `TrackPiece` z dwiema niezależnymi parami krawędzi w jednej komórce (dwa tory przecinają się bez interakcji)
- **Przełącznik** — `TrackPiece` ze stanem przełączającym aktywną parę krawędzi w zależności od kierunku wjazdu pociągu
- **Stacja przesiadkowa** — wariant `Station` pozwalający więcej niż jednemu pociągowi zatrzymać się i wymienić "ładunek"
- **Tunel** — para powiązanych komórek tworząca bezpośrednie połączenie z pominięciem fizycznej odległości na siatce

**Dozwolone konfiguracje `TrackPiece` (przed odblokowaniem Skrzyżowania):** dokładnie jedna para z czterech krawędzi (N/E/S/W), bez powtórzeń — 6 ważnych kombinacji: 2 proste (N-S, E-W) + 4 zakręty (N-E, N-W, S-E, S-W). Do czasu odblokowania narzędzia "skrzyżowanie" **każda komórka może zawierać maksymalnie jeden `TrackPiece`** — próba postawienia drugiego w tej samej komórce jest błędem (`can_place_segment()` zwraca `false`). Skrzyżowanie jest jedynym wyjątkiem od tej reguły (patrz niżej) i jego obsługa w `GridModel` zostanie dodana dopiero przy M13.

**Uzasadnienie siatki kwadratowej (zamiast swobodnych punktów jak w Mini Metro):** deterministyczna kolizja oparta o współrzędne całkowitoliczbowe (bez arytmetyki zmiennoprzecinkowej/kątów), prostszy, w pełni testowalny model (stan komórki to plain data, łatwe do zamockowania w GUT), i szybszy start biorąc pod uwagę małe doświadczenie z Godotem — unikamy dodatkowej złożoności geometrii ciągłej na etapie nauki silnika.

**Uwaga projektowa:** dokładny kształt struktur dla pozostałych narzędzi (przełącznik, stacja przesiadkowa, tunel) zostanie doprecyzowany tuż przed implementacją danego poziomu (zgodnie z zasadą małych kroków w sekcji 7) — nie projektujemy ich szczegółowo "na zapas", żeby uniknąć złego zgadywania wymagań.

## 3. Architektura systemów

**Zasada nadrzędna:** cała logika gry żyje w `core/` jako czyste klasy GDScript (`class_name`, bez dziedziczenia po `Node`), niezależne od drzewa scen. Dzięki temu każdy system jest testowalny jednostkowo (GUT, sekcja 7) bez uruchamiania edytora/gry. Warstwa `scenes/` tylko odczytuje stan z `core/`, renderuje go i przekazuje input gracza z powrotem.

**Kluczowe systemy:**

1. **GridModel** (`core/grid.gd`) — stan planszy: rozmiar (10×10), postawione segmenty toru, przeszkody, pozycje stacji. Konkretne sygnatury (do doprecyzowania przy M2, ale jako punkt startowy):
   - `can_place_segment(cell: Vector2i, edge_a: int, edge_b: int) -> bool`
   - `place_segment(cell: Vector2i, edge_a: int, edge_b: int) -> bool` (zwraca `false` i nic nie zmienia, jeśli `can_place_segment` byłoby `false`)
   - `remove_segment(cell: Vector2i) -> void`
   - `get_budget_remaining() -> int`
   - Krawędzie (`edge_a`/`edge_b`) jako `enum { NORTH, EAST, SOUTH, WEST }` zdefiniowany w `core/grid.gd`.
   - Powiadomienia o zmianie stanu: `GridModel` deklaruje sygnały (`signal segment_placed(cell)`, `signal segment_removed(cell)`) — klasy w `core/` mogą używać `Signal` z Godota bez dziedziczenia po `Node` (wystarczy `extends RefCounted`), więc to nie łamie zasady "logika niezależna od drzewa scen" i GUT może na nie nasłuchiwać w testach.

2. **LevelData** (`core/level_data.gd`) — wczytana definicja poziomu: budżet segmentów, stacje (pozycja + kolor/typ), liczba i typy pociągów, przeszkody, dostępne narzędzia, aktywne warunki zwycięstwa. Format pliku źródłowego — do ustalenia w sekcji 4.

3. **SimulationEngine** (`core/simulation_engine.gd`) — na podstawie `GridModel` wylicza deterministyczną trasę każdego pociągu i symuluje ruch wszystkich naraz krok po kroku, wykrywając kolizje (dwa pociągi na tym samym polu/krawędzi w tym samym kroku). Zwraca wynik (sukces/porażka) + log kroków do animacji w warstwie prezentacji.

4. **WinConditionEvaluator** (`core/win_condition/`) — interfejs bazowy + implementacje per typ celu z DESIGN.md (dostawa podstawowa, dopasowanie kolorem, bonus za minimalizację segmentów). Poziom może mieć kilka aktywnych warunków naraz.

5. **ToolUnlockRegistry** — pole w `LevelData` wskazujące, które narzędzia (skrzyżowanie, przełącznik, stacja przesiadkowa, tunel) są odblokowane w danym poziomie; UI filtruje pasek budowy na tej podstawie.

6. **Warstwa prezentacji (`scenes/`)** — `GridView` renderuje `GridModel` i obsługuje input przeciągania; `TrainView` animuje ruch na podstawie logu z `SimulationEngine`; `HUD` pokazuje licznik budżetu i przycisk "Graj". Węzły te NIE zawierają logiki gry — tylko odczyt stanu i przekazywanie zdarzeń.

**Progresja między poziomami:** prosty autoload/singleton `GameFlow` (jedyny wyjątek od reguły "core bez Node" — to już warstwa spinająca, nie logika domenowa) trzyma indeks aktualnego poziomu i ścieżkę do pliku JSON kolejnego poziomu; `Main.tscn` pyta go o to, co wczytać po sukcesie. Na czas MVP: liniowa kolejność 1→20, bez zapisu stanu między uruchomieniami gry (zgodnie z DESIGN.md sekcja 6).

**Przepływ danych (jeden cykl gry):**
`LevelData` (wczytany plik) → `GridModel` (stan edytowalny przez gracza) → "Graj" → `SimulationEngine.simulate(GridModel)` → wynik → `WinConditionEvaluator.evaluate(wynik, LevelData)` → sukces (kolejny poziom) / porażka (powrót do edycji, `GridModel` zachowany bez zmian).

## 4. Format definicji poziomu

**Format:** JSON, jeden plik na poziom w `res://levels/`.

**Przykład (`level_01.json` — poziom wprowadzający, bez narzędzi):**
```json
{
  "id": "level_01",
  "grid_size": { "width": 10, "height": 10 },
  "segment_budget": 8,
  "obstacles": [],
  "stations": [
    { "id": "A", "x": 0, "y": 0, "color": "red", "role": "source" },
    { "id": "B", "x": 9, "y": 9, "color": "red", "role": "destination" }
  ],
  "trains": [
    { "id": "train_1", "start_station": "A", "target_station": "B" }
  ],
  "available_tools": [],
  "win_conditions": ["basic_delivery"],
  "bonus": null
}
```

**Przykład (poziom z dopasowaniem kolorem, przeszkodą i bonusem — profil poziomu z zakresu 17-20):**
```json
{
  "id": "level_18",
  "grid_size": { "width": 10, "height": 10 },
  "segment_budget": 14,
  "obstacles": [ { "x": 4, "y": 4 }, { "x": 4, "y": 5 } ],
  "stations": [
    { "id": "A", "x": 0, "y": 0, "color": "red", "role": "source" },
    { "id": "B", "x": 9, "y": 0, "color": "blue", "role": "source" },
    { "id": "C", "x": 0, "y": 9, "color": "red", "role": "destination" },
    { "id": "D", "x": 9, "y": 9, "color": "blue", "role": "destination" }
  ],
  "trains": [
    { "id": "train_1", "start_station": "A", "target_station": "C" },
    { "id": "train_2", "start_station": "B", "target_station": "D" }
  ],
  "available_tools": ["crossing", "switch", "transfer_station", "tunnel"],
  "win_conditions": ["basic_delivery", "color_match"],
  "bonus": { "type": "min_segments", "target": 20 }
}
```

**Walidacja:** `LevelData` przy wczytywaniu sprawdza spójność (np. czy `target_station` istnieje, czy narzędzia użyte w `available_tools` są rozpoznawane) i zgłasza czytelny błąd zamiast cichego zawieszenia — istotne przy 20 ręcznie pisanych plikach, gdzie łatwo o literówkę.

**Konwencja obsługi błędów:** `LevelData.load_from_file(path: String) -> LevelData` zwraca `null` przy błędzie (brak pliku, niepoprawny JSON, nieistniejąca stacja referencjonowana przez pociąg, nierozpoznane narzędzie w `available_tools`) i loguje szczegóły przez `push_error()`. Testy w GUT sprawdzają wprost `assert_null(result)` dla przypadków błędnych oraz `assert_not_null(...)` + konkretne pola dla przypadków poprawnych — bez osobnego mechanizmu kodów błędów na etapie MVP.

## 5. Plan implementacji

Poniższe to **kamienie milowe**, nie gotowe zadania — każdy z nich zostanie podzielony na mniejsze kroki (sekcja 7) dopiero na etapie faktycznego kodowania z Claude Code.

1. **M0 — Konfiguracja projektu:** inicjalizacja projektu Godot, struktura folderów, instalacja GUT, jeden trywialny test potwierdzający że `godot --headless -s addons/gut/gut_cmdln.gd` w ogóle działa
2. **M1 — Podstawowe struktury danych:** `Cell`, `TrackPiece`, `Station`, `Obstacle`, `Train` + testy (bez rozgrywki)
3. **M2 — GridModel:** stawianie/usuwanie segmentu, budżet, kolizja z przeszkodą + testy
4. **M3 — Wczytywanie poziomu:** parser JSON → `LevelData`, walidacja, `level_01.json` jako fixture testowy
5. **M4 — SimulationEngine (1 pociąg):** deterministyczne wyliczanie trasy, krok po kroku, wykrycie dotarcia do celu + testy
6. **M5 — SimulationEngine (wiele pociągów):** wykrywanie kolizji między pociągami + testy
7. **M6 — WinConditionEvaluator:** typ `basic_delivery` + testy
8. **M7 — Warstwa prezentacji (statyczna):** render siatki/torów/stacji z hardkodowanego `GridModel`, bez interakcji
9. **M8 — Interakcja gracza:** przeciąganie do stawiania/usuwania segmentów, licznik budżetu w HUD
10. **M9 — Symulacja na ekranie:** przycisk "Graj", animacja pociągów na podstawie logu z `SimulationEngine`
11. **M10 — Pętla porażka/sukces:** przy kolizji powrót do edycji z zachowanym torem; przy sukcesie przejście do kolejnego poziomu
12. **M11 — Poziomy 1-4:** zaprojektowane i ręcznie przetestowane (tylko podstawowa dostawa, bez narzędzi)
13. **M12 — Dopasowanie po kolorze:** nowy `WinConditionEvaluator` + testy, poziomy 5-8
14. **M13 — Skrzyżowanie:** model + obsługa w symulacji + UI + testy, integracja z poziomami
15. **M14 — Przełącznik:** analogicznie, poziomy 9-12
16. **M15 — Stacja przesiadkowa:** analogicznie, poziomy 13-16
17. **M16 — Tunel:** analogicznie, poziomy 17-20
18. **M17 — Bonus za minimalną liczbę segmentów:** evaluator + testy
19. **M18 — Pełny playtest 20 poziomów:** ręczne przejście całości, poprawki

Kolejność M12-M17 (narzędzia i poziomy) może się zmieniać w praktyce — priorytet ma zawsze mieć grywalny, przetestowany rdzeń (M0-M11) zanim dołoży się kolejne warstwy złożoności.

## 6. Otwarte pytania techniczne / ryzyka

- **Podgląd trasy przed symulacją** (DESIGN.md sek. 4) wymaga funkcji "dry-run" w `SimulationEngine`, która wylicza trasę bez pełnej animacji — nie zaprojektowane jeszcze jako osobne API, do doprecyzowania przy M4/M9
- **Implementacja tunelu** (teleportacja między niesąsiadującymi komórkami) może wymagać rozszerzenia `SimulationEngine` poza prosty model "sąsiad-sąsiad" — ryzyko dodatkowej złożoności przy M16
- **Kalibracja 10×10 + budżet segmentów** — rozmiar planszy i budżety per poziom to robocze założenia z DESIGN.md, do skorygowania po pierwszych realnych rozgrywkach
- **Undo podczas budowy** — obecnie zaplanowane jest tylko usuwanie pojedynczego segmentu (prawy klik); wieloetapowe "cofnij" nie jest ustalone — backlog, nie blokuje MVP
- **Kolor/typ ładunku jako string w JSON** — wystarczające przy małej liczbie kolorów; jeśli lista typów urośnie, warto rozważyć enum zamiast dowolnego stringa (niskie ryzyko, łatwe do zrefaktoryzowania później)
- **Testowanie rozwiązywalności poziomów** — nie ma automatycznego "solvera" sprawdzającego, że dany poziom da się ukończyć w podanym budżecie; na MVP weryfikacja jest ręczna (autor gra sam) — ewentualny solver to potencjalne rozszerszenie po MVP, nie wymóg startowy

## 7. Proces pracy i zasady dla Claude Code (TDD)

**Framework testowy:** GUT (Godot Unit Test) — addon w `addons/gut/`, testy w `res://tests/`, dziedziczą po `GutTest`, uruchamiane poleceniem:
```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
Ponieważ cała logika gry (`core/`) to czyste klasy bez zależności od `Node`/sceny, testy działają bez otwierania edytora — Claude Code może samodzielnie zweryfikować, czy zadanie jest zrobione poprawnie, zanim zgłosi je jako gotowe.

**Cykl pracy (red-green-refactor) dla każdego zadania:**
1. Napisz test(y) opisujące oczekiwane zachowanie — na start powinny nie przechodzić (red)
2. Zaimplementuj minimalny kod, żeby testy przeszły (green)
3. Uporządkuj kod bez zmiany zachowania, testy nadal zielone (refactor)
4. Pokaż podsumowanie zmian (diff) przed commitem

**Definicja "małego kroku"** (kluczowe dla kontroli nad zmianami):
- Jedno zadanie = jedna klasa `core/` (lub jedna dobrze wydzielona metoda w istniejącej klasie) + komplet testów dla niej
- Orientacyjny rozmiar: pojedyncza zmiana nie powinna przekraczać ok. **150-200 linii diffu** — jeśli zadanie wygląda na większe, dzielimy je na mniejsze podzadania przed rozpoczęciem
- Warstwa prezentacji (`scenes/`) i logika (`core/`) to osobne zadania, nawet jeśli dotyczą tej samej funkcjonalności — najpierw testowalna logika, potem podłączenie UI
- Przykład dobrego kroku: "zaimplementuj `GridModel.place_segment()` + `can_place_segment()` wraz z testami sprawdzającymi budżet i kolizję z przeszkodą"
- Przykład zbyt dużego kroku: "zaimplementuj cały system budowy toru wraz z UI i symulacją" — to wymaga podziału na min. 4-5 osobnych zadań

**Zasady kontroli nad zmianami:**
- Żadnych dużych refaktorów bez wyraźnej zgody — jeśli coś wymaga przebudowy istniejącego kodu, zgłoś to jako osobną propozycję zanim zaczniesz
- Commit tylko gdy wszystkie testy są zielone
- Każdy krok kończy się czytelnym podsumowaniem: co zostało dodane/zmienione i dlaczego
- W razie wątpliwości co do zakresu zadania — zapytaj, zamiast zgadywać i robić więcej "na wszelki wypadek"
