# Impressora — HP DeskJet Ink Advantage 2774

**Status:** funcionando via Wi-Fi
**Contexto:** HP DeskJet 2700 series (nome interno do driver; a caixa/etiqueta diz "Ink Advantage 2774"), sem tela, painel só com botões físicos. USB vendor/produto `03f0:1853`.

## Descrição

Setup do zero: o sistema não tinha nenhum driver/serviço de impressão instalado, e a impressora estava sem Wi-Fi configurado (rede antiga perdida). Este doc cobre pacotes necessários, instalação via USB, e o método confiável para configurar o Wi-Fi — o assistente gráfico oficial da HP (`hp-toolbox` → "Wireless/wifi setup using USB") é **instável nesse modelo** e não deve ser o primeiro caminho.

---

## 1. Pacotes necessários

Nenhum vem por padrão. Instalados via `pacman` (adicionar a `packages/pacman.txt` se for setup permanente de uma máquina nova):

```bash
sudo pacman -S --needed cups hplip nss-mdns system-config-printer usbutils python-pyqt5
sudo systemctl enable --now cups.service
```

| Pacote | Por quê |
|---|---|
| `cups` | serviço de impressão (spooler) |
| `hplip` | driver HP + ferramentas (`hp-setup`, `hp-wificonfig`, `hp-toolbox`) |
| `nss-mdns` | resolve nomes `.local` de impressoras de rede (mDNS) |
| `system-config-printer` | GUI de gerência de impressoras (opcional, não usado neste setup) |
| `usbutils` | fornece `lsusb` — **sem isso o `hp-wificonfig`/`hp-toolbox` falha silenciosamente** ao escanear USB (erro só aparece no log: `Failed to find the lsusb command`) |
| `python-pyqt5` | GUI do HPLIP (`hp-toolbox`, `hp-wificonfig`) é Qt5; sem isso `hp-setup -u` recusa abrir e pede pra usar `-i` (modo texto) |

## 2. Instalação via USB (base, sempre funciona)

Conectar a impressora por cabo USB e rodar o instalador interativo (modo texto, mais confiável que a GUI):

```bash
hp-setup -i
```

Fluxo: `0` (USB) → `m` (nome de fila padrão) → `y` (confirma PPD `hp-deskjet_2700_series.ppd.gz`) → Enter (localização/notas, pode deixar em branco) → `y` (imprime página de teste).

Isso já deixa a impressora funcional via cabo (fila `DeskJet_2700`). Serve de base pra depois configurar o Wi-Fi pelo mesmo cabo.

## 3. Escala da UI Qt (HiDPI)

As janelas do HPLIP (`hp-toolbox`, `hp-wificonfig`) abrem minúsculas em tela HiDPI por padrão. Fixado no `zsh/.zshrc`:

```bash
export QT_SCALE_FACTOR=1.3
export QT_AUTO_SCREEN_SCALE_FACTOR=0
```

Vale pra qualquer app Qt5 aberto do terminal, não só HP. Ajustar o valor se ficar grande/pequeno demais.

## 4. Wi-Fi — por que o assistente gráfico falha

Tentativa pelo caminho "oficial" (`hp-toolbox` → **Wireless/wifi setup using USB**, assistente de 5 passos):

- **Sem `usbutils`:** trava sem erro visível na tela (só no log: `Failed to find the lsusb command`).
- **Escaneamento via USB é lento** (~15-30s por etapa) e a janela fica com cara de travada nesse meio tempo — não é bug, só falta feedback visual.
- **Bug real:** ao clicar "< Back" a partir do passo de senha (step 4) e refazer o fluxo, o assistente **auto-seleciona a rede errada** (a de 5GHz, que essa impressora nem consegue usar — o rádio dela só fala 2.4GHz) em vez de manter/pedir a seleção manual. Em pelo menos uma tentativa, clicar diretamente na linha certa da tabela também não teve efeito (seleção não mudava visualmente).
- **SSID "sumiu" do scan:** em execuções sucessivas, a rede 2.4GHz do roteador (`TAPI WIFI -GIULIBROW`, sem sufixo "5G") apareceu em alguns scans e não em outros — comportamento normal de chip Wi-Fi barato/scan curto, não indica problema de configuração.

