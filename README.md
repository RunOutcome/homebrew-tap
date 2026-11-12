# homebrew-tap

The Homebrew tap for [Outcome](https://runoutcome.com). Once the formula is published:

    brew install runoutcome/tap/out

The binaries come from the public [RunOutcome/releases](https://github.com/RunOutcome/releases).

## The out formula

**Not published.** The formula is written and tested here, but it is not published until the founder approves the public release (F-0017 @ac-7). No workflow in this repository pushes a formula or a tap.

- `Formula/out.rb.tmpl` is the formula's template. It installs the platform's `out` as `bin/out`, and `bin/outsh` as a link to it, as outcome-cli's `install.sh` does. The links live in the formula's own `bin`, so `brew link` puts them in `$(brew --prefix)/bin` and `brew uninstall out` removes them.

`scripts/render-formula.sh` writes `Formula/out.rb` from the template, a version, the address of the release's `out-<os>-<arch>` binaries, and the release's `checksums.txt`. It refuses a checksums file that lacks any darwin or linux binary:

    scripts/render-formula.sh --version v0.0.1 \
      --base-url https://github.com/RunOutcome/releases/releases/download/v0.0.1 \
      --checksums checksums.txt

Homebrew installs formulae only from a tap, so CI's `formula` job taps this checkout on the runner. It:
1. takes the newest release in RunOutcome/releases, a pre-release included, and its `checksums.txt` (with no release yet, it says so and passes);
2. renders the formula with that release's download addresses, and commits it on a branch that exists only in the runner's checkout;
3. runs `brew tap runoutcome/tap "$GITHUB_WORKSPACE"`, then `brew audit --strict`;
4. runs `brew install runoutcome/tap/out` on a clean `PATH`; then `out up --native`, a login and `out status` must succeed (F-0017 @ac-6). Afterwards `brew uninstall out` and `brew cleanup --prune-prefix` must leave no `out` or `outsh` link.

## Licensing

homebrew-tap is licensed under the Apache License, version 2.0 (`Apache-2.0`); see
`LICENSE`. Contributions are accepted under the same license (Apache-2.0 §5); no
Contributor License Agreement is required.

"Outcome", "VRAISON" and "Outcome server" are trademarks of COR Holdings, LLC; see
`TRADEMARKS.md`.
