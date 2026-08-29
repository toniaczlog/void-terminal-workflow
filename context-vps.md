# Kontekst Projektu: VPS / Serwer Linux

Ten plik służy jako "pamięć" dla ChatGPT. Wklejaj go na początku każdej nowej rozmowy.

## Informacje ogólne
- **Przeznaczenie serwera:** [np. hosting aplikacji Node.js, baza danych dla hobbystycznego projektu]
- **Dostawca / System:** [np. Ubuntu 22.04 LTS (DigitalOcean)]

## Dane dostępowe i środowisko
- **Adres IP / Domena:** [Wpisz IP - uważaj z publicznym podawaniem haseł!]
- **Zalogowany jako użytkownik:** [np. root, ubuntu]
- **Zarządzanie procesami:** [np. PM2, Docker, systemd]
- **Serwer WWW (Reverse Proxy):** [np. Nginx, Caddy, brak]
- **Otwarte porty / Firewall (UFW):** [np. 22 (SSH), 80, 443]

## Struktura plików i ważne miejsca
- `/var/www/moj-projekt` - Główny folder z kodem produkcyjnym
- `/etc/nginx/sites-available/` - Pliki konfiguracyjne Nginx
- `~/.env` - Zmienne środowiskowe (nie kopiuj ich tutaj, ale pamiętaj że tam są)

## Używane komendy (Ściąga)
- Logowanie SSH: `ssh user@IP -i ~/.ssh/klucz.pem`
- Sprawdzanie logów: `pm2 logs` lub `docker-compose logs -f`
- Restart aplikacji: `pm2 restart aplikacja`

## Aktualny status prac
- **Co zostało zrobione:** 
  - (2026-08-30): Postawienie serwera i konfiguracja SSH
  - (YYYY-MM-DD): [opis]
- **Bieżący problem/zadanie:** [Nad czym teraz pracujesz, np. instalacja SSL certbota]

## Notatki i zasady dla modelu
- Użytkownik to osoba początkująca w zarządzaniu serwerem Linux.
- Jeśli podajesz komendy, tłumacz po krótce do czego służą (np. czytanie, nadawanie uprawnień).
- Uprzedzaj o komendach niszczących (np. usuwanie katalogów).
