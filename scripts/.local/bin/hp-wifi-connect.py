#!/usr/bin/env python3
"""Configura o Wi-Fi da HP DeskJet Ink Advantage 2774 (DeskJet 2700 series)
direto via USB, sem passar pelo assistente gráfico do hp-toolbox/hp-wificonfig
(instável nesse modelo: trava no scan e seleciona a rede errada por padrao).

Requisitos: impressora ligada e conectada por cabo USB; pacote `hplip`
instalado (fornece /usr/share/hplip). Depois de rodar, pode desconectar o USB.

Uso:
    python3 ~/.local/bin/hp-wifi-connect.py

Ver docs/printer-hp-deskjet-2774.md no repo de dotfiles para o contexto
completo (por que o assistente gráfico não funciona, como achar o
DEVICE_URI de novo se a impressora for trocada, etc.).
"""
import sys
import getpass

sys.path.insert(0, '/usr/share/hplip')
from base import device, LedmWifi

# Achado via `hp-setup -i` (conexão USB) -> "Setting up device: hp:/usb/...".
# Se a impressora for outra/trocada, redescobrir com `hp-probe -b usb`.
DEVICE_URI = 'hp:/usb/DeskJet_2700_series?serial=BR32KDG2NK'


def scan_networks(d, adapter_name):
    print("Escaneando redes...")
    scan = LedmWifi.performScan(d, adapter_name)
    n = scan.get('numberofscanentries', 0)
    networks = []
    for i in range(n):
        networks.append({
            'ssid': scan.get('ssid-%d' % i),
            'mode': scan.get('communicationmode-%d' % i),
            'enc': scan.get('encryptiontype-%d' % i),
            'dbm': scan.get('dbm-%d' % i),
        })
    return networks


def main():
    d = device.Device(DEVICE_URI)
    d.open()
    try:
        ids = LedmWifi.getWifiAdaptorID(d)
        if not ids:
            print("ERRO: nenhum adaptador wifi encontrado na impressora.")
            sys.exit(1)
        adapter_name = ids[0][1]
        print(f"Adaptador: {adapter_name}")

        networks = scan_networks(d, adapter_name)
        while not networks:
            print("Nenhuma rede encontrada nesse scan, tentando de novo...")
            networks = scan_networks(d, adapter_name)

        print("\nRedes encontradas:")
        for i, net in enumerate(networks):
            print(f"  [{i}] {net['ssid']!r}  sinal={net['dbm']}dBm  enc={net['enc']}  modo={net['mode']}")

        print("\nATENCAO: essa impressora so enxerga 2.4GHz. NAO escolha rede com '5G'/'5Ghz' no nome.")
        choice = input("\nDigite o numero da rede que quer usar (ou 'r' para escanear de novo): ").strip()
        while choice.lower() == 'r':
            networks = scan_networks(d, adapter_name)
            print("\nRedes encontradas:")
            for i, net in enumerate(networks):
                print(f"  [{i}] {net['ssid']!r}  sinal={net['dbm']}dBm  enc={net['enc']}  modo={net['mode']}")
            choice = input("\nDigite o numero da rede que quer usar (ou 'r' para escanear de novo): ").strip()

        idx = int(choice)
        target = networks[idx]
        ssid = target['ssid']
        mode = target['mode']
        enc = target['enc']
        print(f"\nEscolhido: {ssid!r} (modo={mode}, criptografia={enc})")

        password = getpass.getpass(f"Senha do Wi-Fi '{ssid}': ")
        if not password:
            print("Senha vazia, abortando.")
            sys.exit(1)

        print("Conectando...")
        result = LedmWifi.associate(d, adapter_name, ssid, mode, enc, password)
        code = result.get('errorreturn')
        if code in (200, 204):
            print(f"OK: comando de associacao aceito pela impressora (HTTP {code}).")
            print("A impressora vai reiniciar o radio wifi e tentar conectar.")
            print("Espera ~20-30s e confere o LED de wifi (deve ficar aceso fixo).")
        else:
            print(f"FALHOU: resposta HTTP {code}. Confere a senha e tenta de novo.")
            sys.exit(1)
    finally:
        d.close()


if __name__ == '__main__':
    main()
