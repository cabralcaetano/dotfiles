# Browser tabs — Tab Shifter e ordem das abas no Zen

**Status:** aplicado manualmente em 2026-09-04.

## Objetivo

Manter navegação por abas previsível nos browsers principais:

- Brave: extensão local para mover abas por atalho nativo do browser.
- Zen Browser: extensão local `Tab Shifter` para mover abas verticais com `Alt+Shift+J/K`.
- Zen Browser: nova aba manual entra no fim da lista vertical, preservando WhatsApp em `Alt+1`.

## Brave — extensão original

Source versionado:

- `scripts/.local/share/browser-tab-mover/manifest.json`
- `scripts/.local/share/browser-tab-mover/background.js`

Instalação ativa observada no Brave profile `swprofile1`:

- Extension ID: `lbbccpioeaehfbmgncdkoncheiebaeja`
- Path carregado pelo Brave: `/home/caetano/Projects/dotfiles/scripts/.local/share/browser-tab-mover`
- Nome no manifest: `OMP Tab Mover`

Atalhos configurados no Brave via `Preferences > extensions.commands`:

| Atalho | Comando |
|---|---|
| `Alt+Shift+H` | `move-left` |
| `Alt+Shift+L` | `move-right` |
| `Alt+Shift+1..9` | `move-to-1..9` |
| `Alt+Shift+0` | `move-to-10` |

O manifest do Brave não fixa `suggested_key`; os atalhos ficam no profile do Brave.

## Zen Browser — port local

Zen é Firefox/Gecko, então a extensão do Brave foi portada para Manifest V2 com `browser.*` APIs e empacotada como XPI local.

Source versionado:

- `scripts/.local/share/zen-tab-mover/manifest.json`
- `scripts/.local/share/zen-tab-mover/background.js`

Arquivos ativos aplicados manualmente:

- Source local: `~/.local/share/zen-tab-mover/manifest.json`
- Source local: `~/.local/share/zen-tab-mover/background.js`
- XPI fonte: `~/.local/share/zen-tab-mover/omp-tab-mover@caetano.local.xpi`
- XPI instalado no profile ativo: `~/.config/zen/fygd0cys.Default (release)/extensions/omp-tab-mover@caetano.local.xpi`
- Profile antigo/Flatpak ignorado: `~/.var/app/app.zen_browser.zen/.zen/9l11paxc.Default (release)`
- Policy de install/update: `~/.local/opt/zen/distribution/policies.json`

Identidade da extensão:

| Campo | Valor |
|---|---|
| Nome visível | `Tab Shifter` |
| Gecko ID | `omp-tab-mover@caetano.local` |
| Versão atual | `1.0.3` |
| Permissão | `tabs` |

Atalhos do Zen:

| Atalho | Comando | Ação |
|---|---|---|
| `Alt+Shift+K` | `move-up` | move aba ativa uma posição para cima |
| `Alt+Shift+J` | `move-down` | move aba ativa uma posição para baixo |

No Zen, `H/L` não ficam ativos: como a UI usa abas verticais, `Shift+J/K` é o par intencional para reordenar sem colidir com navegação simples.

## Zen Browser — ordem de novas abas

Problema observado: nova aba manual entrava no topo da lista vertical, deslocando WhatsApp do slot `Alt+1`.

Prefs fixadas no profile do Zen via `user.js`:

```js
user_pref("browser.tabs.insertAfterCurrent", false);
user_pref("browser.tabs.insertAfterCurrentExceptPinned", false);
user_pref("browser.tabs.insertRelatedAfterCurrent", true);
user_pref("zen.tabs.show-newtab-vertical", true);
user_pref("zen.view.show-newtab-button-top", false);
```

Efeito esperado:

- Abas verticais continuam ativas.
- Botão de nova aba fica na lista vertical, mas não no topo.
- Nova aba manual abre no fim da lista.
- Abas relacionadas ainda podem abrir depois da aba atual quando o browser marcar relação (`insertRelatedAfterCurrent = true`).
- WhatsApp permanece no primeiro slot e continua acessível por `Alt+1`.

## Zen Browser — seleção ao fechar abas

Problema observado: ao fechar uma aba com `Ctrl+W`, o Zen voltava para a primeira aba/WhatsApp em vez de selecionar a próxima aba da pilha, quebrando o fluxo de fechar várias abas em sequência.

Prefs fixadas no profile do Zen via `user.js`:

```js
user_pref("browser.tabs.selectOwnerOnClose", false);
user_pref("browser.tabs.selectMRUOnClose", false);
user_pref("zen.tabs.select-recently-used-on-close", false);
```

Efeito esperado:

- `Ctrl+W` fecha a aba atual e mantém o foco na vizinhança da lista.
- Repetir `Ctrl+W` fecha abas uma por uma, sem pular de volta para WhatsApp/`Alt+1`.
- A seleção por aba dona/recentemente usada fica desligada para esse fluxo.

## Zen Browser — estado visual mantido

Prefs atuais relevantes em `user.js`:

```js
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("zen.tabs.vertical", true);
```

O CSS horizontal experimental foi desativado de propósito:

- ativo esperado: `chrome/userChrome.css.disabled`
- ausente esperado: `chrome/userChrome.css`

## Reaplicar em máquina nova

1. Instalar Zen em `~/.local/opt/zen` ou ajustar os caminhos abaixo.
2. Copiar ou stowar `scripts/.local/share/zen-tab-mover` para `~/.local/share/zen-tab-mover`.
3. Criar o XPI local da extensão Zen a partir dos arquivos em `~/.local/share/zen-tab-mover`.
4. Copiar o XPI para o profile ativo do Zen em `~/.config/zen/<profile>/extensions/omp-tab-mover@caetano.local.xpi`.
5. Criar `~/.local/opt/zen/distribution/policies.json` apontando `ExtensionSettings` para o XPI local com `file:///home/caetano/.local/share/zen-tab-mover/omp-tab-mover@caetano.local.xpi`.
6. Garantir no `user.js` do profile as prefs de abas verticais, ordem de novas abas e seleção ao fechar abas listadas acima.
7. Fechar e abrir o Zen.

## Verificação

Checks feitos quando a configuração foi criada:

- XPI do Zen contém `manifest.json` e `background.js`.
- Manifest instalado declara `Tab Shifter 1.0.3`.
- Manifest instalado expõe só `move-up = Alt+Shift+K` e `move-down = Alt+Shift+J`.
- Zen headless carregou a extensão local como `active: true` em profile temporário.
- `user.js` do profile ativo real contém as prefs de nova aba no fim da lista e seleção ao fechar abas sem voltar para WhatsApp.
