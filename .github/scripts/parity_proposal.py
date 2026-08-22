#!/usr/bin/env python3
"""Validate an approved parity handoff and idempotently request a draft proposal."""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import PurePosixPath
from typing import Any


SOURCE_REPOSITORY = "Azure/bicep-ptn-aiml-landing-zone"
TARGET_REPOSITORY = "Azure/terraform-azurerm-avm-ptn-aiml-landing-zone"
TARGET_REF = "main"
HANDOFF_SCHEMA_PATH = "parity/schemas/terraform-handoff.schema.json"
INVENTORY_PATH = "parity/inventory.json"
MAX_DISPATCH_BYTES = 16_384
MAX_EVENT_BYTES = 1_048_576
MAX_HANDOFF_BYTES = 262_144
MAX_SCHEMA_BYTES = 131_072
MAX_INVENTORY_BYTES = 4_194_304
MAX_CAPABILITIES = 100
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
CAPABILITY_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
HANDOFF_ID_PATTERN = re.compile(r"^handoff-[a-z0-9-]+$")
BASELINE_ID_PATTERN = re.compile(r"^baseline-[a-z0-9.-]+$")
ASSESSMENT_ID_PATTERN = re.compile(r"^assessment-[a-z0-9-]+$")
REF_PATTERN = re.compile(r"^(?:refs/(?:heads|tags)/)?[A-Za-z0-9](?:[A-Za-z0-9._/-]{0,126}[A-Za-z0-9._-])?$")

COMMON_FIELDS = {
    "handoffId",
    "handoffPath",
    "provenanceType",
    "provenanceId",
    "capabilityIds",
    "sourceRepository",
    "sourceRef",
    "sourceCommitSha",
    "targetRepository",
    "targetRef",
    "targetCommitSha",
}
BASELINE_FIELDS = {
    "inventoryDigest",
    "inventoryCommitSha",
    "inventoryReviewUrl",
}
ASSESSMENT_FIELDS = {"sourcePrNumber"}


