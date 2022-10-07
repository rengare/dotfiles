# extract-it() {
# 	if [ -f $1 ] ; then
# 		case $1 in
# 			*.tar)       tar xvf $1     ;;
# 			*.gz)        gunzip $1      ;;
# 			*.tar.gz)    tar zxvf $1    ;;
# 			*.tgz)       tar zxvf $1    ;;
# 			*.txz)       tar xvf $1     ;;
# 			*.xz)        tar xvf $1     ;;
# 			*.zip)       unzip $1       ;;
# 			*.7z)        7z x $1        ;;
# 			*.tar.bz2)   tar xvjf $1    ;;
# 			*.tbz2)      tar xvjf $1    ;;
# 			*.bz2)       bunzip2 $1     ;;
# 			*.rar)       unrar x $1     ;;
# 			*.Z)         uncompress $1  ;;
# 			*)           echo "Unable to extract <$1>'" ;;
# 		esac
# 	else
# 			echo "'$1' is not a valid file"
# 	fi
# }

function extract --description "Expand or extract bundled & compressed files"
  set --local ext (echo $argv[1] | awk -F. '{print $NF}')
  switch $ext
    case tar  # non-compressed, just bundled
      tar -xvf $argv[1]
    case gz
      if test (echo $argv[1] | awk -F. '{print $(NF-1)}') = tar  # tar bundle compressed with gzip
        tar -zxvf $argv[1]
      else  # single gzip
        gunzip $argv[1]
      end
    case tgz  # same as tar.gz
      tar -zxvf $argv[1]
    case bz2  # tar compressed with bzip2
      tar -jxvf $argv[1]
    case rar
      unrar x $argv[1]
    case zip
      unzip $argv[1]
    case '*'
      echo "unknown extension"

# TODO: add other cases 

  end
end

function qq
  set q "https://lite.duckduckgo.com/lite?q=$argv"
  lynx $q
end

function fuzzpack_run 
  flatpak list | fzf -1 -q $argv | awk '{print $3}' | xargs flatpak run &
end
