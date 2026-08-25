# Hyprland Super Workspaces

**Status:** implementado e verificado (2026-08-13) — bancos independentes de workspaces `1..9/0` por super workspace, mais marca de urgente/notificação cross-banco.
**Contexto:** Hyprland 0.56.x em configuração Lua, monitor único, Waybar mostrando apenas os slots do super workspace ativo.

## Objetivo

Manter a memória muscular `SUPER+1..5` para os apps fixos do dia a dia e, ao mesmo tempo, permitir mais conjuntos de workspaces sem transformar a barra em uma lista longa e difícil de ler.

Modelo mental:

```text
super workspace 1
  ├─ workspace 1  → name:super-1-1
  ├─ workspace 2  → name:super-1-2
  └─ scratchpad   → special:super-1-magic

super workspace 2
  ├─ workspace 1  → name:super-2-1
  ├─ workspace 2  → name:super-2-2
  └─ scratchpad   → special:super-2-magic
```

Os números continuam sendo os mesmos na tecla e nos nomes internos; a Waybar mostra o símbolo configurado para o super workspace ativo.

## Arquivos

| Arquivo | Função |
|---|---|
| `hypr/.config/hypr/super-workspaces.txt` | Lista os super workspaces disponíveis, uma linha por item, na ordem do ciclo. |
| `scripts/.local/bin/super-workspace.sh` | Roteia foco, movimento, scratchpad, troca de super workspace e payload da Waybar. |
| `hypr/.config/hypr/hyprland.lua` | Binds `SUPER+1..9/0`, `SUPER+Tab`, `SUPER+S` chamam o script. |
| `waybar/.config/waybar/config.jsonc` | Adiciona `custom/super-workspace` e filtra `hyprland/workspaces`. |
| `waybar/.config/waybar/style.css` | Ajusta o ícone do super workspace e preserva o espaçamento dos numerais. |
| `scripts/.local/bin/super-workspace-urgent-watch.sh` | Escuta `urgent>>` no socket IPC do Hyprland; mantém `~/.cache/hypr/super-workspace-urgent-banks`. |

## Estado

O super workspace ativo fica em:

```text
~/.cache/hypr/super-workspace
~/.cache/hypr/super-workspace-slots/<super-workspace>
```

Se o arquivo de super workspace não existir ou contiver um valor fora de `super-workspaces.txt`, o script usa a primeira linha da lista como default. Se o arquivo de slot não existir, o default daquele super workspace é o slot `1`.

Lista atual:

```text
1
2
3
4
5
```

Símbolos em `icon_for()`: `1`=`>`, `2`=`~`, `3`=`=`, `4`=`^`, `5`=`*`. Fallback (workspace fora desse mapa) mostra o próprio número.

## Nomes internos no Hyprland

Hyprland mantém um espaço global de workspaces. Para simular bancos independentes sem colisão, o script usa workspaces nomeados:

| Slot lógico | Nome interno |
|---|---|
| super `1`, workspace `1` | `name:super-1-1` |
| super `1`, workspace `4` | `name:super-1-4` |
| super `2`, workspace `1` | `name:super-2-1` |
| super `2`, scratchpad | `special:super-2-magic` |

O prefixo `name:` é obrigatório nos dispatches de foco/move. Sem ele, Hyprland trata o valor como workspace numérico/legacy e pode rejeitar o comando.

## Keybindings

