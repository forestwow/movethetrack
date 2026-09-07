# DECISIONS.md — Log decyzji projektowych

> `DESIGN.md` i `TECH_SPEC.md` to punkt wyjścia, nie wyrocznia. Ten plik zapisuje decyzje
> podjęte w trakcie implementacji, zwłaszcza tam, gdzie odbiegają od pierwotnych założeń.
> Format: co ustalono, dlaczego, co to zastępuje.

## D1 — Budżet liczy kafelki z torem, nie połączenia

**Ustalenie:** `segment_budget` z pliku poziomu oznacza maksymalną liczbę komórek zawierających
jakikolwiek tor. Komórki stacji i przeszkód nie liczą się nigdy.

**Dlaczego:** licznik w HUD ma odpowiadać temu, co gracz widzi na ekranie — a widzi kafelki.
Liczenie połączeń rozjeżdża się z intuicją: kafelek zakrętu to wizualnie jeden element, ale dwa
połączenia.

**Znaleziony problem:** przykład `level_01.json` w TECH_SPEC sekcji 4 jest niewykonalny —
stacje w `(0,0)` i `(9,9)` przy `segment_budget: 8`, podczas gdy odległość Manhattan to 18 kroków
(17 kafelków toru bez stacji). Przykład był ilustracyjny; realne budżety poziomów trzeba wyliczyć
od minimalnej trasy w górę.

## D2 — GridModel przechowuje połączenia między komórkami, nie pary krawędzi

**Ustalenie:** stan toru to `Vector2i -> maska bitowa krawędzi`. Główne API to
`connect(from, to)` dla dwóch sąsiadujących pól. `TrackPiece` jest obiektem pochodnym —
`get_piece(cell)` zwraca go tylko, gdy komórka ma dokładnie dwie krawędzie.

**Zastępuje:** `place_segment(cell, edge_a, edge_b)` z TECH_SPEC sekcji 3.

**Uwaga nazewnicza:** metody nazywają się `connect_cells()` / `can_connect_cells()`, bo `connect()`
jest zajęte przez `Object.connect()` z Godota i nie da się go nadpisać.

**Dlaczego:**
- Sterowanie z DESIGN sekcji 4 to przeciąganie przez sąsiednie pola. Przeciąganie produkuje
  ścieżkę komórek; jeden krok przeciągnięcia to dokładnie jedno `connect()`. Przy API opartym na
  parach krawędzi ktoś musiałby przeliczać ścieżkę na pary — i wylądowałoby to w `scenes/`,
  wbrew zasadzie „warstwa prezentacji bez logiki gry" z TECH_SPEC sekcji 3.
- Model „dokładnie jedna para krawędzi" nie potrafi zapisać ślepego końca, a ślepy koniec to
  normalny stan: gracz puszcza przycisk myszy w połowie trasy albo buduje tor kawałkami.
- Skrzyżowanie (M13) to w tym modelu po prostu komórka z czterema krawędziami — podniesienie
  stałej `MAX_EDGES_PER_CELL` z 2 na 4, bez zmiany struktury danych.

## D3 — Stacja blokuje pole, tor na niej nie stoi

**Ustalenie:** komórka stacji jest traktowana jak przeszkoda przy stawianiu toru.
Pociąg wyjeżdża ze stacji na sąsiednie pole, którego tor ma krawędź skierowaną ku stacji.

**Dlaczego:** jedna reguła mniej (stacje nie zjadają budżetu, nie trzeba osobno pilnować, żeby
stacja miała dokładnie jedno wyjście z toru na własnym polu).

**Poprawka (przy projektowaniu M4):** pierwsza wersja tej decyzji była niewykonalna. `GridModel`
odrzucał połączenia z polem stacji, więc krawędź skierowana ku stacji — od której zależy cały
wyjazd — nie mogła nigdy powstać. Kafelek obok stacji kończył się ślepo, a `other_edge()` dla
wjazdu od strony stacji zwracał `-1`.

Połączenie z polem stacji jest teraz dozwolone, ale **asymetryczne**: krawędź dostaje wyłącznie
kafelek z torem, stacja nie dostaje żadnej, nie może trzymać toru i nie liczy się do budżetu.
Połączenie stacji ze stacją jest odrzucane. `get_station_exits(cell)` zwraca sąsiadów, których tor
faktycznie wskazuje na stację.

