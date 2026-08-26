# RAM alto por múltiplos engines de navegador — solução proposta (perfis do Brave)

**Status:** proposta testada ao vivo, **não aplicada** e **não commitada**. O
script já existe, prototipado e verificado numa sessão com Claude/OMP, em
`~/Projects/dotfiles/scripts/.local/bin/brave-profile.sh` (working tree do
repo real, fora deste submodule) — só não foi commitado nem usado ainda para
substituir a sessão atual do Contab OS.

## Contexto do problema

Setup de "super workspaces" (ver [[hyprland-super-workspaces]]):

- Super workspace 1: Brave (WhatsApp/trabalho), Spotify nativo, Discord nativo.
- Super workspace 2: Contab OS (software de contabilidade em desenvolvimento),
  rodando localhost, aberto num `chromium` **separado** do Brave.
- Super workspace 3 (planejado): outro navegador só para pesquisa de um
  segundo software em desenvolvimento.

Cada engine de navegador diferente rodando ao mesmo tempo (Brave + Chromium)
sobe seu próprio processo principal, GPU process, network service e par de
zygotes — overhead de infraestrutura duplicado antes de qualquer aba de
conteúdo real.

## Evidência medida (nesta máquina, sessão real)

- `chromium` solo (sem `--app=`, só pra hospedar 1 aba de `localhost` do
  Contab OS): **~2.6GB de RSS** somando toda a família de processos
  (principal + GPU 266MB + network service 96MB + zygotes ~140MB + crashpad +
  renderer de UI `top-chrome-webui` 169MB + abas).
- Brave (tudo: WhatsApp, abas de trabalho): ~4.1–4.3GB, mas sob **um único**
  processo principal (`pid` fixo) — todas as janelas/abas dele já
  compartilham GPU/network/zygote entre si.
- `earlyoom` já está configurado com `--prefer` incluindo
  `brave|electron|Discord|node|bun|chrome|chromium|spotify` — ou seja, o
  sistema já mitiga picos de OOM matando esses processos primeiro, mas isso é
  sintoma, não causa.

## Mecanismo testado

Abrir um `--profile-directory=<Nome>` **dentro do mesmo `--user-data-dir`**
de um Brave que já está rodando **não** sobe processo principal, GPU nem
network service novos — confirmado via `ps` antes/depois em teste ao vivo
(lançado, verificado, fechado). Só sobe um `renderer` para a janela, o mesmo
custo de abrir mais uma aba/janela normal. O profile fica isolado
(cookies/sessão/histórico próprios), o engine pesado é compartilhado.

Classe de janela resultante no Hyprland: `brave-<host>__-<Profile>` (ex.:
`brave-localhost__-ContabOS`).

**Gotcha descoberto:** como o Brave já está rodando (instância única), o
processo que a gente spawna só sinaliza a instância existente e sai — a
janela real pertence ao PID do Brave já rodando. Isso quebra o
`workspace = "..."` passado direto no `exec_cmd` do Hyprland (a regra fica
atrelada ao PID do processo temporário, que já morreu). Solução: esperar a
janela aparecer pela classe (poll) e mover ela manualmente
(`hl.dsp.window.move`) pro slot certo, sem roubar o foco atual.

## Script já escrito (não commitado)

`~/Projects/dotfiles/scripts/.local/bin/brave-profile.sh <profile> <slot ex: super-2-1> [url]`:

- Sem janela existente desse profile: dispara `brave --profile-directory=<profile> [--app=<url>]`,
  espera aparecer (até 10s) e move pro slot indicado, sem trocar o foco atual.
- Com `[url]`: app-mode (`--app=`, sem chrome de abas/bookmarks — mais leve
  para janela de propósito único).
- Já existe janela desse profile: só foca ela (dedupe — testado, não duplica
  em segunda chamada).

Aplicação prevista quando decidir aplicar (troca o `chromium` solo do
Contab OS por um profile do Brave):

```bash
brave-profile.sh ContabOS super-2-1 "http://localhost:PORTA"
```

Navegador de pesquisa do super workspace 3 (múltiplas abas, sem app-mode):

```bash
brave-profile.sh Research super-3-1
```

Também precisa de uma entrada em `docs/hyprland-super-workspaces.md` (seção
"Perfis de navegador on-demand (RAM)") — já redigida no repo real
(`~/Projects/dotfiles`), também não commitada ainda.

## Decisão consciente: Spotify e Discord ficam nativos

Cada um também paga o mesmo tipo de tax (GPU + zygote + network service
próprios, como qualquer app Electron/Chromium), mas migrar pra abas do Brave
**não compensa**: `ducking/ducking.md` e `scripts/.local/bin/brave-duck.sh`
identificam o Spotify pelo client nativo no PipeWire (`get_spotify_id` via
`wpctl status`). Virando aba do Brave, o áudio apareceria como cliente
"brave" e o ducking automático (abaixar volume do Spotify quando o Brave
toca áudio) pararia de funcionar. Mantém os dois nativos.

## Próximo passo (quando decidir aplicar)

1. Revisar o diff em `~/Projects/dotfiles` (`scripts/.local/bin/brave-profile.sh`
   novo + seção nova em `docs/hyprland-super-workspaces.md`).
2. Rodar `brave-profile.sh ContabOS super-2-1 "http://localhost:PORTA"` com a
   porta real do Contab OS.
3. Fechar manualmente a janela antiga do `chromium` solo.
4. Só então, se quiser, commitar no repo real.
