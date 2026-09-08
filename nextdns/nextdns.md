# NextDNS — DNS criptografado + filtro por dispositivo (Linux + iPhone)

> Resolver DNS-over-HTTPS na nuvem, usado neste notebook (Arch Linux) e no iPhone via o mesmo profile. Complementa — não substitui — o plano de [AdGuard Home self-hosted](../../wiki-ia/personal/projects/home-network/_home-network.md) da rede de casa: AdGuard Home vai cobrir todos os dispositivos *dentro* da rede quando o homelab existir; NextDNS cobre este notebook e o iPhone em qualquer rede, inclusive fora de casa, e já funciona hoje sem depender de hardware novo.

**Profile:** `932497` (conta `caetano29cabral@gmail.com`, dashboard em `my.nextdns.io/932497`)
**Dispositivos linkados:** notebook Arch (`archlinux`, via CLI) + iPhone (via app oficial)

---

## 1. Por que NextDNS (e não só Pi-hole/AdGuard Home)

Pi-hole e AdGuard Home só protegem dispositivos *dentro* da rede onde rodam — não servem pra um notebook que sai de casa. Servidores DNS públicos simples (`1.1.1.1`, `9.9.9.9`) não têm bloqueio de ads/tracker nem dashboard de análise. NextDNS resolve especificamente o caso "dispositivo móvel, sem homelab ainda":

| Opção | Escopo | Por que não serve (ou serve) aqui |
|---|---|---|
| AdGuard Home / Pi-hole | Só a rede onde roda | Preso à rede local — não cobre o notebook fora de casa. É o plano definitivo pra rede de casa, mas ortogonal a este setup |
| Quad9 / Cloudflare puro | Qualquer device | Só bloqueia malware, sem ads/tracker, sem dashboard, zero customização |
| ControlD | Qualquer device | Concorrente quase idêntico ao NextDNS; troca é trivial (mesmo mecanismo, outro profile ID) se algum dia quiser migrar |
| **NextDNS** | Qualquer device | Free tier generoso (300k queries/mês), CLI oficial pro Arch/AUR, blocklists + analytics + DoH |

### NextDNS vs uBlock Origin — não são redundantes

NextDNS bloqueia por **domínio inteiro**, na rede toda (inclusive fora do navegador — apps do iPhone, telemetria de SO). Não faz *cosmetic filtering* (não esconde o espaço vazio de um ad) e não pega ads **first-party** — ex.: anúncios do YouTube vêm do mesmo domínio `googlevideo.com` do vídeo, DNS não consegue diferenciar. uBlock Origin filtra por padrão de URL dentro da página e esconde elementos via CSS, cobrindo exatamente esse caso. **Mantém os dois** — uBlock no navegador, NextDNS pra tudo mais.

---

## 2. Instalação (Arch Linux)

```bash
yay -S nextdns-bin
sudo nextdns install -profile 932497 -report-client-info
sudo nextdns activate
```

- `nextdns install` sobe o binário como serviço systemd (`nextdns.service`) escutando em `127.0.0.1:53`/`[::1]:53`, fazendo proxy DNS53 → DoH pro profile configurado.
- `-report-client-info` manda o hostname da máquina (`archlinux`) pro dashboard, pra identificar de qual device veio cada query nos Registros.
- `nextdns activate` reescreve `/etc/resolv.conf` pra apontar `nameserver 127.0.0.1` (com comentário `# This file is managed by nextdns.`), via hook no NetworkManager. Reverter com `sudo nextdns deactivate`.

### Config resultante — `/etc/nextdns.conf`

```
auto-activate true
bogus-priv true
cache-max-age 0s
cache-metrics false
cache-size 0
control /var/run/nextdns.sock
debug false
detect-captive-portals false
discovery-dns
hardened-privacy false
listen localhost:53
log-queries false
max-inflight-requests 256
max-ttl 0s
mdns all
profile 932497
report-client-info true
setup-router false
timeout 5s
use-hosts true
```

### Serviço systemd — `/etc/systemd/system/nextdns.service`

Instalado pelo pacote `nextdns-bin`, habilitado automaticamente (`WantedBy=multi-user.target`). Não precisa de unit customizada neste repo.

---

## 3. Verificação

```bash
systemctl status nextdns          # active (running), Listening on 127.0.0.1:53/[::1]:53
cat /etc/resolv.conf              # nameserver 127.0.0.1, comentário "managed by nextdns"
curl -sL https://test.nextdns.io/ # status ok, protocol DOH, deviceName do hostname
```

Resposta esperada do `test.nextdns.io`:

```json
{
  "status": "ok",
  "protocol": "DOH",
  "server": "anexia-rio-1",
  "clientName": "nextdns-cli",
  "deviceName": "archlinux",
  "deviceModel": "Arch Linux"
}
```

