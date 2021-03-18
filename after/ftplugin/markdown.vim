setlocal autoindent
setlocal completefunc=local#markdown#complete
setlocal conceallevel=2
setlocal dictionary=/usr/share/dict/words
" Enable completion after [[ and #
setlocal iskeyword+=[,#
" Disable HTML completion function set by the Markdown plugin:
setlocal omnifunc=
setlocal path=.,**3/
setlocal spell
setlocal spelllang=en
setlocal suffixesadd=.md
setlocal textwidth=80

call local#text#enable_soft_wrap()

" Search notes in the current directory
nnoremap <silent> <buffer> <leader>n :<c-u>call zeef#open(local#markdown#notes(''), 'local#markdown#set_arglist', 'Choose notes')<cr>

let b:mucomplete_chain = ['user', 'path', 'keyn', 'dict', 'uspl']

let s:root = finddir("Notes", ".;")
execute "lcd" (empty(s:root) && !empty(expand("%")) ? "%:h" : s:root)
unlet s:root

call local#text#load_snippets()
