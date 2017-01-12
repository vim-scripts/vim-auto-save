"======================================
"    Script Name:  vim-auto-save (http://www.vim.org/scripts/script.php?script_id=4521)
"    Plugin Name:  AutoSave
"        Version:  0.1.7
"======================================

if exists("g:auto_save_loaded")
  finish
else
  let g:auto_save_loaded = 1
endif

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:auto_save")
  let g:auto_save = 0
endif

if !exists("g:auto_save_only_git")
  let g:auto_save_only_git = 0
endif

if !exists("g:auto_save_no_updatetime")
  let g:auto_save_no_updatetime = 0
endif

if !exists("g:auto_save_in_insert_mode")
  let g:auto_save_in_insert_mode = 1
endif

if g:auto_save_no_updatetime == 0
  set updatetime=200
endif

if !exists("g:auto_save_silent")
  let g:auto_save_silent = 0
endif

" Vim plugin to change the working directory to the project root.
"
" Copyright 2010-2016 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.

if !exists('g:git_patterns')
  let g:git_patterns = ['.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

if !exists('g:git_targets')
  let g:git_targets = '/,*'
endif

if !exists('g:git_resolve_links')
  let g:git_resolve_links = 0
endif

function! s:IsDirectory(pattern)
  return stridx(a:pattern, '/') != -1
endfunction

function! s:ChangeDirectoryForBuffer()
  let patterns = split(g:git_targets, ',')

  if isdirectory(s:fd)
    return index(patterns, '/') != -1
  endif

  if filereadable(s:fd) && empty(&buftype)
    if exists('*glob2regpat')
      for p in patterns
        if p !=# '/' && s:fd =~# glob2regpat(p)
          return 1
        endif
      endfor
    else
      return 1
    endif
  endif

  return 0
endfunction

function! s:FindAncestor(pattern)
  let fd_dir = isdirectory(s:fd) ? s:fd : fnamemodify(s:fd, ':h')

  if s:IsDirectory(a:pattern)
    let match = finddir(a:pattern, fnameescape(fd_dir).';')
  else
    let match = findfile(a:pattern, fnameescape(fd_dir).';')
  endif

  if empty(match)
    return ''
  endif

  if s:IsDirectory(a:pattern)
    return fnamemodify(match, ':p:h:h')
  else
    return fnamemodify(match, ':p:h')
  endif
endfunction

function! s:SearchForRootDirectory()
  for pattern in g:git_patterns
    let result = s:FindAncestor(pattern)
    if !empty(result)
      return result
    endif
  endfor
  return ''
endfunction

function! s:RootDirectory()
  let root_dir = getbufvar('%', 'rootDir')
  if empty(root_dir)
    let root_dir = s:SearchForRootDirectory()
    if !empty(root_dir)
      call setbufvar('%', 'rootDir', root_dir)
    endif
  endif
  return root_dir
endfunction

" For third-parties.  Not used by plugin.
function! s:FindRootDirectory()
  let s:fd = expand('%:p')

  if g:git_resolve_links
    let s:fd = resolve(s:fd)
  endif

  if !s:ChangeDirectoryForBuffer()
    return ''
  endif

  return s:RootDirectory()
endfunction

function! SetIsGitDirectory()
  let git_directory = s:FindRootDirectory()
  if empty(git_directory)
    let s:is_git_directory = 0
  else
    let s:is_git_directory = 1
  endif
endfunction

augroup auto_save
  autocmd!
  if g:auto_save_in_insert_mode == 1
    au CursorHoldI,CompleteDone * nested call AutoSave()
  endif
  if g:auto_save_only_git == 1
    au BufEnter * nested call SetIsGitDirectory()
  endif
  au CursorHold,InsertLeave * nested call AutoSave()
augroup END

command! AutoSaveToggle :call AutoSaveToggle()

function! AutoSave()

  if g:auto_save >= 1 
    if g:auto_save_only_git >= 1 
      if s:is_git_directory >= 1
        echo "in if "
        let was_modified = &modified
        silent! wa
        if was_modified && !&modified
          if exists("g:auto_save_postsave_hook")
            execute "" . g:auto_save_postsave_hook
          endif
          if g:auto_save_silent == 0
            echo "(AutoSaved at " . strftime("%H:%M:%S") . ")"
          endif
        endif
      endif
    else
      let was_modified = &modified
      silent! wa
      if was_modified && !&modified
        if exists("g:auto_save_postsave_hook")
          execute "" . g:auto_save_postsave_hook
        endif
        if g:auto_save_silent == 0
          echo "(AutoSaved at " . strftime("%H:%M:%S") . ")"
        endif
      endif
    endif
  endif
endfunction

function! AutoSaveToggle()
  if g:auto_save >= 1
    let g:auto_save = 0
    echo "AutoSave is OFF"
  else
    let g:auto_save = 1
    echo "AutoSave is ON"
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

