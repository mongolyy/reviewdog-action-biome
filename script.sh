#!/bin/sh
set -e

SCRIPT_DIR=$(dirname "$0")

. "${SCRIPT_DIR}/lib/biome.sh"

if [ -n "${GITHUB_WORKSPACE}" ]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

install_biome

echo '::group:: Running Biome with reviewdog 🐶 ...'
if [ "$INPUT_REPORTER" = "github-pr-review" ]; then
  # shellcheck disable=SC2086
  biome_check ${INPUT_BIOME_FLAGS} |
    reviewdog \
      -efm="%-G%f ci ━%#" \
      -efm="%-G%f lint ━%#" \
      -efm="%-Gci ━%#" \
      -efm="%E%f:%l:%c %.%#" \
      -efm="%E%f %.%#" \
      -efm="%C" \
      -efm="%C  × %m" \
      -efm="%C  %m" \
      -efm="%-G%.%#" \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}
else
  # shellcheck disable=SC2086
  biome_ci ${INPUT_BIOME_FLAGS} |
    reviewdog \
      -efm="%-G%f ci ━%#" \
      -efm="%-G%f lint ━%#" \
      -efm="%-Gci ━%#" \
      -efm="%E%f:%l:%c %.%#" \
      -efm="%E%f %.%#" \
      -efm="%C" \
      -efm="%C  × %m" \
      -efm="%C  %m" \
      -efm="%-G%.%#" \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}
fi

exit_code=$?
echo '::endgroup::'
exit $exit_code
