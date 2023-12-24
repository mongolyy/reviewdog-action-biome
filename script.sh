#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

npx --no-install -c 'biome --version'
if [ $? -ne 0 ]; then
  echo '::group::🐶 Installing biome...'
  npm install
  echo '::endgroup::'
fi

echo "biome version:$(npx --noinstall -c 'biome --version')}"

echo '::group:: Running biome with reviewdog 🐶 ...'
biome ci "${INPUT_BIOME_FLAGS}" |
  reviewdog \
    -efm="%E%f:%l:%c %m ━%r" \
    -efm="%C" \
    -efm="%Z  × %m" \
    -efm="%E%f %m ━%r" \
    -efm="%C" \
    -efm="%Z  × %m" \
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
