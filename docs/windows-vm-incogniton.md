# Windows VM — Incogniton / multilogin

Configuração operacional da VM Windows usada no Arch Linux para rodar Incogniton, Brave e ferramentas Windows isoladas.

Aplicado em: 2026-07-21 · Arch Linux · Hyprland/Wayland · KVM/QEMU/libvirt.

> Segurança: a VM usa Ghost Spectre por decisão operacional. Tratar como ambiente não confiável: não guardar senhas principais, seeds, chaves privadas, home inteira ou arquivos sensíveis. Habilitar clipboard/transferência de arquivos só quando necessário.

---

## 1. Estado final validado

### Host

Monitor interno:

```text
eDP-1: 1920x1200 @ 60 Hz
Scale: 1.25
Tamanho físico: 15"
```

Pacotes relevantes no Arch:

```bash
qemu-full
virt-manager
virt-viewer
libvirt
edk2-ovmf
dnsmasq
iptables
openbsd-netcat
spice-gtk
libisoburn     # fornece xorrisofs, usado para criar ISOs de transferência
swtpm          # opcional para Windows 11 com TPM emulado
```

Serviço libvirt:

```bash
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"   # requer logout/login
sudo virsh net-autostart default
sudo virsh net-start default
```

### VM libvirt

```text
Nome: win11
OS guest: Windows 11 Ghost Spectre / WIN11.PRO.25H2.U3-2.X64.(WPE)
Firmware: UEFI OVMF secure boot
Chipset: Q35
CPU: 4 vCPU, host-passthrough
RAM: 8 GiB
Disk: /var/lib/libvirt/images/win11.qcow2
Disk bus: SATA
Display: SPICE
Video: QXL, 64 MiB RAM/VRAM, 16 MiB VGA memory
SPICE channel: com.redhat.spice.0
Network final: QEMU user-mode networking, model virtio
```

Rede final:

```xml
<interface type='user'>
  <model type='virtio'/>
</interface>
```

Motivo: `default NAT` via `virbr0` funcionou parcialmente, mas conflitou com `nftables`/DNS/DHCP. `user-mode networking` eliminou a dependência de `virbr0`, `dnsmasq` e regras NAT do host para esta VM.

Verificação final dentro do Windows:

```cmd
ping 8.8.8.8
ping -4 google.com
```

Resultado validado: ambos com `0% loss`.

---

## 2. Criação / reprodução da VM

### 2.1 Base da VM

No `virt-manager`:

```text
Connection: qemu:///system
Install media: ISO do Windows/Ghost
OS: Windows 11
Memory: 8192 MiB
CPU: 4
Disk: 80 GiB qcow2
Customize before install: yes
```

Hardware recomendado:

```text
Overview:
  Chipset: Q35
  Firmware: UEFI x86_64 / OVMF

CPU:
  host-passthrough / Copy host CPU configuration

Disk:
  SATA para instalação simples

Display:
  SPICE

Video:
  QXL

Channel:
  spicevmc / com.redhat.spice.0
```

### 2.2 Network

Preferido para esta VM:

```text
NIC type: Usermode networking
Model: virtio
IP/DNS dentro do Windows: Automatic DHCP / Automatic DNS
```

Se a VM já existir com `default NAT`, converter para `user-mode`:

```bash
cat >/tmp/win11-user-nic.xml <<'EOF'
<interface type='user'>
  <model type='virtio'/>
</interface>
EOF

virsh -c qemu:///system detach-interface win11 network --mac <MAC-ANTIGO> --live --config
virsh -c qemu:///system attach-device win11 /tmp/win11-user-nic.xml --live --config
virsh -c qemu:///system reboot win11
```

> Na sessão original, a MAC antiga era `52:54:00:37:11:89`; a user-mode NIC criada ficou `52:54:00:0c:3e:ef`.

Depois da troca, remover config estática antiga dentro do Windows:

```cmd
netsh interface ipv4 set address name="Ethernet" source=dhcp
netsh interface ipv4 set dnsservers name="Ethernet" source=dhcp
ipconfig /release
ipconfig /renew
```

Se a interface não se chamar `Ethernet`:

```cmd
netsh interface show interface
```

---

## 3. ISOs e artefatos usados

Diretórios criados no host:

```text
~/ISOs/virtio-win.iso
~/Downloads/incogniton-vm/
~/Downloads/spice-vm/
```

Downloads:

```bash
# VirtIO drivers
curl -L --fail -o ~/ISOs/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

# Incogniton Windows v5
curl -L --fail -o ~/Downloads/incogniton-vm/incogniton-windows-v5.exe \
  https://incogniton.com/incognitondownloadwin5

# SPICE guest tools
curl -L --fail -o ~/Downloads/spice-vm/spice-guest-tools-latest.exe \
  https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe

# SPICE WebDAV daemon
curl -L --fail -o ~/Downloads/spice-vm/spice-webdavd-x64-latest.msi \
  https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi
```

ISOs de transferência:

