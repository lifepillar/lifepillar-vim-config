let s:winpos_map = {
      \ "T": "to ",  "t": "abo ", "B": "bo ",  "b": "bel ",
      \ "L": "to v", "l": "abo v", "R": "bo v", "r": "bel v"
      \ }

" Run a shell command and send its output to a new buffer.
" cmdline: the command to be executed (String);
" ...    : the position of the output window (see s:winpos_map).
fun! lf_shell#run(cmdline, ...) abort
  execute get(s:winpos_map, get(a:000, 0, "B"), "bo ")."new"
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  execute '%!'. join(map(split(a:cmdline), 'v:val !~# "\v^[%#<]" || expand(v:val) == "" ? v:val : shellescape(expand(v:val))'))
  setlocal nomodifiable
  nnoremap <silent> <buffer> <tab> <c-w><c-p>
  nnoremap <silent> <buffer> q <c-w><c-p>@=winnr("#")<cr><c-w>c
endf

" Thin wrapper over Vim and NeoVim asynchronous job functions.
" The first argument should be a List. The second (optional) argument is
" a callback function.
"
" Note that Vim and NeoVim use different calling conventions for the callback
" function. See `:h job_start()` and `:h jobstart()`, respectively.
if has("nvim") " NeoVim

  fun! lf_shell#async_run(cmd, ...)
    let l:callback = a:0 > 0 ? a:1 : 'lf_shell#callback'
    " Without calling it explicitly before invoking jobstart(),
    " NeoVim may not find a callback function defined in autoload:
    execute 'call' l:callback . "(0,0,'load')"
    call jobstart(a:cmd, {"on_exit": l:callback})
  endf

elseif exists("*job_start") " Vim

  fun! lf_shell#async_run(cmd, ...)
    silent! bwipeout! STDOUT
    silent! bwipeout! STDERR
    let l:job = job_start(a:cmd, {
          \ "exit_cb": function(get(a:000, 0, "lf_shell#callback"), [bufnr('%')]),
          \ "in_io": "null", "out_io": "buffer", "out_name": "[STDOUT]", "err_io": "buffer", "err_name": "[STDERR]"
          \ })
    call ch_setoptions(l:job, {"close_cb": function('lf_shell#close_cb', [l:job])})
  endf

else " Vim (old version)

  fun! lf_shell#async_run(cmd, ...)
    let l:callback = a:0 > 0 ? a:1 : 'lf_shell#callback'
    let l:cmd = type(a:cmd) == type([]) ? join(a:cmd) : a:cmd
    execute "!" . l:cmd
    execute 'call '.l:callback.'("Synchronous job",'.v:shell_error.')'
  endf

endif

if has("nvim")

  fun! lf_shell#callback(job_id, data, event)
    if a:event == 'exit'
      if a:data == 0 " 2nd arg is exit status when event is 'exit'
        call lf_msg#notice("Success!")
      else
        call lf_msg#err("Job failed.")
      endif
    endif
  endf

else

  fun! lf_shell#close_cb(job, channel)
    call job_status(a:job) " Trigger exit_cb's callback
  endf

  fun! lf_shell#callback(bufnr, job, status)
    if a:status == 0
      call lf_msg#notice("Success!")
    else
      call lf_msg#err("Job failed.")
    endif
  endf

endif

