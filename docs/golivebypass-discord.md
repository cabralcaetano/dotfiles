# GoLiveBypass — Discord Go Live no Brasil

**Status:** ativo desde 2026-09-06.
**Escopo:** Arch Linux + Hyprland + Discord desktop.
**Objetivo:** restaurar Go Live/câmera do Discord para conta brasileira sem rotear o sistema inteiro por VPN.

---

## Decisão

Usar `bezumiya/GoLiveBypass` via AppImage GUI.

Motivo:

- é o fork/repo mais ativo entre os avaliados;
- possui release Linux AppImage;
- usa WireGuard com network namespace no Linux, então só o processo do Discord entra no túnel;
- não exige instalar o app Proton VPN oficial;
- aceita arquivo WireGuard `.conf` customizado, evitando o login Proton embutido quando ele trava.

Versão instalada:

| Item | Valor |
|---|---|
| Repo | `https://github.com/bezumiya/GoLiveBypass` |
| Release | `v2.0.4` |
| AppImage | `~/Applications/GoLiveBypass-2.0.4.AppImage` |
| Symlink estável | `~/Applications/GoLiveBypass.AppImage` |
| SHA-256 verificado | `db046ce8cce21445e385203f29b752e7a9aab1dcd350149f0a36bb8e02968c7d` |
| Modo usado | `Arquivo .conf` |
| Config Proton criada | `golivebypass3` |
| Servidor Proton | `US-FREE#65` |

---

## Arquivos locais

| Caminho | Conteúdo | Versionar? |
|---|---|---|
| `~/Applications/GoLiveBypass-2.0.4.AppImage` | binário baixado da release | não |
| `~/Applications/GoLiveBypass.AppImage` | symlink estável para a versão atual | não |
| `~/.local/bin/golivebypass` | wrapper estável do launcher | sim, em `scripts/.local/bin/golivebypass` |
| `~/.local/share/applications/golivebypass.desktop` | entrada do menu | sim, em `desktop-apps/.local/share/applications/golivebypass.desktop` |
| `~/.local/share/GoLiveBypass/settings.json` | preferências locais do app | não |
| `~/.local/share/GoLiveBypass/wireguard.conf` | config WireGuard com `PrivateKey` | nunca |
| `~/.local/share/GoLiveBypass/logs/` | logs do app | não |

`wireguard.conf` contém chave privada. Nunca copiar para o repo, gist, issue, chat ou screenshot.

---

## Dependências Arch

Pacotes necessários:

```bash
sudo pacman -S --needed wireguard-tools iproute2 curl
```

O estado verificado em 2026-09-06:

- `wireguard-tools`: instalado (`wg` disponível);
- `iproute2`: instalado (`ip` disponível);
- `curl`: instalado;
- GoLiveBypass preflight: `ok=true`, `elevation=sudo`, `netns=true`, Discord detectado.

`wireguard-tools` foi adicionado ao manifesto `packages/pacman.txt` junto dos utilitários de rede usados pelo app.

---

## Instalação da AppImage

Baixar o asset da release `v2.0.4`, dar permissão de execução e criar symlink estável:

```bash
mkdir -p "$HOME/Applications"
curl -L --fail --show-error \
  -o "$HOME/Applications/GoLiveBypass-2.0.4.AppImage" \
  "https://github.com/bezumiya/GoLiveBypass/releases/download/v2.0.4/GoLiveBypass-2.0.4.AppImage"
chmod +x "$HOME/Applications/GoLiveBypass-2.0.4.AppImage"
ln -sf "$HOME/Applications/GoLiveBypass-2.0.4.AppImage" "$HOME/Applications/GoLiveBypass.AppImage"
printf '%s  %s\n' \
  'db046ce8cce21445e385203f29b752e7a9aab1dcd350149f0a36bb8e02968c7d' \
  "$HOME/Applications/GoLiveBypass-2.0.4.AppImage" | sha256sum -c -
```

Smoke test sem abrir UI:

```bash
~/Applications/GoLiveBypass.AppImage --appimage-help
```

---

## Launcher

O `.desktop` não chama a AppImage diretamente. Ele chama o wrapper `~/.local/bin/golivebypass`.

Razão: quando o AppImage é iniciado por launcher/Hyprland e o stdout/stderr fecha, o Electron pode tentar escrever logs no pipe morto e cair com:

```text
A JavaScript error occurred in the main process
Uncaught Exception: Error: write EPIPE
```

O wrapper redireciona stdout/stderr para:

```text
~/.local/share/GoLiveBypass/logs/appimage-stdio.log
```

Aplicar launcher via Stow:

```bash
cd ~/Projects/dotfiles
stow --target="$HOME" scripts desktop-apps
update-desktop-database ~/.local/share/applications || true
```

---

## Config WireGuard pela Proton

O login Proton embutido do app travou em `Conectando...` após `iniciando autenticação ProtonVPN`. O caminho estável foi gerar o `.conf` pelo site da Proton e importar/instalar no GoLiveBypass.

Fluxo usado:

