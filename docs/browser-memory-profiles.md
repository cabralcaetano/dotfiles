# Perfis de navegador por super workspace — post-mortem (encerrado 2026-09-10)

**Status:** encerrado. A ideia foi prototipada, medida e depois abandonada; os
helpers que a implementavam foram removidos do repo em 2026-09-10. Este
documento é registro histórico — não há nada aqui para executar.

**O que vale hoje:** Zen Browser é o navegador padrão XDG e do `SUPER+B`
(`hyprland.lua` chama `~/.local/bin/zen` direto). O Brave **continua
instalado e em uso**, lançado pelo `.desktop` próprio dele
(`brave-browser.desktop`, pacote `brave-bin`). O que morreu foi só o modelo de
rotear navegador/profile por super workspace.

## Contexto do problema (2026-08)

Setup de super workspaces (ver [`hyprland-super-workspaces.md`](hyprland-super-workspaces.md)):

- Super workspace 1: Brave (WhatsApp/trabalho), Spotify nativo, Discord nativo.
- Super workspace 2: Contab OS (software de contabilidade em desenvolvimento),
  rodando em localhost, aberto num `chromium` **separado** do Brave.
- Super workspace 3 (planejado na época): outro navegador só para pesquisa de
  um segundo software em desenvolvimento.

Cada engine de navegador rodando ao mesmo tempo (Brave + Chromium) sobe seu
próprio processo principal, GPU process, network service e par de zygotes —
overhead de infraestrutura duplicado antes de qualquer aba de conteúdo real.

## Evidência medida (nesta máquina, sessão real)

- `chromium` solo (sem `--app=`, só hospedando 1 aba de `localhost` do
  Contab OS): **~2,6 GB de RSS** somando toda a família de processos
  (principal + GPU 266 MB + network service 96 MB + zygotes ~140 MB + crashpad +
  renderer de UI `top-chrome-webui` 169 MB + abas).
- Brave (tudo: WhatsApp, abas de trabalho): ~4,1–4,3 GB, mas sob **um único**
  processo principal — todas as janelas/abas dele já compartilham
  GPU/network/zygote entre si.
- `earlyoom` já estava configurado com `--prefer` incluindo
  `brave|electron|Discord|node|bun|chrome|chromium|spotify`, mitigando picos de
  OOM matando esses processos primeiro — sintoma, não causa.

## O que o protótipo provou (e o que quebrou)

Abrir um `--profile-directory=<Nome>` **dentro do mesmo `--user-data-dir`** de
um Brave já rodando **não** sobe processo principal, GPU nem network service
novos — confirmado via `ps` antes/depois em teste ao vivo. Só sobe um
`renderer` para a janela, o mesmo custo de abrir mais uma aba/janela normal. O
profile fica isolado (cookies/sessão/histórico próprios) e o engine pesado é
compartilhado. A classe de janela resultante no Hyprland era
`brave-<host>__-<Profile>` (ex.: `brave-localhost__-ContabOS`).

Gotcha descoberto: com o Brave já rodando (instância única), o processo
spawnado só sinaliza a instância existente e sai — a janela real pertence ao
PID do Brave antigo. Isso quebrava o `workspace = "..."` passado direto no
`exec_cmd` do Hyprland (a regra ficava atrelada ao PID do processo temporário,
já morto). O contorno usado nos helpers era esperar a janela aparecer pela
classe (poll) e movê-la manualmente para o slot, sem roubar o foco.

## Por que foi abandonado

1. **Depuração contaminada:** profiles diferentes dentro do mesmo Brave
   compartilham o processo do navegador. Quando o OMP Browser Relay prendia um
   target desse processo, o aviso de debug aparecia em todo o Brave — inclusive
   no profile pessoal.
2. **Zen assumiu o papel de navegador padrão** (boot, `SUPER+B`, `xdg-open`),
   e o Zen não participa desse modelo de profiles Chromium.
3. **Os wrappers viraram mentira:** `brave-super-workspace.sh` e
   `browser-super-workspace.sh` mantinham nome/ícone de Brave mas executavam o
   Zen. Dois `.desktop` correspondentes propagavam o engano no launcher.
4. Nenhum super workspace acabou usando profile isolado no dia a dia — o custo
   de manter quatro scripts para isso não se pagou.

## O que foi removido em 2026-09-10

- `scripts/.local/bin/brave-profile.sh`
- `scripts/.local/bin/chromium-profile.sh`
- `scripts/.local/bin/brave-super-workspace.sh`
- `scripts/.local/bin/browser-super-workspace.sh`
- `desktop-apps/.local/share/applications/brave-super-workspace.desktop`
- `desktop-apps/.local/share/applications/browser-super-workspace.desktop`

Sobrevivem, sem relação com esse modelo: a extensão local
`scripts/.local/share/browser-tab-mover/` (usada no Brave) e
`scripts/.local/bin/browser-tab-mover-sync-shortcuts.sh` — ver
[`browser-tab-shifter.md`](browser-tab-shifter.md).

## Decisão preservada: Spotify e Discord ficam nativos

Cada um paga o mesmo tipo de tax (GPU + zygote + network service próprios, como
qualquer app Electron/Chromium), mas virar aba de navegador **não compensa**:
`ducking/ducking.md` e o serviço de ducking identificam o Spotify pelo client
nativo no PipeWire (`get_spotify_id` via `wpctl status`). Como aba, o áudio
apareceria como cliente do navegador e o ducking automático pararia de
funcionar. Os dois seguem nativos.
