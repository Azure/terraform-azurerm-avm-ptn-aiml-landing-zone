# Terraform parity proposal receiver

The `parity-proposal.yml` workflow accepts only the `parity-proposal-requested`
`repository_dispatch` event from the reviewed Bicep parity process. It validates a bounded
identifier/reference payload, retrieves the full handoff and its JSON Schema from the immutable
Bicep commit, and requires an approved handoff before requesting a coding-agent draft pull request.

## Payload contract

Every request contains:

- `handoffId` and `handoffPath`;
- `provenanceType`, `provenanceId`, and `capabilityIds`;
- `sourceRepository`, `sourceRef`, and `sourceCommitSha`;
- `targetRepository`, `targetRef`, and `targetCommitSha`; and
- either `inventoryDigest`, `inventoryCommitSha`, and `inventoryReviewUrl` for baseline provenance,
  or `sourcePrNumber` for alignment-assessment provenance.

Unknown fields, unsafe paths or refs, malformed or oversized values, unsupported repositories,
non-`main` targets, stale target commits, and commits not reachable from their stated source ref are
rejected before any issue is created.

Baseline requests hash the exact bytes of `parity/inventory.json` at `inventoryCommitSha`, verify the
active baseline and both implementation commits, and require the inventory artifact commit to be
distinct from the Bicep and Terraform implementation commits. Alignment-assessment requests verify
the cited capabilities against the inventory at the immutable source commit.

## Idempotency and review

Concurrency is serialized by `handoffId`. The receiver searches active draft proposals and proposal
requests for the handoff marker and first honors a handoff's recorded `terraformPullRequestUrl`. A
duplicate dispatch returns the existing URL rather than creating another request. A new request
assigns the repository's `parity-proposal` custom agent, which may create a focused branch and draft
pull request only.

The target pull request must preserve traceability, compatibility and migration analysis,
semantic-version impact, both standalone scenarios, AVM checks, exact deferrals, and the `hub-spoke`
exclusion. No automatic reverse write updates the Bicep inventory; recording the proposal URL there
requires a separately reviewed source-repository change.

Static validation and Terraform plans are proposal evidence only. This workflow does not merge,
deploy, release, configure credentials, or claim parity.

## Activation and evidence deferrals

- Do not activate the dispatch path until the source coordination pull request is merged and its
  narrowly scoped GitHub App and protected publication environment are configured and reviewed.
- Do not automatically write the proposal URL back to Bicep. That update requires a separate,
  approved source-repository contribution.
- Do not merge, deploy, release, or claim parity from this workflow.
- Do not treat this workflow as Azure evidence. Runtime parity still requires separate approved
  deployments and reviewed comparisons for `standalone-standard` and
  `standalone-network-isolated`.
- Keep `hub-spoke` and arbitrary optional-feature combinations deferred unless a later approved
  handoff explicitly changes those exclusions.
