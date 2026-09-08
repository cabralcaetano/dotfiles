# Extensões de navegador — Zen (principal) e Brave (secundário)

> Zen Browser é o navegador padrão do sistema (ver `README.md` § Estrutura do repo). Brave fica só pra uso manual/pontual — hoje principalmente pra tarefas de dev (Claude, React DevTools) e Web Clipper do Obsidian. Inventário abaixo levantado direto dos profiles reais (`~/.config/zen/*/extensions.json` e `~/.config/BraveSoftware/Brave-Browser/Default/Preferences`), não é uma lista de intenção.

---

## Zen Browser (perfil `fygd0cys.Default (release)`)

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

## Brave (perfil `Default`, uso manual/dev)

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