| Atalho | Ação |
|---|---|
| `SUPER+1..9` | Vai para o slot `1..9` dentro do super workspace ativo. |
| `SUPER+0` | Vai para o slot `10` dentro do super workspace ativo. |
| `SUPER+SHIFT+1..9` | Move a janela focada para o slot `1..9` do super workspace ativo. |
| `SUPER+SHIFT+0` | Move a janela focada para o slot `10` do super workspace ativo. |
| `SUPER+Tab` | Próximo super workspace **com janela aberta** (`bank_has_windows()`); grava o slot atual, restaura o último slot do destino e sincroniza Waybar. Sem nenhum banco ativo, alterna entre `1` e `2`. Também abre por 1s o submap de seleção direta. |
| `SUPER+Space` | Entra no submap de seleção direta de super workspace sem ciclar; timeout automático de 1,5s. |
| `1..5` dentro do submap | Pula direto para o super workspace `1..5`, restaurando o último slot salvo daquele banco. Funciona após `SUPER+Tab` ou `SUPER+Space`; `SUPER+<n>` também é aceito dentro do submap. |
| `SUPER+SHIFT+G` | Super workspace anterior, mesmo filtro de `SUPER+Tab`; mesma restauração de slot. |
| `SUPER+SHIFT+Tab` | Move a janela focada para o mesmo slot no próximo super workspace e segue para lá (troca o super workspace ativo, restaura foco e sincroniza Waybar). **Não filtra por janela aberta** — precisa alcançar bancos vazios pra poder populá-los pela primeira vez. |
| `SUPER+S` | Toggle do scratchpad do super workspace ativo. |
| `SUPER+SHIFT+S` | Move a janela focada para o scratchpad do super workspace ativo. |

`SUPER+Scroll` continua global (`e+1`/`e-1`) de propósito. Ele pode atravessar workspaces de outros super workspaces, mas não altera o estado salvo do super workspace ativo.

`SUPER+Space` antes era o atalho default do Fcitx5 para alternar grupos (`Super+Space`/`Super+Shift+Space`). O repo versiona `fcitx5/.config/fcitx5/config` com `EnumerateGroupForwardKeys=` e `EnumerateGroupBackwardKeys=` vazios para liberar esse chord para o Hyprland; troca manual de layout continua em `SUPER+K`.

Quando você está em `super-1-2`, alterna para outro super workspace e depois volta, o script retorna para `super-1-2` em vez de cair sempre em `super-1-1`.

**Duas funções de vizinho, propósitos diferentes:** `active_neighbor_sw()` (usada por `next`/`prev`, ou seja `SUPER+Tab`/`SUPER+SHIFT+G`) só considera bancos com `bank_has_windows()`, com fallback pro par `1`/`2` se nenhum banco tiver janela; `neighbor_sw()` (usada só por `move-super`) continua percorrendo a lista inteira sem filtro, senão nunca daria pra levar a primeira janela pra um banco vazio.

`SUPER+SHIFT+1..9/0` move sem seguir: a janela muda de slot, mas o super workspace ativo e o foco continuam onde estavam. `SUPER+SHIFT+Tab` é o único bind que move *e* segue — pensado para o caso de "levar essa janela para o outro banco e ir com ela".

## Waybar

A barra da esquerda fica:

```text
<ícone do super workspace ativo>  i ii iii iv ...  <janela ativa>
```

Componentes:

- `custom/super-workspace`: fica no extremo superior esquerdo, executa `super-workspace.sh waybar` e recebe JSON no formato `{"text":"...","tooltip":"...","class":[...]}`. Como é o primeiro módulo e a barra não tem padding antes dele, o canto `x=0,y=0` também aciona o botão.
- `hyprland/workspaces`: continua sendo o módulo nativo, preservando clique/scroll nos workspaces.
- `ignore-workspaces`: é reescrito pelo script em cada `next`/`prev` para mostrar só nomes com prefixo do super workspace ativo.

Exemplo para super workspace `1`:

```jsonc
"ignore-workspaces": ["^(?!super-1-).*$"]
```

Tooltip do ícone mostra o banco ativo (marcado com `•`) + qualquer outro banco que tenha janela aberta (`bank_has_windows()`, checa `hyprctl clients -j` por prefixo `super-<n>-`). Bancos vazios não entram na lista — evita listar os 5 sempre que só 1-2 estão em uso:

```text
• > 1
  ~ 2
```

