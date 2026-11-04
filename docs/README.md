# mz_lib

Biblioteca standalone para FiveM. Não requer ESX, QBCore, Qbox ou ox_lib.

## Instalação

1. Execute `pnpm install && pnpm build` dentro de `mz_lib/web` se o diretório `dist` não estiver presente.
2. Copie a pasta `mz_lib` para o diretório `resources` do servidor.
3. Adicione `ensure mz_lib` antes de qualquer resource que consuma a biblioteca.
4. Ajuste `config.lua` para locale, debug e tema.

## APIs de interface

- `notify(data)` — notification success, error, warning ou info.
- `progress(data)` — progresso bloqueante, cancelável, com animação opcional.
- `textUI(text, options)` / `hideTextUI()` — prompt contextual.
- `contextMenu(options)` — retorna o valor selecionado.
- `radialMenu(options)` — menu rápido com retorno assíncrono.
- `inputDialog(title, fields, options)` — formulário tipado.
- `alertDialog(options)` — retorna `true`, `false` ou `nil`; com `keyboard = true`, aceita Y/N/ESC. `duration` (ms) fecha automaticamente retornando `nil` (o `false` continua sendo exclusivo de recusa explícita); `variant = 'compact'` renderiza discreto, sem backdrop.
- `taskbar(options)` — teste de perícia lento com zona-alvo; retorna boolean.
- `skillCheck(options)` — alias compatível de `taskbar(options)`.
- `SkillProgress(options)` / `skillProgress(options)` — progresso contínuo com skillchecks circulares, estatísticas e cancelamento.
- `spinner(options)` / `hideSpinner()` — estado de loading.
- `setClipboard(value)` — copia via NUI.

## Core

- `callback(name, ...)` e `registerCallback(name, handler)` em client e server.
- `addZone(options)` / `removeZone(id)` para sphere, box e poly.
- `addPoint(options)` / `removePoint(id)` para loops de proximidade eficientes.
- Streaming: model, anim dict/set, texture dict, weapon asset e particle asset.
- World: closest vehicle/ped/object, network control e raycast.
- Cache: `getCache()` retorna ped, playerId, serverId, coords e veículo atual.

## Tema

A NUI usa tokens CSS controlados por `MzConfig.ui`: `accent`, `radius`, `scale`, `font`, `surfaceOpacity`, posições e redução de movimento. A base é neutra para aceitar a identidade visual de cada servidor.

## Callbacks

Callbacks possuem IDs, timeout configurável e validam o `source` no retorno server-side. Nunca confie em dados recebidos do client para economia, permissões ou inventário: valide tudo no servidor.

## Zones

Sphere usa `coords` e `radius`. Box usa `coords` e `size`. Poly usa `points`, `minZ` e `maxZ`. Todos aceitam `onEnter`, `onExit` e `nearby`.

## Checklist in-game

- Verifique foco, cursor e Escape em todos os dialogs.
- Teste cancelamento de progress a pé e em veículo.
- Valide resoluções 16:9, 21:9 e safe zone do HUD.
- Reinicie a resource com overlays abertos e confirme a liberação do foco.
- Teste callbacks sob desconexão e timeout.
- Ative `debug = true` apenas em ambiente de desenvolvimento.

## Exemplos de desenvolvimento

Os arquivos em `examples/` não são carregados pelo `fxmanifest.lua` de produção. Para homologação local, inclua temporariamente `examples/client.lua` em `client_scripts`, reinicie `mz_lib` e execute `/mz_skillprogress_test`. O comando abre uma atividade de 30 segundos com 3 a 5 skillchecks e mostra as estatísticas no notify final; remova a inclusão antes de publicar o resource.
