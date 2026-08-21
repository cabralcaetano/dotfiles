# 🎵 Auto Duck de Áudio — Abaixar música automaticamente quando chegar áudio

> Guia para fazer o Linux (Fedora/Ubuntu/Arch), Windows e macOS abaixarem automaticamente o volume da música quando um áudio do WhatsApp (ou qualquer app) tocar — igual ao iPhone.

---

## 🐧 Linux (Fedora, Ubuntu, Arch — com PipeWire)

### O que você vai precisar
- Fedora 34+ / Ubuntu 22.04+ / Arch (qualquer versão recente)
- PipeWire como servidor de áudio (padrão no Fedora 34+)
- Spotify instalado como app nativo (não Flatpak)
- WhatsApp Web no navegador

### Passo 1 — Instalar o Brave (ou qualquer navegador) como RPM/nativo (não Flatpak)

> O Flatpak cria uma sandbox que impede o controle de áudio externo. Use a versão nativa.

**Brave no Fedora:**
```bash
sudo tee /etc/yum.repos.d/brave-browser.repo << 'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

sudo dnf install brave-browser
```

**Migrar perfil do Flatpak para o RPM:**
```bash
cp -r ~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser ~/.config/BraveSoftware/
```

### Passo 2 — Forçar o navegador a declarar role de áudio

Isso faz o sistema de áudio saber que o navegador está tocando uma "comunicação", não música.

**Renomear o binário original e criar um wrapper:**
```bash
sudo mv /usr/bin/brave-browser-stable /usr/bin/brave-browser-stable.real

sudo tee /usr/local/bin/brave-browser-stable << 'EOF'
#!/bin/bash
export PULSE_PROP_OVERRIDE="media.role=phone"
exec /usr/bin/brave-browser-stable.real "$@"
EOF

sudo chmod +x /usr/local/bin/brave-browser-stable
```

> Para outros navegadores, substitua `brave-browser-stable` pelo binário do seu navegador (ex: `firefox`, `chromium-browser`, `google-chrome`).

### Passo 3 — Criar o script de ducking

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/brave-duck.sh
```

Cole o conteúdo abaixo:

```bash
#!/usr/bin/env bash
# Sem `-e`: o loop depende de comandos que retornam não-zero por design (grep sem match).
set -uo pipefail
DUCK_LEVEL=0.3
FADE_STEPS=20
FADE_DELAY=0.03
is_ducked=false
saved_spotify_volume=""