class ContractError(RuntimeError):
    """A deterministic contract or authorization failure."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def canonical_json_bytes(value: Any) -> bytes:
    return json.dumps(value, separators=(",", ":"), sort_keys=True).encode("utf-8")


def validate_text(value: Any, field: str, maximum: int, pattern: re.Pattern[str] | None = None) -> str:
    require(isinstance(value, str), f"{field} must be a string")
    require(0 < len(value) <= maximum, f"{field} must contain 1..{maximum} characters")
    require("\x00" not in value and "\r" not in value and "\n" not in value, f"{field} contains prohibited control characters")
    if pattern is not None:
        require(pattern.fullmatch(value) is not None, f"{field} has an invalid format")
    return value


def validate_https_github_url(value: Any, field: str, repository: str) -> str:
    text = validate_text(value, field, 512)
    parsed = urllib.parse.urlparse(text)
    require(parsed.scheme == "https" and parsed.netloc == "github.com", f"{field} must be an https://github.com URL")
    require(parsed.path == f"/{repository}" or parsed.path.startswith(f"/{repository}/"), f"{field} must reference {repository}")
    require(not parsed.username and not parsed.password and not parsed.fragment, f"{field} contains prohibited URL components")
    return text


def validate_ref(value: Any, field: str) -> str:
    ref = validate_text(value, field, 128, REF_PATTERN)
    require(".." not in ref and "//" not in ref and "@{" not in ref and not ref.endswith("."), f"{field} is unsafe")
    return ref


def validate_handoff_path(value: Any) -> str:
    path = validate_text(value, "handoffPath", 256)
    parsed = PurePosixPath(path)
    require(
        not parsed.is_absolute()
        and ".." not in parsed.parts
        and path.startswith("parity/handoffs/")
        and path.endswith(".json")
        and "\\" not in path,
        "handoffPath must be a JSON file below parity/handoffs/",
    )
    return path


def validate_dispatch(payload: Any) -> dict[str, Any]:
    require(isinstance(payload, dict), "client_payload must be an object")
    require(len(canonical_json_bytes(payload)) <= MAX_DISPATCH_BYTES, "client_payload exceeds 16384 bytes")

    provenance_type = payload.get("provenanceType")
    if provenance_type == "baseline-inventory":
        allowed = COMMON_FIELDS | BASELINE_FIELDS
        required = allowed
    elif provenance_type == "alignment-assessment":
        allowed = COMMON_FIELDS | ASSESSMENT_FIELDS
        required = allowed
    else:
        raise ContractError("provenanceType must be baseline-inventory or alignment-assessment")

    unknown = sorted(set(payload) - allowed)
    missing = sorted(required - set(payload))
    require(not unknown, f"client_payload contains unknown fields: {', '.join(unknown)}")
    require(not missing, f"client_payload is missing fields: {', '.join(missing)}")

    validate_text(payload["handoffId"], "handoffId", 128, HANDOFF_ID_PATTERN)
    validate_handoff_path(payload["handoffPath"])
    validate_text(payload["provenanceId"], "provenanceId", 128)
    validate_text(payload["sourceRepository"], "sourceRepository", 128)
    validate_ref(payload["sourceRef"], "sourceRef")
    validate_text(payload["sourceCommitSha"], "sourceCommitSha", 40, SHA_PATTERN)
    validate_text(payload["targetRepository"], "targetRepository", 128)
    validate_ref(payload["targetRef"], "targetRef")
    validate_text(payload["targetCommitSha"], "targetCommitSha", 40, SHA_PATTERN)

    require(payload["sourceRepository"] == SOURCE_REPOSITORY, f"sourceRepository must be {SOURCE_REPOSITORY}")
    require(payload["targetRepository"] == TARGET_REPOSITORY, f"targetRepository must be {TARGET_REPOSITORY}")
    require(payload["targetRef"] == TARGET_REF, f"targetRef must be {TARGET_REF}")

    capabilities = payload["capabilityIds"]
    require(isinstance(capabilities, list), "capabilityIds must be an array")
    require(1 <= len(capabilities) <= MAX_CAPABILITIES, f"capabilityIds must contain 1..{MAX_CAPABILITIES} entries")
    require(len(capabilities) == len(set(capabilities)), "capabilityIds must be unique")
    for index, capability_id in enumerate(capabilities):
        validate_text(capability_id, f"capabilityIds[{index}]", 128, CAPABILITY_PATTERN)

    if provenance_type == "baseline-inventory":
        validate_text(payload["provenanceId"], "provenanceId", 128, BASELINE_ID_PATTERN)
        validate_text(payload["inventoryDigest"], "inventoryDigest", 64, re.compile(r"^[0-9a-f]{64}$"))
        validate_text(payload["inventoryCommitSha"], "inventoryCommitSha", 40, SHA_PATTERN)
        validate_https_github_url(payload["inventoryReviewUrl"], "inventoryReviewUrl", SOURCE_REPOSITORY)
        require(
            payload["inventoryCommitSha"] not in {payload["sourceCommitSha"], payload["targetCommitSha"]},
            "inventoryCommitSha must remain distinct from implementation commits",
        )
    else:
        validate_text(payload["provenanceId"], "provenanceId", 128, ASSESSMENT_ID_PATTERN)
        number = payload["sourcePrNumber"]
        require(isinstance(number, int) and not isinstance(number, bool) and 1 <= number <= 2_147_483_647, "sourcePrNumber must be a positive integer")
        require(
            payload["provenanceId"].startswith(f"assessment-{number}-"),
            "provenanceId must identify sourcePrNumber",
        )

    return payload


def _schema_type_matches(instance: Any, expected: str) -> bool:
    return {
        "object": isinstance(instance, dict),
        "array": isinstance(instance, list),
        "string": isinstance(instance, str),
        "integer": isinstance(instance, int) and not isinstance(instance, bool),
        "number": isinstance(instance, (int, float)) and not isinstance(instance, bool),
        "boolean": isinstance(instance, bool),
        "null": instance is None,
    }.get(expected, False)


def _resolve_pointer(root: dict[str, Any], reference: str) -> dict[str, Any]:
    require(reference.startswith("#/"), f"unsupported schema reference: {reference}")
    current: Any = root
    for part in reference[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        require(isinstance(current, dict) and part in current, f"unresolved schema reference: {reference}")
        current = current[part]
    require(isinstance(current, dict), f"schema reference is not an object: {reference}")
    return current


def _schema_matches(instance: Any, schema: dict[str, Any], root: dict[str, Any]) -> bool:
    try:
        validate_schema(instance, schema, root)
        return True
    except ContractError:
        return False


def validate_schema(instance: Any, schema: dict[str, Any], root: dict[str, Any] | None = None, path: str = "$") -> None:
    root = schema if root is None else root
    if "$ref" in schema:
        validate_schema(instance, _resolve_pointer(root, schema["$ref"]), root, path)
        return

    for subschema in schema.get("allOf", []):
        validate_schema(instance, subschema, root, path)

    if "if" in schema:
        branch = schema.get("then") if _schema_matches(instance, schema["if"], root) else schema.get("else")
        if branch is not None:
            validate_schema(instance, branch, root, path)

    if "oneOf" in schema:
        matches = sum(_schema_matches(instance, candidate, root) for candidate in schema["oneOf"])
        require(matches == 1, f"{path} must match exactly one schema alternative")

    if "anyOf" in schema:
        require(any(_schema_matches(instance, candidate, root) for candidate in schema["anyOf"]), f"{path} does not match any schema alternative")

    if "not" in schema:
        require(not _schema_matches(instance, schema["not"], root), f"{path} matches a prohibited schema")

    if "const" in schema:
        require(instance == schema["const"], f"{path} must equal {schema['const']!r}")
    if "enum" in schema:
        require(instance in schema["enum"], f"{path} contains an unsupported value")

    expected_type = schema.get("type")
    if expected_type is not None:
        expected_types = [expected_type] if isinstance(expected_type, str) else expected_type
        require(any(_schema_type_matches(instance, item) for item in expected_types), f"{path} has an invalid type")

    if isinstance(instance, dict):
        required = schema.get("required", [])
        missing = [name for name in required if name not in instance]
        require(not missing, f"{path} is missing required fields: {', '.join(missing)}")
        properties = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            unknown = sorted(set(instance) - set(properties))
            require(not unknown, f"{path} contains unknown fields: {', '.join(unknown)}")
        for name, value in instance.items():
            if name in properties:
                validate_schema(value, properties[name], root, f"{path}.{name}")

    if isinstance(instance, list):
        if "minItems" in schema:
            require(len(instance) >= schema["minItems"], f"{path} has too few items")
        if "maxItems" in schema:
            require(len(instance) <= schema["maxItems"], f"{path} has too many items")
        if schema.get("uniqueItems"):
            encoded = [canonical_json_bytes(item) for item in instance]
            require(len(encoded) == len(set(encoded)), f"{path} must contain unique items")
        prefix_items = schema.get("prefixItems", [])
        for index, item_schema in enumerate(prefix_items):
            if index < len(instance):
                validate_schema(instance[index], item_schema, root, f"{path}[{index}]")
        items = schema.get("items")
        if items is False:
            require(len(instance) <= len(prefix_items), f"{path} contains unexpected trailing items")
        elif isinstance(items, dict):
            for index, item in enumerate(instance[len(prefix_items) :], start=len(prefix_items)):
                validate_schema(item, items, root, f"{path}[{index}]")

    if isinstance(instance, str):
        if "minLength" in schema:
            require(len(instance) >= schema["minLength"], f"{path} is too short")
        if "maxLength" in schema:
            require(len(instance) <= schema["maxLength"], f"{path} is too long")
        if "pattern" in schema:
            require(re.search(schema["pattern"], instance) is not None, f"{path} has an invalid format")
        if schema.get("format") == "uri":
            parsed = urllib.parse.urlparse(instance)
            require(bool(parsed.scheme and parsed.netloc), f"{path} must be an absolute URI")
        if schema.get("format") == "date-time":
            try:
                dt.datetime.fromisoformat(instance.replace("Z", "+00:00"))
            except ValueError as exc:
                raise ContractError(f"{path} must be an RFC 3339 date-time") from exc


class GitHubClient:
    def __init__(self, token: str, api_url: str = "https://api.github.com") -> None:
        require(bool(token), "GH_TOKEN is required")
        self.token = token
        self.api_url = api_url.rstrip("/")

    def request(self, method: str, path: str, body: dict[str, Any] | None = None) -> Any:
        data = canonical_json_bytes(body) if body is not None else None
        request = urllib.request.Request(
            f"{self.api_url}{path}",
            data=data,
            method=method,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": "Bearer " + self.token,
                "Content-Type": "application/json",
                "User-Agent": "terraform-parity-proposal",
                "X-GitHub-Api-Version": "2022-11-28",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:1000]
            raise ContractError(f"GitHub API {method} {path} failed with HTTP {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise ContractError(f"GitHub API {method} {path} failed: {exc.reason}") from exc
        return json.loads(raw) if raw else None

    def get_paginated(self, path: str, page_size: int = 100, maximum_pages: int = 10) -> list[Any]:
        separator = "&" if "?" in path else "?"
        results: list[Any] = []
        for page in range(1, maximum_pages + 1):
            response = self.request("GET", f"{path}{separator}per_page={page_size}&page={page}")
            require(isinstance(response, list), f"paginated GitHub API response for {path} must be an array")
            results.extend(response)
            if len(response) < page_size:
                return results
        raise ContractError(f"pagination limit exceeded while reconciling {path}")

    def get_file(self, repository: str, path: str, commit: str, maximum: int) -> bytes:
        encoded_path = urllib.parse.quote(path, safe="/")
        encoded_commit = urllib.parse.quote(commit, safe="")
        response = self.request("GET", f"/repos/{repository}/contents/{encoded_path}?ref={encoded_commit}")
        require(isinstance(response, dict) and response.get("type") == "file", f"{path} is not a file")
        require(response.get("encoding") == "base64" and isinstance(response.get("content"), str), f"{path} has an unsupported encoding")
        try:
            content = base64.b64decode(response["content"], validate=True)
        except ValueError as exc:
            raise ContractError(f"{path} contains invalid base64 content") from exc
        require(len(content) <= maximum, f"{path} exceeds the {maximum}-byte limit")
        return content

    def resolve_commit(self, repository: str, ref: str) -> str:
        encoded_ref = urllib.parse.quote(ref, safe="")
        response = self.request("GET", f"/repos/{repository}/commits/{encoded_ref}")
        sha = response.get("sha") if isinstance(response, dict) else None
        require(isinstance(sha, str) and SHA_PATTERN.fullmatch(sha) is not None, f"could not resolve {repository}@{ref}")
        return sha

    def require_reachable(self, repository: str, commit: str, ref: str) -> None:
        ref_commit = self.resolve_commit(repository, ref)
        if ref_commit == commit:
            return
        response = self.request("GET", f"/repos/{repository}/compare/{commit}...{ref_commit}")
        require(response.get("status") in {"ahead", "identical"}, f"{commit} is not reachable from {repository}@{ref}")


def load_json_bytes(content: bytes, name: str) -> Any:
    try:
        return json.loads(content.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ContractError(f"{name} is not valid UTF-8 JSON") from exc


def validate_handoff(payload: dict[str, Any], handoff: Any, schema: Any) -> None:
    require(isinstance(schema, dict), "source handoff schema must be an object")
    require(isinstance(handoff, dict), "handoff must be an object")
    validate_schema(handoff, schema)
    require(handoff["approval"]["status"] == "approved", "handoff approval.status must be approved")
    require(handoff["id"] == payload["handoffId"], "handoff ID does not match dispatch")
    require(handoff["capabilityIds"] == payload["capabilityIds"], "handoff capability IDs do not match dispatch order and content")

    for side in ("source", "target"):
        expected = {
            "repository": payload[f"{side}Repository"],
            "ref": payload[f"{side}Ref"],
            "commitSha": payload[f"{side}CommitSha"],
        }
        require(handoff[side] == expected, f"handoff {side} reference does not match dispatch")

    provenance = handoff["provenance"]
    require(provenance["type"] == payload["provenanceType"], "handoff provenance type does not match dispatch")
    id_field = "baselineId" if payload["provenanceType"] == "baseline-inventory" else "assessmentId"
    require(provenance[id_field] == payload["provenanceId"], "handoff provenance ID does not match dispatch")

    if payload["provenanceType"] == "baseline-inventory":
        require(provenance["inventoryDigest"] == {"algorithm": "sha256", "value": payload["inventoryDigest"]}, "handoff inventory digest does not match dispatch")
        require(provenance["inventoryCommitSha"] == payload["inventoryCommitSha"], "handoff inventory commit does not match dispatch")
        require(provenance["inventoryReviewUrl"] == payload["inventoryReviewUrl"], "handoff inventory review URL does not match dispatch")


def validate_inventory(payload: dict[str, Any], inventory_bytes: bytes, inventory: Any) -> None:
    require(isinstance(inventory, dict), "inventory must be an object")
    baseline = inventory.get("baseline")
    require(isinstance(baseline, dict), "inventory baseline is missing")
    require(baseline.get("status") == "active", "inventory baseline must be active")
    require(baseline.get("source", {}).get("repository") == SOURCE_REPOSITORY, "inventory source repository is invalid")
    require(baseline.get("terraform", {}).get("repository") == TARGET_REPOSITORY, "inventory target repository is invalid")
    require(baseline.get("source", {}).get("commitSha") == payload["sourceCommitSha"], "inventory source commit does not match handoff")
    require(baseline.get("terraform", {}).get("commitSha") == payload["targetCommitSha"], "inventory target commit does not match handoff")

    capability_ids = {
        item.get("id")
        for item in inventory.get("capabilities", [])
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    missing = sorted(set(payload["capabilityIds"]) - capability_ids)
    require(not missing, f"capability IDs are absent from inventory: {', '.join(missing)}")

    if payload["provenanceType"] == "baseline-inventory":
        digest = hashlib.sha256(inventory_bytes).hexdigest()
        require(digest == payload["inventoryDigest"], "exact inventory bytes do not match inventoryDigest")
        require(baseline.get("id") == payload["provenanceId"], "inventory baseline ID does not match provenanceId")


def validate_remote_state(client: GitHubClient, payload: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    target = client.request("GET", f"/repos/{TARGET_REPOSITORY}")
    require(target.get("default_branch") == TARGET_REF, f"{TARGET_REPOSITORY} default branch must be {TARGET_REF}")
    target_head = client.resolve_commit(TARGET_REPOSITORY, TARGET_REF)
    require(target_head == payload["targetCommitSha"], "targetCommitSha is stale or is not current main")
    client.require_reachable(SOURCE_REPOSITORY, payload["sourceCommitSha"], payload["sourceRef"])

    handoff_bytes = client.get_file(SOURCE_REPOSITORY, payload["handoffPath"], payload["sourceCommitSha"], MAX_HANDOFF_BYTES)
    schema_bytes = client.get_file(SOURCE_REPOSITORY, HANDOFF_SCHEMA_PATH, payload["sourceCommitSha"], MAX_SCHEMA_BYTES)
    handoff = load_json_bytes(handoff_bytes, payload["handoffPath"])
    schema = load_json_bytes(schema_bytes, HANDOFF_SCHEMA_PATH)
    validate_handoff(payload, handoff, schema)

    inventory_commit = payload.get("inventoryCommitSha", payload["sourceCommitSha"])
    inventory_bytes = client.get_file(SOURCE_REPOSITORY, INVENTORY_PATH, inventory_commit, MAX_INVENTORY_BYTES)
    inventory = load_json_bytes(inventory_bytes, INVENTORY_PATH)
    validate_inventory(payload, inventory_bytes, inventory)
    return handoff, inventory


def proposal_marker(handoff_id: str) -> str:
    return f"<!-- parity-handoff-id: {handoff_id} -->"


def find_existing(client: GitHubClient, payload: dict[str, Any], handoff: dict[str, Any]) -> tuple[str, str]:
    recorded_url = handoff.get("terraformPullRequestUrl")
    if recorded_url is not None:
        return validate_https_github_url(
            recorded_url,
            "terraformPullRequestUrl",
            TARGET_REPOSITORY,
        ), ""

    marker = proposal_marker(payload["handoffId"])
    pulls = client.get_paginated(f"/repos/{TARGET_REPOSITORY}/pulls?state=open&base={TARGET_REF}")
    matches = [item for item in pulls if marker in (item.get("body") or "")]
    require(len(matches) <= 1, f"multiple active proposals exist for {payload['handoffId']}")
    if matches:
        return matches[0]["html_url"], ""

    issues = client.get_paginated(f"/repos/{TARGET_REPOSITORY}/issues?state=open")
    trackers = [
        item
        for item in issues
        if "pull_request" not in item and marker in (item.get("body") or "")
    ]
    require(len(trackers) <= 1, f"multiple active proposal requests exist for {payload['handoffId']}")
    return "", trackers[0]["html_url"] if trackers else ""


def build_issue(payload: dict[str, Any], handoff: dict[str, Any]) -> dict[str, Any]:
    marker = proposal_marker(payload["handoffId"])
    provenance_url = (
        payload["inventoryReviewUrl"]
        if payload["provenanceType"] == "baseline-inventory"
        else f"https://github.com/{SOURCE_REPOSITORY}/pull/{payload['sourcePrNumber']}"
    )
    prompt = f"""Implement the approved parity handoff `{payload['handoffId']}` as a focused, reviewable draft pull request.