(banco `2` só aparece porque tem janela aberta; `3..5`, vazios, ficam de fora). Se só o ativo tiver conteúdo, o tooltip é uma linha só (`• > 1`). Lista completa de todos os 5, independente de conteúdo, fica no popup do `fuzzel` do clique esquerdo (`super-workspace.sh menu`). `class:"urgent"` continua marcando o ícone quando algum banco não-ativo tem pendência.

O ícone é clicável:

| Ação | Comando |
|---|---|
| Click esquerdo | `super-workspace.sh menu` — abre `fuzzel --dmenu` listando os super workspaces (marcador `•` no ativo), aplica direto o escolhido via `switch` |
| Click direito | `super-workspace.sh prev` |

### Marca de urgente/notificação entre bancos

`hyprland/workspaces` só mostra os slots do banco ativo (`ignore-workspaces`),
então um `urgent` hint (Hyprland marca a janela quando ela pede atenção) num
banco escondido fica invisível — não tem como saber que o super workspace `2`
tem algo pra ver enquanto você está no `1`.

**`hyprctl clients -j` não expõe o campo `urgent` nesse build (0.56.2)** —
verificado empiricamente: a chave simplesmente não existe no JSON, `jq` só
devolve `null` porque a chave está ausente. O único jeito de saber que uma
janela virou urgente é escutar o evento `urgent>>ADDR` no socket IPC
(`.socket2.sock`) — é assim que a própria Waybar detecta urgência pro
`hyprland/workspaces`. Então isso não dá pra fazer com polling; precisa de
um listener rodando.

`scripts/.local/bin/super-workspace-urgent-watch.sh`:

- conecta em `.socket2.sock` via `socat` (loop de respawn se a conexão cair);
- em `urgent>>ADDR`, resolve `ADDR` pra `workspace.name` via
  `hyprctl clients -j` e marca o banco (`super-<n>-`) em
  `~/.cache/hypr/super-workspace-urgent-banks`;
- em `workspace>>`/`workspacev2>>` (troca de foco), desmarca o banco da
  workspace visitada — mesmo comportamento do Hyprland limpando urgência ao
  focar. Fechar a janela urgente sem visitar o banco NÃO limpa a marca (não
  há rastreio por janela, só a flag do banco).
- reload da Waybar (`SIGUSR2`) a cada marca/desmarca, pro ícone atualizar na
  hora em vez de esperar o próximo evento do módulo.

Autostart em `hyprland.lua` (`hl.on("hyprland.start", ...)`). Reiniciar o
watcher perde marcas já setadas até o próximo evento `urgent>>` reafirmar.

`bank_has_urgent()` em `super-workspace.sh` só lê esse arquivo de estado.
`waybar_payload()`:

- marca `"class":["urgent"]` no payload do ícone quando QUALQUER banco que
  não é o ativo está na lista;
- adiciona `!` na linha do tooltip do banco urgente (ex.: `  ~ 2 !`).

`style.css` estende a mesma marca visual dos workspaces individuais
(`#workspaces button.urgent`, sublinhado `border-bottom` na cor do
foreground) para `#custom-super-workspace.urgent`. Urgência do próprio banco
ativo não precisa desse tratamento: `hyprland/workspaces` já sublinha o slot
individual normalmente.

Verificado ponta-a-ponta: janela ghostty silenciosa no banco `1` (inativo,
banco ativo era `2`), `BEL` (`\a`) escrito direto no pty do processo pra
disparar o hint de urgência sem precisar de foco → evento `urgent>>` capturado
→ `super-workspace-urgent-banks` marcado com `1` → payload da Waybar virou
`{"class":["urgent"]}` → screenshot confirmou o sublinhado branco sob o `~`
→ `switch 1` limpou o arquivo de estado e o payload voltou a `"class":[]`.

## Ícones

Mapa atual em `icon_for()`:

