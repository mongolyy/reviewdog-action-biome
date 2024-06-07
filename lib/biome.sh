#!/bin/sh
set -e

install_biome() {
  if [ ! -f "$(npm root)"/.bin/biome ]; then
    echo '::group::🐶 Installing Biome...'
    npm install
    echo '::endgroup::'
  fi

  if [ ! -f "$(npm root)"/.bin/biome ]; then
    echo "❌ Unable to locate or install Biome. Did you provide a workdir which contains a valid package.json?"
    exit 1
  fi

  echo "Biome $("$(npm root)"/.bin/biome --version)"
}

biome_check() {
  if [ -z "$1" ]; then
    echo "❌ biome_check requires at least one argument"
    exit 1
  fi
  # shellcheck disable=SC2086
  "$(npm root)"/.bin/biome check --write $1 2>&1 1>/dev/null |
    sed 's/ *$//' |
    awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
}

biome_ci() {
  if [ -z "$1" ]; then
    echo "❌ biome_ci requires at least one argument"
    exit 1
  fi
  # shellcheck disable=SC2086
  "$(npm root)"/.bin/biome ci --max-diagnostics=30 $1 2>&1 1>/dev/null |
    sed 's/ *$//' |
    awk 'BEGIN { RS=""; ORS="\n\n" } { if (index($0, "│") > 0) { print "  ```\n" $0 "\n  ```" } else { print $0 } }'
}
