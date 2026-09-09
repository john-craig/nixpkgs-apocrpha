
# Automated Development Workflows

This directory is reserved for Project Manager workflow modules. The initial
workflow is documented here before a functional Home Manager module is added.

## Create a Polymirror planning spec

Run the flake-provided `systems-architect` agent from the Grimoire catalog:

```console
nix run /home/evak/programming/by_language/nix/nixpkgs-apocrypha#opencode-agent -- \
  --agent systems-architect \
  --directory /home/evak/programming/by_category/project_management/grimoire \
  --prompt 'Create the coordinated OpenSpec specification for changing Polymirror live mode to mirror the 10 most successful traders based on the previous week.

Inspect only local evidence: the Grimoire repository mappings, the local Polymirror repository, the relevant local Panoply configuration, and existing Grimoire OpenSpec structures. Do not use webfetch, Context7, remote MCPs, or external documentation; record any unresolved API questions as explicit assumptions or open questions. Define the performance metric, week boundaries and timezone, ranking data source, tie-breaking, stale or missing data behavior, fewer-than-10 behavior, refresh cadence, persistence, auditability, rate limits, failure-safe behavior, existing-position handling, tests, observability, migration, rollback, and deployment requirements.

Create the appropriate Grimoire topic, project, spec-set, manifest, and repository-specific OpenSpec artifacts. Write only planning/specification artifacts. Do not implement code, deploy anything, submit trades, access or expose secrets, commit changes, or recursively delegate.'
```

The command requires an `opencode` executable and provider authentication at
runtime. If the local `opencode` command is a wrapper that forces server attach
mode, put the underlying OpenCode binary directory first on `PATH` before running
the command so the runner can invoke `opencode run` directly.

The `systems-architect` environment may write only the requested planning files
in the target repository. It cannot implement code, commit changes, deploy
systems, submit trades, mutate external records, or recursively delegate.

## Open a Grimoire pull request

For the idea-processing workflow, use Sceptre to publish the prepared Grimoire
worktree and open or update its pull request:

```console
nix run /home/evak/programming/by_language/nix/nixpkgs-apocrypha#sceptre -- \
  idea-process publish \
  --catalog /home/evak/programming/by_category/project_management/grimoire \
  --idea-id <idea-id> \
  --worktree /path/to/grimoire-worktree \
  --message 'Add Polymirror weekly top traders specification' \
  --title 'Add Polymirror weekly top traders specification'
```

The catalog must contain `repos/grimoire.json`; the worktree must be a Grimoire
checkout with the prepared changes under the repository-root `specs/` directory.
Sceptre does not create the worktree or prepare the files. Git operations use
the configured SSH upstream, so an SSH client and key must be available. The
`tea` client must also be authenticated to the Gitea instance before Sceptre can
list or create the pull request.

`specset publish` is for opening implementation pull requests against the
repositories listed in a spec-set manifest, not for publishing changes to
Grimoire itself.

## Poll pull-request feedback

Poll the pull request for requested changes and bounded review feedback:

```console
nix shell --inputs-from /home/evak/programming/by_language/nix/nixpkgs-apocrypha \
  nixpkgs#tea --command \
  nix run /home/evak/programming/by_language/nix/nixpkgs-apocrypha#sceptre -- \
  idea-process feedback \
  --upstream https://gitea.chiliahedron.wtf/chiliahedron/grimoire \
  --number <pull-request-number>
```

The command puts the flake-pinned `tea` on `PATH`, emits one JSON result, and
uses the configured `tea` credentials for Gitea. It does not modify the pull
request or the local worktree.

## Address pull-request feedback

Use this workflow to have the `systems-architect` agent address comments in an
existing Grimoire pull request. It starts from the PR branch, so the agent sees
the current proposed changes:

