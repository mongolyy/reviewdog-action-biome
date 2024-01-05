#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

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

echo '::group:: Running Biome with reviewdog 🐶 ...'
# shellcheck disable=SC2086
"$(npm root)"/.bin/biome ci --max-diagnostics=30 ${INPUT_BIOME_FLAGS} 2>&1 1>/dev/null |
  sed '/^$/d' |
  reviewdog \
    -efm="%-G%f ci ━%#" \
    -efm="%-G%f lint ━%#" \
    -efm="%-Gci ━%#" \
    -efm="%E%f:%l:%c %.%#" \
    -efm="%E%f %.%#" \
    -efm="%C  × %m" \
    -efm="%C  %m" \
    -efm="%-G%.%#" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS}
exit_code=$?
echo '::endgroup::'
exit $exit_code
