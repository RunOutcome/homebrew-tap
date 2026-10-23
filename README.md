# homebrew-tap

Part of VRAI by VRAISON. See https://github.com/VRAISON/vrai-workspace for how the repositories fit together.

## The vrai formula

**Not published.** The formula is written and tested here, but it is not published until the founder approves the public release (F-0017 @ac-7). No workflow in this repository pushes a formula or a tap.

- `Formula/vrai.rb.tmpl` is the formula's template. It installs the platform's `vrai` as `bin/vrai`, and `bin/vraish` as a link to it.
- Its `post_install` creates `v` and `vsh` in `$(brew --prefix)/bin`, unless a program of that name is already on your `PATH`. In that case it prints `skipped v: <path> exists (V language?)` or `skipped vsh: <path> exists`, as vrai-cli's `install.sh` does (F-0017 @ac-3, @ac-4). It reads your `PATH` from `HOMEBREW_PATH`, because Homebrew cleans `PATH` while a formula runs.
- `brew uninstall vrai` doesn't remove `v` and `vsh`, because Homebrew doesn't track them. `brew cleanup --prune-prefix` removes them once they dangle.

`scripts/render-formula.sh` writes `Formula/vrai.rb` from the template, a version, the address of the release's `vrai-<os>-<arch>` binaries, and the release's `checksums.txt`. It refuses a checksums file that lacks any darwin or linux binary:

    scripts/render-formula.sh --version v0.0.1 \
      --base-url https://github.com/VRAISON/vrai-cli/releases/download/v0.0.1 \
      --checksums checksums.txt

Homebrew installs formulae only from a tap, so CI's `formula` job tests a local one that exists only on the runner. It:
1. builds `vrai` from vrai-cli `main`;
2. renders the formula with `file://` addresses;
3. copies it into a tap made with `brew tap-new --no-git vraison/local`;
4. runs `brew audit --strict`;
5. runs `brew install vraison/local/vrai` twice: once on a clean `PATH`, and once with files `v` and `vsh` on `PATH`. After each install, `vrai up --native`, a login and `vrai status` must succeed (F-0017 @ac-6).

## Licensing

homebrew-tap is licensed under the Apache License, version 2.0 (`Apache-2.0`); see
`LICENSE`. Contributions are accepted under the same license (Apache-2.0 §5); no
Contributor License Agreement is required.

"VRAI", "VRAISON" and "Cortex server" are trademarks of COR Holdings, LLC; see
`TRADEMARKS.md`.
