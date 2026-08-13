# Hyprland Super Workspaces

**Status:** implementado e verificado (2026-08-11) — bancos independentes de workspaces `1..9/0` por super workspace.
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

Os números continuam sendo os mesmos na tecla e na Waybar; só o destino interno muda conforme o super workspace ativo.

## Arquivos

| Arquivo | Função |
|---|---|
| `hypr/.config/hypr/super-workspaces.txt` | Lista os super workspaces disponíveis, uma linha por item, na ordem do ciclo. |
| `scripts/.local/bin/super-workspace.sh` | Roteia foco, movimento, scratchpad, troca de super workspace e payload da Waybar. |
| `hypr/.config/hypr/hyprland.lua` | Binds `SUPER+1..9/0`, `SUPER+Tab`, `SUPER+S` chamam o script. |
| `waybar/.config/waybar/config.jsonc` | Adiciona `custom/super-workspace` e filtra `hyprland/workspaces`. |
| `waybar/.config/waybar/style.css` | Ajusta o ícone do super workspace e preserva o espaçamento dos numerais. |

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
```

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
| `SUPER+Tab` | Próximo super workspace; grava o slot atual, restaura o último slot do destino e sincroniza Waybar. |
| `SUPER+SHIFT+G` | Super workspace anterior; mesma restauração de slot. |
| `SUPER+SHIFT+Tab` | Move a janela focada para o mesmo slot no próximo super workspace e segue para lá (troca o super workspace ativo, restaura foco e sincroniza Waybar). |
| `SUPER+S` | Toggle do scratchpad do super workspace ativo. |
| `SUPER+SHIFT+S` | Move a janela focada para o scratchpad do super workspace ativo. |

`SUPER+Scroll` continua global (`e+1`/`e-1`) de propósito. Ele pode atravessar workspaces de outros super workspaces, mas não altera o estado salvo do super workspace ativo.

Quando você está em `super-1-2`, alterna para outro super workspace e depois volta, o script retorna para `super-1-2` em vez de cair sempre em `super-1-1`.

`SUPER+SHIFT+1..9/0` move sem seguir: a janela muda de slot, mas o super workspace ativo e o foco continuam onde estavam. `SUPER+SHIFT+Tab` é o único bind que move *e* segue — pensado para o caso de "levar essa janela para o outro banco e ir com ela".

## Waybar

A barra da esquerda fica:

```text
<ícone do super workspace ativo>  i ii iii iv ...  <janela ativa>
```

Componentes:

- `custom/super-workspace`: executa `super-workspace.sh waybar` e recebe JSON no formato `{"text":"...","tooltip":"..."}`.
- `hyprland/workspaces`: continua sendo o módulo nativo, preservando clique/scroll nos workspaces.
- `ignore-workspaces`: é reescrito pelo script em cada `next`/`prev` para mostrar só nomes com prefixo do super workspace ativo.

Exemplo para super workspace `1`:

```jsonc
"ignore-workspaces": ["^(?!super-1-).*$"]
```

Tooltip do ícone mostra somente a lista dos super workspaces, com marcador no ativo:

```text
•  1
   2
```

O ícone é clicável:

| Ação | Comando |
|---|---|
| Click esquerdo | `super-workspace.sh next` |
| Click direito | `super-workspace.sh prev` |

## Ícones

Mapa atual em `icon_for()`:

| Super workspace | Ícone | Nerd Font name | Codepoint |
|---|---:|---|---|
| `1` | `` | `fa-skull` | `U+EE15` |
| `2` | `` | `cod-terminal_linux` | `U+EBC6` |
| `3` | `` | `cod-symbol_namespace` | `U+EA8B` |
| `4` | `` | `cod-terminal` | `U+EA85` |
| `5` | `` | `cod-terminal_cmd` | `U+EBC4` |
| fallback | `` | `nf-fa-circle` | `U+F111` |

Todos foram verificados via `fc-match :charset=<codepoint>` contra `JetBrainsMonoNLNerdFont-Regular.ttf`.

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

1. Adicione uma linha em `hypr/.config/hypr/super-workspaces.txt`:

   ```text
   3
   ```

2. Se quiser ícone específico, adicione o caso em `icon_for()`:

   ```bash
   3) printf '\uea8b' ;;  # cod-symbol_namespace
   ```

3. Se quiser que a Waybar mostre numerais para o novo banco, adicione chaves `super-3-1` até `super-3-10` em `format-icons`.

4. Recarregue:

   ```bash
   hyprctl reload
   ~/.local/bin/super-workspace.sh sync-waybar
   ```

## Comandos úteis

| Comando | Uso |
|---|---|
| `super-workspace.sh focus 1` | Vai para o slot `1` do super workspace ativo. |
| `super-workspace.sh move 2` | Move a janela focada para o slot `2` do super workspace ativo. |
| `super-workspace.sh move-super next` | Move a janela focada pro mesmo slot no próximo super workspace e segue pra lá. |
| `super-workspace.sh move-super prev` | Idem, no super workspace anterior. |
| `super-workspace.sh next` | Cicla para o próximo super workspace. |
| `super-workspace.sh prev` | Cicla para o anterior. |
| `super-workspace.sh scratchpad` | Toggle do scratchpad do super workspace ativo. |
| `super-workspace.sh scratchpad-move` | Move a janela focada para esse scratchpad. |
| `super-workspace.sh waybar` | Emite JSON para o módulo custom da Waybar. |
| `super-workspace.sh icon 5` | Mostra o ícone mapeado para o super workspace `5`. |

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