> O campo `"profile"` nessa resposta mostra um hash interno (`fp...`), não o ID literal `932497` — é assim que a API do teste anonimiza o profile na resposta pública; não indica erro. Conferir o profile real em `/etc/nextdns.conf` ou no dashboard (`my.nextdns.io/932497/logs`, que já mostra `archlinux`/`iPhone` como device de cada query).

---

## 4. Configuração do profile `932497` (dashboard)

Estado alvo depois de reproduzir em máquina nova — replicar manualmente em `my.nextdns.io/932497` (a API de config não é coberta por este repo, é feita pela UI).

### Segurança (`/932497/security`) — tudo ligado

| Proteção | Estado |
|---|---|
| Feeds de inteligência de ameaças | ON |
| Detecção de ameaças por IA (beta) | ON |
| Google Safe Browsing | ON |
| Proteção contra cryptojacking | ON |
| Proteção contra DNS rebinding | ON |
| Proteção contra ataques homográficos IDN | ON |
| Proteção contra typosquatting | ON |
| Proteção contra DGA (domain generation algorithms) | ON |
| Bloquear domínios recém-registrados (NRD, <30 dias) | **ON** — anti-phishing forte; risco de falso positivo baixo (só afeta produto/site lançado há <30 dias) |
| Bloquear nomes de host DNS dinâmicos (DDNS) | **ON** — sem impacto: nenhum domínio deste setup usa DDNS (`_home-network.md` usa domínio próprio via Contabo/EasyPanel) |
| Bloquear domínios estacionados (parked) | **ON** — zero valor legítimo |
| Bloquear material de abuso sexual infantil (Project Arachnid) | ON |
| Bloquear TLDs específicos | não configurado |

### Privacidade (`/932497/privacy`)

| Item | Estado |
|---|---|
| Lista de bloqueio NextDNS Ads & Trackers (80k+ itens) | Adicionada |
| Proteção contra rastreamento nativo — Apple (iOS/macOS/tvOS) | Adicionada |
| Bloquear rastreadores de terceiros disfarçados (CNAME cloaking) | ON |
| Permitir links de afiliados/rastreamento | OFF (padrão) |

> Segunda blocklist (ex: OISD Full) — avaliada e **não adicionada**: mais cobertura de ads/tracker, mas risco real de over-block em site legítimo. Decisão em aberto.

### Configurações (`/932497/settings`)

| Item | Estado | Motivo |
|---|---|---|
| Ativar registros (logs) | ON | Necessário pra debugar qualquer device |
| Registrar endereços IP dos clientes | **OFF** | Privacidade — identificação por device (`archlinux`/`iPhone`) já vem do `report-client-info`, independente do IP; log de domínio+device+timestamp continua intacto pra troubleshooting |
| Registrar domínios | ON | Necessário pra troubleshooting |
| Retenção de logs | **1 semana** (era 3 meses) | Reduz janela de dado sensível guardado em servidor de terceiro; 1 semana é de sobra pra investigar qualquer incidente recente |
| Local de armazenamento | Estados Unidos (padrão da conta) | — |
| Página de bloqueio | OFF | Responde `0.0.0.0`/`::` em vez de servir página de bloqueio própria — evita warning de certificado HTTPS em domínio bloqueado |
| Sub-rede de cliente EDNS anonimizada | ON | Acelera CDN sem expor IP real |
| Aprimoramento de cache (TTL mínimo) | ON | Reduz número de queries |
| Nivelamento CNAME | **ON** | Fecha brecha de rastreador escondido atrás de CNAME que a lista de "disguised trackers" não pega sozinha |
| Ignorar verificação de idade | OFF | Não relevante ao caso de uso |
| Web3 (ENS/IPFS/Handshake gateway) | OFF | Não relevante ao caso de uso |

---

## 5. iPhone

Configurado com o app oficial NextDNS (App Store), apontando pro mesmo profile `932497` — confirmado nos Registros do dashboard (entradas com device `iPhone`, ex: `scontent.fallback.cdninstagram.com`). Toda config de Segurança/Privacidade/Configurações acima vale pros dois dispositivos automaticamente, é por profile — não precisa duplicar nada no app do iPhone além de logar com o profile ID correto.

---

## 6. Troubleshooting

```bash
sudo nextdns deactivate    # reverte /etc/resolv.conf pro DNS anterior do NetworkManager
sudo nextdns activate      # reaplica
systemctl restart nextdns  # reinicia o proxy sem mexer no resolv.conf
journalctl -u nextdns -n 50 --no-pager   # logs do serviço (conexão DoH, troca de endpoint, etc)
```

Investigar um domínio específico (bloqueado sem saber por quê, ou suspeita de query não chegando): `my.nextdns.io/932497/logs`, filtra por device (`archlinux`/`iPhone`) e domínio — mostra lista/regra responsável pelo bloqueio.
