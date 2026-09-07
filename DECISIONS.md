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

## D16 — M6 (`WinConditionEvaluator`) przesunięte za warstwę prezentacji

**Zmienia:** kolejność kamieni milowych z TECH_SPEC sekcji 5.

**Dlaczego:** `basic_delivery` jest w praktyce równoważne `SimulationResult.is_success()` — pociąg
albo dociera do celu, albo symulacja kończy się jednym z trybów porażki. Interfejs bazowy
warunków zwycięstwa nie miałby dziś drugiej implementacji, na której można sprawdzić, czy
abstrakcja jest właściwa. Wraca przy `color_match` (M12), kiedy będą dwa warunki i będzie co
uogólniać.

**Priorytet:** grywalny PoC przed dopracowaniem struktury — decyzja autora.

## D17 — Poziomy mają testy rozwiązywalności zamiast solvera

**Zamyka:** ryzyko z TECH_SPEC sekcji 6 o braku automatycznego sprawdzania, czy poziom da się
ukończyć w podanym budżecie.

**Ustalenie:** `tests/test_levels_are_solvable.gd` trzyma zamierzone rozwiązanie każdego poziomu
jako listę kafelków. Test buduje je przez publiczne API `GridModel`, sprawdza, że mieści się
w budżecie, uruchamia symulację i porównuje przejechaną trasę z zamierzoną.

**Dlaczego to wystarczy zamiast solvera:** solver odpowiadałby na pytanie „czy istnieje jakieś
rozwiązanie". Test odpowiada na mocniejsze: „czy rozwiązanie, które miałem na myśli, faktycznie
działa i mieści się w budżecie". Wyłapuje literówkę we współrzędnych, za ciasny budżet i
przeszkodę postawioną w poprzek zamierzonej trasy — czyli wszystko, co realnie psuje ręcznie
pisany poziom. Nie wyłapie poziomu, który da się przejść łatwiej niż zakładałem; to zostaje dla
playtestów.

## D18 — Kolejność poziomów wynika z nazw plików

**Ustalenie:** `Main` czyta `res://levels/*.json`, sortuje alfabetycznie i tak ustala kolejność
kampanii. Brak osobnego rejestru poziomów i singletona `GameFlow`.

**Zastępuje:** `GameFlow` z TECH_SPEC sekcji 3.

**Dlaczego:** przy nazwach `level_01`..`level_20` sortowanie daje dokładnie tę kolejność, a
rejestr byłby drugim miejscem, które trzeba zaktualizować przy dodaniu poziomu. Nie ma zapisu
postępu między sesjami (non-goal z DESIGN sekcji 6), więc singleton nie ma czego trzymać.

## D19 — Styl OpenTTD w widoku z góry, rysowany proceduralnie

**Zmienia:** DESIGN sekcja 5, gdzie MVP miał zostać przy „prostych kształtach geometrycznych",
a pixel art był odłożony warunkowo na później.

**Ustalenie:** plansza dostaje wygląd inspirowany OpenTTD — trawa z drobnymi kępkami, tor jako
podsypka z podkładami i dwiema szynami, przeszkody jako drzewa, stacje jako peron z budynkiem
w kolorze linii, pociągi jako lokomotywy zorientowane w kierunku jazdy. HUD to szary panel
z fazowaną ramką w stylu interfejsów z lat 90.

**Czego świadomie NIE robimy:** rzutu izometrycznego. OpenTTD jest izometryczny, ale zmiana rzutu
wymagałaby przeliczania siatki na ekran i z powrotem, przepisania trafiania myszą w kafelek,
sortowania rysowania wg głębokości i toru w ośmiu kierunkach ekranowych — dużo pracy, która nie
dotyka mechaniki. Plansza zostaje kwadratowa, `GridModel`, sterowanie i symulacja są nietknięte.

**Dlaczego proceduralnie, a nie sprite'ami:** wszystko rysuje `_draw()` z kolorów i proporcji
wyliczanych od `CELL`, więc każda poprawka to jedna linijka i zmiana rozmiaru kafelka nadal działa
bez regenerowania grafik. Prawdziwe sprite'y pixel art zostają jako opcja, jeśli styl się obroni.

**Fazowanie przycisków** powstaje z wygenerowanego w kodzie obrazka 6×6 użytego jako
`StyleBoxTexture` 9-patch — jasne krawędzie u góry i po lewej, ciemne u dołu i po prawej,
odwrócone w stanie wciśniętym. `StyleBoxFlat` ma tylko jeden kolor ramki, więc nie da się nim
zrobić prawdziwego fazowania.

## D20 — Rozjazd opisany parą (iglica, nastawa), konfigurowany kliknięciem

**Realizuje:** M14 z TECH_SPEC sekcji 5, wcześniej niż M13 (skrzyżowanie).

**Znaleziony problem:** konfiguracji rozjazdu **nie da się wyprowadzić z geometrii**. W poziomie
`level_05_bottleneck` oba rozjazdy — `(3,5)` i `(7,5)` — mają identyczny zestaw krawędzi
`{W, E, N}`, ale muszą zachowywać się różnie: zachodni potrzebuje `W→E` i `E→N`, wschodni `W→E`
i `N→W`. Sprawdzone i odrzucone reguły bezstanowe: „jedź prosto jeśli możesz", „zawsze skręcaj",
„aktywna para krawędzi z dopełnieniem po trzeciej" — każda obsługuje jeden z tych rozjazdów i
wykłada się na drugim.

