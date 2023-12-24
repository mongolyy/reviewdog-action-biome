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
"$(npm root)"/.bin/biome ci "${INPUT_BIOME_FLAGS}" 2>&1 |
  reviewdog \
    -efm="%C" \
    -efm="%-Gci ━%#" \
    -efm="%E%f:%l:%c %.%#━" \
    -efm="%Z  × %m" \
    -efm="%E%f %m %.%#━" \
    -efm="%Z  × %m" \
    -efm="%-G%.%#" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    "${INPUT_REVIEWDOG_FLAGS}"
exit_code=$?
echo '::endgroup::'
exit $exit_code
