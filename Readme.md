**ARCHIVED:** I am gradually moving my personal projects to Fossil.

## My Vim setup

My own Vim configuration. Some features:

- Foldable and thoroughly commented `vimrc`.
- Loads in way less than 50ms.
- Put your customizations into `vimrc_local`.
- Move freely between Vim and tmux using `⌥-h/j/k/l`
  (plugin-free, requires [some configuration](https://github.com/lifepillar/dotfiles/blob/master/dot-tmux.conf)
  in tmux, too).
- 40-column **cheat sheet** always two keys away (courtesy of
  [Cheat40](https://github.com/lifepillar/vim-cheat40)).
- Handcrafted, collapsible, fully customizable, **"plugin-free" status line**
  (let Vim spend a few tens of microseconds on updating the status line rather
  than the several milliseconds that plugins “as light as air” need). It used to
  support Powerline fonts up to commit
  [ca915737](https://github.com/lifepillar/vimrc/commit/ca9157376be876b030e5306adf38efd7093b870a),
  when I decided that simple is better (and Powerline fonts are an ugly hack
  anyway).
- Uses [Zeef](https://github.com/lifepillar/vim-zeef), aka wise man's CtrlP.
- **Distraction-free mode** (courtesy of
  [Goyo](https://github.com/junegunn/goyo.vim) and
  [Limelight](https://github.com/junegunn/limelight.vim)).
- Etc... (read the cheat sheet and the source!)


### Requirements

- A fairly recent Vim (7.4 or later) (`brew install vim` recommended on macOS).

Recommended:

- Vim 8.
- [Exuberant ctags](http://ctags.sourceforge.net);
- A fuzzy finder, one among
  [fzf](https://github.com/junegunn/fzf) (only the executable, not the Vim plugin),
  [fzy](https://github.com/jhawthorn/fzy),
  [pick](https://github.com/calleerlandsson/pick),
  [selecta](https://github.com/garybernhardt/selecta), or
  [skim](https://github.com/lotabout/skim);
- [ripgrep](https://github.com/BurntSushi/ripgrep).


### Installation

```sh
    cd ~
    git clone --depth 1 https://github.com/lifepillar/vimrc.git .vim
    cd .vim
    chmod 700 ./tmp ./tmp/{backup,swap,undo}
    git checkout -b local
    # We use shallow submodules; --remote makes sure we are able to check them out:
    git submodule update --init --remote
    # Commit changes (needed only if there are changes):
    git commit -a -m "Git submodule update --remote."
```


### Update

```sh
    cd ~/.vim
    git checkout master
    git pull origin master
    git submodule sync
    git submodule update --init --recursive
    git checkout local
    git rebase master
```

…and fix conflicts.


### Update plugins and colorschemes

Make sure the repo is in a clean state.

```sh
    git submodule update --remote --depth 1
    git commit -a
    git submodule update --recursive # Optional, only if there are plugins with submodules
```


### How to add a new plugin or colorscheme

To add a plugin `Foo` from `https://repo/foo.git`:

```sh
    git submodule add --name foo --depth 1 https://repo/foo.git pack/bundle/start/foo
    git config -f .gitmodules submodule.foo.shallow true
    git add .gitmodules
    git commit
```

To add `Foo` as an optional plugin, change `start` with `opt` (it works if Vim
has packages, otherwise you also have to add the plugin to
`g:pathogen_blacklist`).

To add a color scheme, change `bundle/start` with `bundle/opt` (create the
directory if it does not exist).


### Useful resources

- [VimGolf](https://vimgolf.com)
- [VimAwesome](https://vimawesome.com)
- [vimrcfu](https://vimrcfu.com)
- [vim-galore](https://github.com/mhinz/vim-galore)
- [vimcolors](https://vimcolors.com)

