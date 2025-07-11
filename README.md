# reviewdog-action-biome

[![test](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/test-action.yml/badge.svg)](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/test-action.yml)
[![depup](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/depup.yml/badge.svg)](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/depup.yml)
[![release](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/release.yml/badge.svg)](https://github.com/mongolyy/reviewdog-action-biome/actions/workflows/release.yml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/mongolyy/reviewdog-action-biome?logo=github&sort=semver)](https://github.com/mongolyy/reviewdog-action-biome/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

> [!IMPORTANT]  
> This action supports Biome v2 and later.  
> If you are using Biome v1, please use [reviewdog-action-biome@v1.13.0](https://github.com/mongolyy/reviewdog-action-biome/releases/tag/v1.13.0).

This action runs [Biome](https://biomejs.dev/) with [reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve code review experience.

![sample-pr-review](assets/readme/sample-pr-review.png)
![sample-commit-suggestion](assets/readme/sample-commit-suggestion.png)

## Input

```yaml
inputs:
  github_token:
    description: 'GITHUB_TOKEN'
    required: true
    default: '${{ github.token }}'
  workdir:
    description: |
      Working directory relative to the root directory.
      This is where the action will look for a package.json file which declares Biome as a dependency.
      Please note that this is different from the directory where the action will run Biome, which is specified in the biome_flags input.
    required: false
    default: '.'
  ### Flags for reviewdog ###
  tool_name:
    description: 'Tool name to use for reviewdog reporter.'
    required: false
    default: 'Biome'
  level:
    description: 'Report level for reviewdog [info,warning,error].'
    required: false
    default: 'error'
  reporter:
    description: 'Reporter of reviewdog command [github-check,github-pr-review,github-pr-check].'
    required: false
    default: 'github-pr-review'
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added,diff_context,file,nofilter].
      Default is `added`.
    required: false
    default: 'added'
  fail_level:
    description: |
      If set to `none`, always use exit code 0 for reviewdog. Otherwise, exit code for reviewdog if it finds at least 1 issue with severity greater than or equal to the given level.
      Possible values: [none,any,info,warning,error]
    required: false
  fail_on_error:
    description: |
      Deprecated, use `fail_level` instead.
      Exit code for reviewdog when errors are found [true,false].
      Default is `false`.
    deprecationMessage: Deprecated. Use `fail_level` instead.
    required: false
    default: 'false'
  reviewdog_flags:
    description: 'Additional reviewdog flags.'
    required: false
    default: ''
  ### Flags for Biome ###
  biome_flags:
    description: 'Flags and args for Biome command.'
    required: false
    default: '.'
```

## Usage

> [!NOTE]  
> For users who used reviewdog-action-biome@v1.5 or lower.  
> This action uses biomejs/setup-biome from v1.6.0.  
> This will set up the appropriate version of @biomejs/biome from the lockfiles.  
> No need to [set up manually](https://github.com/mongolyy/reviewdog-action-biome/blob/v1.5.1/README.md#usage) anymore!

This is an example of commenting on a pull request and failing CI when there are issues pointed out in Biome check.

```yaml
name: reviewdog
on: [pull_request]
jobs:
  biome:
    name: runner / Biome
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - uses: mongolyy/reviewdog-action-biome@bf7dffa9b14e8904941a18a28782b74fc40104f0 # v1.11.1
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review
          fail_on_error: true
```

## Development

### Test

Install [shellspec](https://github.com/shellspec/shellspec) and run `shellspec` command.

```shell
$ shellspec
```
