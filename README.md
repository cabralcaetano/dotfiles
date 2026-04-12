# 🧩 Meu Setup Linux (Dotfiles)

Este repositório contém minhas configurações pessoais para ambiente Linux, incluindo Hyprland, Neovim, Zsh e outras ferramentas.

---

## 📸 Preview

(Coloque aqui prints do seu desktop depois)

---

## 🛠️ Programas usados

* Hyprland (window manager)
* Waybar (barra de status)
* Kitty (terminal)
* Neovim (editor)
* Zsh (shell)
* Tmux (multiplexador de terminal)

---

## 📁 Estrutura

```
dotfiles/
├── hypr/
├── waybar/
├── kitty/
├── nvim/
├── zsh/
├── scripts/
├── install/
└── README.md
```

---

## 🚀 Instalação

### 1. Clonar o repositório

```
git clone https://github.com/SEU_USUARIO/dotfiles.git
cd dotfiles
```

### 2. Rodar script de instalação

#### Arch Linux

```
bash install/arch.sh
```

#### Fedora

```
bash install/fedora.sh
```

---

## ⚙️ Como funciona

Este repositório usa **GNU Stow** para criar links simbólicos automaticamente.

Exemplo:

```
stow hypr
```

---

## 🧠 Observações

* Algumas configs podem precisar de ajustes dependendo do seu sistema
* Certifique-se de ter todas as dependências instaladas

---

## 📌 TODO

* [ ] Adicionar screenshots
* [ ] Melhorar scripts
* [ ] Documentar keybinds do Hyprland

---

## 📄 Licença

MIT