```console
set -euo pipefail

NIXPKGS_APOCRYPHA=/home/evak/programming/by_language/nix/nixpkgs-apocrypha
GRIMOIRE=/home/evak/programming/by_category/project_management/grimoire
UPSTREAM=https://gitea.chiliahedron.wtf/chiliahedron/grimoire
PR_NUMBER=1
BRANCH=spec/automated-development-workflow
WORKTREE=$(mktemp -d /tmp/grimoire-feedback.XXXXXX)

git -C "$GRIMOIRE" fetch origin "$BRANCH"
git -C "$GRIMOIRE" worktree add --detach "$WORKTREE" "origin/$BRANCH"

FEEDBACK=$(nix shell --inputs-from "$NIXPKGS_APOCRYPHA" \
  nixpkgs#jq nixpkgs#tea --command \
  nix run "$NIXPKGS_APOCRYPHA#sceptre" -- \
  idea-process feedback --upstream "$UPSTREAM" --number "$PR_NUMBER")
COMMENTS=$(printf '%s' "$FEEDBACK" | jq -r \
  '.feedback.comments[]? | "[" + .author + "] " + .body')

nix run "$NIXPKGS_APOCRYPHA#opencode-agent" -- \
  --agent systems-architect \
  --directory "$WORKTREE" \
  --prompt "Address the following review comments in this pull request.

$COMMENTS

Inspect the current worktree and local Grimoire context before editing. Make the
smallest changes that resolve the comments while preserving the intended
specification structure. Change only the requested planning/specification
artifacts under specs/. Do not use webfetch, external documentation, remote
MCPs, or recursive delegation. Do not commit, push, deploy, submit trades,
modify secrets, or change unrelated files; the calling workflow handles Git
operations after you finish. If a comment is ambiguous, record the assumption
in the appropriate planning artifact instead of guessing silently."

git -C "$WORKTREE" diff --check
git -C "$WORKTREE" add -- specs
if ! git -C "$WORKTREE" diff --cached --quiet; then
  git -C "$WORKTREE" commit -m 'Address pull-request review feedback'
fi
git -C "$WORKTREE" push origin "HEAD:$BRANCH"
git -C "$GRIMOIRE" worktree remove "$WORKTREE"
```

The workflow requires SSH access for Git and configured `tea` and OpenCode
credentials. If the agent or Git operation fails, inspect and either commit or
remove the worktree manually before retrying; do not discard uncommitted agent
changes automatically.

## Begin specification implementation

After the Grimoire specification pull request is merged, refresh the local
catalog, validate the coordinated spec set, select the next implementation
target, and materialize it into a target repository worktree:

```console
set -euo pipefail

NIXPKGS_APOCRYPHA=/home/evak/programming/by_language/nix/nixpkgs-apocrypha
GRIMOIRE=/home/evak/programming/by_category/project_management/grimoire
MANIFEST="$GRIMOIRE/specs/financial/prediction-market-livetrader/weekly-top-traders-live-v1/manifest.yaml"
WORKTREE=/path/to/polymirror-worktree

# 1. Refresh the local Grimoire catalog.
git -C "$GRIMOIRE" pull --ff-only

# 2. Validate the coordinated specification set.
nix run "$NIXPKGS_APOCRYPHA#sceptre" -- \
  specset ready \
  --manifest "$MANIFEST" \
  --catalog "$GRIMOIRE"

# 3. Select the next implementation target.
nix run "$NIXPKGS_APOCRYPHA#sceptre" -- \
  specset next \
  --manifest "$MANIFEST" \
  --catalog "$GRIMOIRE"

# 4. Materialize the selected specification into an existing target worktree.
nix run "$NIXPKGS_APOCRYPHA#sceptre" -- \
  specset materialize \
  --manifest "$MANIFEST" \
  --catalog "$GRIMOIRE" \
  --worktree "$WORKTREE"
```

The first target should be Polymirror, based on the manifest's
`implementation_order`. `WORKTREE` must be an existing checkout of the selected
target repository; Sceptre materializes the specification but does not create or
manage that worktree.

## Select and run the implementation agent

Use the target returned by `specset next` to determine which registered agent is
assigned to the materialized specification, then run that agent against the
Polymirror worktree:

```console
set -euo pipefail

NIXPKGS_APOCRYPHA=/home/evak/programming/by_language/nix/nixpkgs-apocrypha
GRIMOIRE=/home/evak/programming/by_category/project_management/grimoire
MANIFEST="$GRIMOIRE/specs/financial/prediction-market-livetrader/weekly-top-traders-live-v1/manifest.yaml"
WORKTREE=/path/to/polymirror-worktree

NEXT=$(nix shell --inputs-from "$NIXPKGS_APOCRYPHA" nixpkgs#jq --command \
  nix run "$NIXPKGS_APOCRYPHA#sceptre" -- \
  specset next --manifest "$MANIFEST" --catalog "$GRIMOIRE")
AGENT=$(printf '%s' "$NEXT" | nix shell --inputs-from "$NIXPKGS_APOCRYPHA" \
  nixpkgs#jq --command jq -r '.target.agent')
REPOSITORY=$(printf '%s' "$NEXT" | nix shell --inputs-from "$NIXPKGS_APOCRYPHA" \
  nixpkgs#jq --command jq -r '.target.repository')
SPECIFICATION=$(printf '%s' "$NEXT" | nix shell --inputs-from "$NIXPKGS_APOCRYPHA" \
  nixpkgs#jq --command jq -r '.target.specification')

test "$REPOSITORY" = polymirror
test -n "$AGENT"
test -n "$SPECIFICATION"

nix run "$NIXPKGS_APOCRYPHA#opencode-agent" -- \
  --agent "$AGENT" \
  --directory "$WORKTREE" \
  --prompt "Implement the materialized specification '$SPECIFICATION' in this
Polymirror worktree. Read the specification and the existing repository code,
then make the smallest implementation changes required by the contract. Run
focused tests and relevant repository checks. Preserve existing safety,
credential, and fail-closed boundaries. Do not use webfetch, external
documentation, remote MCPs, or recursive delegation. Do not commit, push,
deploy, submit trades, modify secrets, or change unrelated files; the calling
workflow will inspect and publish the changes. Report unresolved assumptions and
test results when finished."
```

The agent name is taken from the registered assignment in the spec-set catalog;
do not substitute an agent based only on the repository name. The selected agent
must be present in `GRIMOIRE/agents/`, and `WORKTREE` must already contain the
materialized specification.

## Commit, push, and open the implementation pull request

After the implementation agent exits, review its worktree before publishing
anything. The materialized worktree is detached, so create the feature branch
before committing. Stage only the files intentionally changed for this
specification; do not use `git add -A` when the worktree may contain unrelated
files:

```console
set -euo pipefail

NIXPKGS_APOCRYPHA=/home/evak/programming/by_language/nix/nixpkgs-apocrypha
GRIMOIRE=/home/evak/programming/by_category/project_management/grimoire
WORKTREE=/path/to/polymirror-worktree
BRANCH=feature/weekly-top-traders-live-v1
UPSTREAM=https://gitea.chiliahedron.wtf/john-craig/polymirror
REPOSITORY=john-craig/polymirror

# 1. Confirm the agent did not commit and inspect all changes.
git -C "$WORKTREE" status --short --branch
git -C "$WORKTREE" log --oneline -3
git -C "$WORKTREE" diff --check
git -C "$WORKTREE" diff
git -C "$WORKTREE" diff --no-index /dev/null \
  "$WORKTREE/openspec/specs/developer-weekly-top-trader-selection/spec.md" || true

# 2. Run the repository's focused tests and checks before staging.
PYTHONPATH="$WORKTREE/src" python -m compileall -q \
  "$WORKTREE/src" "$WORKTREE/tests"
PYTHONPATH="$WORKTREE/src" python -m pytest -q "$WORKTREE/tests"

# 3. Create the branch because Sceptre materializes into a detached worktree.
git -C "$WORKTREE" switch -c "$BRANCH"

# 4. Stage only reviewed implementation and specification files.
git -C "$WORKTREE" add -- \
  openspec/specs/developer-weekly-top-trader-selection/spec.md \
  src/polymirror_bot/cli.py \
  src/polymirror_bot/config.py \
  src/polymirror_bot/selection.py \
  src/polymirror_bot/state.py \
  tests/test_selection.py
git -C "$WORKTREE" diff --cached --check
git -C "$WORKTREE" diff --cached --stat
git -C "$WORKTREE" diff --cached

# 5. Commit the reviewed implementation.
git -C "$WORKTREE" commit -m 'Implement weekly top trader selection'

# 6. Push the feature branch and set its upstream tracking branch.
git -C "$WORKTREE" push --set-upstream origin "$BRANCH"

# 7. Open the implementation PR with the pinned Gitea client.
nix shell --inputs-from "$NIXPKGS_APOCRYPHA" nixpkgs#tea --command \
  tea pulls create \
  --repo "$REPOSITORY" \
  --head "$BRANCH" \
  --base main \
  --title 'Implement weekly top trader selection' \
  --description "Implements the Polymirror specification
developer-weekly-top-trader-selection from the weekly-top-traders-live-v1
spec set. Focused tests and repository checks were run before publication.

Specification source: $UPSTREAM"
```