get_spotify_id() {
  local spotify_client
  spotify_client=$(wpctl status | grep -i "spotify" | grep -oP '^\s+\K\d+' | head -1)
  [ -z "$spotify_client" ] && return

  pactl list sink-inputs 2>/dev/null | awk -v cid="\"$spotify_client\"" '
    /client\.id /  { matched = ($3 == cid) }
    /object\.id /  { if (matched) { gsub(/"/, "", $3); print $3; exit } }
  '
}

get_spotify_volume() {
  wpctl get-volume "$1" 2>/dev/null | awk '/^Volume:/ { print $2; exit }'
}

duck_target_volume() {
  awk -v current="$1" -v duck="$DUCK_LEVEL" \
    'BEGIN { printf "%.4f", (current < duck ? current : duck) }'
}

calc_volume() {
  awk -v start="$1" -v target="$2" -v step="$3" -v steps="$FADE_STEPS" \
    'BEGIN { printf "%.4f", start + ((target - start) * step / steps) }'
}

fade_volume() {
  local id=$1
  local start=$2
  local target=$3
  local vol

  for i in $(seq 1 "$FADE_STEPS"); do
    vol=$(calc_volume "$start" "$target" "$i")
    wpctl set-volume "$id" "$vol"
    sleep "$FADE_DELAY"
  done

  wpctl set-volume "$id" "$target"
}

fade_out() {
  local current=$2
  local target
  target=$(duck_target_volume "$current")
  fade_volume "$1" "$current" "$target"
}

fade_in() {
  local current=$2
  local target=$3
  fade_volume "$1" "$current" "$target"
}

resolve_hyprland_env() {
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && return 0

  local socket sig
  for socket in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/hypr/*/.socket.sock; do
    [ -S "$socket" ] || continue
    sig=${socket%/.socket.sock}
    sig=${sig##*/}
    export HYPRLAND_INSTANCE_SIGNATURE="$sig"
    return 0
  done

  return 1
}

has_whatsapp_brave_window() {
  resolve_hyprland_env || return 1

  hyprctl clients 2>/dev/null | awk '
    /^Window / {
      if (class ~ /brave/ && title ~ /whatsapp/) found = 1
      class = ""; title = ""
      next
    }
    /^[[:space:]]*class:/ {
      class = tolower($2)
      next
    }
    /^[[:space:]]*title:/ {
      sub(/^[[:space:]]*title:[[:space:]]*/, "", $0)
      title = tolower($0)
      next
    }
    END {
      if (class ~ /brave/ && title ~ /whatsapp/) found = 1
      exit found ? 0 : 1
    }
  '
}

check_brave() {
  local brave_audio
  brave_audio=$(pactl list sink-inputs 2>/dev/null | awk '
    /^Entrada|^Sink Input/ {
      if (brave && playing) count++
      brave=0; playing=0
    }
    /application\.process\.binary.*"brave"/ { brave=1 }
    /Cork(ed)?:.*(não|no)/ { playing=1 }
    END {
      if (brave && playing) count++
      print count+0
    }
  ')

  [ "${brave_audio:-0}" -eq 0 ] && echo 0 && return

  if has_whatsapp_brave_window; then
    echo "$brave_audio"
  else
    echo 0
  fi
}

brave_really_stopped() {
  for i in 1 2 3; do
    [ "$(check_brave)" -gt 0 ] && return 1
    sleep 0.3
  done
  return 0
}

while true; do
  SPOTIFY_ID=$(get_spotify_id)
  BRAVE_PLAYING=$(check_brave)

  if [ "$BRAVE_PLAYING" -gt 0 ] && [ "$is_ducked" = "false" ] && [ -n "$SPOTIFY_ID" ]; then
    saved_spotify_volume=$(get_spotify_volume "$SPOTIFY_ID")
    if [ -n "$saved_spotify_volume" ]; then
      echo "$(date +%T.%N) - Brave tocando, fade_out para preservar volume $saved_spotify_volume"
      fade_out "$SPOTIFY_ID" "$saved_spotify_volume"
      is_ducked=true
    fi
  elif [ "$BRAVE_PLAYING" -eq 0 ] && [ "$is_ducked" = "true" ]; then
    if brave_really_stopped; then
      echo "$(date +%T.%N) - Brave parou, fade_in para $saved_spotify_volume"
      SPOTIFY_ID=$(get_spotify_id)
      if [ -n "$SPOTIFY_ID" ] && [ -n "$saved_spotify_volume" ]; then
        current_spotify_volume=$(get_spotify_volume "$SPOTIFY_ID")
        [ -n "$current_spotify_volume" ] && fade_in "$SPOTIFY_ID" "$current_spotify_volume" "$saved_spotify_volume"
      fi
      echo "$(date +%T.%N) - fade_in concluido"
      saved_spotify_volume=""
      is_ducked=false
    fi
  fi

  sleep 0.5
done
```

Salvar: `Ctrl+O`, `Enter`, `Ctrl+X`.

```bash
chmod +x ~/.local/bin/brave-duck.sh
```

> **Filtro WhatsApp Web:** o ducking só dispara quando o Brave tem áudio ativo **e** há uma janela com "whatsapp" no título visível no Hyprland. Outros sites com áudio no Brave não ativam o ducking.

> **Debounce:** `brave_really_stopped()` confirma 3× com 0.3s de intervalo antes de fazer o fade_in — evita oscilações em pausas curtas.

### Passo 4 — Criar serviço systemd para rodar automaticamente

```bash
mkdir -p ~/.config/systemd/user/

cat > ~/.config/systemd/user/brave-duck.service << 'EOF'
[Unit]
Description=Auto duck Brave audio role
After=pipewire.service wireplumber.service

[Service]
ExecStart=%h/.local/bin/brave-duck.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now brave-duck.service
```

### Verificar se está funcionando

```bash
systemctl --user status brave-duck.service
```

### Ajustar o nível de volume do ducking

Edite o arquivo `~/.local/bin/brave-duck.sh` e mude:
- `DUCK_LEVEL=0.3` → porcentagem do volume (0.3 = 30%, 0.5 = 50%)
- `FADE_STEPS=15` → quantidade de passos do fade (mais = mais suave)
- `FADE_DELAY=0.02` → velocidade do fade em segundos por passo

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