`GridModel` nie ogranicza liczby połączeń stacji — dwa tory wchodzące do stacji docelowej są
poprawne. Niejednoznaczny jest tylko wyjazd ze stacji startowej i to `SimulationEngine` uznaje za
porażkę, zgodnie z zasadą „brak ukrytej logiki" z DESIGN sekcji 4.

## D4 — Jeden sygnał `track_changed(cell)` zamiast pary placed/removed

**Zastępuje:** `segment_placed(cell)` / `segment_removed(cell)` z TECH_SPEC sekcji 3.

**Dlaczego:** jedno `connect()` może zmienić dwie komórki naraz, a zmiana kształtu bez zmiany
zajętości (prosta → zakręt) nie pasuje do żadnego z dwóch oryginalnych sygnałów — mimo że widok
musi taką komórkę przerysować. „Ta komórka wygląda inaczej niż przed chwilą" pokrywa wszystkie
przypadki jednym sygnałem.

## D5 — Enum `Edge` mieszka w `track_piece.gd`, nie w `grid.gd`

**Zastępuje:** TECH_SPEC sekcja 3, punkt o `enum { NORTH, EAST, SOUTH, WEST }` w `core/grid.gd`.

**Dlaczego:** `TrackPiece` powstał przed `GridModel` i to on jest właścicielem pojęcia krawędzi.
`GridModel` odwołuje się przez `TrackPiece.Edge`.

## D6 — Bez osobnych klas `Cell` i `Obstacle`

**Ustalenie:** komórka to `Vector2i`, przeszkoda to komórka na liście zablokowanych w `GridModel`.

**Zastępuje:** listę struktur z TECH_SPEC sekcji 2, gdzie `Cell` i `Obstacle` figurują jako
osobne byty.

**Dlaczego:** obie byłyby pustymi opakowaniami bez zachowania. To PoC.

## D7 — Oś Y rośnie w dół

**Ustalenie:** `NORTH = Vector2i(0, -1)`, komórka `(0, 0)` to lewy górny róg planszy.

**Dlaczego:** zgodność z konwencją współrzędnych ekranu w Godocie i z przykładami JSON w
TECH_SPEC sekcji 4.

## D8 — Komórka istnieje tylko dopóki ma choć jedno połączenie

**Ustalenie:** `remove_track(cell)` czyści lustrzane krawędzie u sąsiadów. Sąsiad, któremu po tej
operacji nie zostaje żadne połączenie, sam znika z planszy i zwalnia budżet.

**Dlaczego:** stan „kafelek z torem, ale bez żadnej krawędzi" nie ma reprezentacji wizualnej ani
znaczenia dla symulacji — byłby niewidzialnym pożeraczem budżetu. Konsekwencja: usunięcie jednego
z dwóch kafelków dwuelementowego toru kasuje oba, ale usunięcie środka dłuższego toru zabiera
tylko ten jeden kafelek, bo sąsiedzi mają jeszcze inne połączenia.

**Skąd się wzięło:** dwa testy M2b zakładały odwrotnie i padły. Analiza pokazała, że błędne było
oczekiwanie w teście, nie implementacja.

## D9 — `grid_size` znika z pliku poziomu, rozmiar planszy to stała

**Zastępuje:** pole `grid_size` z przykładów w TECH_SPEC sekcji 4.

**Dlaczego:** DESIGN sekcja 6 wymienia zmienny rozmiar planszy między poziomami wprost jako
non-goal, a sekcja 3 zapowiada, że 10×10 może wymagać korekty po playtestach. Stała
`LevelData.GRID_WIDTH` / `GRID_HEIGHT` sprawia, że taka korekta to zmiana w jednym miejscu —
przy polu w JSON trzeba by edytować wszystkie 20 plików.

## D10 — Bonus jako płaski klucz `bonus_min_segments`

**Zastępuje:** `"bonus": { "type": "min_segments", "target": N }` z TECH_SPEC sekcji 4.

**Dlaczego:** w MVP istnieje dokładnie jeden typ bonusu, więc pole `type` niczego nie rozróżnia.
Brak klucza oznacza brak bonusu (`bonus_min_segments == -1`).

**Znaleziony problem:** przykład `level_18` w TECH_SPEC ma `"target": 20` przy
`segment_budget: 14` — cel bonusowy większy od budżetu jest nieosiągalny. `LevelData` odrzuca
teraz taki plik.

