# Spotifast

Cliente Spotify nativo usado neste sistema. O projeto upstream é
[`crmne/spotifast`](https://github.com/crmne/spotifast). A release estável é
instalada pelo pacote AUR `spotifast-bin`, que fornece `/usr/bin/spotifast` e
os arquivos de integração com o desktop.

## Estado atual

- Pacote: `spotifast-bin`, gerenciado pelo `yay`.
- Binário: `/usr/bin/spotifast`.
- Desktop entry e ícone: fornecidos pelo pacote em `/usr/share`.
- Autostart: `hypr/.config/hypr/hyprland.lua` abre `/usr/bin/spotifast`
  diretamente em `name:super-1-3 silent`.
- Atalho: `Super+M` abre o Spotifast.
- MPRIS: player `spotifast`; usado pelo painel Quickshell e por `playerctl`.
- Credenciais: Secret Service (`gnome-keyring`), serviço
  `rocks.spotifast.Spotifast`; nunca versionar tokens ou Client Secret.

O pacote AUR substitui a antiga instalação manual em `~/.local/bin`. Manter
outro binário nesse caminho sombrearia `/usr/bin/spotifast` no shell e faria o
Hyprland, o launcher e o gerenciador de pacotes usarem versões diferentes.

## Instalação e atualização

Instale a release estável pronta pelo AUR:

```bash
yay -S spotifast-bin
```

O pacote passa a ser atualizado com os demais pacotes AUR nas atualizações
normais do `yay`. O `pacman` não instala `spotifast-bin` diretamente porque o
pacote não está nos repositórios oficiais do Arch.

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

## Remoção

1. Use **Sair da conta** no Spotifast para remover grants e credenciais.
2. Remova o pacote com `yay -Rns spotifast-bin`.
3. Remova o autostart e o atalho do `hyprland.lua` se não for instalar outro
   cliente no lugar.
4. Opcionalmente remova estado e cache em `~/.config/spotifast`,
   `~/.local/state/spotifast` e `~/.cache/spotifast`.

A remoção de estado/cache é destrutiva: histórico local, preferências, skins e
presets deixam de existir. Playlists e biblioteca permanecem na conta Spotify.
