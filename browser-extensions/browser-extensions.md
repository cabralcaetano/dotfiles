# Extensões de navegador — Ungoogled Chromium ativo, Zen/Brave preservados

> Ungoogled Chromium é o perfil Chromium enxuto atual para RAM/performance/privacidade. Zen e Brave ficam preservados para fallback/uso específico, mas deprecated como navegadores principais. Inventário levantado dos profiles reais quando documentado; não apagar configs antigas. Setup completo do Ungoogled Chromium em [`../docs/ungoogled-chromium.md`](../docs/ungoogled-chromium.md).

---

## Ungoogled Chromium (ativo/enxuto)

| Extensão | ID | Função |
|---|---|---|
| **Bitwarden Password Manager** | `nngceckbapebfimnlniiiahkandclblb` | Gerenciador de senhas/passkeys. |
| **uBlock Origin** | `cjpalhdlnbpafiamejdnhcphjbkeiagm` | Bloqueio de ads/tracker com cosmetic filtering; preferir o normal ao `uBlock Origin Lite` quando disponível. |
| **Caetano Dashboard** | local/unpacked | Substitui a nova guia por painel local com clima, GitHub, navegação e estatísticas do NextDNS; fonte em [`chromium-dashboard/`](chromium-dashboard/). |
| **Vimium C** | `hfjbmagddngcpeloejdejnfgbamkjaeg` | Navegação por teclado (hints `f`, `J`/`K` entre abas, omnibar). ID conferido de memória; confirmar na Chrome Web Store ao instalar. Não funciona em `chrome://` nem na nova guia local. |

Instalar em máquina nova:

```bash
yay -S --needed ungoogled-chromium-bin chromium-extension-web-store
```

Depois abrir `chrome://extensions` e confirmar **Chromium Web Store** ativo. Se a Chrome Web Store bloquear `.crx`, abrir `chrome://flags/#extension-mime-request-handling`, escolher **Always prompt for install** e relançar.

Links:

```
https://chromewebstore.google.com/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb
https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
```

Dashboard local:

1. abrir `chrome://extensions`;
2. ativar **Modo do desenvolvedor**;
3. escolher **Carregar sem compactação**;
4. selecionar `~/Projects/dotfiles/browser-extensions/chromium-dashboard`;
5. abrir uma nova guia e, nas configurações do dashboard, informar cidade e credenciais da API do NextDNS.

A extensão solicita histórico e sites mais acessados para métricas locais. A API key do NextDNS fica em `chrome.storage.local` do próprio perfil; não entra nos dotfiles.

O dashboard mantém a linguagem TUI — tipografia monoespaçada, superfícies
planas, cantos retos e estados entre colchetes — mas replica os valores medidos
na UI do dark nativo do Chromium no perfil real:

- frame/background `#1f2020`;
- toolbar/cards `#3c3c3c`;
- bordas `#5a5a5a`;
- texto `#e3e3e3`;
- texto secundário `#89898c`.

Accents são semânticos: azul `#8ab4f8` identifica labels, navegação, foco e
ações; verde `#81c995` fica restrito a estados saudáveis/`ONLINE`; vermelho
`#f28b82` aparece apenas em erros de validação. As superfícies continuam iguais
às cores medidas do Chromium. A busca interna foi removida; o omnibox nativo já
cobre essa função sem duplicar espaço.

No desktop, o shell ocupa exatamente `100vh` e o grid divide o espaço restante
em duas linhas iguais; a página não cria scroll vertical. Em largura de até
`860px`, volta ao fluxo de uma coluna com scroll normal para não cortar conteúdo.

O card **Agora** reúne saudação, hora, data e clima. O botão de configurações
também fica nesse card, eliminando o cabeçalho isolado.

O atalho **Favoritos** abre o gerenciador nativo `chrome://bookmarks/` na mesma
aba.

Tema do navegador: usar o **dark nativo do Chromium**. `Caetano Arch Black`
permanece apenas como fonte experimental preservada em
`chromium-black-theme/`; não carregar no perfil real.

---

## Zen Browser (perfil `fygd0cys.Default (release)`, deprecated como principal leve)