```bash
xorrisofs -o ~/Downloads/incogniton-vm/incogniton-installer.iso \
  -J -R ~/Downloads/incogniton-vm/incogniton-windows-v5.exe

xorrisofs -o ~/Downloads/spice-vm/spice-tools-v2.iso \
  -J -R \
  ~/Downloads/spice-vm/spice-guest-tools-latest.exe \
  ~/Downloads/spice-vm/spice-webdavd-x64-latest.msi
```

Montar/trocar mídia na VM:

```bash
virsh -c qemu:///system change-media win11 sdb \
  ~/Downloads/incogniton-vm/incogniton-installer.iso \
  --live --config --force

virsh -c qemu:///system attach-disk win11 \
  ~/Downloads/spice-vm/spice-tools-v2.iso \
  sdd --type cdrom --mode readonly --live --config
```

Estado observado após montagem:

```text
sda -> /var/lib/libvirt/images/win11.qcow2
sdb -> incogniton-installer.iso ou spice-tools-v2.iso
sdc -> ~/ISOs/virtio-win.iso
sdd -> spice-tools-v2.iso
```

---

## 4. Drivers Windows

### 4.1 Network VirtIO

O instalador geral `virtio-win-guest-tools.exe` falhou no Ghost Spectre com erro MSI `0x80070643`. Instalação manual funcionou.

No Windows:

```text
Device Manager > Other devices > Ethernet Controller
Update driver > Browse my computer
CD virtio-win > NetKVM > w11 > amd64
```

Driver esperado:

```text
Red Hat VirtIO Ethernet Adapter
```

### 4.2 Vídeo QXL / resolução

Se `1920x1200` não aparecer, instalar o driver QXL/QXLDOD:

```cmd
for %d in (D E F G H) do @if exist %d:\qxldod\w11\amd64\qxldod.inf pnputil /add-driver %d:\qxldod\w11\amd64\qxldod.inf /install
```

Driver esperado em `Device Manager > Display adapters`:

```text
Red Hat QXL controller
```

Config de display usada:

```text
Resolution: 1920 x 1200
Scale: 125%
Refresh: padrão exposto pelo QXL/SPICE
```

> Em QXL/SPICE, `60 Hz` pode não aparecer. O refresh é virtual; fluidez vem mais de SPICE/QXL + viewer do que do valor mostrado pelo Windows.

### 4.3 SPICE clipboard / file transfer

Instalar dentro do Windows:

```cmd
for %d in (D E F G H) do @if exist %d:\spice-guest-tools-latest.exe start /wait %d:\spice-guest-tools-latest.exe
for %d in (D E F G H) do @if exist %d:\spice-webdavd-x64-latest.msi msiexec /i %d:\spice-webdavd-x64-latest.msi
shutdown /r /t 0
```

Efeitos esperados:

```text
spice-guest-tools: clipboard, resolução dinâmica, mouse melhor, SPICE agent
spice-webdavd: base para compartilhamento/transferência de arquivos via SPICE/WebDAV
```

Para drag-and-drop, preferir `virt-viewer`:

```bash
virt-viewer -c qemu:///system win11
```

### 4.4 QEMU Guest Agent — acesso remoto sem SSH

O acesso remoto funcional desta VM usa **QEMU Guest Agent** via canal VirtIO, não SSH/WinRM. Isso evita port forwarding porque a NIC final é `user-mode networking`, que permite saída da VM mas não entrada do host por padrão.

Canal libvirt aplicado no host:

```xml
<channel type='unix'>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
```

Aplicar numa VM existente:

```bash
cat >/tmp/win11-qga-channel.xml <<'EOF'
<channel type='unix'>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
EOF

virsh -c qemu:///system attach-device win11 /tmp/win11-qga-channel.xml --live --config
```

No Ghost Spectre, o MSI normal do QEMU Guest Agent falhou por custom action/VSS. Instalação funcional usada:

```cmd
:: 1) garantir VirtIO Serial
pnputil /add-driver D:\vioserial\w11\amd64\vioser.inf /install

:: 2) extrair MSI sem instalar custom actions
mkdir C:\qga
msiexec /a D:\guest-agent\qemu-ga-x86_64.msi TARGETDIR=C:\qga /qn

:: 3) copiar binários extraídos
mkdir "C:\Program Files\QEMU Guest Agent"
xcopy /E /I /Y "C:\qga\QEMU Guest Agent\Qemu-ga" "C:\Program Files\QEMU Guest Agent"

:: 4) desabilitar VSS provider, quebrado/removido no Ghost
cd /d "C:\Program Files\QEMU Guest Agent"
ren qga-vss.dll qga-vss.dll.disabled

:: 5) instalar e iniciar serviço
qemu-ga.exe -s install
sc start QEMU-GA
sc query QEMU-GA
```

Resultado esperado:

```text
STATE : 4 RUNNING
```

Teste pelo host:

```bash
virsh -c qemu:///system qemu-agent-command win11 '{"execute":"guest-ping"}'
```

Resultado validado:

```json
{"return":{}}
```

Executar comando remoto:

```bash
virsh -c qemu:///system qemu-agent-command win11 \
  '{"execute":"guest-exec","arguments":{"path":"cmd.exe","arg":["/c","echo QGA_OK"],"capture-output":true}}'
```