The handoff is at `https://github.com/{SOURCE_REPOSITORY}/blob/{payload['sourceCommitSha']}/{payload['handoffPath']}`.
Use target baseline `{payload['targetCommitSha']}` on `main`. Follow `.github/agents/parity-proposal.agent.md`.
Open a draft PR only; do not merge, deploy, release, publish, configure credentials, or claim parity.
Include `{marker}` in the PR body so duplicate dispatches reconcile this proposal.
"""
    body = f"""{marker}

## Approved parity handoff

- Handoff: [`{payload['handoffId']}`](https://github.com/{SOURCE_REPOSITORY}/blob/{payload['sourceCommitSha']}/{payload['handoffPath']})
- Provenance: [{payload['provenanceType']} `{payload['provenanceId']}`]({provenance_url})
- Capabilities: {", ".join(f"`{item}`" for item in payload["capabilityIds"])}
- Bicep implementation commit: `{payload['sourceCommitSha']}`
- Terraform baseline commit: `{payload['targetCommitSha']}`
- Approval: {handoff["approval"]["approvalUrl"]}

## Agent boundary

Create one focused branch and one draft pull request against `main`. Preserve compatibility or
document migration and semantic-version impact. Cover `standalone-standard` and
`standalone-network-isolated` independently. Run target-native and AVM checks, report exact
deferrals, and keep `hub-spoke` excluded. Static checks and plans are proposal evidence only; they
must not be presented as deployment evidence or a parity claim.
"""
    return {
        "title": f"Parity proposal: {payload['handoffId']}",
        "body": body,
        "agent_assignment": {
            "target_repo": TARGET_REPOSITORY,
            "base_branch": TARGET_REF,
            "custom_agent": "parity-proposal",
            "custom_instructions": prompt,
        },
    }


def write_outputs(output_path: str, summary_path: str, proposal_url: str, tracker_url: str, payload: dict[str, Any], duplicate: bool) -> None:
    with open(output_path, "a", encoding="utf-8", newline="\n") as stream:
        stream.write(f"proposal_url={proposal_url}\n")
        stream.write(f"tracker_url={tracker_url}\n")
        stream.write(f"duplicate={'true' if duplicate else 'false'}\n")

    result_url = proposal_url or tracker_url
    result_label = "Existing draft proposal" if proposal_url else "Proposal request"
    with open(summary_path, "a", encoding="utf-8", newline="\n") as stream:
        stream.write("## Terraform parity proposal\n\n")
        stream.write(f"- Handoff: `{payload['handoffId']}`\n")
        stream.write(f"- Result: [{result_label}]({result_url})\n")
        stream.write(f"- Duplicate delivery reconciled: `{'yes' if duplicate else 'no'}`\n")
        stream.write("- Evidence boundary: proposal only; no deployment, release, or parity claim was performed.\n")


def receive(args: argparse.Namespace) -> None:
    with open(args.event, "rb") as stream:
        event_bytes = stream.read(MAX_EVENT_BYTES + 1)
    require(len(event_bytes) <= MAX_EVENT_BYTES, "event file exceeds the 1 MiB limit")
    event = load_json_bytes(event_bytes, args.event)
    require(isinstance(event, dict), "event must be an object")
    require(event.get("action") == "parity-proposal-requested", "unexpected repository_dispatch action")
    payload = validate_dispatch(event.get("client_payload"))
    require(args.repository == TARGET_REPOSITORY, f"workflow repository must be {TARGET_REPOSITORY}")

    client = GitHubClient(os.environ.get("GH_TOKEN", ""))
    handoff, _ = validate_remote_state(client, payload)
    proposal_url, tracker_url = find_existing(client, payload, handoff)
    duplicate = bool(proposal_url or tracker_url)

    if not duplicate:
        issue = client.request("POST", f"/repos/{TARGET_REPOSITORY}/issues", build_issue(payload, handoff))
        tracker_url = issue.get("html_url", "")
        require(bool(tracker_url), "GitHub did not return a proposal request URL")

    write_outputs(args.output, args.summary, proposal_url, tracker_url, payload, duplicate)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    receive_parser = subparsers.add_parser("receive")
    receive_parser.add_argument("--event", required=True)
    receive_parser.add_argument("--repository", required=True)
    receive_parser.add_argument("--output", required=True)
    receive_parser.add_argument("--summary", required=True)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    try:
        args = parse_args(sys.argv[1:] if argv is None else argv)
        if args.command == "receive":
            receive(args)
        return 0
    except ContractError as exc:
        print(f"parity proposal rejected: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
