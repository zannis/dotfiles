augroup auto_reload_vimrc
  autocmd!
  autocmd BufWritePost ~/.config/nvim/**/*.vim source $MYVIMRC | echo "Vim configuration reloaded!"
augroup END
