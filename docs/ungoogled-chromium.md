# Ungoogled Chromium — navegador leve/privado

**Status:** ativo para o perfil Chromium enxuto. Configurações dos navegadores anteriores ficam preservadas, mas **deprecated** para uso como navegador principal.

## Decisão

Usar `ungoogled-chromium-bin` como opção Chromium principal quando a prioridade for RAM/performance + privacidade, mantendo compatibilidade de sites modernos.

Motivo:

- base Blink/V8 do Chromium: boa responsividade e compatibilidade;
- sem Sync/login/serviços Google embutidos;
- menos camadas extras que Brave/Edge/Vivaldi;
- menos customização visual/produtiva que Zen, logo menor superfície para peso extra;
- poucas extensões reduzem RAM, CPU e superfície de ataque.

Tradeoff aceito:

- Chrome Web Store não funciona nativamente;
- sem Google Sync;
- updates dependem do pacote AUR/binário acompanhar o Chromium upstream;
- alguns recursos Google/DRM/tradução/safe-browsing podem exigir ajuste manual ou outro navegador.

## Pacotes

A fonte reproduzível fica em `packages/aur.txt`:

```bash
yay -S --needed ungoogled-chromium-bin chromium-extension-web-store
```

- `ungoogled-chromium-bin`: build binária; evita compilar Chromium localmente.
- `chromium-extension-web-store`: helper que libera instalação pela Chrome Web Store em Chromium/ungoogled Chromium.

`chromium` do repo oficial permanece listado em `packages/pacman.txt` como fallback/deprecated. Não remover configs de Firefox/Zen/Brave/Chrome: elas continuam úteis para fallback, dev, Meet, sites quebrados ou comparação.

## Extensões ativas recomendadas

Manter mínimo:

| Extensão | ID | Motivo |
|---|---|---|
| Bitwarden Password Manager | `nngceckbapebfimnlniiiahkandclblb` | Senhas/passkeys. |
| uBlock Origin | `cjpalhdlnbpafiamejdnhcphjbkeiagm` | Bloqueio de ads/tracker com cosmetic filtering. |
| Caetano Dashboard | local/unpacked | Nova guia local com dados úteis do navegador, GitHub, clima e NextDNS. |
| Caetano Arch Black | local/unpacked | Tema preto para frame, abas, toolbar e omnibox. |

Opcional:

| Extensão | ID | Motivo |
|---|---|---|
| ClearURLs | `lckanjgmijmafbedllaakclkaicjfmnk` | Remove parâmetros de tracking em URLs. Só instalar se necessário. |
| uBlock Origin Lite | `ddkjiahejlhfcafbddmgiahcphecmpfh` | Fallback Manifest V3; preferir uBlock Origin normal quando disponível. |

Não instalar extensões “por conveniência” se não forem usadas. Extensão também consome RAM, roda código e aumenta superfície de ataque.

## Instalação da Chrome Web Store

Sintoma antes do helper:

> Mude para o Chrome para instalar extensões e temas

ou botão `Usar no Chrome` bloqueado.

Passos:

1. Instalar o helper:

   ```bash
   yay -S --needed chromium-extension-web-store
   ```

2. Fechar todas as janelas do `ungoogled-chromium`.
3. Abrir de novo.
4. Verificar em `chrome://extensions` se **Chromium Web Store** está ativo.
5. Abrir `chrome://flags/#extension-mime-request-handling`.
6. Definir **Extension MIME request handling** como **Always prompt for install**.
7. Clicar em **Relaunch**.
8. Voltar na Chrome Web Store e instalar Bitwarden/uBlock.

## Erro: “Não é possível adicionar extensões e apps deste site”

Causa provável: o Chromium não está tratando `.crx` baixado da Web Store como instalação interativa.

Fix:

```text
chrome://flags/#extension-mime-request-handling
→ Always prompt for install
→ Relaunch
```

Depois repetir a instalação pela Web Store.

## Página `support.9oo91e.qjz9zk` bloqueada

Sintoma observado:

```text
support.9oo91e.qjz9zk está bloqueado
ERR_BLOCKED_BY_CLIENT
```

Esse domínio é usado pelo helper **Chromium Web Store** como página interna/fake de suporte/aviso. Não é navegação normal.

Se ele for bloqueado por DNS/adblock:

1. confirmar que `chromium-extension-web-store` está ativo;
2. desativar temporariamente DNS/adblock que bloqueie esse host, se necessário;
3. instalar a extensão desejada;
4. reativar o bloqueio depois.