O retorno traz um `pid`. Consultar status:

```bash
virsh -c qemu:///system qemu-agent-command win11 \
  '{"execute":"guest-exec-status","arguments":{"pid":<PID>}}'
```

`out-data` e `err-data` vêm em base64:

```bash
echo '<BASE64>' | base64 -d
```

Limitação: `guest-exec` roda via serviço, não como sessão gráfica interativa. É ótimo para baixar arquivos, conferir hashes e rodar comandos; instaladores GUI ainda devem ser abertos pelo usuário dentro da sessão Windows.


---

## 5. Apps dentro do Windows

### Brave

Primeira opção:

```cmd
winget install --id Brave.Brave -e --source winget --accept-package-agreements --accept-source-agreements
```

Fallback sem `winget`:

```cmd
curl.exe -L -o "%TEMP%\BraveSetup.exe" https://laptop-updates.brave.com/latest/winx64
"%TEMP%\BraveSetup.exe"
```

### Incogniton

Installer v5 oficial:

```text
Host:  ~/Downloads/incogniton-vm/incogniton-windows-v5.exe
Guest: C:\Temp\IncognitonSetup.exe
SHA256: 2a12bf33e38194767c310082228c9a60b67554f2443d73eb70a9d7bab76089c6
Size: 183071448 bytes
```

No Ghost Spectre usado, o installer v5 falhou com:

```text
The setup files are corrupted. Please obtain a new copy of the program.
```

O arquivo foi baixado duas vezes no host e uma vez dentro da VM com mesmo tamanho/hash; portanto o problema observado foi compatibilidade do installer v5 com o Ghost, não cópia incompleta.

Fallback usado: versão anterior oficial:

```cmd
curl.exe -L -o C:\Temp\IncognitonSetup-v4.exe https://incogniton.com/incognitondownloadwin3
C:\Temp\IncognitonSetup-v4.exe
```

Baixado via QEMU Guest Agent:

```text
C:\Temp\IncognitonSetup-v4.exe
Size: 185636552 bytes
```

---

## 6. nftables / libvirt NAT — histórico e regra preservada

O host tinha `/etc/nftables.conf` com `policy drop` em `input` e `forward`, permitindo ICMP mas bloqueando DNS/DHCP/forward da rede `virbr0`. Sintomas na VM com `default NAT`:

```text
ping 192.168.122.1 OK
ping 1.1.1.1 parcialmente OK
nslookup google.com 192.168.122.1 timeout
nslookup google.com 1.1.1.1 timeout
DHCP sem lease
```

Ajuste aplicado em `/etc/nftables.conf` para não quebrar futuras VMs em `default NAT`:

```nft
iifname "virbr0" udp dport { 53, 67 } accept comment "allow libvirt DNS/DHCP"
iifname "virbr0" tcp dport 53 accept comment "allow libvirt DNS TCP"
```

Em `forward`:

```nft
iifname "virbr0" accept comment "allow VM outbound traffic"
oifname "virbr0" ct state { established, related } accept comment "allow VM return traffic"
```

Carregar:

```bash
sudo nft -f /etc/nftables.conf
```

Nota sobre Arch: `nftables.service` é `Type=oneshot`; `systemctl is-active nftables` pode mostrar `inactive (dead)` mesmo após `ExecStart` com `status=0/SUCCESS`.

---

## 7. Troubleshooting rápido

### DNS falha mas IP funciona

```cmd
ping 8.8.8.8
ping -4 google.com
```

Se `8.8.8.8` funciona e domínio falha: DNS.

Em `default NAT`, conferir firewall/libvirt. Em `user-mode networking`, voltar IP/DNS para DHCP automático.

### VM ficou fora da bridge após `net-destroy/start`

Sinal no host:

```bash
bridge link show   # sem vnet master virbr0
ip addr show virbr0 # NO-CARRIER
```

Correção: desligar e iniciar a VM, não só reboot:

```bash
virsh -c qemu:///system shutdown win11
# aguardar desligado
virsh -c qemu:///system start win11
```

### Windows ainda usa IP antigo `192.168.122.50`

Isso quebra após trocar para user-mode networking.

```cmd
netsh interface ipv4 set address name="Ethernet" source=dhcp
netsh interface ipv4 set dnsservers name="Ethernet" source=dhcp
ipconfig /renew
```

### `1920x1200` não aparece

Instalar QXL driver (`qxldod`) e SPICE guest tools; depois abrir a VM em fullscreen.

### Ícone do Windows ainda mostra globo

Se `ping -4 google.com` funciona, o ícone é apenas NCSI/Windows status bugado. Ghost Spectre pode remover/alterar componentes de detecção de conectividade.

---

## 8. Snapshots recomendados

Criar snapshots com a VM desligada:

```text
01-clean-ghost
02-network-ok
03-drivers-spice-qxl-ok
04-incogniton-installed
```

Não manter clipboard/file-transfer sempre habilitado se a VM for usada para navegação arriscada ou fontes não confiáveis.