| Extensão | ID | Função |
|---|---|---|
| **uBlock Origin** | `uBlock0@raymondhill.net` | Bloqueio de ads/tracker no nível da página — cosmetic filtering e ads first-party (ex: YouTube) que bloqueio DNS não alcança. Ver comparação completa em [`../nextdns/nextdns.md`](../nextdns/nextdns.md) § "NextDNS vs uBlock Origin". |
| **SponsorBlock for YouTube - Skip Sponsorships** | `sponsorBlocker@ajay.app` | Pula automaticamente trechos de publi/patrocínio, autopromoção, "curte e se inscreve", intro/outro não-musical, preview/recap e promoção de produto externo dentro de vídeos do YouTube, usando a mesma base de dados crowdsourced que o YouTube Vanced/YouTube++ integravam. Funciona em `youtube.com` normal (não precisa de `m.youtube.com`). Categorias pulam por padrão conforme preset do addon; toggle individual por categoria no ícone da extensão. |
| **Unhook - Remove YouTube Recommended & Shorts** | `myallychou@gmail.com` | Remove recomendados, Shorts e outras distrações da UI do YouTube. |
| **Bitwarden Password Manager** | `{446900e4-71c2-419f-a6a7-df9c091e268b}` | Gerenciador de senhas. Abre flutuante 1000×800 centralizado via window rule do Hyprland (`hyprland.lua`). |
| **Tab Shifter** | `omp-tab-mover@caetano.local` | Extensão local, própria — move abas verticais com `Alt+Shift+J/K`. Documentação completa (manifest, permissões, comportamento de nova aba) em [`../docs/browser-tab-shifter.md`](../docs/browser-tab-shifter.md); fonte em `../scripts/.local/share/zen-tab-mover/`. |

Instalar em máquina nova (Mozilla Add-ons, exceto Tab Shifter que é local):

```
https://addons.mozilla.org/firefox/addon/ublock-origin/
https://addons.mozilla.org/firefox/addon/sponsorblock/
https://addons.mozilla.org/firefox/addon/youtube-recommended-videos/   # Unhook
https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/
```

Tab Shifter: `stow --target="$HOME" scripts` (instala o XPI local) — ver `docs/browser-tab-shifter.md` pro passo de carregar como extensão temporária/permanente no Zen.

---

## Brave (perfil `Default`, deprecated como navegador principal; uso manual/dev/fallback)

| Extensão | ID | Função |
|---|---|---|
| **Claude** | `fcoeoabgfenejglbffodgkkbkcdhcgfn` | Extensão oficial Anthropic — Claude no navegador. |
| **Obsidian Web Clipper** | `cnjifjpddelmedmihgijeibhnjfabmlf` | Clip de página/artigo direto pro vault Obsidian. |
| **React Developer Tools** | `fmkadmapgofadopljbjfkapdkoienihi` | Inspeção de árvore de componentes React — uso de desenvolvimento. |
| **Bitwarden Gerenciador de Senhas** | `nngceckbapebfimnlniiiahkandclblb` | Mesmo gerenciador de senhas do Zen, perfil separado do Brave. |
| **Quick Tabs** | `jnjfeinjfmenlddahdjdmgpbokiacbbb` | Busca/troca rápida de abas abertas. |
| **Video Download Helper** | `lmjnegcaeklhafolokijcfjliaokphfk` | Download de vídeo embutido em página. |
| **Udemy Dark Theme** | `kkcgdamhkijlpibacnelakenbkejjidm` | Tema escuro pro player da Udemy. |

> Extensões de tab-mover do Brave (`browser-tab-mover`, nativa) documentadas junto com o Tab Shifter do Zen em `docs/browser-tab-shifter.md`, não repetido aqui.

Instalar em máquina nova (Chrome Web Store, compatível com Brave):

```
https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn
https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf
https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi
https://chromewebstore.google.com/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb
https://chromewebstore.google.com/detail/quick-tabs/jnjfeinjfmenlddahdjdmgpbokiacbbb
https://chromewebstore.google.com/detail/video-download-helper/lmjnegcaeklhafolokijcfjliaokphfk
https://chromewebstore.google.com/detail/udemy-dark-theme/kkcgdamhkijlpibacnelakenbkejjidm
```

---

## Por que não uma extensão só cobre tudo

- **uBlock Origin** cobre ad/tracker na página; **SponsorBlock** cobre trecho patrocinado *dentro* do vídeo (problema diferente — o vídeo carrega normal, só pula o segmento marcado); **Unhook** cobre ruído de UI (recomendados/Shorts) que não é ad nem tracker. Os três resolvem camadas diferentes do mesmo objetivo geral ("YouTube sem lixo").
- **NextDNS** (ver [`../nextdns/nextdns.md`](../nextdns/nextdns.md)) atua numa camada anterior a tudo isso — bloqueio por domínio, na rede toda, antes até do navegador entrar em cena. Não substitui nenhuma das extensões acima.