## Updates e critério de segurança

Browser desatualizado é risco maior que telemetria. O fluxo do ungoogled Chromium tem um passo a mais:

1. Chromium upstream lança versão nova;
2. ungoogled Chromium adapta/aplica patches;
3. maintainer do AUR/binário publica pacote;
4. máquina atualiza via `yay -Syu`.

Critério operacional:

- atraso de 1–3 dias em relação ao Chromium estável: aceitável;
- atraso de uma semana: ruim para navegador principal;
- atraso de várias semanas: parar de usar como principal e voltar para Chromium/Brave/Firefox até normalizar.

Verificar versão local:

```bash
ungoogled-chromium --version
```

Comparar com a versão estável publicada do Chromium/Chrome quando houver suspeita de atraso.

## Configuração recomendada

Em `chrome://settings`:

- desativar execução em segundo plano;
- desativar preload/pré-carregamento de páginas se a meta for economia de RAM/rede;
- revisar permissões de câmera/microfone/localização;
- manter poucas extensões;
- não ativar sync Google — o navegador não foi escolhido para isso.

Em `chrome://extensions`:

- ativar Bitwarden, uBlock, Dashboard e Caetano Arch Black; remover extensões não usadas;
- revisar permissões por site quando possível.

## Dashboard da nova guia

Fonte versionada:

```text
browser-extensions/chromium-dashboard/
```

Carregar como extensão sem compactação em `chrome://extensions`. Ela substitui
`chrome://newtab/`. A inicialização usa `RestoreOnStartup=1` em
`system/etc/chromium/policies/managed/startup-homepage.json` — restaura a
sessão real (abas que estavam de fato abertas), sem lista fixa de URLs.

O card NextDNS usa a API oficial `https://api.nextdns.io`, perfil `932497` e uma
API key informada dentro do dashboard. A chave é salva somente no
`chrome.storage.local` da extensão e não deve ser versionada.


Tema local complementar:

```text
browser-extensions/chromium-black-theme/
```

Carregar sem compactação aplica a paleta preta imediatamente, sem alterar o
dashboard. Dashboard e tema são extensões separadas para evitar acoplar UI do
navegador ao conteúdo da nova guia.

## Ocultar ícone de instalar app/PWA na barra

O ícone de “instalar app” no omnibox aparece quando o site expõe um manifest PWA
válido. Nas versões atuais do Chromium não há uma flag confiável para só esconder
esse botão. A opção suportada é policy corporativa:

```json
{
  "WebAppInstallByUserEnabled": false
}
```

Tradeoff: não é apenas cosmético. A policy desativa instalação manual de PWA/web
app pelo usuário e remove/bloqueia o affordance normal de instalação na UI.
PWAs já instalados não são necessariamente removidos, e `WebAppInstallForceList`
continuaria funcionando se algum dia for usado.

Arquivo versionado:

```text
system/etc/chromium/policies/managed/pwa-install.json
```

Aplicação manual:

```bash
sudo install -d -m 755 /etc/chromium/policies/managed
sudo install -Dm644 system/etc/chromium/policies/managed/pwa-install.json /etc/chromium/policies/managed/pwa-install.json
```

Depois fechar todo Chromium, abrir de novo e verificar em:

```text
chrome://policy
```

Policy esperada:

```text
WebAppInstallByUserEnabled = false
```


## Status dos outros navegadores

Não apagar configs. Só mudar o status operacional:

| Navegador | Status | Uso atual |
|---|---|---|
| Ungoogled Chromium | ativo/enxuto | Navegação Chromium com foco em RAM/performance/privacidade. |
| Chromium repo oficial | deprecated/fallback | Fallback rápido se ungoogled atrasar updates ou quebrar extensão/site. |
| Brave | deprecated como principal | Manter para perfil antigo, dev pontual e fallback Chromium com Shields. |
| Zen Browser | deprecated como principal leve | Manter configs, Meet/câmera/mic e workflow antigo; não é opção mais leve. |
| Firefox | fallback Gecko | Útil para testar engine diferente e sites que quebrem no Chromium. |
| Google Chrome Flatpak | deprecated | Manter só se algum serviço exigir Chrome oficial. |

## Princípio

O objetivo não é “um browser perfeito”. É um browser principal enxuto:

- poucos processos extras;
- poucas extensões;
- sem camada Google automática;
- update monitorado;
- fallbacks preservados sem apagar histórico/configs.
