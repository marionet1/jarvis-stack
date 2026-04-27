# Tool Integration Playbook

Instrukcja utrzymania porzadku przy wdrazaniu nowych tooli w `stack-jarvis1net`.

## Cel

- Kazdy nowy tool ma jedno, oczywiste miejsce implementacji.
- Agent pozostaje cienki (orchestracja + kanal), a logika narzedzi siedzi w MCP.
- Sekrety sa tylko w `.env`, a konfiguracja niesekretna tylko w plikach JSON.
- Brak "porozrzucanych" wrapperow i duplikacji logiki.

## Architektura docelowa (zasada)

- `agent-jarvis1net`:
  - tylko runtime agenta, kanaly (`src/channels`), orchestration LLM (`src/core`), integracje (`src/integrations`).
  - bez logiki biznesowej nowego toola.
- `mcp-jarvis1net`:
  - pelna implementacja toola, walidacja, operacje i rejestracja w MCP.

## Gdzie dodawac nowy tool

Kazdy tool trafia do grupy domenowej w MCP:

- Filesystem: `mcp-jarvis1net/src/tools/filesystem/`
- Microsoft: `mcp-jarvis1net/src/tools/microsoft/`
- Shell/diagnostics: `mcp-jarvis1net/src/tools/shell/`
- Nowa domena: utworz nowy katalog `mcp-jarvis1net/src/tools/<domena>/`

Rejestr tooli:

- `mcp-jarvis1net/src/tools/manifest.py`
- `mcp-jarvis1net/src/server.py` (podpiecie handlera, importy)

## Standard wdrozenia nowego toola (end-to-end)

1. **Zdefiniuj kontrakt**
   - nazwa toola, input schema, output schema, warunki bledu.
   - nazwa ma byc jednoznaczna i zgodna z domena, np. `microsoft_list_events`.

2. **Dodaj implementacje w MCP**
   - kod dodaj do odpowiedniego katalogu `src/tools/<domena>/`.
   - logika ma byc domknieta lokalnie (bez kopiowania do innych modulow).

3. **Podlacz tool do manifestu i serwera**
   - dopisz definicje do `src/tools/manifest.py`.
   - dopnij wykonanie w `src/server.py`.

4. **Konfiguracja**
   - sekrety: tylko `.env` (np. API keys, tokeny).
   - niesekretne opcje runtime: JSON:
     - MCP: `mcp-jarvis1net/src/tools/tools_config.json` lub `mcp-jarvis1net/src/rag/rag_config.json` (gdy dotyczy RAG).
     - Agent: `agent-jarvis1net/config/runtime_config.json`.
   - nie dodawaj fallbackow "ENV albo plik", jesli ustalony jest jeden sposob.

5. **Agent (tylko integracja, bez logiki toola)**
   - jesli potrzeba, zaktualizuj opisy/komendy w `agent-jarvis1net/src/channels/`.
   - wywolanie idzie przez warstwe MCP integration: `agent-jarvis1net/src/integrations/mcp/`.

6. **Dokumentacja**
   - dopisz narzedzie do:
     - `mcp-jarvis1net/README.md` (tool groups / config),
     - `stack-jarvis1net/README.md` (jesli zmienia onboarding/deploy),
     - tego playbooka (jesli dochodzi nowa zasada).

7. **Walidacja**
   - testy lokalne + runtime:
     - `docker compose up -d --build`
     - `docker compose ps`
     - `docker compose logs --tail=... jarvis1net`
   - sprawdz brak stalego kodu:
     - usun nieuzywane wrappery/pliki po refaktorze.

8. **Git hygiene**
   - commituj logicznie (MCP, agent, stack/submodule update).
   - push submodule, potem bump submodule pointer w root repo.

## Checklist "Definition of Done" dla nowego toola

- [ ] Kod toola jest tylko w MCP (`mcp-jarvis1net/src/tools/<domena>/`).
- [ ] Tool zarejestrowany w `manifest.py` i obslugiwany w `server.py`.
- [ ] Brak duplikacji logiki po stronie agenta.
- [ ] Sekrety tylko w `.env`; konfiguracja niesekretna w JSON.
- [ ] README i docs zaktualizowane.
- [ ] Stack przechodzi `up -d --build` i dziala bez runtime errorow.
- [ ] Brak legacy plikow po zmianie (`git status` clean po commitach).

## Anty-wzorce (czego nie robic)

- Nie dodawaj nowego toola "tymczasowo" do `agent-jarvis1net/src/core`.
- Nie trzymaj tej samej konfiguracji jednoczesnie w ENV i JSON bez powodu.
- Nie zostawiaj starych wrapperow "na wszelki wypadek".
- Nie rozrzucaj plikow jednego toola po wielu katalogach bez jasnej granicy.

## Szybki szablon zadania "wdrazamy nowy tool"

Przy nowym pomysle mozna uzyc tego formatu:

1. Nazwa toola i domena: `...`
2. Wejscie/wyjscie (schema): `...`
3. Katalog MCP docelowy: `mcp-jarvis1net/src/tools/<domena>/...`
4. Wymagane sekrety `.env`: `...`
5. Wymagane opcje JSON: `...`
6. Zmiany w agent channel/UX (jesli potrzebne): `...`
7. Test plan (docker + runtime): `...`

To jest domyslny standard dla wszystkich kolejnych tooli.
