# CONTEXT.md — szablon

Plik trzymasz w katalogu głównym repo. Na starcie każdej nowej rozmowy
(ChatGPT / Claude / Codex) wklejasz go jako pierwszą wiadomość.
Aktualizujesz na koniec sesji — najlepiej prosząc model: `HANDOFF:`.

---

```markdown
# CONTEXT — NAZWA_PROJEKTU
Ostatnia aktualizacja: RRRR-MM-DD

## Cel
Jedno–dwa zdania: co ta aplikacja ma robić i dla kogo.

## Stack
- Runtime: Node 22 / Python 3.12 / ...
- Framework: Next.js 15 (App Router) / ...
- Baza: Postgres (Supabase) / SQLite / brak
- Deploy: Vercel — URL produkcyjny: https://...
- Repo: github.com/USER/REPO (private)

## Środowisko lokalne
- OS: Windows 11, Windows Terminal, PowerShell 7
- Ścieżka repo: C:\Users\...\projekty\NAZWA
- Uruchomienie: `npm run dev` → http://localhost:3000
- Zmienne środowiskowe: .env.local (klucze: NAZWA_1, NAZWA_2 — wartości NIE w tym pliku)

## Struktura (istotne katalogi)
- `src/app/` — routing i strony
- `src/components/` — komponenty UI
- `src/lib/` — logika, klienty API
- `prisma/` lub `db/` — schema i migracje

## Co działa
- [x] Funkcja A — gotowa, przetestowana
- [x] Funkcja B — działa lokalnie, niewdrożona

## Co w toku
- [ ] Funkcja C — zaczęte w `src/lib/c.ts`, brakuje obsługi błędów

## Znane problemy
1. Opis problemu — objaw, kiedy występuje, co już próbowane.

## Decyzje projektowe (żeby model ich nie podważał co rozmowę)
- Dlaczego X zamiast Y — jednym zdaniem.

## Następny krok
Konkretnie jedno zadanie, od którego zaczynamy.

## Zasady dla modelu
- Komendy: PowerShell, cały etap w jednym bloku, z komentarzami `#`.
- Zmiany w plikach: pełna zawartość pliku, nie fragmenty.
- Nie proponuj zmiany stacku bez wyraźnej prośby.
```

---

## Jak to utrzymywać bez wysiłku

Na koniec sesji wpisujesz do modelu:

```
HANDOFF: zaktualizuj sekcje "Co działa", "Co w toku", "Znane problemy"
i "Następny krok" w moim CONTEXT.md na podstawie tej rozmowy.
Zwróć cały plik.
```

Następnie: `filec .\CONTEXT.md` (skrót z profilu PowerShell) na starcie
kolejnej rozmowy — kontekst jest w schowku jednym poleceniem.
