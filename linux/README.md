# How to Install Modern Shell Tools on Debian 12/13

This guide provides the steps to install and configure `bat` (a `cat` replacement) and `eza` (an `ls` replacement) on a Debian 12 (Bookworm) or Debian 13 (Trixie) system.

---

## 1. Install `bat` (a modern `cat`)

On Debian systems, the `bat` package is available in the default repositories. The binary is often named `batcat` to prevent name conflicts.

1.  **Update your package lists:**
    ```bash
    sudo apt update
    ```
2.  **Install the `bat` package:**
    ```bash
    sudo apt install bat
    ```
3.  **Verify the installation:**
    You can check the version and the binary name.
    ```bash
    bat --version
    ```
    If your system uses the `batcat` binary, you can check for it with `ls -l /usr/bin/bat*`. We will use `batcat` in the alias for safety.

---

## 2. Install `eza` (a modern `ls`)

The `apt` repository for `eza` can sometimes have network or DNS issues. The most reliable method is to download the pre-compiled binary directly from GitHub.

1.  **Navigate to a temporary directory:**
    ```bash
    cd /tmp
    ```
2.  **Download the latest release:**
    This command grabs the `x86_64` (standard 64-bit) binary.
    ```bash
    wget https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
    ```
3.  **Extract the binary:**
    ```bash
    tar xvf eza_x86_64-unknown-linux-gnu.tar.gz
    ```
4.  **Move the binary to your system path:**
    This makes the `eza` command available system-wide.
    ```bash
    sudo mv eza /usr/local/bin/
    ```
5.  **Clean up the downloaded file:**
    ```bash
    rm eza_x86_64-unknown-linux-gnu.tar.gz
    ```
6.  **Verify the installation:**
    ```bash
    eza --version
    ```

---

## 3. Configure Your `.bashrc`

Here is a complete `.bashrc` file you can use. It's based on your provided file but includes enhanced color settings for better visibility and a full set of useful aliases for your new tools.

1.  **Open your `.bashrc` file:**
    ```bash
    nano ~/.bashrc
    ```
2.  **Delete everything** in the file and **paste all the code below:**

    ```bash
    # ~/.bashrc: executed by bash(1) for non-login shells.
    # see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
    # for examples

    # If not running interactively, don't do anything
    case $- in
        *i*) ;;
          *) return;;
    esac

    # don't put duplicate lines or lines starting with space in the history.
    # See bash(1) for more options
    HISTCONTROL=ignoreboth

    # append to the history file, don't overwrite it
    shopt -s histappend

    # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
    HISTSIZE=1000
    HISTFILESIZE=2000

    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # If set, the pattern "**" used in a pathname expansion context will
    # match all files and zero or more directories and subdirectories.
    #shopt -s globstar

    # make less more friendly for non-text input files, see lesspipe(1)
    #[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

    # set variable identifying the chroot you work in (used in the prompt below)
    if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=$(cat /etc/debian_chroot)
    fi

    # set a fancy prompt (non-color, unless we know we "want" color)
    case "$TERM" in
        xterm-color|*-256color) color_prompt=yes;;
    esac

    # uncomment for a colored prompt, if the terminal has the capability; turned
    # off by default to not distract the user: the focus in a terminal window
    # should be on the output of commands, not on the prompt
    #force_color_prompt=yes

    if [ -n "$force_color_prompt" ]; then
        if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
            # We have color support; assume it's compliant with Ecma-48
            # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
            # a case would tend to support setf rather than setaf.)
            color_prompt=yes
        else
            color_prompt=
        fi
    fi

    if [ "$color_prompt" = yes ]; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    else
        PS1='${debian_chrot:+($debian_chroot)}\u@\h:\w\$ '
    fi
    unset color_prompt force_color_prompt

    # If this is an xterm set the title to user@host:dir
    case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
    esac

    # enable color support of ls and also add handy aliases
    # This is now handled by eza, but we keep the check.
    if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi

    # colored GCC warnings and errors
    #export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

    # --- Eza Color Customization for Better Visibility ---
    # This configures eza to use brighter, more visible colors
    # Especially useful on dark terminal backgrounds
    export EZA_COLORS="uu=38;5;249:gu=38;5;249:sn=38;5;249:sb=38;5;249:da=38;5;249:ur=38;5;220:uw=38;5;203:ux=38;5;148:ue=38;5;148:gr=38;5;220:gw=38;5;203:gx=38;5;148:tr=38;5;220:tw=38;5;203:tx=38;5;148:di=1;34:ex=1;32"

    # Color codes explained:
    # uu/gu = user/group (249 = light gray)
    # sn/sb = size number/size unit (249 = light gray)
    # da = date (249 = light gray)
    # ur/gr/tr = read permission (220 = bright yellow)
    # uw/gw/tw = write permission (203 = bright red)
    # ux/gx/tx = execute permission (148 = bright green)
    # di = directories (1;34 = bold blue)
    # ex = executables (1;32 = bold green)

    # --- Custom Aliases for eza and bat ---

    # History
    alias h='history'

    # eza aliases (replaces ls)
    alias ls='eza --icons --git'                                # basic ls
    alias l='eza -l --icons --git'                              # long format
    alias la='eza -la --icons --git'                            # long format, all files
    alias ll='eza -lA --header --icons --git --color=always'    # enhanced ll with forced colors
    alias lt='eza --tree --level=2 --icons --git'               # a handy tree view

    # bat alias (replaces cat)
    # Use 'batcat' as it's the collision-safe name on Debian
    alias cat='batcat -p'

    # Additional modern CLI tools
    alias top='btop'           # Replace top with btop
    alias htop='btop'          # Replace htop with btop  
    alias lg='lazygit'         # Quick lazygit access
    alias du='ncdu --color dark -rr -x'  # Better disk usage

    # ----------------------------------------

    # Alias definitions.
    # You may want to put all your additions into a separate file like
    # ~/.bash_aliases, instead of adding them here directly.
    # See /usr/share/doc/bash-doc/examples in the bash-doc package.

    if [ -f ~/.bash_aliases ]; then
        . ~/.bash_aliases
    fi

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
    # sources /etc/bash.bashrc).
    if ! shopt -oq posix; then
      if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
      elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
      fi
    fi
    ```