Review the staged diff again immediately before `commit`; the commit and push
commands above are the first publishing operations. Git uses the configured SSH
remote, while `tea` uses its configured Gitea credentials. Do not include
credentials, local machine paths, generated secrets, live-trading keys, or
unrelated files in the commit. Do not enable live mode, submit trades, deploy,
or merge the pull request as part of this workflow.

For a workflow that lets Sceptre perform the Git and pull-request operations in
one step, use `specset publish` instead of the explicit steps above:

```console
nix shell --inputs-from /home/evak/programming/by_language/nix/nixpkgs-apocrypha \
  nixpkgs#tea --command \
  nix run /home/evak/programming/by_language/nix/nixpkgs-apocrypha#sceptre -- \
  specset publish \
  --manifest /home/evak/programming/by_category/project_management/grimoire/specs/financial/prediction-market-livetrader/weekly-top-traders-live-v1/manifest.yaml \
  --catalog /home/evak/programming/by_category/project_management/grimoire \
  --worktree /path/to/polymirror-worktree \
  --implementation-path src/polymirror_bot/selection.py \
  --implementation-path src/polymirror_bot/config.py \
  --implementation-path src/polymirror_bot/state.py \
  --implementation-path src/polymirror_bot/cli.py \
  --implementation-path tests/test_selection.py \
  --message 'Implement weekly top trader selection' \
  --title 'Implement weekly top trader selection'
```

Use the consolidated command only after reviewing the worktree and verifying
that its configured `tea` and SSH credentials target the intended Polymirror
repository. It is intended for a worktree whose changes are ready to publish;
the implementation agent must still not commit, push, or open the PR itself.

## Run an OpenSpec implementation workflow

The `homeModules.projectManagerAutomatedDevelopmentWorkflowsImplementor`
module installs `openspec-implementor`. It selects an active, incomplete
OpenSpec change, creates an isolated `feature/<change>` worktree, runs the
matching OpenCode agent, archives the change, and opens a pull request:

```nix
{
  imports = [ inputs.nixpkgs-apocrypha.homeModules.projectManagerAutomatedDevelopmentWorkflowsImplementor ];
  evak.project-manager.automated-development-workflows.implementor.enable = true;
}
```

```console
openspec-implementor --upstream https://github.com/owner/project.git
openspec-implementor --upstream https://gitea.example/owner/project.git --change developer-add-cache
```

The command uses `openspec list --json` and `openspec status --json` for change
selection. A change beginning with a configured agent name, such as
`software-architect-add-cache`, selects that agent; other names use
`developer`. Open pull requests for the matching feature branch are skipped;
use `--force` to rerun implementation, but the command still avoids creating a
duplicate pull request. Use `--keep-worktree` after a failure to preserve the
temporary clone for diagnosis.

GitHub publication requires authenticated `gh`; Gitea publication requires
authenticated `tea`. Git transport uses the upstream URL and the user's SSH or
HTTPS configuration. The workflow does not embed credentials or invoke
Sceptre's Grimoire-specific `specset publish` command because arbitrary
repository-local OpenSpec changes do not have a Grimoire manifest.

