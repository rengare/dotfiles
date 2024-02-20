# FNM PATH
try {
  ^pyenv init | load-env
  $env.PATH = ($env.PATH | prepend [
    $"($env.FNM_MULTISHELL_PATH)/bin"
  ])
} catch { print 'fnm not in path' }
