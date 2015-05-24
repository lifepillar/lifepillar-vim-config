" Modeline and Notes {{
" vim: set sw=3 ts=3 sts=0 noet tw=78 fo-=o foldmarker={{,}} foldlevel=0 foldmethod=marker foldtext=substitute(getline(v\:foldstart),'\\"\\s\\\|\{\{','','g') nospell:
"
" Remember to check "Set locale environment variables on startup" in OS X Terminal.app's preferences.
" }}
" Environment {{
	set nocompatible " Must be first line.
	" See http://stackoverflow.com/questions/18321538/vim-error-e474-invalid-argument-listchars-tab-trail
	scriptencoding utf-8
	set encoding=utf-8
	set termencoding=utf-8
	set nobomb
	set fileformats=unix,mac,dos
	set ttimeoutlen=100 " Faster feedback in status line when returning to normal mode
	set ttyfast
	syntax enable
	filetype on " Enable file type detection.
	filetype plugin on " Enable loading the plugin files for specific file types.
	filetype indent on " Load indent files for specific file types.
	runtime bundle/pathogen/autoload/pathogen.vim " Load Pathogen.
	execute pathogen#infect()
	set sessionoptions-=options " See FAQ at https://github.com/tpope/vim-pathogen.
	set autoread " Re-read file if it is changed by an external program.
	set hidden " Allow buffer switching without saving.
	set formatoptions-=o " Do not automatically insert comment when opening a line
	set formatoptions+=j " Remove extra comment when joining lines
	set history=1000 " Keep a longer history.
	" Consolidate temporary files in a central spot
	set backupdir=~/.vim/tmp
	set directory=~/.vim/tmp
	set viminfo+=n~/.vim/viminfo
	set undofile
	set undodir=~/.vim/tmp
	set undolevels=1000         " Maximum number of changes that can be undone.
	set undoreload=10000        " Maximum number lines to save for undo on a buffer reload.
	set nobackup " Do not keep a backup copy of a file.
	set nowritebackup " Don't write temporary backup files.
" }}
" File-type specific configuration {{
	autocmd BufNewFile,BufReadPost *.md,*.mmd setlocal filetype=markdown dictionary=/usr/share/dict/words spell spelllang=en
	autocmd BufNewFile,BufReadPost *.txt setlocal dictionary=/usr/share/dict/words spell spelllang=en
	" Instead of reverting the cursor to the last position in the buffer, we
	" set it to the first line when editing a git commit message
	au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
" }}
" Helper functions {{
	" Set the tab width in the current buffer (see also http://vim.wikia.com/wiki/Indenting_source_code).
	func! SetTabWidth(w)
		let twd=(a:w>0)?(a:w):1 " Disallow non-positive width
		" For the following assignment, see :help let-&.
		" See also http://stackoverflow.com/questions/12170606/how-to-set-numeric-variables-in-vim-functions.
		let &l:tabstop=twd
		let &l:shiftwidth=twd
		let &l:softtabstop=twd
	endfunc

	" Set the tab width globally.
	func! SetGlobalTabWidth(w)
		let twd=(a:w>0)?(a:w):1
		let &tabstop=twd
		let &shiftwidth=twd
		let &softtabstop=twd
	endfunc

	" Alter the tab width in the current buffer.
	" To decrease the tab width, pass a negative value.
	func! IncreaseTabWidth(incr)
		call SetTabWidth(&tabstop + a:incr)
	endfunc

	" Delete trailing white space.
	func! RemoveTrailingSpace()
		" Save window state
		let l:winview = winsaveview()
		%s/\s\+$//ge
		" Restore window state
		call winrestview(l:winview)
	endfunc

	func! ToggleBackgroundColor()
		" Seoul256 with custom background colors requires
		" special treatment to switch between dark and light background:
		if exists('g:colors_name')
			if g:colors_name ==# 'seoul256'
				colorscheme seoul256-light
				return
			elseif g:colors_name ==# 'seoul256-light'
				colorscheme seoul256
				return
			endif
		endif
		let &background = (&background == 'dark') ? 'light' : 'dark'
	endfunc

	" See http://stackoverflow.com/questions/4064651/what-is-the-best-way-to-do-smooth-scrolling-in-vim
	func! SmoothScroll(up)
		let scrollaction = a:up ? "\<C-y>" : "\<C-e>"
		exec "normal" scrollaction
		redraw
		let counter = 1
		while counter < &scroll
			let counter += 2
			sleep 10m
			redraw
			exec "normal" scrollaction
		endwhile
	endfunc

	" Move the cursor to the specified column,
	" filling the line with spaces if necessary.
	func! GotoCol(pos)
		exec "normal" a:pos . "|"
		let diff = a:pos - virtcol('.')
		if diff > 0 | exec "normal" diff . "a " | endif
	endfunc

	" Find all occurrences of a pattern in a file.
	func! FindAll(pattern)
		exec "noautocmd lvimgrep " . a:pattern . " % | lopen"
	endfunc

	" Find all occurrences of a pattern in all open files.
	func! MultiFind(pattern)
		exec "noautocmd bufdo vimgrepadd " . a:pattern . " % | copen"
	endfunc

	" Run an external command and display its output in a new buffer.
	" cmdline: the command to be executed;
	" pos: a letter specifying the position of the output window.
	" See http://vim.wikia.com/wiki/Display_output_of_shell_commands_in_new_window
	" See also https://groups.google.com/forum/#!topic/vim_use/4ZejMpt7TeU
	func! RunShellCommand(cmdline, pos) abort
		let winpos_map = {
			\ "T": "to new",  "t": "abo new", "B": "bo new",  "b": "bel new",
			\ "L": "to vnew", "l": "abo vnew", "R": "bo vnew", "r": "bel vnew"
			\ }
		let cmd = ""
		for part in split(a:cmdline, ' ')
			if part =~ '\v^[%#<]'
				let expanded_part = expand(part)
				let cmd .= ' ' . (expanded_part == "" ? part : shellescape(expanded_part))
			else
				let cmd .= ' ' . part
			endif
		endfor
		exec get(winpos_map, a:pos, "bo new")
		setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
		execute '%!'. cmd
		setlocal nomodifiable
		"echomsg cmd  " Uncomment this for debugging
		1
	endfunc

	command! -complete=shellcmd -nargs=+ Shell      call RunShellCommand(<q-args>, "B")
	command! -complete=shellcmd -nargs=+ ShellRight call RunShellCommand(<q-args>, "R")
	command! -complete=shellcmd -nargs=+ ShellTop   call RunShellCommand(<q-args>, "T")

	" Execute a non-interactive Git command in the directory containing
	" the file of the current buffer, and send the output to a new buffer.
	" args: a string of arguments for the commmand
	" pos: a letter specifying the position of the new buffer (see RunShellCommand()).
	func! Git(args, pos)
		call RunShellCommand("git -C %:p:h " . a:args, a:pos)
	endfunc

	" Execute an arbitrary (non-interactive) Git command and show the output in a new buffer.
	command! -complete=shellcmd -nargs=+ Git call Git(<q-args>, "B")

	" Show a vertical diff (use <C-w> K to arrange horizontally)
	" between the current buffer and its last committed version.
	func! GitDiff()
		let ft = getbufvar("%", '&ft') " Get the file type
		call Git("show HEAD:./" . shellescape(expand("%:t")), 'r')
		let &l:filetype = ft
		au BufWinLeave <buffer> diffoff!
		diffthis
		wincmd p
		diffthis
	endfunc

	" Show a three-way diff. Useful for fixing merge conflicts.
	" This assumes that the current file is the working copy, of course.
	func! Git3WayDiff()
		let filename = shellescape(expand("%:t"))
		let ft = getbufvar("%", "&ft") " Get the file type
		" Show the version from the current branch on the left
		call Git("show :2:./" . filename, "l")
		let &l:filetype = ft
		au BufWinLeave <buffer> diffoff!
		diffthis
		wincmd p
		" Show version from the other branch on the right
		call Git("show :3:./" . filename, "r")
		let &l:filetype = ft
		au BufWinLeave <buffer> diffoff!
		diffthis
		wincmd p
		diffthis
	endfunc

	command! -nargs=0 Conflicts call Git3WayDiff()
" }}
" Editing {{
	set backspace=indent,eol,start " Intuitive backspacing in insert mode.
	set whichwrap+=<,>,[,],h,l " More intuitive arrow movements.
	set scrolloff=999 " Keep the edited line vertically centered.
	" set clipboard=unnamed " Use system clipboard by default.
	" Smooth scrolling that works both in terminal and in MacVim
	nnoremap <C-U> :call SmoothScroll(1)<Enter>
	nnoremap <C-D> :call SmoothScroll(0)<Enter>
	" Scroll the viewport faster.
	nnoremap <C-e> <C-e><C-e>
	nnoremap <C-y> <C-y><C-y>
	" Easier horizontal scrolling
	nnoremap zl 10zl
	nnoremap zh 10zh
	set showmatch " Show matching brackets/parenthesis
	set matchtime=2 " show matching bracket for 0.2 seconds
	set nojoinspaces " Prevents inserting two spaces after punctuation on a join (J)
	set splitright " Puts new vsplit windows to the right of the current
	set splitbelow " Puts new split windows to the bottom of the current
	" Load matchit.vim, but only if the user hasn't installed a newer version.
	if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
		runtime! macros/matchit.vim " Enable % to go to matching keyword/tag.
	endif
	" Shift left/right repeatedly
	vnoremap > >gv
	vnoremap < <gv
	" Use soft tabs by default
	set expandtab
	call SetGlobalTabWidth(2)
" }}
" Find, replace, and auto-complete {{
	" set gdefault " Apply substitutions globally by default
	" set hlsearch " Highlight search terms.
	set incsearch " Search as you type.
	set ignorecase " Case-insensitive search by default.
	set smartcase " Use case-sensitive search if there is a capital letter in the search expression.
	set wildmenu " Show possible matches when autocompleting.
	set wildignorecase " Ignore case when completing file names and directories.
	" set wildmode=list:longest,full " Command <Tab> completion, list matches, then longest common part, then all.
	" Find all in current buffer
	command! -nargs=1 FindAll call FindAll(<q-args>)
	" Find all in all open buffers
	command! -nargs=1 MultiFind call MultiFind(<q-args>)
" }}
" Key mappings (plugins excluded) {{
	" Swap ; and :  Convenient.
	nnoremap ; :
	nnoremap : ;
	vnoremap ; :
	vnoremap : ;
	let mapleader = ","
	" A handy cheat sheet ;)
	nnoremap <silent> <Leader>cs :botright vert 40sview ${HOME}/.vim/cheatsheet.txt<CR>
	" Toggle between hard tabs and soft tabs in the current buffer
	nnoremap <silent> <Leader>t :setlocal invexpandtab<CR>
	" Increase tab width by one in the current buffer
	nnoremap <silent> + :call IncreaseTabWidth(+1)<CR>
	" Decrease tab width by one in the current buffer
	nnoremap <silent> - :call IncreaseTabWidth(-1)<CR>
	" Add blank line below or above the current line, but stay in normal mode
	" (see http://vim.wikia.com/wiki/Quickly_adding_and_deleting_empty_lines)
	" (see also http://stackoverflow.com/questions/16359878/vim-how-to-map-shift-enter)
	nnoremap <silent> <Leader>j :set paste<CR>m`o<Esc>``:set nopaste<CR>
	nnoremap <silent> <Leader>k :set paste<CR>m`O<Esc>``:set nopaste<CR>
	" Select all with ,A
	nnoremap <silent> <Leader>A ggVG
	" Toggle invisibles in the current buffer with ,i
	nnoremap <silent> <Leader>i :setlocal nolist!<CR>
	" Toggle spelling in the current buffer with ,s
	nnoremap <silent> <Leader>s :setlocal spell!<CR>
	" Remove trailing space globally with ,ts
	nnoremap <Leader>ts :call RemoveTrailingSpace()<CR>
	" Capitalize words in selected text with ,U (see h gU)
	vnoremap <silent> <Leader>U :s/\v<(.)(\w*)/\u\1\L\2/g<CR>
	" Toggle search highlighting with ,h
	nnoremap <silent> <Leader>h :set invhlsearch<CR>
	" Hard-wrap paragraphs at textwidth with ,r
	nnoremap <silent> <leader>r gwap
	" Mappings to access buffers.
	" ,b       : show the list of buffers
	nnoremap <Leader>b :ls<CR>
	" Remap H,L, and M to go to previous/next/last used buffer
	nnoremap H :bp<CR>
	nnoremap L :bn<CR>
	nnoremap M :e#<CR>
	" Move between windows with ctrl-h/j/k/l
	nnoremap <silent> <C-h> <C-w>h
	nnoremap <silent> <C-j> <C-w>j
	nnoremap <silent> <C-k> <C-w>k
	nnoremap <silent> <C-l> <C-w>l
	" ,1 ,2 ,3 : go to tab 1/2/3 etc
	nnoremap <Leader>1 1gt
	nnoremap <Leader>2 2gt
	nnoremap <Leader>3 3gt
	nnoremap <Leader>4 4gt
	nnoremap <Leader>5 5gt
	nnoremap <Leader>6 6gt
	nnoremap <Leader>7 7gt
	nnoremap <Leader>8 8gt
	nnoremap <Leader>9 9gt
	nnoremap <Leader>0 10gt
	" Toggle absolute line numbers with ,n
	nnoremap <silent> <Leader>N :set invnumber<CR>:set nornu<CR>
	" Toggle relative line numbers with ,m
	nnoremap <silent> <Leader>M :set invnumber<CR>:set rnu<CR>
	" Toggle background color with F7
	noremap <silent> <F7> :call ToggleBackgroundColor()<CR>
	" Apply 'git diff' to the current buffer with ,gd
	nnoremap <silent> <Leader>gd :call GitDiff()<CR>
	" Show the output of 'git status' with ,gs
	nnoremap <silent> <Leader>gs :Git status<CR>:setlocal ft=gitcommit<CR>
	" Invoke 'git commit' with ,gc (must be set up on the Git side)
	nnoremap <silent> <Leader>gc :!git -C %:p:h commit<CR>
	" Show the revision history for the current file with ,gl
	nnoremap <silent> <Leader>gl :Git log --oneline -- %<CR>
	" Add files/patches to the index
	nnoremap <silent> <Leader>ga :!git -C %:p:h add -p %<CR>
	" Find merge conflict markers with ,C
	nnoremap <leader>C /\v^[<\|=>]{7}<CR>
	" Use bindings in command mode similar to those used by the shell (see also :h cmdline-editing)
	cnoremap <C-a> <Home>
	cnoremap <C-e> <End>
	cnoremap <C-p> <Up>
	cnoremap <C-n> <Down>
	" cnoremap <C-b> <Left>
	" cnoremap <C-f> <Right>
	" Allow using alt-arrows to jump over words in OS X, as in Terminal.app
	cnoremap <Esc>b <S-Left>
	cnoremap <Esc>f <S-Right>
" }}
" Appearance {{
	set title " Set the terminal title.
	set number " Turn line numbering on.
	set relativenumber " Display line numbers relative to the line with the cursor.
	set nowrap " Don't wrap lines by default.
	set linebreak " If wrapping is enabled, wrap at word boundaries.
	" set colorcolumn=80 " Show page guide at column 80.
	set laststatus=2 " Always show status line.
	set shortmess-=l " Don't use abbreviations for 'characters', 'lines'
	set shortmess-=r " Don't use abbreviations for 'readonly'
	set showcmd " Show (partial) command in the last line of the screen.
	set noshowmode " Do not show current mode because it is already shown in status line
	set diffopt+=vertical " Diff in vertical mode
	set listchars=tab:▸\ ,trail:·,eol:¬,nbsp:• " Symbols to use for invisible characters (see also http://stackoverflow.com/questions/20962204/vimrc-getting-e474-invalid-argument-listchars-tab-no-matter-what-i-do).
	set fillchars+=vert:\  " Get rid of vertical split separator (http://stackoverflow.com/questions/9001337/vim-split-bar-styling)
	set fillchars+=fold:\·
	" MacVim {{
		if has('gui_macvim')
			set guifont=Monaco:h14
			set guioptions-=aP " Do not use system clipboard by default
			set guioptions-=T  " No toolbar
			set guioptions-=lL " No left scrollbar
			set guicursor=n-v-c:ver20 " Use a thin vertical bar as the cursor
			set transparency=4
		endif
	" }}
" }}
" Themes {{
	" To add support for a new theme, define a function called
	" HighlightGroups_<theme_name>. That function will be automatically called
	" after the color scheme is activated. The function should at least
	" define the hightlight groups for the status line, but it can also
	" be used to override the theme's highlight groups.

	" Set up highlight groups for the current theme and background.
	func! UpdateHighlightGroups()
		if exists('g:colors_name')
			let fn = 'HighlightGroups_' . substitute(tolower(g:colors_name), '[-]', '_', 'g')
			if exists('*' . fn)
				call eval(fn . '()')
			endif
		endif
	endfunc

	autocmd ColorScheme * call UpdateHighlightGroups()

	" Solarized {{
		let g:solarized_bold = 1
		let g:solarized_underline = 0

		func! HighlightGroups_solarized()
			if &background ==# 'dark'
				hi VertSplit   ctermbg=0  ctermfg=0  guibg=#073642 guifg=#073642 term=reverse cterm=reverse gui=reverse
				hi MatchParen  ctermbg=0  ctermfg=14 guibg=#073642 guifg=#93a1a1 term=bold    cterm=bold    gui=bold
			else
				hi VertSplit   ctermbg=7  ctermfg=7  guibg=#eee8d5 guifg=#eee8d5 term=reverse cterm=reverse gui=reverse
				hi MatchParen  ctermbg=7  ctermfg=0  guibg=#eee8d5 guifg=#073642 term=bold    cterm=bold    gui=bold
				hi TabLineSel  ctermbg=10 ctermfg=15 guibg=#586e75 guifg=#fdf6e3 term=reverse cterm=reverse gui=reverse
				hi TabLine     ctermbg=7  ctermfg=14 guibg=#eee8d5 guifg=#93a1a1 term=reverse cterm=reverse gui=reverse
				hi TabLineFill ctermbg=7  ctermfg=14 guibg=#eee8d5 guifg=#93a1a1 term=reverse cterm=reverse gui=reverse
			endif
			hi clear Title
			hi clear Folded

			" Status line
			if &background ==# 'dark'
				hi StatusLine   ctermbg=7   ctermfg=10  guibg=#eee8d5 guifg=#586e75 term=reverse cterm=reverse gui=reverse
				hi StatusLineNC ctermbg=10  ctermfg=0   guibg=#586e75 guifg=#073642 term=reverse cterm=reverse gui=reverse
				hi NormalMode   ctermbg=14  ctermfg=15  guibg=#93a1a1 guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			else
				hi StatusLine   ctermbg=7   ctermfg=14  guibg=#eee8d5 guifg=#93a1a1 term=reverse cterm=reverse gui=reverse
				hi StatusLineNC ctermbg=14  ctermfg=7   guibg=#93a1a1 guifg=#eee8d5 term=reverse cterm=reverse gui=reverse
				hi NormalMode   ctermbg=10  ctermfg=15  guibg=#586e75 guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			endif
			hi InsertMode      ctermbg=6   ctermfg=15  guibg=#2aa19  guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi ReplaceMode     ctermbg=9   ctermfg=15  guibg=#cb4b1  guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi VisualMode      ctermbg=5   ctermfg=15  guibg=#d3368  guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi CommandMode     ctermbg=5   ctermfg=15  guibg=#d3368  guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi Warnings        ctermbg=1   ctermfg=15  guibg=#dc322  guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
		endfunc
	" }}
	" Seoul256 {{
		let g:seoul256_background = 236
		let g:seoul256_light_background = 255

		func! HighlightGroups_seoul256()
			hi VertSplit    ctermbg=239 ctermfg=239 guibg=#616161 guifg=#616161 term=reverse cterm=reverse gui=reverse
			hi TabLineSel   ctermbg=236 ctermfg=187 guibg=#3f3f3f guifg=#dfdebd term=NONE    cterm=NONE    gui=NONE
			hi TabLine      ctermbg=239 ctermfg=249 guibg=#616161 guifg=#bfbfbf term=NONE    cterm=NONE    gui=NONE
			hi TabLineFill  ctermbg=239 ctermfg=249 guibg=#616161 guifg=#bfbfbf term=NONE    cterm=NONE    gui=NONE
			" Status line
			hi StatusLineNC ctermbg=187 ctermfg=239 guibg=#dfdebd guifg=#616161 term=reverse cterm=reverse gui=reverse
			hi StatusLine   ctermbg=187 ctermfg=95  guibg=#dfdebd guifg=#9a7372 term=reverse cterm=reverse gui=reverse
			hi NormalMode   ctermbg=239 ctermfg=187 guibg=#616161 guifg=#dfdebd term=NONE    cterm=NONE    gui=NONE
			hi InsertMode   ctermbg=65  ctermfg=187 guibg=#719872 guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi ReplaceMode  ctermbg=220 ctermfg=238 guibg=#ffdd00 guifg=#565656 term=NONE    cterm=NONE    gui=NONE
			hi VisualMode   ctermbg=23  ctermfg=252 guibg=#007173 guifg=#d9d9d9 term=NONE    cterm=NONE    gui=NONE
			hi CommandMode  ctermbg=52  ctermfg=187 guibg=#730b00 guifg=#dfdebd term=NONE    cterm=NONE    gui=NONE
			hi Warnings     ctermbg=52  ctermfg=252 guibg=#730b00 guifg=#d9d9d9 term=NONE    cterm=NONE    gui=NONE
		endfunc

		func! HighlightGroups_seoul256_light()
			hi TabLineSel   ctermbg=255 ctermfg=238 guibg=#f0f1f1 guifg=#565656 term=NONE    cterm=NONE    gui=NONE
			hi TabLine      ctermbg=252 ctermfg=243 guibg=#d9d9d9 guifg=#d1d0d1 term=NONE    cterm=NONE    gui=NONE
			hi TabLineFill  ctermbg=252 ctermfg=243 guibg=#d9d9d9 guifg=#d1d0d1 term=NONE    cterm=NONE    gui=NONE
			" Status line
			hi StatusLine   ctermbg=187 ctermfg=95  guibg=#dfdebd guifg=#9a7372 term=reverse cterm=reverse gui=reverse
			hi StatusLineNC ctermbg=238 ctermfg=251 guibg=#565656 guifg=#d1d0d1 term=reverse cterm=reverse gui=reverse
			hi NormalMode   ctermbg=239 ctermfg=187 guibg=#616161 guifg=#dfdebd term=NONE    cterm=NONE    gui=NONE
			hi InsertMode   ctermbg=65  ctermfg=187 guibg=#719872 guifg=#fdf6e3 term=NONE    cterm=NONE    gui=NONE
			hi ReplaceMode  ctermbg=220 ctermfg=238 guibg=#ffdd00 guifg=#565656 term=NONE    cterm=NONE    gui=NONE
			hi VisualMode   ctermbg=23  ctermfg=252 guibg=#007173 guifg=#d9d9d9 term=NONE    cterm=NONE    gui=NONE
			hi CommandMode  ctermbg=52  ctermfg=187 guibg=#730b00 guifg=#dfdebd term=NONE    cterm=NONE    gui=NONE
			hi Warnings     ctermbg=52  ctermfg=252 guibg=#730b00 guifg=#d9d9d9 term=NONE    cterm=NONE    gui=NONE
		endfunc
	" }}

	" Default theme
	colorscheme solarized
" }}
" Status line {{
	" This was very helpful: http://www.blaenkdenum.com/posts/a-simpler-vim-statusline/

	let g:mode_map = {
				\ 'n':      ['NORMAL',  '%#NormalMode#' ],
				\ 'i':      ['INSERT',  '%#InsertMode#' ],
				\ 'R':      ['REPLACE', '%#ReplaceMode#'],
				\ 'v':      ['VISUAL',  '%#VisualMode#' ],
				\ 'V':      ['V-LINE',  '%#VisualMode#' ],
				\ "\<C-v>": ['V-BLOCK', '%#VisualMode#' ],
				\ 'c':      ['COMMAND', '%#CommandMode#'],
				\ 's':      ['SELECT',  '%#VisualMode#' ],
				\ 'S':      ['S-LINE',  '%#VisualMode#' ],
				\ "\<C-s>": ['S-BLOCK', '%#VisualMode#' ] }

	" Return the text and color to be used for the current mode
	func! GetModeInfo()
		return get(g:mode_map, mode(), ['??????', '%#Warnings#'])
	endfunc

	func! ConcatIf(l1, l2, minwd, wd)
		if a:minwd >= a:wd | return a:l1 | endif
		return a:l1 + a:l2
	endfunc

	" Return a warning if trailing space or mixed indent is detected in the *current buffer*.
	" See http://got-ravings.blogspot.it/2008/10/vim-pr0n-statusline-whitespace-flags.html
	func! StatusLineWarnings()
		if !exists('b:statusline_warnings')
			let b:statusline_warnings = ''
			let trail = search('\s$', 'nw')
			let mix = search('\v(^ +\t)|(^\t+ )|(^\t.*\n )|(^ .*\n\t)', 'nw')
			if trail != 0
				let b:statusline_warnings .= 'Trailing space (' . trail . ')'
				if mix != 0 | let b:statusline_warnings .= ' ' | endif
			endif
			if mix != 0 | let b:statusline_warnings .= 'Mixed indent (' . mix . ')' | endif
		endif
		return b:statusline_warnings
	endfunc

	" Alternative status lines (e.g., for help files)
	func! AltStatusLine(wd, bufnum, active)
		let stat = []
		let ft = getbufvar(a:bufnum, '&ft')
		if ft ==# 'help'
			if a:active
				let stat = ['%#NormalMode# HELP %* %<%f ⚔ %=']
				let stat = ConcatIf(stat, ['%#NormalMode# %5l %2v %3p%%'], 40, a:wd)
			else
				let stat = [' HELP  %<%f ⚔']
				let stat = ConcatIf(stat, ['%= %5l %2v %3p%%'], 40, a:wd)
			endif
		elseif ft ==# 'undotree' || ft ==# 'diff'
			let stat = a:active ? ['%#NormalMode#', ft] : ['', ft]
		elseif ft ==# 'tagbar'
			let stat = a:active ? ['%#NormalMode# Tagbar'] : [' Tagbar', tagbar#currenttag('%s','')]
		endif
		return stat
	endfunc

	" Build the status line the way I want - no fat light plugins!
	" wd: window width
	" bufnum: buffer number
	" active: 1=active, 0=inactive
	func! BuildStatusLine(wd, bufnum, active)
		let stat = AltStatusLine(a:wd, a:bufnum, a:active)
		if stat != [] | return join(stat) . ' %*' | endif

		let enc = getbufvar(a:bufnum, '&fenc')
		if enc == '' | let enc = getbufvar(a:bufnum, '&enc') | endif
		if getbufvar(a:bufnum, '&bomb') | let enc .= ',BOM' | endif
		let ft = getbufvar(a:bufnum, '&ft')
		let ff = getbufvar(a:bufnum, '&ff')
		let ff = (ff ==# 'unix') ? '␊ (Unix)' : (ff ==# 'mac') ? '␍ (Classic Mac)' : (ff ==# 'dos') ? '␍␊ (Windows)' : '? (Unknown)'
		let mod = getbufvar(a:bufnum, '&modified') ? '◇' : ''  " Symbol for modified file
		let ro  = getbufvar(a:bufnum, '&modifiable') ? (getbufvar(a:bufnum, '&readonly') ? '✗' : '') : '⚔'  " Symbol for read-only/unmodifiable
		let tabs = (getbufvar(a:bufnum, '&expandtab') == 'expandtab' ? '⇥ ' : '˽ ') . getbufvar(a:bufnum, '&tabstop')
		if a:active
			let modeinfo = GetModeInfo()
			let warnings = StatusLineWarnings()
			let currmode = modeinfo[0] . (getbufvar(a:bufnum, '&paste') ? ' PASTE' : '')
			let stat = [modeinfo[1], currmode, '%*', '%<%F', mod, ro, '%=', ft]
			let rhs = [modeinfo[1], '%5l %2v %3p%%']
			if warnings != '' | let rhs += ['%*%#Warnings#', warnings] | endif
		else
			let stat = [' %<%F', mod, ro, '%=', ft]
			let rhs = ['%5l %2v %3p%%']
		endif
		let stat = ConcatIf(stat, ['', enc, ff, tabs], 80, a:wd)
		let stat = ConcatIf(stat, rhs, 60, a:wd)
		return join(stat) . ' %*'
	endfunc

	func! RefreshStatusLines()
		for nr in range(1, winnr('$'))
			call setwinvar(nr, '&statusline', '%!BuildStatusLine(' . winwidth(nr) . ',' . winbufnr(nr) . ',' . (nr == winnr()) . ')')
		endfor
	endfunc

	func! RefreshActiveStatusLine()
		call setwinvar(winnr(), '&statusline', '%!BuildStatusLine(' . winwidth(winnr()) . ',' . winbufnr(winnr()) . ',1)')
	endfunc

	func! EnableStatusLine()
		let g:stl = &statusline
		augroup status
			autocmd!
			autocmd VimEnter,WinEnter,BufWinEnter,VimResized * call RefreshStatusLines()
			au InsertEnter,InsertLeave call * RefreshActiveStatusLine()
			autocmd BufWritePost * unlet! b:statusline_warnings
		augroup END
		call RefreshStatusLines()
	endfunc!

	func! DisableStatusLine()
		augroup status
			autocmd!
		augroup END
		augroup! status
		let &statusline = g:stl
		for t in range(1, tabpagenr('$'))
			for n in range(1, tabpagewinnr(t, '$'))
				call settabwinvar(t, n, '&statusline', '')
			endfor
		endfor
	endfunc!

	call EnableStatusLine()
" }}
" Plugins {{
	" CtrlP {{
		" Open CtrlP in MRU mode by default
		let g:ctrlp_cmd = 'CtrlPMRU'
		let g:ctrlp_status_func = {
					\ 'main': 'CtrlP_Main',
					\ 'prog': 'CtrlP_Progress',
					\ }
		let g:ctrlp_extensions = ['funky']

		" See https://gist.github.com/kien/1610859
		" Arguments: focus, byfname, s:regexp, prv, item, nxt, marked
		"            a:1    a:2      a:3       a:4  a:5   a:6  a:7
		func! CtrlP_Main(...)
			if a:1 ==# 'prt'
				let color = '%#InsertMode#'
				let rhs = color . (a:3 ? ' regex ' : ' match ') . a:2 . ' %*'
			else
				let color = '%#VisualMode#'
				let rhs = color . ' select %*'
			endif
			let item = color . ' ' . a:5 . ' %*'
			let dir = ' ' . getcwd()
			return item . dir . '%=' . rhs
		endfunc

		" Argument: len
		"           a:1
		func! CtrlP_Progress(...)
			let len = '%#Warnings# ' . a:1 . ' %*'
			let dir = ' %=%<%#Warnings#' . getcwd() . ' %*'
			return len . dir
		endf
	" }}
	" Easy Align {{
		vmap <Enter> <Plug>(EasyAlign)
	" }}
	" Goyo {{
		" Toggle distraction-free mode with ,F
		nnoremap <silent> <Leader>F :Goyo<CR>
		func! s:goyo_enter()
			call DisableStatusLine()
			if has('gui_macvim')
				set fullscreen
				set guifont=Monaco:h14
				set linespace=7
				set guioptions-=r " hide right scrollbar
			endif
			set wrap
			set noshowcmd
			Limelight
		endfunc

		func! s:goyo_leave()
			if has('gui_macvim')
				set nofullscreen
				set guifont=Monaco:h14
				set linespace=0
				set guioptions+=r
			endif
			set nowrap
			set showcmd
			Limelight!
			call EnableStatusLine()
		endfunc

		autocmd! User GoyoEnter
		autocmd! User GoyoLeave
		autocmd! User GoyoEnter call <SID>goyo_enter()
		autocmd! User GoyoLeave call <SID>goyo_leave()
	" }}
	" Ledger {{
		let g:ledger_maxwidth = 63
		let g:ledger_fillstring = '    ·'
		" let g:ledger_detailed_first = 1
		" let g:ledger_fold_blanks = 0
		let g:ledger_decimal_sep = ','
		let g:ledger_align_at = 60
		let g:ledger_default_commodity = 'EUR'
		let g:ledger_commodity_before = 0
		let g:ledger_commodity_sep = ' '

		" Run an arbitrary ledger command.
		func! Ledger(args)
			call RunShellCommand(g:ledger_bin . " -f % " . a:args, "r")
		endfunc

		command! -complete=shellcmd -nargs=+ Ledger call Ledger(<q-args>)

		" Enter a new transaction based on the text in the current line.
		func! LedgerEntry()
			" enter a new transaction based on the text in the current line.
			let l = line('.') - 1 " Insert transaction at the current line (i.e., below the line above the current one)
			let query = getline('.')
			normal "_dd
			exec l . 'read !' g:ledger_bin '-f' shellescape(expand('%')) 'entry' shellescape(query)
		endfunc

		" Align the amount expression after an account name at the decimal point.
		"
		" This function moves the amount expression of a posting so that the decimal
		" separator is aligned at the column specified by g:ledger_align_at.
		"
		" For example, after selecting:
		"
		"   2015/05/09 Some Payee
		"     Expenses:Other    $120,23  ; Tags here
		"     Expenses:Something  $-4,99
		"     Expenses:More                 ($12,34 + $16,32)
		"
		"  :'<,'>call AlignCommodity() produces:
		"
		"   2015/05/09 Some Payee
		"      Expenses:Other                                    $120,23  ; Tags here
		"      Expenses:Something                                 $-4,99
		"      Expenses:More                                     ($12,34 + $16,32)
		"
		func! AlignCommodity()
			" Extract the part of the line after the account name (excluding spaces)
			let rhs = matchstr(getline('.'), '\m^\s\+[^;[:space:]].\{-}\(\t\|  \)\s*\zs.*$')
			if rhs != ''
				" Remove everything after the account name (including spaces)
				.s/\m^\s\+[^[:space:]].\{-}\zs\(\t\|  \).*$//
				if g:ledger_decimal_sep == ''
					let pos = matchend(rhs, '\m\d[^[:space:]]*')
				else
					" Find the position of the first decimal separator
					let pos = match(rhs, '\V' . g:ledger_decimal_sep)
				endif
				" Go to the column that allows us to align the decimal separator at g:ledger_align_at
				call GotoCol(g:ledger_align_at - pos - 1)
				" Append the part of the line that was previously removed
				exe 'normal a' . rhs
			endif
		endfunc!

		command! -range AlignCommodities <line1>,<line2>call AlignCommodity()

		" Align the amount under the cursor and append/prepend the default currency.
		func! AlignAmountAtCursor()
			" Select and cut text
			normal viWd
			" Find the position of the decimal separator
			let pos = match(@", g:ledger_decimal_sep) " 0 if g:ledger_decimal_sep is the empty string
			" Paste text at the correct column and append/prepend default commodity
			if g:ledger_commodity_before
				call GotoCol(g:ledger_align_at - (pos > 0 ? pos : len(@"))  - len(g:ledger_default_commodity) - len(g:ledger_commodity_sep) - 1)
				exe 'normal a' . g:ledger_default_commodity . g:ledger_commodity_sep
				normal p
			else
				call GotoCol(g:ledger_align_at - (pos > 0 ? pos : len(@")) - 1)
				exe 'normal pa' . g:ledger_commodity_sep . g:ledger_default_commodity
			endif
		endfunc!

		" Toggle transaction state with <space>
		au FileType ledger nnoremap <silent><buffer> <Space> :call ledger#transaction_state_toggle(line('.'), '* !')<CR>
		" Use tab to autocomplete
		au FileType ledger inoremap <silent><buffer> <Tab> <C-x><C-o>
		" Enter a new transaction based on the text in the current line
		au FileType ledger nnoremap <silent><buffer> <C-t> :call LedgerEntry()<CR>
		au FileType ledger inoremap <silent><buffer> <C-t> <Esc>:call LedgerEntry()<CR>
		" Align amounts at the decimal point
		au FileType ledger vnoremap <silent><buffer> <Leader>a :AlignCommodities<CR>
		au FileType ledger inoremap <silent><buffer> <C-l> <Esc>:call AlignAmountAtCursor()<CR>

		func! BalanceReport()
			call inputsave()
			let accounts = input("Accounts: ", "^asset ^liab")
			call inputrestore()
			call Ledger('cleared --real ' . accounts)
		endfunc
	" }}
	" Tagbar {{
		" Use F9 to toggle tag bar:
		nnoremap <silent> <F9> :TagbarToggle<CR>
		let g:tagbar_autofocus = 1
		let g:tagbar_iconchars = ['▸', '▾']
	" }}
	" Undotree {{
		" Use F8 to toggle undo tree
		nnoremap <silent> <F8> :UndotreeToggle<CR>
	" }}
" }}

