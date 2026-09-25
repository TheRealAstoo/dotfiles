# Dotfiles — installation

My personal macOS dotfiles, managed with [rcm](https://github.com/thoughtbot/rcm)
(`rcup`) and [Homebrew](https://brew.sh). SSH is handled by the **1Password SSH
agent** — no private key on disk.

## Prerequisites

- A Mac (Apple Silicon or Intel) with an internet connection.
- A GitHub account and a 1Password account.
- `git` is already available on macOS through the Xcode Command Line Tools
  (Homebrew installs them if missing).

## 1. Set up 1Password + your SSH key (do this first)

1Password holds the key and acts as the SSH agent, so it must be ready before you
can clone over SSH.

1. Install the 1Password app and sign in (download from
   <https://1password.com/downloads>).
2. Enable the agent: **1Password → Settings → Developer → "Use the SSH agent"**.
3. Create the key: **New Item → SSH Key → generate** (ed25519). The private key
   stays in your vault; nothing is written to disk.
4. Add it to GitHub: copy the public key 1Password shows you → **GitHub →
   Settings → SSH and GPG keys → New SSH key**, type *Authentication*.

## 2. Install Homebrew

Run the install command from <https://brew.sh>, then add `brew` to your `PATH`
(Apple Silicon):

```shell
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version
```

## 3. Clone the dotfiles

Your `~/.ssh/config` (which points SSH at the 1Password agent) isn't in place yet,
so point SSH at the agent socket for this first clone:

```shell
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
ssh -T git@github.com   # optional check — approve in 1Password; exits 1 even on success
git clone git@github.com:TheRealAstoo/dotfiles.git ~/.dotfiles
```

> Keep this same terminal open for the next steps so `SSH_AUTH_SOCK` stays set.
> Once your dotfiles are linked (step 5), your shell/SSH config sets this
> permanently and you won't need the export again.

## 4. Install everything from the Brewfile

```shell
brew bundle --file ~/.dotfiles/Brewfile
```

This installs `rcm`, `asdf`, VS Code and everything else.

## 5. Symlink the dotfiles into your home directory

```shell
rcup
```

Your Git name and settings come from the repo's `gitconfig` (symlinked here). Your
per-identity email and signing key are set up in the next section.

> If `rcup` conflicts with a file that already exists — typically `~/.zprofile`,
> which Homebrew writes during install — back it up and re-run with `rcup -f`.

## 6. Install the language runtimes (asdf)

`asdf` reads `~/.tool-versions` (symlinked in the previous step):

```shell
asdf plugin add nodejs
asdf plugin add yarn
asdf install
asdf list nodejs
node --version && yarn --version
```

## 7. Reload your shell

```shell
exec zsh
```

...or just open a new terminal window.

## 8. Set up your Git identities (perso / work)

The committed `gitconfig` signs commits with SSH and routes your **email +
signing key** by folder with `includeIf`:

```
# already in the repo's gitconfig
[includeIf "gitdir:~/Workspace/Perso/"]
    path = ~/Workspace/Perso/.gitconfig
[includeIf "gitdir:~/Workspace/Work/"]
    path = ~/Workspace/Work/.gitconfig
```

So any repo you clone under `~/Workspace/Perso/` or `~/Workspace/Work/` picks up
the matching identity automatically. Create the two local files — they're
machine-local and not committed, so your work email stays out of the public repo.
Get each **public** signing key from 1Password (open the SSH key item → copy the
public key):

```shell
mkdir -p ~/Workspace/Perso ~/Workspace/Work

cat > ~/Workspace/Perso/.gitconfig <<'CFG'
[user]
    email = louis.fanien@gmail.com
    signingkey = ssh-ed25519 AAAA...   # personal key (public) from 1Password
CFG

cat > ~/Workspace/Work/.gitconfig <<'CFG'
[user]
    email = you@yourcompany.com
    signingkey = ssh-ed25519 AAAA...   # work key (public) from 1Password
CFG
```

Add each **public** key to the matching GitHub/GitLab account as a **Signing**
key (separate from the Authentication key), then clone your projects under the
right folder (e.g. `~/Workspace/Work/<repo>`).

## Restoring your secrets (optional)

The shell config sources `~/.dotfiles/.secrets` **only if it exists** (the line is
guarded), so a fresh install works fine without it. If you have secrets to restore
— API tokens, deploy credentials, etc. — create the file and add your exports:

```shell
touch ~/.dotfiles/.secrets
# add "export KEY=value" lines as needed (gitignored, never committed)
```

---

## Notes

- **SSH via 1Password:** Git authenticates through the 1Password agent, so the
  repo's `gitconfig` does **not** pin an on-disk key in `core.sshCommand` (no
  `-i ~/.ssh/id_ed25519`) — the agent provides the key. The persistent setting
  lives in `~/.ssh/config` as
  `IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"`.
- **Commit signing:** the `gitconfig` signs commits through 1Password
  (`gpg.format = ssh`, `gpg.ssh.program = .../op-ssh-sign`, `commit.gpgsign =
  true`). The per-identity `signingkey` lives in each `~/Workspace/*/.gitconfig`
  (step 8). Toggle globally with `git config --global commit.gpgsign false`, or
  per-commit with `git commit --no-gpg-sign`.
- **asdf shell setup:** the shell config puts asdf's shims on the `PATH`
  (`export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"`). Recent asdf (Go
  rewrite, 0.16+) no longer ships an `asdf.sh` to source.
- **Editor:** `gitconfig` uses `code --wait`. VS Code is in the Brewfile; if the
  `code` command isn't on your `PATH`, run *"Shell Command: Install 'code'
  command in PATH"* from VS Code's command palette.

## Not using 1Password? (fallback — traditional on-disk key)

<details>
<summary>Show steps</summary>

```shell
ssh-keygen -t ed25519 -C "you@example.com"   # SET A PASSPHRASE
```

Add to `~/.ssh/config`:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

```shell
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub   # add at https://github.com/settings/ssh/new
```

Then clone normally (skip the `SSH_AUTH_SOCK` export in step 3). SSH finds
`~/.ssh/id_ed25519` by default, so `gitconfig` still needs no `-i`.
</details>

## Optional — oh-my-zsh

If your `.zshrc` depends on [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh),
install it **after step 5** with `--keep-zshrc` so it doesn't overwrite the
`.zshrc` that `rcup` just symlinked:

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
```

Then re-run step 7.