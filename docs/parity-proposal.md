# Terraform parity proposal receiver

The `parity-proposal.yml` workflow accepts only the `parity-proposal-requested`
`repository_dispatch` event from the reviewed Bicep parity process. It validates a bounded
payload-v2 identifier/reference envelope, retrieves the full handoff and its JSON Schema from the
immutable handoff artifact commit, and requires an approved handoff before requesting a coding-agent
draft pull request.

## Payload contract

Every request has `payloadVersion: "2.0.0"` and contains:

- `handoffId`, `handoffPath`, and `handoffDigest`;
- `handoffSchemaPath` (`parity/schemas/terraform-handoff.schema.json`);
- `handoffCommitSha` and allow-listed `handoffRef` (`develop` initially);
- `provenanceType`, `provenanceId`, and `capabilityIds`;
- `sourceRepository`, `sourceRef`, and `sourceCommitSha`;
- `targetRepository`, `targetRef`, and `targetCommitSha`; and
- either `inventoryDigest`, `inventoryCommitSha`, and `inventoryReviewUrl` for baseline provenance,
  or `sourcePrNumber` for alignment-assessment provenance.

Absent or non-major-2 payload versions fail with `unsupported_payload_version`. Unknown fields,
unsafe handoff or schema paths, malformed or oversized values, unsupported repositories, arbitrary
handoff refs, and non-`main` targets are rejected before any fetch or write.

The receiver proves that `handoffCommitSha` is contained in the allow-listed handoff ref, then
fetches both the handoff and schema at that commit only. It compares `handoffDigest` with SHA-256 of
the exact handoff bytes after CRLF/CR-to-LF normalization and validates the handoff against the
schema from the same commit. `sourceCommitSha` and `targetCommitSha` are immutable comparison
baselines, never artifact fetch locations. The Terraform baseline must resolve and be an ancestor
of current upstream `main`; the current `main` head is recorded separately and is the branch point
for the proposal.

The approved handoff's `approvalUrl` is semantically constrained to a canonical pull-request URL in
the declared source repository. It may point to the PR itself or to a canonical GitHub issue-comment,
pull-request-review, or review-comment fragment on that PR. Baseline `inventoryReviewUrl` values must
identify the canonical source-repository PR without a query or fragment. Unrelated repositories,
issues, arbitrary paths, credentials, queries, and malformed fragments are rejected without requiring
additional network permissions.

Baseline requests hash the exact bytes of `parity/inventory.json` at `inventoryCommitSha`, verify
the active baseline and both comparison commits, and require the inventory, handoff, and
implementation commits to remain distinct. Alignment-assessment requests use the approved handoff
and reviewed source PR; they do not infer or fetch an inventory from an implementation commit.

## Idempotency and review

Concurrency and idempotency are keyed by `handoffId`. Proposals carry the handoff ID, artifact
commit, dispatch-approved `sha256:<handoffDigest>`, and target-head markers. The generated issue and
agent instructions require the agent to independently fetch the immutable artifact, normalize line
endings to LF, and compare its SHA-256 with that trusted dispatch value. A repeat with the same
`handoffCommitSha` returns the existing URL. A changed artifact commit for the same ID posts one
drift notice on the existing proposal and does not open a second.

A new REST issue payload uses GitHub's canonical Copilot coding-agent assignee
`copilot-swe-agent[bot]` together with the repository's `parity-proposal` custom agent assignment.
The agent may create a focused branch from the recorded current `main` head and a draft pull request
only.

The target pull request must preserve traceability, compatibility and migration analysis,
semantic-version impact, both standalone scenarios, AVM checks, exact deferrals, and the `hub-spoke`
exclusion.

This repository remains an AVM Pattern Module. PMNFR2's guidance that a Pattern Module **SHOULD** use
AVM Resource Modules still exists; this repository consciously adopts a local exception for parity
work. Parity implementations **SHOULD** prefer direct `Azure/azapi` resources and focused local
submodules. An AVM Resource Module is allowed only when its concrete benefit is documented against
the added contract, state, release, and capability constraints. External non-AVM modules are
prohibited.

Every generated tracker starts with merge evidence status `blocked`. It remains blocked until:

- `avm pre-commit` has completed and all resulting changes are committed;
- `avm pr-check` passes from that clean commit;
- every applicable unit, integration, and E2E tier passes, with explicit rationale for any
  non-applicable tier; and
- upstream managed AVM CI shows successful PR validation and every applicable unit, integration,
  and E2E job.

Unavailable, pending, skipped, or failed evidence is blocked, not success. A passing static plan or
local validation is not a substitute for an applicable Azure-backed tier or upstream managed CI.

For a proposal from a fork, credentialed managed CI continues to use the official security flow. A
module owner reviews the fork changes, creates an upstream `release/*` branch from `main`, merges the
fork PR into that branch, and opens a release-branch-to-`main` PR for managed validation and tests.
The receiver does not enable credentials or the managed workflow directly on an untrusted fork.

No automatic reverse write updates the Bicep inventory; recording the proposal URL there requires a
separately reviewed source-repository change.

Static validation and Terraform plans are proposal evidence only. This workflow does not merge,
deploy, release, configure credentials, or claim parity.

## Activation and evidence deferrals

- Do not activate the dispatch path until the source coordination pull request is merged and its
  narrowly scoped GitHub App and protected publication environment are configured and reviewed.
- Treat a live repository dispatch and successful Copilot assignment as external activation
  validation; local contract tests do not prove that repository policies permit either operation.
- Do not automatically write the proposal URL back to Bicep. That update requires a separate,
  approved source-repository contribution.
- Do not merge, deploy, release, or claim parity from this workflow.
- Do not treat this workflow as Azure evidence. Runtime parity still requires separate approved
  deployments and reviewed comparisons for `standalone-standard` and
  `standalone-network-isolated`.
- Keep `hub-spoke` and arbitrary optional-feature combinations deferred unless a later approved
  handoff explicitly changes those exclusions.
- Approval URL validation proves repository and canonical PR/review URL shape only. The receiver
  cannot prove from the bounded handoff metadata that `approvedBy` authored the linked GitHub review
  or that the reviewer was authorized. Maintainers must review that residual risk before activation.
