# Spotifast

Cliente Spotify nativo usado neste sistema. O projeto upstream é
[`crmne/spotifast`](https://github.com/crmne/spotifast); a instalação atual é a
release oficial para Linux em `~/.local/bin/spotifast`, fora do `pacman` e do
Stow.

## Estado atual

- Versão instalada: `0.13.2`.
- Binário: `~/.local/bin/spotifast`.
- Desktop entry: `~/.local/share/applications/spotifast.desktop`.
- Ícone: `~/.local/share/icons/hicolor/scalable/apps/spotifast.svg`.
- Autostart: `hypr/.config/hypr/hyprland.lua` abre o binário diretamente em
  `name:super-1-3 silent`.
- Atalho: `Super+M` abre o Spotifast.
- MPRIS: player `spotifast`; usado pelo painel Quickshell e por `playerctl`.
- Credenciais: Secret Service (`gnome-keyring`), serviço
  `rocks.spotifast.Spotifast`; nunca versionar tokens ou Client Secret.

A instalação foi feita por usuário porque o ambiente de sessão não tinha
`~/.local/bin` no `PATH` e a instalação AUR exigia elevação. Por isso o
`hyprland.lua` e o desktop entry usam o caminho absoluto do binário. O
`bootstrap.sh` não instala o Spotifast automaticamente.

## Instalação por usuário

Baixe a release `x86_64-unknown-linux-gnu.tar.gz` e o `checksums.txt` na
[página de releases](https://github.com/crmne/spotifast/releases). Antes de
instalar, confira o SHA-256 do arquivo contra o manifesto da mesma release.
Depois extraia e copie:

```bash
install -Dm755 spotifast ~/.local/bin/spotifast
install -Dm644 LICENSE ~/.local/share/licenses/spotifast/LICENSE
install -Dm644 README.md ~/.local/share/doc/spotifast/README.md
install -Dm644 packaging/applications/spotifast.desktop \
  ~/.local/share/applications/spotifast.desktop
install -Dm644 packaging/icons/spotifast.svg \
  ~/.local/share/icons/hicolor/scalable/apps/spotifast.svg
```

Ajuste o `Exec=` do desktop entry para
`/home/caetano/.local/bin/spotifast %u`; launchers gráficos não recebem hoje
`~/.local/bin` no `PATH` da sessão systemd.

Alternativa futura: `yay -S spotifast-bin`. Antes de migrar para o pacote AUR,
remova o binário em `~/.local/bin/spotifast`; caso contrário ele continua
sombreando `/usr/bin/spotifast` no shell.

## Conta e reprodução

O app pessoal da Web API e a reprodução local são autorizações independentes.

1. No [Spotify Developer Dashboard](https://developer.spotify.com/dashboard),
   crie um app pessoal com **Web API** e Redirect URI exata
   `http://127.0.0.1:8989/login`.
2. Cole somente o Client ID em **Configurações → App pessoal do Spotify** e
   autorize com a mesma conta Premium. O Client Secret não é usado.
3. Em **Reprodução neste computador**, escolha **Ativar a reprodução aqui** e
   conclua a segunda autorização. Essa etapa registra o computador no Spotify
   Connect.

O Client ID pode ficar nas configurações locais do aplicativo; credenciais e
tokens permanecem no Secret Service e não entram neste repositório.

## Atualização

O Spotifast consulta releases no GitHub e possui atualizador próprio com
verificação de assinatura e SHA-256. A instalação atual é gravável pelo usuário,
mas esse fluxo ainda não foi exercitado neste sistema.

Se a atualização interna falhar, repita a instalação manual com a nova release,
verifique o checksum e substitua apenas o binário e os arquivos de integração.
Configurações, caches e credenciais ficam em diretórios separados e não são
substituídos.

## Remoção

1. Use **Sair da conta** no Spotifast para remover grants e credenciais.
2. Remova o autostart e o atalho do `hyprland.lua` antes de apagar o binário.
3. Apague `~/.local/bin/spotifast`, o desktop entry, o ícone, a licença e o
   README instalados.
4. Opcionalmente remova estado e cache em `~/.config/spotifast`,
   `~/.local/state/spotifast` e `~/.cache/spotifast`.

A remoção de estado/cache é destrutiva: histórico local, preferências, skins e
presets deixam de existir. Playlists e biblioteca permanecem na conta Spotify.
