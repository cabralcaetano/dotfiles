config.load_autoconfig()

# Bloqueio: listas estilo uBlock (precisa do pacote python-adblock) + hosts
c.content.blocking.enabled = True
c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
]

# Userscripts Greasemonkey (*.user.js) em ~/.config/qutebrowser/greasemonkey/
c.content.javascript.enabled = True

# Buscas
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "g": "https://www.google.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "aw": "https://wiki.archlinux.org/?search={}",
}

# Abas
c.tabs.show = "multiple"
c.tabs.last_close = "close"

# Restaura as abas da última sessão ao abrir (como o Chromium). Sem isso só
# `:wq` salva a sessão; fechar de qualquer outro jeito perde as abas.
c.auto_save.session = True

# Cores: geradas por theme-set.sh a partir de themes/<tema>/colors.toml
config.source("colors.py")

c.completion.open_categories = ["searchengines", "quickmarks", "bookmarks", "history"]

# Atualiza as listas de bloqueio
config.bind(",u", "adblock-update")

# Alt+N vai para a aba N
for i in range(1, 10):
    config.bind(f"<Alt+{i}>", f"tab-focus {i}")

# Bitwarden via rbw (userscripts/qute-rbw). Foque o campo e use o atalho.
config.bind(",p", "spawn --userscript qute-rbw")
config.bind(",P", "spawn --userscript qute-rbw --password-only")
