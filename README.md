# reviewdog-action-biome

This action runs [Biome](https://biomejs.dev/) with [reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve code review experience.

![2024-01-08_00h04_56](https://github.com/mongolyy/reviewdog-action-biome/assets/10972787/6a6efde7-ed19-43ee-9382-389560dfa1ee)

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
      Default is added.
    required: false
    default: 'added'
  fail_on_error:
    description: |
      Exit code for reviewdog when errors are found [true,false].
      Default is `false`.
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
      - uses: actions/checkout@v4
      - uses: mongolyy/reviewdog-action-biome@v0
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review
```

You can also set up node and Biome manually:

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
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
        with:
          node-version: "20"
      - run: yarn install
      - uses: reviewdog/action-biome@v0
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review
```

## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)
You can bump version on merging Pull Requests with specific labels (bump:major,bump:minor,bump:patch).
Pushing tag manually by yourself also work.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: https://help.github.com/en/articles/about-actions#versioning-your-action

### Lint - reviewdog integration

This reviewdog action itself is integrated with reviewdog to run lints
which is useful for [action composition] based actions.

[action composition]:https://docs.github.com/en/actions/creating-actions/creating-a-composite-action

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

Supported linters:

- [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)
- [reviewdog/action-shfmt](https://github.com/reviewdog/action-shfmt)
- [reviewdog/action-actionlint](https://github.com/reviewdog/action-actionlint)
- [reviewdog/action-misspell](https://github.com/reviewdog/action-misspell)
- [reviewdog/action-alex](https://github.com/reviewdog/action-alex)

### Dependencies Update Automation
This repository uses [reviewdog/action-depup](https://github.com/reviewdog/action-depup) to update
reviewdog version.

![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)
