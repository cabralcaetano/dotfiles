# Network — DNS e troubleshooting

Configuração de rede fora do stow (NetworkManager, DNS). Este documento existe para reproduzir a config numa máquina nova e para diagnosticar problemas recorrentes.

> **Estado atual (2026-09-17):** o `nextdns.service` gerencia `/etc/resolv.conf` (`nameserver 127.0.0.1`, proxy DoH) e todos os seis perfis Wi-Fi salvos no NetworkManager usam DNS automático, sem servidores IPv4/IPv6 manuais. Ver [`nextdns/nextdns.md`](../nextdns/nextdns.md).

---

## 1. DNS — política atual e histórico do provedor

### O problema (2026-07-11)

Sintoma: sites intermitentemente inacessíveis no browser (`DNS_PROBE_POSSIBLE` no Brave), enquanto a conexão em si funcionava (`ping 1.1.1.1` OK).

Diagnóstico: os dois servidores DNS entregues pelo DHCP do provedor (`177.184.73.32` e `177.184.73.33`, rede "TAPI WIFI -GIULIBROW 5G") estavam com **timeout em 100% das queries**. Como os dois pertencem ao mesmo provedor, caíram juntos — zero redundância real. Algumas resoluções ainda passavam via o resolver IPv6 do roteador (`fe80::1`) e cache, por isso o sintoma era intermitente e não uma queda total.

Como testar cada nameserver individualmente (sem `dig`/`nslookup` instalados):

```bash
# conectividade bruta (descarta problema de rota)
ping -c 2 1.1.1.1

# ver quais DNS estão em uso
nmcli dev show | grep DNS
cat /etc/resolv.conf

# query DNS manual contra um servidor específico (python puro)
python3 -c "
import socket, struct, random
q = struct.pack('>HHHHHH', random.randint(0,65535), 0x0100, 1, 0, 0, 0)
for p in 'www.hostinger.com'.split('.'): q += bytes([len(p)]) + p.encode()
q += b'\x00' + struct.pack('>HH', 1, 1)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.settimeout(3)
s.sendto(q, ('177.184.73.32', 53))
print(s.recvfrom(512))"
```

### Política atual — NextDNS + DNS automático no NetworkManager (2026-09-17)

Com o cliente NextDNS instalado no host, os perfis do NetworkManager não devem fixar Cloudflare, Google ou outro resolvedor:

- `ipv4.dns` e `ipv6.dns`: vazios;
- `ipv4.ignore-auto-dns` e `ipv6.ignore-auto-dns`: `no`;
- método IPv4/IPv6: automático.

O DNS entregue pelo DHCP ainda aparece em `nmcli device show`, mas não é o resolvedor usado pelas aplicações: `/etc/resolv.conf` aponta para `127.0.0.1`, onde o NextDNS recebe DNS53 e encaminha por DoH para o profile `932497`.

DNS manual no perfil também não funciona como fallback se o daemon NextDNS cair, pois `/etc/resolv.conf` continua apontando para localhost. A recuperação deliberada é `sudo nextdns deactivate`, que devolve o controle ao NetworkManager; nesse caso ele volta a usar o DNS automático da rede.

Para limpar um perfil legado:

```bash
nmcli connection modify "<perfil>" \
  ipv4.dns "" ipv4.ignore-auto-dns no \
  ipv6.dns "" ipv6.ignore-auto-dns no
nmcli device reapply wlan0  # somente se esse perfil estiver ativo
```

Verificação do estado efetivo:

```bash
nextdns status              # running
cat /etc/resolv.conf        # nameserver 127.0.0.1
getent ahosts example.com   # resolução IPv4/IPv6 funcionando
```

### Solução histórica — DNS público fixado (2026-07-11 a 2026-09-17)

