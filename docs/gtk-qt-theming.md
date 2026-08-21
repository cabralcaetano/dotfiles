# GTK/Qt Theming — Hyprland sem DE completo

**Status:** em andamento — Qt6 dark resolvido (2026-07-23); accent color cinza em libadwaita ainda não funcionando
**Contexto:** Hyprland puro, sem GNOME Shell nem Plasma completo

## Descrição

Ajuste de tema para apps GTK3, GTK4/libadwaita e Qt6/Kirigami convivendo no mesmo setup (Hyprland), buscando consistência visual próxima do GNOME (Nautilus como referência), com accent color cinza (`#a0a0a0`, mesmo tom usado no `col.active_border` do Hyprland e no Waybar).

## Decisões tomadas

- **File manager:** trocado `Nemo` (GTK3, Cinnamon) → `Nautilus` (GTK4/libadwaita), pra eliminar divergência de toolkit entre file manager e outros apps GNOME (Overskride, Pavucontrol). `xdg-mime` setado pra `org.gnome.Nautilus.desktop` em `inode/directory`.
- **GTK3:** `adw-gtk3-dark` + ícones `Adwaita` — mantido como padrão em vez de `Materia-dark` (testado e revertido) pra bater com libadwaita.
- **EasyEffects:** upstream (`wwmm/easyeffects`) abandonou GTK4/libadwaita e reescreveu em Qt6/Kirigami a partir da v8.0 — não tem mais build GTK oficial mantido. Fica visualmente "meio Plasma" (Breeze icons, QQC2 controls) sem solução limpa. Tentativa de aproximar via `QT_QUICK_CONTROLS_STYLE=Material` + accent azul GNOME testada e **revertida** (ficou "rosa/estranho").
- **qt6ct + Kvantum:** instalados. Kvantum continua sem uso. O qt6ct ficou sem config nenhuma até 2026-07-23 ("revertido pro padrão") — decisão revista, ver seção abaixo: sem config o qt6ct não é neutro, ele força tema **claro**.

## Resolvido 2026-07-23 — apps Qt6 abriam em tema claro

**Sintoma:** o `hyprland-share-picker` — a janela "Screen / Window / Region" que o `xdg-desktop-portal-hyprland` abre ao compartilhar tela (Discord, Meet, etc.) — aparecia toda branca no meio de um desktop dark.

**Causa:** o picker é **Qt6 Widgets** (`ldd /usr/bin/hyprland-share-picker` → `libQt6Widgets.so.6`). O `hyprland.conf` já exportava `QT_QPA_PLATFORMTHEME=qt6ct` (e a variável chegava até o portal — confirmado em `systemctl --user show-environment`), mas `~/.config/qt6ct/` estava **vazio**. Sem `qt6ct.conf` o plugin não é no-op: ele aplica o default dele, que é Fusion com paleta clara. Ou seja, o `env` sozinho piorava — sem ele o app cairia no default do Qt, com ele caía no default do qt6ct.

**Fix:** pacote stow `qt6ct/` no repo, adicionado ao `STOW_PKGS` do `_dotfiles-lib.sh`:

- `qt6ct/.config/qt6ct/qt6ct.conf` — `style=Fusion`, `custom_palette=true`, `icon_theme=Adwaita`, `color_scheme_path` apontando pro arquivo abaixo.
- `qt6ct/.config/qt6ct/colors/dotfiles-dark.conf` — paleta dark própria no formato de 21 roles do qt6ct (window `#181819`, base `#1c1c1f`, texto `#e8e8e8`, highlight `#5e81ac`).

Vale para qualquer app Qt6 sem tema próprio, não só o picker. Kvantum ficou de fora de propósito: `Fusion` + paleta custom já resolve, sem mais uma camada.

**Como testar sem abrir compartilhamento de tela real:** `hyprland-share-picker` roda standalone. Não precisa relogar nem reiniciar o portal — a config é lida a cada invocação do picker.

