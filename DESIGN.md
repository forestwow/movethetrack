# DESIGN.md — Dokument Projektowy Gry

> Status: v1 kompletny, gotowy do przekazania jako kontekst dla implementacji.

## 1. Pitch i wizja

**Jedno zdanie:** Minimalistyczna łamigłówka sieciowa — budujesz tor kolejowy ograniczoną liczbą segmentów tak, by wszystkie pociągi bezpiecznie i jednocześnie dotarły do celu w jednym, w pełni zsynchronizowanym przejeździe.

**Dlaczego to ma sens jako coś więcej niż kolejny klon:**
- W przeciwieństwie do Mini Metro (presja czasu, przetrwanie, brak "końca" poziomu) każdy poziom tutaj ma jasny, dyskretny stan: rozwiązany albo nie — bliżej klasycznej łamigłówki (jak Baba Is You) niż symulacji przetrwania
- W przeciwieństwie do Baba Is You mechanika opiera się na planowaniu przestrzenno-czasowym sieci, a nie na manipulacji regułami językowymi — inny rodzaj myślenia (systemowe/logistyczne zamiast symbolicznego)
- Twardy budżet segmentów wymusza rozwiązania "tangramowe" — nie ma miejsca na chaotyczne próby, trzeba zaplanować całość z góry, co pasuje do formatu małych, gęstych w treść poziomów zamiast rozległej ekonomii jak w Transport Tycoon

**Grupa docelowa (na razie):** sam autor jako pierwszy tester — walidacja, czy rdzeń mechaniki jest satysfakcjonujący, zanim rozważy się szerszą publikację.

## 2. Rdzeń mechaniki

**Pętla rozgrywki:**
1. **Faza budowy** — gracz układa sieć torów na siatce, korzystając z budżetu maksymalnie N segmentów (limit definiowany per poziom; użycie mniejszej liczby jest dozwolone i pożądane). Brak presji czasowej — dowolnie długa edycja.
2. **Faza symulacji** — po naciśnięciu "Graj" wszystkie pociągi ruszają jednocześnie; tura = jeden zsynchronizowany krok wszystkich pociągów naraz.
   - Gracz nie steruje pociągami podczas symulacji — jedyna interakcja gracza to budowa sieci przed startem. Podczas symulacji można ją tylko obserwować, przerwać (powrót do edycji) lub poczekać na rozstrzygnięcie.
3. **Rozstrzygnięcie** — poziom jest wygrany tylko jeśli CAŁY przejazd zakończy się sukcesem (wszystkie pociągi docierają do właściwych stacji bez kolizji). Kolizja (dwa pociągi na tym samym polu/krawędzi w tym samym kroku symulacji) = natychmiastowa porażka, powrót do fazy budowy.

**Plansza:** siatka kwadratowa (decyzja robocza — uzasadnienie w TECH_SPEC.md, do potwierdzenia).

**Warunki zwycięstwa (mieszane pomiędzy poziomami, nie każdy poziom używa wszystkich):**
- *Podstawowy*: wszystkie ładunki docierają do właściwych stacji
- *Dopasowanie po kolorze/typie*: różne ładunki muszą trafić do stacji o odpowiadającym kolorze/typie — dokłada warstwę dopasowania do samej topologii
- *Stałe przeszkody*: część pól planszy jest zablokowana na stałe, wymusza objazdy w ramach budżetu segmentów
- *Minimalna liczba segmentów (cel bonusowy)*: poziom ma zdefiniowane "idealne" minimum segmentów; podstawowe zwycięstwo to dowiezienie ładunków, osiągnięcie minimum to dodatkowe wyzwanie dla chcących

**Progresja narzędzi (odblokowywane stopniowo w trakcie kampanii 20 poziomów):**
- Skrzyżowanie torów
- Przełącznik (zmiana kierunku ruchu pociągu)
- Stacja przesiadkowa
- Tunel

**Świadomie odłożone poza MVP (potencjał na rozszerzenie):**
- Kolejność dostaw (sequencing — ładunek A przed B)
- Wspólny odcinek toru z rozjazdem czasowym (bottleneck)
- Poziomy z twardym limitem jednego konkretnego narzędzia
- Ruchome/cykliczne przeszkody

## 3. Projekt poziomów i progresja

**Liczba poziomów:** 20 (docelowo, sztywno).

**Plansza:** stała dla wszystkich poziomów — **10×10 pól**, kafelki 64×64 px w renderze (do korekty po pierwszych testach — jeśli za ciasno/za luźno, zmieniamy).

**Tutorial:** brak tekstu/podpowiedzi w MVP. Nauka zasad wyłącznie przez kolejność i trudność poziomów (pierwsze poziomy muszą być na tyle proste, żeby mechanika broniła się sama).

**Liczba pociągów jednocześnie:** start od 1, rośnie do maksymalnie 3 w najtrudniejszych poziomach tej puli 20 (górna granica do weryfikacji przy testach — jeśli 3 okaże się już przeciążające dla gracza, obcinamy do 2).