## D11 — Kolor pociągu pochodzi ze stacji startowej

**Ustalenie:** pliki poziomów nie podają koloru pociągu; `LevelData` bierze go z jego stacji
źródłowej. Warunek `color_match` porównuje ten kolor z kolorem stacji docelowej.

**Dlaczego:** jedno miejsce prawdy. Kolor podany osobno przy pociągu mógłby się rozjechać
z kolorem stacji, na której ten pociąg stoi, i trzeba by to walidować.

## D12 — Walidacja zwraca powód, testy przypinają się do komunikatu

**Ustalenie:** `_find_problem()` zwraca pusty string albo opis pierwszego napotkanego problemu;
`load_from_file()` loguje go przez `push_error()` i zwraca `null`. Testy używają
`assert_push_error("fragment")` zamiast samego `assert_null`.

**Dlaczego:** GUT 9.7 i tak traktuje każde niezapowiedziane `push_error()` jako niepowodzenie
testu, więc trzeba je jawnie skonsumować. Przy okazji test sprawdza, czy odrzucenie nastąpiło
z właściwego powodu, a nie przypadkiem z innego — przy 22 przypadkach błędnych to realna różnica.

## D13 — Wynik `LOOP` jest dziś nieosiągalny, ale zostaje jako bezpiecznik

**Ustalenie:** `SimulationEngine` przerywa symulację po przekroczeniu limitu kroków
(liczba kafelków z torem + 2) i zwraca `Outcome.LOOP`. Przy obecnym `MAX_EDGES_PER_CELL = 2`
żaden układ toru nie potrafi tego wywołać.

**Dlaczego jest nieosiągalny:** komórka z dwiema krawędziami ma dokładnie jedną parę wjazd-wyjazd,
więc pociąg nie może odwiedzić jej dwa razy. Zamknięta pętla połączona z torem od stacji
wymagałaby komórki z trzema krawędziami — a takiej `GridModel` nie pozwala postawić. Test, który
próbował zbudować pętlę, kończył się na `can_connect_cells()` zwracającym `false`; został
przepisany na sprawdzenie właśnie tego.

**Dlaczego mimo to zostaje:** skrzyżowanie (M13) podnosi limit do 4 krawędzi i wtedy pętla staje
się budowalna. Do tego czasu limit kroków chroni przed zawieszeniem gry, gdyby błąd w symulacji
wprowadził pociąg w nieskończony cykl — pętla w `while` bez wyjścia zawiesiłaby cały proces Godota,
nie tylko poziom.

## D14 — Podgląd trasy to zwykłe `simulate()`, bez osobnego API

**Zamyka:** otwarte pytanie z TECH_SPEC sekcji 6 o funkcję „dry-run" w `SimulationEngine`.

**Ustalenie:** `SimulationEngine.simulate()` jest czystą funkcją bez efektów ubocznych i zwraca
pełny log pozycji (`SimulationResult.steps`). Podgląd trasy przed wciśnięciem „Graj" to po prostu
wywołanie `simulate()` i narysowanie `get_path(train_id)` — ta sama funkcja, którą potem odtwarza
animacja. Osobne API byłoby drugą implementacją tej samej logiki, czyli drugim miejscem na błąd.

## D15 — Kolizja to wspólne pole albo zamiana miejsc

**Ustalenie:** po każdym kroku symulacji `SimulationEngine` sprawdza dwie rzeczy:
dwa pociągi na tym samym polu oraz dwa pociągi, które zamieniły się polami (A→B i B→A w tym
samym kroku).

**Dlaczego druga reguła:** DESIGN sekcja 2 mówi o kolizji „na tym samym polu/krawędzi". Zamiana
miejsc nie daje wspólnego pola w żadnym kroku — pociągi mijają się w środku krawędzi i samo
porównywanie pozycji jej nie wykryje. Bez tej reguły dwa pociągi jadące na siebie po torze o
parzystej długości przenikałyby się nawzajem.

**Kolejność sprawdzeń:** własna porażka pociągu (ślepy tor, zła stacja, brak wyjazdu) jest
zgłaszana przed kolizją. Kolizja to zdarzenie między dwoma poprawnie jadącymi pociągami.

**Krok kolizyjny trafia do logu**, więc animacja pokaże moment zderzenia, a nie zatrzyma pociągi
krok wcześniej.
