# EVEMon Certificates Enhanced

[🇵🇱 Polski](README-PL.md) | [🇬🇧 English](README-EN.md)

**EVEMon Certificates Enhanced** przebudowuje wybrane domyślne certyfikaty EVEMona tak, aby szybciej odpowiadały na praktyczne pytania: czy pilot może używać T1, czy odblokował T2, jak głęboko ma specjalizację i czy supporty są tylko zaczęte czy naprawdę mocne.

Projekt koncentruje się przede wszystkim na **broni, missile core, turret support, dronach i tanku**. Nie zastępuje EVEMon Pilot Progression — uzupełnia go większą rozdzielczością tam, gdzie domyślne certyfikaty EVEMona były zbyt mało kontrastowe.

## Najważniejsze: kolejność instalacji

1. Pobierz i zainstaluj EVEMon z utrzymywanego repo **mgoeppner/evemon**: https://github.com/mgoeppner/evemon/releases
2. **Uruchom EVEMon co najmniej raz.**
3. Na ekranie/popupie aktualizacji danych **zainstaluj wszystkie oferowane datafiles/SDE**.
4. Zamknij EVEMon całkowicie.
5. Pobierz najnowszą paczkę z **Releases** tego repo.
6. Opcjonalnie sprawdź plan zmian:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-EVEMon-Certificates-Enhanced.ps1 -Preview
   ```
7. Zainstaluj:
   ```powershell
   .\Install-EVEMon-Certificates-Enhanced.ps1
   ```
8. Uruchom EVEMon i otwórz **Certificate Browser**.

> Aktualizacja datafiles przez EVEMon może przywrócić upstreamowe definicje certyfikatów. Po takiej aktualizacji uruchom instalator Certificates Enhanced ponownie.

## Zgodny EVEMon

Projekt jest przygotowany i testowany dla **EVEMon 5.0.1** z repo https://github.com/mgoeppner/evemon. Najpierw zaktualizuj upstreamowe pliki danych, dopiero potem nakładaj enhancement.

## Trzy powiązane projekty

- **EvE Modular Skillplans** — https://github.com/Blizbor/EvE-Modular-Skillplans — praktyczne skillplany i training paths.
- **EVEMon Pilot Progression** — https://github.com/Blizbor/EVEMon-Pilot-Progression — szeroka mapa kompetencji pilota w EVEMon.
- **EVEMon Certificates Enhanced** — https://github.com/Blizbor/EVEMon-Certificates-Enhanced — dokładniejsze certyfikaty broni, dronów i tanku.

## Pobieranie paczki

Wejdź w **Releases** i pobierz `EVEMon-Certificates-Enhanced.zip`. Repo ma katalog `package/` i workflow, który tworzy tę paczkę automatycznie.

## Dokumentacja

- [Szybki start](docs/PL/Quick-Start.md)
- [Co zmieniamy](docs/PL/What-Changes.md)
- [Broń](docs/PL/Weapons.md)
- [Drony](docs/PL/Drones.md)
- [Tank](docs/PL/Tank.md)
- [Współpraca z EVEMon Pilot Progression](docs/PL/With-EVEMon-Pilot-Progression.md)
- [Relacja między projektami](docs/PL/Project-Relationship.md)
- [Zasady dla kontrybutorów](docs/PL/Contributor-Guide.md)
- [FAQ](docs/PL/FAQ.md)

## Kontakt

Problemy z instalacją, brakujące/zmienione skille, sugestie gradacji i propozycje certyfikatów zgłaszaj przez **Issue tracker**: https://github.com/Blizbor/EVEMon-Certificates-Enhanced/issues

<p align="center">
  <img src="https://images.evetech.net/characters/91331899/portrait?size=256" width="144" alt="Gazzine TunakTun portrait">
</p>
<p align="center"><strong>Author: Gazzine TunakTun</strong></p>

_EVE Online i powiązane znaki należą do CCP hf. Projekt społecznościowy, niezależny od CCP._