Antes da adoção do NextDNS, a solução para o DNS defeituoso do provedor foi ignorar o DNS do DHCP e fixar servidores públicos por conexão. O par passou de `1.1.1.1`/`1.0.0.1` para `1.1.1.1`/`8.8.8.8` após o incidente de rota descrito abaixo. Essa configuração foi removida de todos os perfis Wi-Fi em 2026-09-17 e não deve ser recriada enquanto o NextDNS estiver ativo.

| Par histórico | Vantagem | Desvantagem |
|---|---|---|
| `1.1.1.1` + `8.8.8.8` | Redundância entre provedores | Fallback Google com política/respostas diferentes |
| `1.1.1.1` + `1.0.0.1` | Consistência e privacidade uniforme | Mesmo provedor: pane/rota ruim derruba os dois |
| `9.9.9.9` (Quad9) | Bloqueia malware/phishing no resolver | Latência um pouco maior no BR |

### O problema (2026-07-21) — perda de pacotes específica ao Cloudflare

Sintoma: "internet lenta" de forma ampla (não um site específico), mesmo com wifi 5G forte (sinal 94/100, link 1170 Mbit/s) e gateway respondendo normal.

Diagnóstico: `ping -c 10 1.1.1.1` mostrou **30–50% de perda de pacotes**, enquanto `ping` ao gateway (`192.168.100.1`) e a `8.8.8.8` deu **0% de perda** nos dois. Ou seja, não era wifi nem roteador — era a rota do provedor até a rede do Cloudflare especificamente, degradada naquele momento. Como o DNS primário era `1.1.1.1`, toda resolução de DNS (e qualquer site atrás da CDN do Cloudflare) ficava lenta/engasgada, o que se manifesta como "internet lenta" em geral.

```bash
# isolar o destino problemático
ping -c 10 1.1.1.1                          # comparar % de perda
GW=$(ip route | grep default | awk '{print $3}')
ping -c 6 "$GW"                              # deve ser 0% — descarta wifi/roteador
ping -c 6 8.8.8.8                            # comparar com outro provedor

# teste de download real (não só ping)
curl -o /dev/null -s -w "%{time_total}s | %{speed_download} B/s\n" \
  "https://speed.cloudflare.com/__down?bytes=25000000" --max-time 15
```

Solução aplicada na época: trocar o par manual para `1.1.1.1`/`8.8.8.8`. Esse workaround foi aposentado com o NextDNS e removido de todos os perfis Wi-Fi em 2026-09-17; hoje o diagnóstico continua útil para distinguir problema de rota, mas não é motivo para recriar DNS manual no NetworkManager.

> Se o padrão se repetir (perda de pacotes isolada a um destino específico, resto da rede limpo), é sinal de problema de peering/rota do provedor até aquele destino, não da rede local. Vale reavaliar o par de DNS ou reportar ao provedor se persistir.

---

## 2. Tailscale — DNS hijack com sessão deslogada

Achado no mesmo diagnóstico: o Tailscale estava **deslogado** mas com `Tailscale DNS: enabled` (`dns=true` nas prefs). Nesse estado ele não aplicava config nenhuma (`OScfg: {}`), mas ao tentar reconectar pode assumir o controle do DNS sem conseguir resolver nada.

Se o Tailscale não estiver em uso ativo com MagicDNS:

```bash
sudo tailscale set --accept-dns=false
tailscale dns status   # conferir: "Tailscale DNS: disabled"
```

> `tailscale set` exige root por padrão. Para dispensar o `sudo` nos comandos do dia a dia:
> `sudo tailscale set --operator=$USER` (uma vez só).

### Boot — habilitar `tailscaled` no systemd

Instalar o pacote não habilita o serviço automaticamente; ele fica `active` na sessão atual mas `disabled` no boot até habilitar explicitamente:

```bash
systemctl is-enabled tailscaled   # disabled == não sobrevive a reboot
sudo systemctl enable tailscaled  # symlink em multi-user.target.wants/
```

Verificar depois de um reboot: `systemctl is-active tailscaled` deve voltar `active` sem intervenção manual.
