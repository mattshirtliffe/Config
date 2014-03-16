#!/bin/bash -e

files=$(git ls-files | grep -v '\.ssh')
target=~

link() {
  ln -sf "$PWD/$1" "$2"
}

do_ssh() {
  cp -rT home/.ssh ~/.ssh
  chmod 700 ~/.ssh
}

do_mkdir() {
  mkdir -p ~/{.vimtmp,.history,tmp}
}

for f in $files; do
  if [[ "$f" =~ ^home/ ]]; then
    :
  else
    continue
  fi

  echo copying $f
  g="$target/${f/home\//}"
  mkdir -p "${g%/*}"
  if ! [[ -L "$g" ]]; then
    if [[ -f "$g" || "$f" -ot "$g" ]]; then
      if diff -q "$f" "$g"; then
        echo "identical $g"
        continue
      else
        echo "overwrite $g? [yn]"
        read option
        case $option in
          [yY]);;
          [nN])
            echo "skipping $g"
            continue;;
        esac
      fi
    fi
    link "$f" "$g"
  fi
done

do_ssh
do_mkdir