---

## 4. Apply Your New Configuration

Your shell won't see the new file until you source it.

1.  **Run this command to load the new `.bashrc`:**
    ```bash
    source ~/.bashrc
    ```
2.  **Test your new aliases:**
    * Type `ll` - should show bright, readable colors
    * Type `la` - long listing with all files
    * Type `cat ~/.bashrc` - should open with `bat`'s syntax highlighting
    * Type `lt` - shows a nice tree view

---

## 5. Troubleshooting Dark Colors

If you still find the output too dark after applying the configuration above, try these additional options:

### Option 1: Use Color Scale
Add `--color-scale` or `--color-scale=all` to your `ll` alias:
```bash
alias ll='eza -lA --header --icons --git --color=always --color-scale=all'
```

### Option 2: Adjust Terminal Theme
Check your terminal emulator's color scheme settings. Dark blue colors may appear very dark on some terminal themes. Consider using:
- A terminal theme with better contrast
- Light background themes if dark colors are consistently hard to read

### Option 3: Custom Color Values
You can further customize the `EZA_COLORS` variable. Here are some alternative bright color values:
- Replace `249` (light gray) with `254` (brighter gray)
- Replace `220` (yellow) with `226` (bright yellow)
- Replace `203` (red) with `196` (bright red)
- Replace `148` (green) with `46` (bright green)

### Option 4: Test Individual Colors
To see all 256 colors available in your terminal:
```bash
for i in {0..255}; do printf "\x1b[38;5;${i}mcolor%-5i\x1b[0m" $i ; if ! (( ($i + 1 ) % 8 )); then echo ; fi ; done
```

Choose colors that look good on your terminal and update the `EZA_COLORS` accordingly.

---

## 6. Additional Useful Shell Tools

Beyond `bat` and `eza`, here are some other excellent modern CLI tools that enhance your terminal experience:

### 6.1 Install `ncdu` (NCurses Disk Usage)

A fast disk usage analyzer with an ncurses interface - much better than `du`.

```bash
sudo apt install ncdu
```

**Usage:**
```bash
ncdu /path/to/directory    # Analyze a specific directory
ncdu ~                     # Analyze your home directory
ncdu /                     # Analyze entire filesystem (as root)
```

**Pro tip:** Add an alias to your `.bashrc`:
```bash
alias du='ncdu --color dark -rr -x'
```

### 6.2 Install `btop` (Resource Monitor)

A beautiful resource monitor showing CPU, memory, disks, network, and processes - the modern replacement for `htop` and `top`.

```bash
sudo apt install btop
```

**Usage:**
```bash
btop    # Launch the interactive resource monitor
```

**Configuration:** Press `ESC` or `M` in btop to access the menu for themes and settings.

### 6.3 Install `lazygit` (Terminal UI for Git)

A fantastic terminal UI for git commands - makes git operations visual and intuitive.

**Installation via binary (recommended for latest version):**
```bash
cd /tmp
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz
sudo mv lazygit /usr/local/bin/
rm lazygit.tar.gz
```

**Verify installation:**
```bash
lazygit --version
```

**Usage:**
```bash
lazygit    # Launch in current git repository
```

**Key shortcuts:**
- `1-5`: Switch between panels (Status, Files, Branches, Commits, Stash)
- `Space`: Stage/unstage files
- `c`: Commit
- `P`: Push
- `p`: Pull
- `x`: Open command menu
- `?`: Help

### 6.4 Other Recommended Tools

Here are a few more modern CLI tools worth considering:

**`fd` - A fast alternative to `find`:**
```bash
sudo apt install fd-find
# Create alias if binary is named fd-find
alias fd='fdfind'
```

**`ripgrep` (rg) - A faster grep:**
```bash
sudo apt install ripgrep
```

**`tldr` - Simplified man pages:**
```bash
sudo apt install tldr
tldr tar    # Get simple examples for tar command
```

**`duf` - Better disk usage display:**
```bash
# Install via binary
cd /tmp
wget https://github.com/muesli/duf/releases/latest/download/duf_0.8.1_linux_amd64.deb
sudo dpkg -i duf_0.8.1_linux_amd64.deb
rm duf_0.8.1_linux_amd64.deb
```

### 6.5 Updated `.bashrc` with Additional Aliases

Add these aliases to your `.bashrc` for quick access:

```bash
# Additional tool aliases
alias top='btop'           # Replace top with btop
alias htop='btop'          # Replace htop with btop
alias lg='lazygit'         # Quick lazygit access
alias find='fdfind'        # Use fd instead of find (if fd-find installed)
```

---

## 7. Additional Useful Aliases

Consider adding these extra aliases for enhanced productivity:

```bash
# More eza variations
alias lsa='eza -la --header --icons --git --sort=modified'  # sorted by modification time
alias lsd='eza -lD --icons --git'                            # directories only
alias lsf='eza -lf --icons --git'                            # files only

# Git-aware listings
alias lsg='eza -la --header --icons --git --git-ignore'       # respects .gitignore

# Colorized grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
```

Your shell environment is now upgraded with enhanced visibility!