**Model:** komórka z trzema krawędziami przechowuje **iglicę** (krawędź, od której trasa się
rozwidla) i **nastawę** (jedną z dwóch pozostałych). Routing jest w pełni deterministyczny:
- wjazd od iglicy → wyjazd na nastawę (jazda ostrzem)
- wjazd od którejkolwiek gałęzi → wyjazd na iglicę (jazda z tyłu, zawsze przechodzi)

Sześć możliwych konfiguracji jest wyliczane z aktualnego zestawu krawędzi, a `GridModel` trzyma
tylko indeks — dzięki temu konfiguracja nie może się zdezaktualizować po zmianie toru.

**Sterowanie:** lewy klik bez przeciągnięcia przełącza konfigurację cyklicznie. Widok rysuje
ustawioną trasę pełnymi szynami, a nieaktywną gałąź przyciemnionymi — gracz widzi trasę przed
wciśnięciem „Graj", zgodnie z DESIGN sekcją 4.

**Wskaźnik przeszedł dwie poprawki, obie po realnym pomyleniu się gracza:**

1. Pierwsza wersja rysowała samą linię między iglicą a nastawą. Konfiguracje „iglica N, nastawa E"
   i „iglica E, nastawa N" wyglądały identycznie, choć zachowują się odwrotnie — sześć konfiguracji
   dawało trzy obrazki.
2. Dodanie grotu na ramieniu nastawy rozróżniło je, ale nadal opisywało tylko jazdę ostrzem.
   Gracz naturalnie ustawiał grot tam, gdzie *chciał* skierować pociąg, mimo że przy wjeździe
   z gałęzi nastawa nie ma znaczenia. Do tego przyciemnione szyny trzeciego ramienia sugerowały
   „tędy się nie da", podczas gdy właśnie tędy pociąg swobodnie przejeżdża.

**Obecna postać rysuje wszystkie trzy przejazdy, bo tyle ich jest.** Trasa iglica↔nastawa to jasna
linia bez grotu (przejezdna w obie strony: od iglicy jedzie się na nastawę, od nastawy na iglicę).
Trzecie ramię dostaje ciemniejszą bursztynową linię z grotem skierowanym do środka, kończącą się
na iglicy — „stąd się wtapiasz". Szyny wszystkich ramion są rysowane normalnie, bo żadne nie jest
nieprzejezdne.

**Limit krawędzi na komórkę** przestał być stałą i wynika z `available_tools` poziomu: 3 gdy
odblokowany jest `switch`, w przeciwnym razie 2.

**Limit kroków symulacji** wzrósł z `kafelki + 2` na `kafelki * limit_krawędzi + 2` — przy trzech
krawędziach pociąg może odwiedzić tę samą komórkę więcej niż raz, więc stare oszacowanie
przestało być górnym ograniczeniem poprawnej trasy (patrz [[D13]]).

## D21 — `level_05_bottleneck` to zagadka o czasie, nie o topologii

**Ustalenie:** poziom dodany przez autora wszedł do kampanii jako `levels/level_05_bottleneck.json`.

**Dlaczego skrzyżowanie by go nie odblokowało:** kolumny 4 i 6 są zamurowane poza `y=5`, więc oba
pociągi muszą przejechać przez `(4,5)` i `(6,5)`. Każde z tych pól może trzymać tylko parę W–E,
bo sąsiedzi N i S to przeszkody — oba pociągi jadą po tym samym torze. Przy dwóch krawędziach na
komórkę ich trasy pokrywają się aż do końców ścieżki, a ścieżka ma dwa końce i tylko do końca może
podpiąć się stacja. Cztery stacje potrzebują czterech końców. Skrzyżowanie to dwie *niezależne*
pary krawędzi, więc nie rozdziela tras — potrzebny był rozjazd.

**Na czym polega zagadka:** trasy schodzą się w jednotorowy korytarz, którym pociągi jadą w
przeciwnych kierunkach. Gracz musi wydłużyć trasę jednego z nich objazdem, żeby drugi zdążył
opuścić korytarz. Test `test_without_the_detour_the_trains_collide_in_the_corridor` pokazuje, że
najkrótszy dojazd kończy się kolizją — objazd nie jest ozdobą, tylko rozwiązaniem.

## D22 — Podgląd tras rysowany na żywo podczas budowy

**Realizuje:** wymaganie z DESIGN sekcji 4 („gracz widzi, którędy pojedzie pociąg, jeszcze przed
wciśnięciem Graj"), które do tej pory nie było zaimplementowane. Korzysta z [[D14]].

**Ustalenie:** po każdej zmianie toru i po każdym przestawieniu rozjazdu `Main` wywołuje
`SimulationEngine.simulate()` i przekazuje widokowi trasę każdego pociągu. `GridView` rysuje je
grubą półprzezroczystą linią w kolorze pociągu, z lekkim przesunięciem per pociąg, żeby na
wspólnym torze obie były widoczne. Kropka na końcu linii oznacza miejsce, w którym przejazd się
kończy. Podgląd znika na czas symulacji.

**Dlaczego to, a nie kolejna poprawka wskaźnika rozjazdu:** dwie iteracje nad rysowaniem iglicy i
nastawy nie rozwiązały problemu, bo gracz nie musi rozumieć rozjazdu — musi wiedzieć, dokąd
pojedzie pociąg. Podgląd odpowiada wprost na to pytanie, a rozjazd staje się pokrętłem, którego
efekt widać natychmiast. Przy złej nastawie czerwona linia skręca w niewłaściwą stronę i urywa się
w miejscu kolizji, zamiast dobiec do stacji.

**Koszt:** zero zmian w `core/`. `simulate()` jest czystą funkcją bez efektów ubocznych, więc
przeliczanie go po każdej zmianie kafelka jest bezpieczne i przy planszy 10×10 niezauważalne.
