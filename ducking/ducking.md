# 🎵 Auto Duck de Áudio — Abaixar música automaticamente quando chegar áudio

> Guia para fazer o Linux (Fedora/Ubuntu/Arch), Windows e macOS abaixarem automaticamente o volume da música quando um áudio do WhatsApp (ou qualquer app) tocar — igual ao iPhone.

---

## 🐧 Linux (Fedora, Ubuntu, Arch — com PipeWire)

### O que você vai precisar
- Fedora 34+ / Ubuntu 22.04+ / Arch (qualquer versão recente)
- PipeWire como servidor de áudio (padrão no Fedora 34+)
- Spotify instalado como app nativo (não Flatpak)
- WhatsApp Web no navegador

### Setup atual — Zen Browser + Spotify nativo

> O Flatpak cria uma sandbox que pode atrapalhar controle externo de áudio. Use Spotify nativo e navegador nativo/local.

O ambiente atual usa:

- `scripts/.local/bin/zen-duck.sh`
- `scripts/.config/systemd/user/zen-duck.service`

Aplicar pelo repo:

```bash
cd ~/Projects/dotfiles
stow --restow --target="$HOME" scripts
systemctl --user daemon-reload
systemctl --user enable --now zen-duck.service
```

Verificar:

```bash
systemctl --user status zen-duck.service
```

Comportamento:

- O ducking só dispara quando o Zen tem áudio ativo e há uma janela com `whatsapp` no título visível no Hyprland.
- Outros sites com áudio no Zen não ativam ducking.
- `zen_really_stopped()` confirma 3× com 0.3s de intervalo antes de fazer o fade-in; evita oscilação em pausas curtas.

### Ajustar o nível de volume do ducking

Edite `~/.local/bin/zen-duck.sh`:

- `DUCK_LEVEL=0.3` → porcentagem do volume (0.3 = 30%, 0.5 = 50%)
- `FADE_STEPS=20` → quantidade de passos do fade (mais = mais suave)
- `FADE_DELAY=0.03` → velocidade do fade em segundos por passo

---

## 🪟 Windows

No Windows, o sistema já tem suporte nativo parcial via **Windows Volume Mixer**, mas para ducking automático você pode usar:

### Opção 1 — EarTrumpet + regras manuais
1. Instale o [EarTrumpet](https://eartrumpet.app/) pela Microsoft Store
2. Permite controlar volume por aplicativo facilmente, mas não tem ducking automático

### Opção 2 — Voicemeeter (mais completo)
1. Baixe o [Voicemeeter Banana](https://vb-audio.com/Voicemeeter/banana.htm) (gratuito)
2. Configure canais separados para Spotify e navegador
3. Use as opções de ducking nos canais de entrada

### Opção 3 — Script PowerShell automático

Abra o PowerShell como administrador e crie o script:

```powershell
# Salve em: C:\Users\SeuUsuario\brave-duck.ps1

Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
}
"@

# Instalar módulo de áudio se necessário
# Install-Module -Name AudioDeviceCmdlets

while ($true) {
    $brave = Get-Process -Name "brave" -ErrorAction SilentlyContinue
    $spotify = Get-Process -Name "Spotify" -ErrorAction SilentlyContinue
    
    if ($brave -and $spotify) {
        # Abaixa Spotify para 30%
        # Use AudioDeviceCmdlets ou nircmd para controlar volume por app
    }
    
    Start-Sleep -Milliseconds 500
}
```

> **Recomendação Windows:** Use o **Voicemeeter Banana** — é a solução mais robusta e tem interface gráfica.

---

## 🍎 macOS

### Opção 1 — Automação nativa com Atalhos (Shortcuts)

O macOS não tem ducking nativo por app, mas você pode:

1. Abra o app **Atalhos** (Shortcuts)
2. Crie um atalho que abaixa o volume do sistema quando ativado
3. Use junto com o **Foco** (Focus) para automatizar

### Opção 2 — Script AppleScript

```applescript
-- Salve como: ~/Library/Scripts/duck-audio.scpt

on run
    tell application "Spotify"
        set current volume to 30
    end tell
end run
```

Execute via Terminal:
```bash
osascript ~/Library/Scripts/duck-audio.scpt
```

### Opção 3 — Rogue Amoeba Loopback (pago, mais completo)

O [Loopback](https://rogueamoeba.com/loopback/) permite roteamento de áudio por aplicativo com ducking automático — é a solução mais próxima do comportamento do iPhone no Mac.

### Opção 4 — Script bash automático (macOS)

```bash
#!/bin/bash
# Salve em: ~/bin/duck-audio.sh

DUCK_VOLUME=30
NORMAL_VOLUME=100

while true; do
  # Verifica se WhatsApp Web está tocando (via processo do navegador)
  if pgrep -x "Brave Browser" > /dev/null; then
    # Abaixa o Spotify via AppleScript
    osascript -e 'tell application "Spotify" to set sound volume to '$DUCK_VOLUME
    
    while pgrep -x "Brave Browser" > /dev/null; do
      sleep 0.5
    done
    
    osascript -e 'tell application "Spotify" to set sound volume to '$NORMAL_VOLUME
  fi
  sleep 0.5
done
```

> **Limitação macOS:** O macOS não expõe facilmente o estado de reprodução de áudio por app sem ferramentas pagas. A detecção por processo é uma aproximação.

---

## 📝 Notas gerais

| Sistema | Dificuldade | Qualidade |
|---------|-------------|-----------|
| Linux (PipeWire) | Média | ⭐⭐⭐⭐ |
| Windows (Voicemeeter) | Baixa | ⭐⭐⭐⭐ |
| macOS (Loopback) | Baixa (pago) | ⭐⭐⭐⭐⭐ |
| macOS (script) | Média | ⭐⭐ |

- No **Linux**, a solução é totalmente gratuita e funciona em background
- No **Windows**, o Voicemeeter é a opção mais prática
- No **macOS**, o comportamento nativo do iPhone vem do sistema operacional móvel e não está presente no macOS desktop — ferramentas de terceiros são necessárias