1. Abrir `https://account.protonvpn.com/downloads`.
2. Ir em **Configuração do WireGuard**.
3. Nomear a config como `golivebypass3`.
4. Selecionar **GNU/Linux**.
5. Manter **VPN Accelerator** ligado.
6. Criar config no servidor recomendado fora do Brasil.
7. Baixar o arquivo `.conf`.
8. Instalar como:

```bash
install -m 600 ~/Downloads/golivebypass3-US-FREE-65.conf ~/.local/share/GoLiveBypass/wireguard.conf
```

Validação mínima do arquivo:

```bash
grep -E '^\[(Interface|Peer)\]|^Address\s*=|^Endpoint\s*=|^AllowedIPs\s*=' ~/.local/share/GoLiveBypass/wireguard.conf
stat -c '%a %s %n' ~/.local/share/GoLiveBypass/wireguard.conf
```

Esperado:

- seções `[Interface]` e `[Peer]` presentes;
- `PrivateKey`, `Address`, `DNS`, `PublicKey`, `AllowedIPs`, `Endpoint` presentes;
- permissão `600`.

Depois remover o `.conf` baixado de `Downloads` se não precisar manter cópia local.

---

## Config do GoLiveBypass

Arquivo local de preferências:

```json
{
  "routeMode": "wireguard",
  "autoRevive": true,
  "vpnMode": "custom"
}
```

Caminho real:

```text
~/.local/share/GoLiveBypass/settings.json
```

`vpnMode=custom` força o modo **Arquivo .conf** e evita o login Proton interno.

---

## Uso

1. Abrir **GoLiveBypass** pelo launcher.
2. Confirmar que está na aba **Arquivo .conf**.
3. Confirmar que o botão principal está como **Ativar**.
4. Clicar **Ativar**.
5. Autorizar `sudo`/`pkexec` quando pedir.
6. O app deve fechar/reabrir o Discord dentro do namespace WireGuard.

O app detectou nesta máquina:

- Discord oficial em `~/.config/discord/app-1.0.156/resources`;
- Vesktop em `/usr/lib/vesktop/resources`;
- Vesktop em `/usr/lib64/vesktop/resources`.

---

## O que ele faz no Linux

O mecanismo Linux usa:

- network namespace chamado `discord-vpn`;
- interface WireGuard `wg-discord`;
- execução do Discord dentro do namespace;
- host continua fora da VPN.

Invariante operacional: não ligar VPN global do sistema para resolver Go Live. O túnel deve ser por processo/namespace.

---

## Segurança operacional

- O `.conf` da Proton dá acesso ao túnel daquela configuração. Tratar como segredo.
- Revogar no site da Proton qualquer config gerada por engano ou exposta em screenshot/log.
- Não colar `PrivateKey` em issue pública.
- Não commitar `~/.local/share/GoLiveBypass/`.
- Se trocar de servidor, gerar novo `.conf`, substituir `wireguard.conf` e revogar o antigo quando confirmar que o novo funciona.

Config ativa esperada no site da Proton:

- manter: `golivebypass3`;
- revogar configs antigas/teste: `golivebypass`, `golivebypass2`.

---

## Troubleshooting

### App travado em `Conectando...` no login Proton

Decisão: não usar login embutido. Gerar WireGuard `.conf` pelo site da Proton e usar modo **Arquivo .conf**.

### Erro Electron `write EPIPE`

Causa: stdout/stderr fechado pelo launcher.
Fix: usar wrapper `~/.local/bin/golivebypass` com redirecionamento para log.

### Botão continua em `Selecione uma Configuração`

Checar:

```bash
test -s ~/.local/share/GoLiveBypass/wireguard.conf
stat -c '%a %s %n' ~/.local/share/GoLiveBypass/wireguard.conf
cat ~/.local/share/GoLiveBypass/settings.json
```

Esperado: `vpnMode` deve ser `custom` e o `.conf` deve existir.

### Discord fica carregando mensagens infinito

Provável túnel/servidor Proton ruim ou saturado.

Ações:

1. Desativar no GoLiveBypass.
2. Gerar novo `.conf` com outro servidor fora do Brasil.
3. Substituir `~/.local/share/GoLiveBypass/wireguard.conf`.
4. Ativar novamente.

### Checar se há processo/túnel sobrando

```bash
pgrep -af 'GoLiveBypass|golive-gui|discord-vpn|wg-discord' || true
ip netns list
```

Se o app falhar no encerramento, fechar pela UI primeiro. Evitar apagar namespace manualmente se não souber se o Discord está usando o túnel.

---

## Verificações realizadas

Em 2026-09-06:

- AppImage baixado da release `v2.0.4`;
- SHA-256 conferido com sucesso;
- `wireguard-tools`, `iproute2`, `curl` presentes;
- AppImage respondeu `--appimage-help`;
- launcher corrigido e reaberto sem `write EPIPE`;
- arquivo WireGuard Proton `golivebypass3` instalado em `~/.local/share/GoLiveBypass/wireguard.conf`;
- GoLiveBypass funcionando segundo teste manual do usuário.
