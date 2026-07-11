# Network — DNS e troubleshooting

Configuração de rede fora do stow (NetworkManager, DNS). Este documento existe para reproduzir a config numa máquina nova e para diagnosticar problemas recorrentes.

---

## 1. DNS — não usar o DNS do provedor

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

### A solução

Fixar DNS público na conexão e ignorar o DNS do DHCP:

```bash
nmcli connection modify "TAPI WIFI -GIULIBROW 5G" \
  ipv4.dns "1.1.1.1 1.0.0.1" ipv4.ignore-auto-dns yes \
  ipv6.dns "2606:4700:4700::1111 2606:4700:4700::1001" ipv6.ignore-auto-dns yes
nmcli connection up "TAPI WIFI -GIULIBROW 5G"
```

> A config é **por conexão**. Em outra rede Wi-Fi com o mesmo problema, repetir trocando o nome da conexão (`nmcli connection show` lista todas).

Verificar depois:

```bash
cat /etc/resolv.conf   # deve mostrar 1.1.1.1 e 1.0.0.1
```

### Escolha dos servidores

Em uso: **`1.1.1.1` + `1.0.0.1`** — par oficial do Cloudflare. Mais rápido testado desta rede (~10ms), política de privacidade forte (logs descartados em 24h), comportamento 100% consistente entre primário e secundário.

Alternativa documentada: **`1.1.1.1` + `8.8.8.8`** (Cloudflare + Google) — mistura dois provedores independentes, então uma pane global do Cloudflare (raro, mas já ocorreu) não derruba o DNS inteiro. Custo: fallback com política de privacidade diferente e respostas de CDN ocasionalmente distintas. Trocar para este par se o episódio "os dois DNS caíram juntos" se repetir com o Cloudflare.

| Par | Vantagem | Desvantagem |
|---|---|---|
| `1.1.1.1` + `1.0.0.1` (atual) | Consistência, privacidade uniforme | Mesmo provedor: pane global derruba os dois |
| `1.1.1.1` + `8.8.8.8` | Redundância real entre provedores | Fallback Google com política/respostas diferentes |
| `9.9.9.9` (Quad9) | Bloqueia malware/phishing no resolver | Latência um pouco maior no BR |

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
