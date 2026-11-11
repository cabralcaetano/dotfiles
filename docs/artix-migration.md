# Possível migração Arch → Artix Linux (em estudo, não decidido)

> **Status: pesquisa preliminar, sem decisão tomada.** Nada disso foi executado. Antes de avançar, o plano é estudar `systemd` a fundo primeiro — o motivo de considerar a troca é puramente organizacional (legibilidade/observabilidade dos serviços), não performance ou bug concreto. Se o estudo do systemd resolver o incômodo, a migração pode nem acontecer.

## Motivação

Não é insatisfação técnica pontual com o systemd — é o escopo dele (init + logging + network + resolved + timesyncd + udev + cgroups num binário só, com muita "mágica" de unit files) que incomoda no quesito organização/clareza. Artix = Arch sem systemd, mantendo pacman/AUR/repos Arch.

## Init systems considerados

| Init | Modelo | Supervisão de processo | Pacotes prontos no repo Artix | Curva |
|---|---|---|---|---|
| **OpenRC** | Dependency-based (`need`/`use`/`after` declarativo) | Não nativa — opt-in via `supervisor="supervise-daemon"` por serviço (ver abaixo) | Maior cobertura, é o init "padrão" da comunidade Artix | Baixa, parecido com sysvinit/bash |
| **runit** | Supervisão real por padrão, sem dependency resolution (ordem por convenção de symlink) | Nativa, todo serviço, sem config extra | Menor cobertura — serviço fora do comum exige escrever `run` script na mão | Muito baixa (minimalista) |
| s6 / s6-rc | Supervisão correta tecnicamente | Nativa | Comunidade pequena, doc escassa | Alta |
| dinit | Syntax amigável | Nativa | Ainda imaturo no Artix | Média |
| 66 | Nicho | Nativa | Pouquíssimo suporte | Alta |

Descartados da consideração real: s6/s6-rc, dinit, 66 — baixa cobertura de pacotes no repo Artix não compensa pro caso de uso (desktop pessoal, não servidor crítico).

**Entre OpenRC e runit, sem decisão ainda.** Resumo do trade-off:
- OpenRC: migração com menos atrito (mais pacotes com init script pronto), respawn automático existe mas é opt-in por serviço.
- runit: respawn automático em todo serviço por padrão, sem config extra; em troca, serviço "caseiro"/exótico exige escrever `run` script manualmente (não é difícil, mas é trabalho extra).
- Nenhum dos dois resolve o motivo organizacional de forma clara e diferente do outro — ambos são ordens de magnitude mais legíveis que unit files do systemd. A diferença de legibilidade entre eles é estilo (script bash com keywords vs. diretório de `run` scripts minimalistas), não substância.

### Supervisão de processo no OpenRC (caso decida por ele)

`supervise-daemon` (nativo do OpenRC, não pacote extra) reinicia processo automaticamente se ele morrer, sem watchdog externo. Precisa ser declarado por serviço no init script:

```sh
#!/sbin/openrc-run

name="meuservico"
command="/usr/bin/meudaemon"
command_args="--foreground --config /etc/meudaemon.conf"
command_user="meudaemon:meudaemon"
supervisor="supervise-daemon"
respawn_max=0        # 0 = respawn infinito
respawn_delay=5
```

Limitação: scripts prontos do repo Artix, em geral, ainda usam `start-stop-daemon` (sem respawn) por padrão — habilitar supervisão é edição manual serviço a serviço.

## Plano de teste seguro (quando/se avançar)

1. **Não trocar a máquina principal direto.** Testar em VM primeiro (mesmo hardware relevante emulado: rede, áudio, se possível GPU passthrough pra validar Hyprland).
2. Inventariar serviços systemd atuais em uso real antes de migrar — checar `systemctl list-unit-files --state=enabled` e `~/.config/systemd/user/` (ver `scripts/.config/systemd/user/` neste repo: `9router.service`, `chromium-duck.service`).
3. Mapear equivalente de cada serviço systemd pro init escolhido (unit `.service` → init script OpenRC ou `run` script runit) antes de migrar de fato.
4. Migração real fica fora de escopo do dotfiles atual (Hyprland/Waybar/tema) até decisão tomada — esse doc é só o registro da pesquisa pra retomar depois.

## Próximo passo

Estudar systemd a fundo (unit files, `systemctl`, journal, timers) antes de decidir se a troca resolve o incômodo organizacional ou se é desnecessária.
