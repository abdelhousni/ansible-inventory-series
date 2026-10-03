# Working in ansible-inventory-series

Companion examples for the "Ansible inventory from scratch" series on
til.housni.eu (abdelhousni/til, `ansible/*.md`). Each example is `NN-name/`
with a `run.sh`, an `expected.txt`, a README, a CI matrix entry and a row in
the root README table.

## Write, review and refactor with the Lola Ansible skills

The Lola modules `ansible-content-development` and `ansible-documentation`
are installed for Claude Code. Use them for every example:

1. **Create** playbooks, inventories, group_vars and templates with the
   `write-content` skill, which follows Red Hat CoP automation good
   practices.
2. **Look things up** in the official docs with `ansible-markdown-docs`
   before stating how a feature behaves.
3. **Review** each new or changed example with `/ansible-cop-review` (rule
   compliance) and the `ansible-zen` skill (simplicity and readability)
   before opening a pull request. Fix the findings, or list in the pull
   request the ones kept on purpose, with the reason.
4. **Refactor** with `write-content` in improve mode when a review asks for
   it, then review again.

ansible-lint at the production profile still runs on every example, and
every example's `run.sh` must match its `expected.txt`.

## Conventions

- Deterministic output only: no timestamps, no host-specific values in
  `expected.txt`. Record real-world output as fixtures when needed.
- Expected failures are caught with `block`/`rescue`, never
  `ignore_errors`.
- Lines under 120 characters. Facts read as `ansible_facts.name` (dot
  notation, as in the published entries).
- Inventories follow the series' own advice: a hosts file without
  variables, and `group_vars/`/`host_vars/` directories.

## Commits

Commits are authored by the repository owner: check
`git var GIT_AUTHOR_IDENT` before the first commit and expect
`abdel.h <23284113+abdelhousni@users.noreply.github.com>`. Credit Claude
only with a `Co-Authored-By` trailer, and don't add a `Claude-Session:`
trailer.