| Super workspace | Símbolo |
|---|---:|
| `1` | `>` |
| `2` | `~` |
| `3` | `=` |
| `4` | `^` |
| `5` | `*` |
| fallback | valor do próprio super workspace |

Símbolos ASCII simples, um caractere, mesmo estilo do `>`/`~` original. Ao expandir além de `5`, adicionar só o símbolo faltante — não trocar os existentes.

## Autostart

Apps fixos do boot entram no super workspace `1`:

| App | Workspace interno |
|---|---|
| Brave | `name:super-1-1 silent` |
| Ghostty/tmux wiki-ia | `name:super-1-2 silent` |
| Obsidian | `name:super-1-2 silent` |
| Spotify | `name:super-1-3 silent` |
| Discord | `name:super-1-4 silent` |

Isso preserva o layout antigo (`1` browser, `2` terminal/Obsidian, `3` Spotify, `4` Discord), mas dentro do banco `super-1-*`.

## Adicionar outro super workspace

1. Adicione uma linha em `hypr/.config/hypr/super-workspaces.txt` (próximo livre — hoje `1..5` já existem):

   ```text
   6
   ```

2. Se quiser símbolo específico, adicione o caso em `icon_for()`:

   ```bash
   6) printf '$' ;;
   ```

3. Se quiser que a Waybar mostre numerais para o novo banco, adicione chaves `super-6-1` até `super-6-10` em `format-icons`.

4. Recarregue:

   ```bash
   hyprctl reload
   ~/.local/bin/super-workspace.sh sync-waybar
   ```

## Perfis de navegador on-demand (RAM)

**Status:** implementado e verificado (2026-08-25).

**Problema:** profiles diferentes dentro do mesmo Brave economizam RAM, mas
continuam compartilhando o mesmo processo do navegador. Quando o OMP Browser
Relay/depuração prende um target desse processo, o aviso de debug aparece em
todo o Brave — inclusive no profile pessoal do SW1.

**Solução atual:** SW1 fica no Brave pessoal (`swprofile1`). SW2+ usam
Chromium dedicado aos super workspaces. Isso cria um limite de processo entre
o browser pessoal e os browsers de trabalho/automação: se o OMP depurar o
Chromium, o banner não contamina o Brave pessoal. Tradeoff aceito: existe um
segundo engine Chromium/Chromium-like rodando quando SW2+ estiverem abertos.

`scripts/.local/bin/brave-profile.sh [--app|--browser] <profile> <slot ex: super-1-1> [url]`:

- Usado para o SW1/pessoal.
- `<profile>` é o nome visível do profile no Brave, ex. `swprofile1`. Antes
  de chamar o Brave, o script resolve esse nome no `Local State`
  (`~/.config/BraveSoftware/Brave-Browser/Local State`) e passa o diretório
  interno correto para `--profile-directory` (`Default`, `Profile 1`, etc.).
  Isso é necessário porque o Brave separa **nome visível** e **diretório do
  profile**.

`scripts/.local/bin/chromium-profile.sh <profile> <slot ex: super-2-1> [url]`:

- Usado para SW2+.
- Usa `~/.config/chromium-super-workspaces` como `--user-data-dir` dedicado e
  `--profile-directory=swprofile<N>` para separar cookies/sessões por banco.
- Mantém o custo de automação/debug fora do Brave pessoal.

`scripts/.local/bin/browser-super-workspace.sh [url]` é o roteador de alto nível:

- `SUPER+B` chama esse script via `hyprland.lua`.
- `xdg-open`/links `http` e `https` chamam esse script via
  `desktop-apps/.config/mimeapps.list` +
  `browser-super-workspace.desktop`.
- O roteamento usa o super workspace ativo (`hyprctl activeworkspace -j`, com
  fallback para `~/.cache/hypr/super-workspace`). O protocolo `xdg-open` não
  informa qual app originou o link; se um processo em background abrir link
  enquanto outro super workspace está focado, vale o banco focado naquele
  instante.