**Gap conhecido:** `qt5ct` não está instalado, então não há config equivalente pra Qt5. Se algum app Qt5 aparecer claro, é por aí.

## Resolvido 2026-08-19 — file chooser do portal abria claro

**Sintoma:** o diálogo de salvar/abrir arquivo do `xdg-desktop-portal-gtk` aparecia em tema branco, mesmo com o desktop em dark mode.

**Causa:** `gsettings get org.gnome.desktop.interface gtk-theme` estava em `Adwaita-dark`, mas não havia `/usr/share/themes/Adwaita-dark`; o tema GTK3 instalado/versionado é `adw-gtk3-dark`. O `xdg-desktop-portal-gtk` é GTK3 (`ldd /usr/lib/xdg-desktop-portal-gtk` → `libgtk-3.so.0`), então caiu no fallback claro. A ordem de autostart também deixava os portals nascerem antes do `gsettings set` do tema.

**Fix:** setado `gtk-theme='adw-gtk3-dark'` + `color-scheme='prefer-dark'` na sessão atual e reordenado `hyprland.lua` para aplicar os dois `gsettings` antes de iniciar `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` e `xdg-desktop-portal`.

**Verificação:** `gdbus` abriu um `org.freedesktop.portal.FileChooser.SaveFile` real via `xdg-desktop-portal-gtk`; screenshot com `grim` confirmou o file chooser escuro.

## Problema em aberto — accent color cinza não aplica em libadwaita

**Sintoma:** `gsettings set org.gnome.desktop.interface accent-color 'slate'` aplica no namespace GNOME, mas Nautilus/Overskride/Pavucontrol continuam com accent **azul**.

**Causa identificada:** `xdg-desktop-portal-gtk` (1.15.3-1, versão mais recente do repo) não repassa a chave `accent-color` no namespace `org.freedesktop.appearance` — que é o que `Adw.StyleManager` (libadwaita) realmente consulta via portal. Confirmado via:
```
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings ReadOne ss "org.freedesktop.appearance" "accent-color"
# → Call failed: A configuração requisitada não foi encontrada
```
`ReadAll` mostra que só existe em `org.gnome.desktop.interface` (namespace legado GNOME), não no namespace freedesktop padrão. Restart do portal (`kill` dos processos `xdg-desktop-portal` / `xdg-desktop-portal-gtk`) não resolveu — não é cache, é falta de suporte na versão instalada.

**Tentativa 2 — override via CSS de usuário:** criado `~/.config/gtk-4.0/gtk.css` (symlink stow → `gtk-4/.config/gtk-4.0/gtk.css` neste repo) redefinindo as cores nomeadas do libadwaita:
```css
@define-color accent_color #a0a0a0;
@define-color accent_bg_color #a0a0a0;
@define-color accent_fg_color #ffffff;
```
Apps reiniciados (`pkill nautilus overskride pavucontrol`) — **ainda não pegou** o cinza (2026-07-09, sessão em andamento). Hipóteses não testadas ainda:
- `Adw.StyleManager` pode estar aplicando o accent via `GtkCssProvider` com prioridade acima do CSS de usuário (não simplesmente "última declaração vence" como CSS normal — pode haver override em runtime a cada load de janela)
- Pode ser necessário reiniciar a sessão inteira (não só os processos dos apps) pra recarregar corretamente
- Vale checar se `libadwaita` 1.9.2 introduziu alguma trava adicional contra override manual de accent nessa versão específica

## Próximos passos

- [ ] Investigar por que `@define-color accent_color/accent_bg_color/accent_fg_color` em `gtk-4/.config/gtk-4.0/gtk.css` não está tendo efeito
- [ ] Testar logout/login completo (não só restart de processo) pra ver se é questão de sessão
- [ ] Alternativa se nada funcionar: aceitar accent azul padrão em apps libadwaita, já que é o menor atrito