Conclusão: **não usar o assistente gráfico** pra esse modelo. Ele serve só pra confirmar que a impressora está acessível via USB (Actions → Print Test Page já basta pra isso).

## 5. Wi-Fi — método confiável (script direto via LEDM/USB)

O HPLIP fala com a impressora por um protocolo HTTP-sobre-USB chamado LEDM (`base/LedmWifi.py` no pacote `hplip`). É o que a GUI usa por baixo dos panos — dá pra chamar direto em Python, sem a camada Qt instável.

Script pronto: [`scripts/.local/bin/hp-wifi-connect.py`](../scripts/.local/bin/hp-wifi-connect.py) (stow → `~/.local/bin/hp-wifi-connect.py`).

```bash
python3 ~/.local/bin/hp-wifi-connect.py
```

O que ele faz:

1. Abre a impressora via USB (`hp:/usb/DeskJet_2700_series?serial=...` — descoberto uma vez com `hp-setup -i`; se a impressora for trocada, redescobrir com `hp-probe -b usb`).
2. Escaneia redes (`LedmWifi.performScan`) e lista numeradas com sinal/criptografia — deixa a **escolha manual** pra evitar o bug de auto-seleção da rede 5GHz.
3. Pede a senha via `getpass` (não aparece na tela, não fica em nenhum log/histórico de shell).
4. Associa (`LedmWifi.associate`) usando o modo/criptografia que o próprio scan reportou pra rede escolhida (não precisa hardcodar WPA2/infra — pega dinâmico).
5. Confirma HTTP 200/204 = comando aceito. A impressora reinicia o rádio e tenta conectar sozinha (~20-30s).

Depois de rodar, validar do lado do notebook:

```bash
# a impressora deve responder ping na sub-rede local depois de ~20-30s
ping -c 3 192.168.100.14   # trocar pelo IP obtido (ver abaixo)

# ou, direto via USB, sem esperar mDNS:
python3 -c "
import sys; sys.path.insert(0,'/usr/share/hplip')
from base import device, LedmWifi
d = device.Device('hp:/usb/DeskJet_2700_series?serial=BR32KDG2NK'); d.open()
ids = LedmWifi.getWifiAdaptorID(d)
print(LedmWifi.getIPConfiguration(d, ids[0][1]))
d.close()"
```

> `avahi-browse -a` **não** encontrou a impressora mesmo depois de conectada — o mDNS/Bonjour dela demora ou não anuncia por padrão nessa rede. Não usar isso como sinal de falha; confiar no ping/IP direto via USB.

## 6. Fila CUPS de rede (depois do Wi-Fi ok)

Com a impressora já com IP na rede (confirmado via ping/USB acima), criar a fila de rede e trocar o padrão:

```bash
hp-setup -i 192.168.100.14   # IP obtido no passo anterior; escolher "1" (net) no menu
# fluxo: nome da fila -> y (confirma PPD) -> Enter -> y (test page)

sudo lpadmin -d DeskJet_2700_WiFi   # define como impressora padrão do sistema
```

A fila USB antiga (`DeskJet_2700`) pode ficar registrada — inofensiva, só some da lista de "ativa" quando o cabo não está plugado. Depois disso o cabo USB pode ser desconectado; a impressão passa a ser 100% via Wi-Fi.

Verificar:

```bash
lpstat -p -d          # lista as duas filas + destino padrão
lp arquivo.pdf         # imprime na fila padrão (Wi-Fi)
```

## 7. Referência rápida — dados desta impressora

| Campo | Valor |
|---|---|
| Modelo (driver) | DeskJet 2700 series |
| USB vendor:product | `03f0:1853` |
| Serial USB | `BR32KDG2NK` |
| Device URI (USB) | `hp:/usb/DeskJet_2700_series?serial=BR32KDG2NK` |
| Rede Wi-Fi em uso | `TAPI WIFI -GIULIBROW` (2.4GHz — **não** a variante "5G") |
| IP (DHCP) | `192.168.100.14` |
| PPD | `hp-deskjet_2700_series.ppd.gz` |
| Fila CUPS padrão | `DeskJet_2700_WiFi` |