The same command is available directly from this flake without Home Manager
activation:

```console
nix run .#openspec-implementor -- --help
nix run .#openspec-implementor -- \
  --upstream https://github.com/owner/project.git \
  --change developer-add-cache \
  --model openai/gpt-5.5
```

The flake package supplies Git, jq, OpenSpec, OpenCode, the packaged
`opencode-agent` environments, `gh`, and `tea`. GitHub/Gitea credentials and
Git transport authentication remain runtime requirements. Direct execution has
the same publishing behavior as the Home Manager command; it is not a dry run.

## Run a Grimoire-backed implementation

For coordinated spec sets in the upstream Grimoire catalog, use the separate
Sceptre-backed Home Manager module. It asks Sceptre to validate the manifest and
select the next repository/specification pair, then invokes the exact registered
OpenCode agent returned by Sceptre:

```nix
{
  imports = [ inputs.nixpkgs-apocrypha.homeModules.projectManagerAutomatedDevelopmentWorkflowsSceptreImplementor ];
  evak.project-manager.automated-development-workflows.sceptre-implementor = {
    enable = true;
    catalogPath = "/home/evak/programming/by_category/project_management/grimoire";
    manifestPath = "specs/project-management/automated-development-workflow/spec-implementation-v1/manifest.yaml";
    workRoot = "/tmp/evak-sceptre-work";
  };
}
```

Run one attempt manually with `sceptre-openspec-implementor`. The command
snapshots the catalog's upstream default branch, clones the selected repository
into private temporary state, materializes the selected specification, runs the
assigned agent, and asks Sceptre to publish only the reviewed implementation
paths. It does not use Grimoire's `local_path`, modify an existing checkout,
merge the pull request, process feedback, synchronize merged specs, or deploy
anything. Git transport, provider (`gh` or `tea`), and OpenCode authentication
must already be configured.

To schedule one serialized attempt every six hours:

```nix
evak.project-manager.automated-development-workflows.sceptre-implementor = {
  enable = true;
  catalogPath = "/home/evak/programming/by_category/project_management/grimoire";
  manifestPath = "specs/project-management/automated-development-workflow/spec-implementation-v1/manifest.yaml";
  interval = "6h";
  persistent = false;
  keepWorktree = true;
};
```

This creates `evak-sceptre-openspec-implementor.service` and its user timer. A
second activation exits successfully while an earlier run holds the private
runtime lock. Successful and no-work runs remove temporary state; with
`keepWorktree = true`, failed state is retained and its path is reported for
diagnosis. The generic `openspec-implementor` and its scheduler remain the right
choice for repositories without a Grimoire spec-set manifest.

## Schedule OpenSpec implementation

The scheduler module installs a Linux `systemd.user` oneshot service and timer.
It selects configured repositories in round-robin order and delegates each
implementation attempt to `openspec-implementor`:

```nix
{
  imports = [ inputs.nixpkgs-apocrypha.homeModules.projectManagerAutomatedDevelopmentWorkflowsImplementorScheduler ];
  evak.project-manager.automated-development-workflows.implementor-scheduler = {
    enable = true;
    interval = "6h";
    retryOnFailure = false;
    upstreams = [
      {
        url = "https://github.com/owner/project.git";
        provider = "github";
        baseBranch = "main";
      }
      {
        url = "https://gitea.example/owner/project.git";
        provider = "gitea";
        baseBranch = "main";
      }
    ];
  };
}
```

The scheduler advances its private cursor after selecting a repository. If that
repository has no eligible OpenSpec change, it immediately tries the next
repository. When `retryOnFailure` is enabled, an implementation failure restores
the failed repository as the next cursor; no-work results never retry the same
repository within the next period. A non-blocking process lock skips a timer
period while an earlier implementation is still running.

The cursor is stored below the systemd state directory and the lock below its
runtime directory. Set `persistent = true` only when missed timer periods should
be replayed after the user session returns. Generic OpenSpec repositories use the
implementor's authenticated `gh` or `tea` provider operations; the current
Sceptre `specset` commands are intentionally not used because they require a
Grimoire catalog and manifest.
