---
name: land
description: >-
  Land requested changes in LukeTandjung/nix-darwin and coordinate emporium
  dependencies when requested. Invoke only for an explicit landing or merge
  request, including /land, not for review, preparation, or skill installation.
metadata:
  delta-action: land
---

# Land dotfiles changes

Apply only to LukeTandjung/nix-darwin. An explicit invocation already supplies
landing intent: proceed without asking for merge permission again. Installation
approval alone does not authorize execution.

## Scope and preflight

Read applicable instructions and inspect status, all diffs, untracked files,
remotes, and recent history. Preserve unrelated work and private data. Stage only
requested files. Use a private branch or isolated checkout if needed to separate
unrelated changes safely; never discard them.

Confirm `origin` identifies this GitHub repository and the intended destination
remains `master`. Check Git, Nix, and `gh` availability and authentication without
exposing credentials. Verify live branch protection, rulesets, contribution
requirements, required reviews, and checks. At setup, this repository had no CI
workflows, protections, PR requirement, or mandatory commit convention. Do not
assume that remains true or bypass new requirements. Stop if rules are unverifiable.

Fetch `origin` and integrate `origin/master` without rewriting shared history.
Use descriptive scoped commits with configured identity/signing and
`GIT_EDITOR=true` for commits and merges. Automatically resolve clear conflicts;
pause for ambiguous intent, unsafe resolutions, or failed checks. Preserve intended
changes on both sides. Reverify after conflict resolution or remote advancement.

## Coordinating emporium

When the requested scope spans package and consumer updates, land emporium first
using its project-local `.agents/skills/land/SKILL.md`. Read that exact file if
duplicate skill names make loading ambiguous. Do not bounce between skills:
once emporium is verified published, resume this workflow.

The consumer input is named `luke-pkgs`, not `autolith`. Source: `flake.nix`
defines `inputs.luke-pkgs.url` and uses `luke-pkgs.homeManagerModules.default`.
The separate `autolith` input is not a substitute for this dependency.

Update only `luke-pkgs` with `nix flake update luke-pkgs`, then inspect `flake.lock`
and verify its locked emporium revision is exactly the intended published commit.
Source: `flake.nix`, `inputs.luke-pkgs`; `flake.lock` stores the resolved GitHub
revision. Do not refresh all inputs. If upstream advanced past that revision,
explicitly pin `inputs.luke-pkgs.url` to
`github:LukeTandjung/luke-nix-emporium/<verified-full-SHA>` and update that input
again, substituting the actual published SHA. Review any necessary transitive
lock changes and exclude unrelated updates. Never land a local-path input.

Do not change this dependency merely because the repositories are attached.
Coordinate only the requested scope. Never undo a published emporium commit
automatically if dotfiles verification or publication is blocked.

## Verify the final candidate

Track required new files before evaluating the Git flake. Check affected
documentation and source consistency. Skill-only or documentation-only changes
need scoped content, frontmatter, references, and whitespace validation rather
than system builds.

For configuration/input changes:

1. Run `nix flake check --no-write-lock-file`. Source: `flake.nix` exports the
   NixOS and Darwin configurations; there is no custom test runner. Explicit
   evaluation below supplements flake checking for custom outputs.
2. Evaluate the affected configuration derivations using the corresponding
   commands:

   ```sh
   nix eval --raw .#nixosConfigurations.Lukes-Um790.config.system.build.toplevel.drvPath --no-write-lock-file
   nix eval --raw .#nixosConfigurations.Lukes-Mac-air.config.system.build.toplevel.drvPath --no-write-lock-file
   nix eval --raw .#darwinConfigurations.Lukes-MacBook-Pro.system.drvPath --no-write-lock-file
   ```

   Source: `flake.nix` defines these three output names;
   `hosts/Lukes-Um790/default.nix` and `hosts/Lukes-Mac-air/default.nix` instantiate
   `nixpkgs.lib.nixosSystem` for x86_64-linux;
   `hosts/Lukes-MacBook-Pro/default.nix` instantiates
   `nix-darwin.lib.darwinSystem` for aarch64-darwin.
   Shared Home Manager or package-input changes affect all three configurations.
3. Build a representative affected configuration on a compatible platform:

   ```sh
   nix build .#nixosConfigurations.Lukes-Um790.config.system.build.toplevel --no-link --no-write-lock-file
   nix build .#nixosConfigurations.Lukes-Mac-air.config.system.build.toplevel --no-link --no-write-lock-file
   nix build .#darwinConfigurations.Lukes-MacBook-Pro.system --no-link --no-write-lock-file
   ```

   Source: the same flake outputs and host constructors above. Choose only the
   applicable command(s), not all platforms blindly. For shared Linux changes,
   one Linux host build is representative after evaluating both; host-specific
   changes require that host's build. Report unbuilt cross-platform coverage.
   A Darwin-only change requires a compatible Darwin builder; if none is
   available, report blocked rather than replacing its build with evaluation.

Do not activate configurations, run `switch`, invoke installation instructions,
or change system settings. README fresh-install commands are not landing checks.
Do not install tools, bypass missing credentials, or update unrelated inputs to
hide a verification failure. Required checks must all pass for the final candidate
under current rules before landing. Pending, missing, failed, or unverifiable
results are blockers; earlier revisions' checks do not establish success.

## Publication

With the current direct-push workflow, push the verified commit with
`git push origin HEAD:refs/heads/master`. Never use force or the `local` backlink
for publication. If rejected because the remote advanced, fetch, integrate,
resolve clear conflicts, reverify, and retry.

If live policy instead requires a PR, publish a topic branch and create the PR
with explicit base `master` and `gh pr create --body-file`. Honor all applicable
contribution, review, and check requirements; merge using an allowed method only
after they pass. A required unavailable human action is a blocker, not permission
to bypass policy. A topic push or open PR is not completion.

Verify the resulting commit is reachable from fetched `origin/master`, and
confirm the destination ref with `git ls-remote`. Do not automatically delete
branches or modify the user's primary checkout.

## Report

In a subthread, use `report_subthread_status` if available; otherwise report in
the conversation. Use `success` only when the complete requested scope has reached
its intended destinations. Use `failure` for an actual blocker or failed attempt,
including partial coordinated completion. Clearly identify what landed and what
did not; safe recovery may continue and produce a later updated outcome.

Keep the title a few sentence-case words and description one short line.
Include verified short-SHA commit links and actual CI check/run result links,
omitting nonexistent or unverified URLs. No CI workflow means no invented CI
success link. Keep questions in the conversation. Passing builds, local commits,
topic-branch pushes, and skill installation are not landing success.