**Kolejność wprowadzania narzędzi** (propozycja robocza, do dopracowania podczas budowy poziomów):
1. Skrzyżowanie torów — najprostsze koncepcyjnie, naturalne rozszerzenie podstawowej siatki
2. Przełącznik (zmiana kierunku pociągu) — wymaga zrozumienia sekwencji ruchu
3. Stacja przesiadkowa — łączy koncepcję wielu pociągów z jednym punktem
4. Tunel — najbardziej złożony (pozwala "ominąć" fragment planszy), najlepszy na koniec

**Warunki zwycięstwa:** mieszane swobodnie od momentu wprowadzenia — nie ma sztywnej reguły "jeden typ na blok poziomów".

**Robocza krzywa trudności (do dopracowania przy projektowaniu konkretnych poziomów):**

| Poziomy | Pociągi | Narzędzia | Warunki zwycięstwa |
|---|---|---|---|
| 1-4 | 1 | brak (tylko prosty tor) | podstawowy (dowieź ładunek) |
| 5-8 | 1-2 | skrzyżowanie | + dopasowanie po kolorze |
| 9-12 | 2 | + przełącznik | + stałe przeszkody |
| 13-16 | 2-3 | + stacja przesiadkowa | mix wszystkich dotychczasowych |
| 17-20 | 3 | + tunel | mix + cel bonusowy (minimalna liczba segmentów) |

**Założenia otwarte / do weryfikacji przy playtestach:**
- Górna granica 3 pociągów może się obniżyć, jeśli budowanie zrobi się nieczytelne
- Rozmiar planszy 10×10 może wymagać korekty po pierwszych rozgrywkach
- Dokładna kolejność narzędzi może się zmienić w trakcie projektowania konkretnych poziomów

## 4. Sterowanie i UX

**Budowa toru:** przeciąganie — gracz klika i przeciąga przez sąsiednie pola, tworząc segmenty toru w locie.

**Usuwanie segmentu:** prawy klik na segmencie usuwa go; dodatkowo menu kontekstowe po najechaniu na obiekt (hover) daje dostęp do usunięcia i innych akcji dotyczących tego segmentu.

**Budżet segmentów:** licznik "wykorzystane / dostępne" zawsze widoczny na ekranie podczas fazy budowy.

**Start symulacji:** przycisk "Graj" uruchamia fazę symulacji.

**Porażka (kolizja):** gra wraca do fazy edycji z zachowanym układem torów — gracz poprawia istniejący układ zamiast zaczynać od zera.

**Podgląd trasy:** trasa pociągu wynika bezpośrednio i deterministycznie z ułożonych torów (brak losowości/ukrytej logiki) — gracz widzi, którędy pojedzie pociąg, jeszcze przed wciśnięciem "Graj".

## 5. Kierunek artystyczny

**MVP (teraz):** proste kształty geometryczne (koła, linie, prostokąty), płaska kolorystyka, minimalna paleta (kilka kolorów o wysokim kontraście). Priorytet: czytelność stanu gry — kolor koduje informację (typ ładunku, dopasowanie do stacji, stan toru), nie estetykę. Zero animacji poza niezbędną (ruch pociągu podczas symulacji).

**Paleta i konkretny styl wizualny:** otwarta decyzja, do ustalenia przy pierwszym prototypie — nie blokuje startu implementacji (placeholder kolory: system domyślny Godota wystarczy na start).

**Przyszłość (warunkowo):** jeśli mechanika się obroni w testach, rozważenie przejścia na pixel art (sprite'y kafelkowe) przy zachowaniu tej samej czytelności funkcjonalnej. Nie jest to zobowiązanie na etapie MVP.

## 6. Zakres MVP i non-goals

**W zakresie MVP:**
- Rdzeń mechaniki opisany w sekcji 2 (budowa → symulacja → rozstrzygnięcie)
- 20 poziomów wg krzywej trudności z sekcji 3
- Sterowanie i UX z sekcji 4 (przeciąganie, licznik budżetu, restart po porażce)
- Placeholder grafika (prosta geometria)

**Świadomie poza zakresem MVP (non-goals):**
- Menu główne, ekran startowy
- Zapis postępu między sesjami (gra od poziomu 1 do 20 w jednym podejściu / ręczny wybór poziomu w kodzie na czas testów)
- Dźwięk i muzyka
- Tekstowy tutorial / podpowiedzi w grze
- Integracja ze Steam (achievementy, karty, itp.)
- Tryb wieloosobowy
- Proceduralna generacja poziomów
- System punktacji / rankingi
- Lokalizacja (wielojęzyczność)
- Ekran ustawień
- Zmienny rozmiar planszy między poziomami
- Więcej niż 3 pociągi jednocześnie

Powyższe to backlog na "po MVP", nie skreślone na zawsze — priorytetem jest sprawdzenie, czy sam rdzeń mechaniki jest grywalny i satysfakcjonujący.
