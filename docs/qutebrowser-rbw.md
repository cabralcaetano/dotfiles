# qutebrowser + rbw (Bitwarden)

**Status:** ativo desde 2026-10-30. O qutebrowser é navegador secundário; o Bitwarden do dia a dia continua sendo a extensão no Firefox/Chromium. Decisão e histórico da avaliação de navegadores: vault `wiki-ia`, `personal/projects/dotfiles/browser-qutebrowser-evaluation.md`.

O `rbw` é um cliente Bitwarden não oficial em Rust. Foi escolhido no lugar do `bw` oficial porque `bitwarden-cli` depende de `nodejs-lts-jod`, que conflita com o `nodejs` 26 instalado (`pacman` oferece remover `nodejs`; não aceitar).

## Peças

| Peça | Local |
|---|---|
| Userscript | `qutebrowser/.config/qutebrowser/userscripts/qute-rbw` (Python, stow) |
| Atalhos | `qutebrowser/.config/qutebrowser/config.py`: `,p` e `,P` |
| Pacote | `rbw` em `packages/pacman.txt` |
| Menu de escolha | `fuzzel --dmenu`; troca por `QUTE_RBW_MENU` |

## Instalar e registrar (uma vez por máquina)

```bash
sudo pacman -S rbw
rbw config set email SEU@EMAIL
rbw register    # pinentry pede client_id e client_secret
rbw login       # pinentry pede a senha mestra
rbw sync && rbw list | head
```

`rbw login` sem `register` falha com `api request returned error: 400` no servidor oficial. `register` com chave errada falha com `incorrect api key`.

A chave de API fica no cofre web: Configurações → Segurança → Chaves → Ver chave da API. `client_id` começa com `user.`.

- O `client_secret` equivale à senha. Não colar em chat, arquivo ou repo; digitar só no `pinentry`, de preferência colado do próprio cofre (`l`/`I`/`1` se confundem ao digitar).
- Se vazar, **Girar chave da API** na mesma tela. O `client_id` não muda.
- O `rbw` guarda a chave no próprio agente; este repo não guarda segredo nenhum.

## Uso no qutebrowser

Recarregue com `:config-source` depois de instalar.

| Atalho | Faz |
|---|---|
| `,p` | Preenche usuário, Tab, senha |
| `,P` | Preenche só a senha (logins em duas etapas) |

1. Abra a página de login e foque o campo de usuário.
2. `,p`.
3. Casamento: o script busca entradas pelo host da URL (sem `www.`), depois pelo penúltimo rótulo do domínio. Uma entrada: preenche direto. Várias: abre o `fuzzel`. Nenhuma: mostra o cofre inteiro.

O `rbw` trava após 1 h (`lock_timeout` 3600) e o `pinentry` pede a senha mestra. Para adiantar: `rbw unlock`.

Não verificado em uso real: se `,p` dispara em modo insert (atalho com vírgula pode ser digitado como texto) e o comportamento do Tab entre campos em sites específicos.

## Comandos úteis no terminal

```bash
rbw list                  # todas as entradas
rbw search github         # busca por nome
rbw get github            # mostra a senha
rbw get github -c         # copia sem mostrar
rbw code NOME             # TOTP, se a entrada tiver
rbw sync                  # atualiza o cofre local
rbw lock                  # trava agora
rbw config show          # email, lock_timeout, sync_interval, pinentry
```

## Testes feitos

- Userscript com `rbw` simulado: usuário, Tab e senha enviados ao FIFO do qutebrowser; `--password-only` só a senha.
- Com o cofre real: `--username-only` em `https://github.com/login` achou a entrada e enviou o usuário. Preenchimento de senha com o cofre real e dentro de uma página real não foi testado.

## Problemas conhecidos

| Sintoma | Causa |
|---|---|
| `rbw list` pendura | Cofre travado e `pinentry` esperando; rodar `rbw unlock` |
| `agent is locked` | Passou o `lock_timeout` |
| `:adblock-update` mostra `Decompression failed: Brotli error` | URL de lista morta devolvendo 404 com corpo `br` quebrado. Foi `easylist-downloads.adblockplus.org/easylist-cookie.txt`; trocada por `secure.fanboy.co.nz/fanboy-cookiemonster.txt` |

Listas de bloqueio em `config.py`: conferir com `curl -s -o /dev/null -w '%{http_code}' URL` quando aparecer erro de download.
