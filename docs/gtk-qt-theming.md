# GTK/Qt Theming — Hyprland sem DE completo

**Status:** em andamento — accent color cinza ainda não funcionando
**Contexto:** Hyprland puro, sem GNOME Shell nem Plasma completo

## Descrição

Ajuste de tema para apps GTK3, GTK4/libadwaita e Qt6/Kirigami convivendo no mesmo setup (Hyprland), buscando consistência visual próxima do GNOME (Nautilus como referência), com accent color cinza (`#a0a0a0`, mesmo tom usado no `col.active_border` do Hyprland e no Waybar).

## Decisões tomadas

- **File manager:** trocado `Nemo` (GTK3, Cinnamon) → `Nautilus` (GTK4/libadwaita), pra eliminar divergência de toolkit entre file manager e outros apps GNOME (Overskride, Pavucontrol). `xdg-mime` setado pra `org.gnome.Nautilus.desktop` em `inode/directory`.
- **GTK3:** `adw-gtk3-dark` + ícones `Adwaita` — mantido como padrão em vez de `Materia-dark` (testado e revertido) pra bater com libadwaita.
- **EasyEffects:** upstream (`wwmm/easyeffects`) abandonou GTK4/libadwaita e reescreveu em Qt6/Kirigami a partir da v8.0 — não tem mais build GTK oficial mantido. Fica visualmente "meio Plasma" (Breeze icons, QQC2 controls) sem solução limpa. Tentativa de aproximar via `QT_QUICK_CONTROLS_STYLE=Material` + accent azul GNOME testada e **revertida** (ficou "rosa/estranho").
- **qt6ct + Kvantum:** instalados, mas config revertida pro padrão (sem tema Kvantum aplicado) — não valia a pena pro ganho visual.

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