Mapa atual:

| Super workspace | Navegador | Profile | Slot |
|---|---|---|---|
| `1` | Brave | `swprofile1` | `super-1-1` |
| `2` | Chromium | `swprofile2` | `super-2-1` |
| `3` | Chromium | `swprofile3` | `super-3-1` |
| `N` | Chromium | `swprofile<N>` | `super-<N>-1` |

Uso — abrir o browser do super workspace ativo:

```bash
browser-super-workspace.sh
```

Uso — abrir link no browser do super workspace ativo:

```bash
browser-super-workspace.sh "https://example.com"
```

**Fora do escopo de propósito:** Spotify e Discord ficam nativos (Electron),
não migram para abas do Brave. Cada um já paga o mesmo tipo de tax (GPU +
zygote + network service próprios), mas `brave-duck.sh` identifica o Spotify
pelo client PipeWire nativo (`get_spotify_id` via `wpctl status`); virando
aba do Brave, o áudio apareceria como cliente "brave" e o ducking automático
pararia de funcionar. Não compensa a troca.

## Comandos úteis

| Comando | Uso |
|---|---|
| `super-workspace.sh focus 1` | Vai para o slot `1` do super workspace ativo. |
| `super-workspace.sh move 2` | Move a janela focada para o slot `2` do super workspace ativo. |
| `super-workspace.sh switch 2` | Pula diretamente para o super workspace `2`. |
| `super-workspace.sh menu` | Abre `fuzzel --dmenu` com os 5 super workspaces (ícone + número), aplica direto o escolhido via `switch`. |
| `super-workspace.sh move-super next` | Move a janela focada pro mesmo slot no próximo super workspace e segue pra lá. |
| `super-workspace.sh move-super prev` | Idem, no super workspace anterior. |
| `super-workspace.sh next` | Cicla para o próximo super workspace. |
| `super-workspace.sh prev` | Cicla para o anterior. |
| `super-workspace.sh scratchpad` | Toggle do scratchpad do super workspace ativo. |
| `super-workspace.sh scratchpad-move` | Move a janela focada para esse scratchpad. |
| `super-workspace.sh waybar` | Emite JSON para o módulo custom da Waybar. |
| `super-workspace.sh icon 2` | Mostra o ícone mapeado para o super workspace `2`. |

## Verificação

Checklist usado após alterações:

```bash
bash -n ~/Projects/dotfiles/scripts/.local/bin/super-workspace.sh
luac5.4 -p ~/Projects/dotfiles/hypr/.config/hypr/hyprland.lua
hyprctl reload
hyprctl configerrors
~/.local/bin/super-workspace.sh waybar | jq .
pkill -SIGUSR2 waybar
```

Também foi validado visualmente com `grim` na região da Waybar para confirmar:

- ícone `fa-skull` inteiro, sem corte;
- espaçamento dos numerais romanos preservado;
- tooltip emitindo lista simples;
- troca `next`/`prev` mantendo o filtro da Waybar sincronizado.

## Gotchas

- `GROUPS` não deve ser usado como nome de array no Bash: é variável especial com os GIDs do usuário. Use `SUPER_WORKSPACES`.
- `sed -i` reescreve `config.jsonc` diretamente. O padrão editado é só a linha `"ignore-workspaces": ...`; comentários JSONC sobrevivem.
- Waybar usa `SIGUSR2` para reload de config. `SIGUSR1` é outro handler.
- Empty workspaces criados por teste somem quando deixam de ser ativos e não têm janelas.
- Workspaces nomeados têm IDs internos negativos no `hyprctl workspaces -j`; isso é normal.
- `bank_has_windows()` (filtro do tooltip) depende de `jq` pra parsear `hyprctl clients -j` — já é dependência existente do resto do setup (usado em `battery-conservation.sh` etc.), sem pacote novo.
