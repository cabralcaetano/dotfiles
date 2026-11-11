# Zen Browser — Google Meet, QCY H3 Pro e câmera

**Status:** diagnóstico aplicado em 2026-09-23 no perfil ativo `~/.config/zen/fygd0cys.Default (release)`.

## Contexto

Ambiente observado:

- Arch Linux + Hyprland/Wayland.
- Zen Browser nativo em `~/.local/opt/zen`, launcher `~/.local/bin/zen`.
- PipeWire + WirePlumber.
- Google Meet em `meet.google.com`.
- Headset Bluetooth `QCY H3 Pro`.
- Câmera integrada USB/UVC: `Integrated Camera: Integrated C`.

## Sintomas

1. No Zen, Google Meet ficava sem áudio/vídeo ou preso em estado de inicialização.
2. Ao entrar no Meet com o QCY selecionado para microfone e saída, o PipeWire colocava o fone em modo chamada.
3. A câmera do Meet ficava em “A câmera está iniciando” até trocar o backend de câmera do Gecko.
4. Depois de funcionar, a imagem parecia cortada/4:3, mas o driver estava entregando 16:9.

## Diagnóstico confirmado

### Permissões do Zen/Meet estavam corretas

No `permissions.sqlite` do perfil ativo:

- `https://meet.google.com` tinha `microphone = allow`.
- `https://meet.google.com` tinha `camera = allow`.
- `desktop-notification` também estava permitido.

Logo, o problema não era bloqueio de permissão do site.

### PipeWire/portal estavam ativos

Serviços de sessão vivos:

- `pipewire`
- `wireplumber`
- `xdg-desktop-portal`
- `xdg-desktop-portal-hyprland`
- `xdg-desktop-portal-gtk`

Zen aparecia como client PipeWire e criava streams de áudio do Meet.

### QCY H3 Pro em chamada força HSP/HFP

Quando o Meet usa o microfone do QCY, o Bluetooth Classic troca o card para perfil de headset:

```text
Active Profile: headset-head-unit
api.bluez5.codec = "msbc"
```

E os streams do Zen/Meet ficam assim:

```text
media.name = "Meet"
target.object = "bluez_input.84:AC:60:E7:7B:5E"
```

Isso é esperado: A2DP/LDAC/AAC/SBC são perfis de saída hi-fi; microfone simultâneo usa HSP/HFP. Consequências:

- saída mono/baixa taxa;
- maior chance de latência/instabilidade;
- Meet/Zen podem ficar presos em seleção de device;
- qualidade de saída cai mesmo que o microfone do QCY seja melhor.

Decisão prática:

- Se qualidade de saída importa: QCY como alto-falante + microfone interno do notebook.
- Se o microfone do QCY é prioridade: QCY como microfone e aceitar perfil HSP/HFP.

### Câmera estava ativa no kernel, mas o Meet/Zen travava

Zen segurava a câmera:

```text
/dev/video1: zen
```

A câmera real é `/dev/video1`. `/dev/video2` é metadata capture, não stream de vídeo útil. `/dev/video0` é OBS Virtual Camera.

Formatos reais da câmera integrada:

```text
MJPG 1280x720 30fps
MJPG 960x540 30fps
MJPG 640x480 30fps
MJPG 640x360 30fps
YUYV 640x480 30fps
YUYV 640x360 30fps
```

O formato ativo depois do fix:

```text
Width/Height : 1280/720
Pixel Format : MJPG
Frames/sec   : 30
```

Ou seja: a câmera está em 16:9. Se o Meet parecer 4:3/cortado, é crop/enquadramento da UI do Meet, não formato do driver.

## Fix aplicado no Zen

Adicionado ao perfil ativo:

```js
user_pref("media.webrtc.camera.allow-pipewire", true);
```

Arquivo real:

```text
~/.config/zen/fygd0cys.Default (release)/user.js
```

Efeito: força o backend PipeWire de câmera do Firefox/Gecko no Zen. Precisa reiniciar o Zen inteiro; reload da aba não basta.

## Procedimento de recuperação

Quando Google Meet no Zen falhar:

1. Fechar o Zen inteiro.
2. Confirmar que o `user.js` contém:

   ```js
   user_pref("media.webrtc.camera.allow-pipewire", true);
   ```

3. Abrir Zen de novo.
4. Entrar no Meet.
5. Selecionar manualmente:
   - Microfone: `QCY H3 Pro` se a prioridade for o mic do fone; ou `Raptor Lake-P/U/H cAVS Digital Microphone` para manter o fone em A2DP.
   - Alto-falante: `QCY H3 Pro`.
   - Câmera: `Integrated Camera`.
6. Se a câmera ficar presa em “iniciando”:
   - resetar permissões do Meet no cadeado da barra de endereço;
   - recarregar;
   - permitir câmera/mic de novo;
   - conferir se não escolheu `OBS Virtual Camera`.
7. Se a imagem parecer cortada:
   - abrir efeitos/configurações de vídeo do Meet;
   - desativar `Auto framing`, `Enquadramento automático`, retoque, fundo e efeitos visuais;
   - manter `Integrated Camera`.

## Comandos úteis

Listar streams PipeWire:

```bash
wpctl status
```

Ver apps usando a câmera:

```bash
fuser -v /dev/video0 /dev/video1 /dev/video2 /dev/media0
```

Listar formatos da câmera real:

```bash
v4l2-ctl --device=/dev/video1 --list-formats-ext
```

Ver formato ativo:

```bash
v4l2-ctl --device=/dev/video1 --get-fmt-video --get-parm
```

Ver permissões salvas do Meet sem depender do Zen aberto:

```bash
sqlite3 -readonly ~/.config/zen/'fygd0cys.Default (release)'/permissions.sqlite \
  "select origin,type,permission,expireType,modificationTime from moz_perms where origin like '%meet.google.com%';"
```

Se o DB estiver locked, copiar `permissions.sqlite`, `permissions.sqlite-wal` e `permissions.sqlite-shm` para `/tmp` e consultar a cópia.

## Interpretação rápida

- `Zen` aparece em `wpctl status` com `Meet` em `Stream/Input/Audio`: Meet está capturando microfone.
- `target.object = bluez_input...`: Meet está usando o mic do QCY; isso força HSP/HFP.
- `/dev/video1` em uso por `zen`: Zen abriu a câmera integrada.
- `1280/720 MJPG`: câmera está widescreen; qualquer crop é Meet/UI.
- `OBS Virtual Camera` deve ser evitada salvo quando OBS estiver emitindo uma cena válida.
