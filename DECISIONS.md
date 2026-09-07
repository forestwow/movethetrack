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
