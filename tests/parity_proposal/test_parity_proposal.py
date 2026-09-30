import base64
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".github" / "scripts" / "parity_proposal.py"
SPEC = importlib.util.spec_from_file_location("parity_proposal", SCRIPT)
parity_proposal = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(parity_proposal)


SOURCE_SHA = "1" * 40
TARGET_SHA = "2" * 40
INVENTORY_SHA = "3" * 40
INVENTORY_DIGEST = "4" * 64
HANDOFF_SHA = "5" * 40
HANDOFF_DIGEST = "6" * 64
CURRENT_HEAD_SHA = "7" * 40


def baseline_payload():
    return {
        "payloadVersion": "2.0.0",
        "handoffId": "handoff-sample",
        "handoffPath": "parity/handoffs/ai-foundry/sample.json",
        "handoffSchemaPath": parity_proposal.HANDOFF_SCHEMA_PATH,
        "handoffCommitSha": HANDOFF_SHA,
        "handoffRef": "develop",
        "handoffDigest": HANDOFF_DIGEST,
        "provenanceType": "baseline-inventory",
        "provenanceId": "baseline-v1.0.0-v1.0.0",
        "capabilityIds": ["ai-foundry-account"],
        "sourceRepository": parity_proposal.SOURCE_REPOSITORY,
        "sourceRef": "v1.0.0",
        "sourceCommitSha": SOURCE_SHA,
        "targetRepository": parity_proposal.TARGET_REPOSITORY,
        "targetRef": "main",
        "targetCommitSha": TARGET_SHA,
        "inventoryDigest": INVENTORY_DIGEST,
        "inventoryCommitSha": INVENTORY_SHA,
        "inventoryReviewUrl": "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/100",
    }


def assessment_payload():
    payload = baseline_payload()
    payload["provenanceType"] = "alignment-assessment"
    payload["provenanceId"] = "assessment-136-abcdef0"
    payload["sourceRef"] = "develop"
    payload.pop("inventoryDigest")
    payload.pop("inventoryCommitSha")
    payload.pop("inventoryReviewUrl")
    payload["sourcePrNumber"] = 136
    return payload


def approved_handoff(payload):
    provenance = (
        {
            "type": "baseline-inventory",
            "baselineId": payload["provenanceId"],
            "inventoryDigest": {"algorithm": "sha256", "value": payload["inventoryDigest"]},
            "inventoryCommitSha": payload["inventoryCommitSha"],
            "inventoryReviewUrl": payload["inventoryReviewUrl"],
        }
        if payload["provenanceType"] == "baseline-inventory"
        else {
            "type": "alignment-assessment",
            "assessmentId": payload["provenanceId"],
        }
    )
    return {
        "id": payload["handoffId"],
        "provenance": provenance,
        "capabilityIds": payload["capabilityIds"],
        "source": {
            "repository": payload["sourceRepository"],
            "ref": payload["sourceRef"],
            "commitSha": payload["sourceCommitSha"],
        },
        "target": {
            "repository": payload["targetRepository"],
            "ref": payload["targetRef"],
            "commitSha": payload["targetCommitSha"],
        },
        "approval": {
            "status": "approved",
            "approvalUrl": "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/101",
            "approvedBy": "reviewer",
            "approvedAt": "2026-08-22T12:00:00Z",
        },
    }


STRICT_TEST_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["id", "provenance", "capabilityIds", "source", "target", "approval"],
    "properties": {
        "id": {"type": "string", "pattern": "^handoff-"},
        "provenance": {"type": "object"},
        "capabilityIds": {"type": "array", "minItems": 1, "uniqueItems": True, "items": {"type": "string"}},
        "source": {"type": "object"},
        "target": {"type": "object"},
        "approval": {
            "type": "object",
            "required": ["status"],
            "properties": {"status": {"enum": ["pending", "approved", "rejected", "superseded"]}},
        },
    },
}


class DispatchContractTests(unittest.TestCase):
    def test_accepts_both_bounded_provenance_forms(self):
        self.assertEqual("baseline-inventory", parity_proposal.validate_dispatch(baseline_payload())["provenanceType"])
        self.assertEqual("alignment-assessment", parity_proposal.validate_dispatch(assessment_payload())["provenanceType"])

    def test_rejects_unknown_and_oversized_fields(self):
        payload = baseline_payload()
        payload["rawDiff"] = "untrusted"
        with self.assertRaisesRegex(parity_proposal.ContractError, "unknown fields"):
            parity_proposal.validate_dispatch(payload)

        payload = baseline_payload()
        payload["capabilityIds"] = [f"capability-{index}" for index in range(101)]
        with self.assertRaisesRegex(parity_proposal.ContractError, "1..100"):
            parity_proposal.validate_dispatch(payload)

    def test_rejects_v1_absent_or_non_major_two_version_by_named_error(self):
        for value in (None, "1.0.0", "3.0.0"):
            payload = baseline_payload()
            if value is None:
                payload.pop("payloadVersion")
            else:
                payload["payloadVersion"] = value
            with self.subTest(value=value), self.assertRaisesRegex(
                parity_proposal.ContractError,
                "unsupported_payload_version",
            ):
                parity_proposal.validate_dispatch(payload)

    def test_requires_all_v2_fields(self):
        for field in ("handoffSchemaPath", "handoffCommitSha", "handoffRef", "handoffDigest"):
            payload = baseline_payload()
            payload.pop(field)
            with self.subTest(field=field), self.assertRaisesRegex(parity_proposal.ContractError, "missing fields"):
                parity_proposal.validate_dispatch(payload)

    def test_rejects_path_traversal_and_wrong_repository_or_branch(self):
        for field, value in (
            ("handoffPath", "parity/handoffs/../inventory.json"),
            ("handoffSchemaPath", "parity/schemas/../handoffs/sample.json"),
            ("handoffRef", "feature/untrusted"),
            ("sourceRepository", "attacker/example"),
            ("targetRepository", "Azure/other"),
            ("targetRef", "develop"),
        ):
            payload = baseline_payload()
            payload[field] = value
            with self.subTest(field=field), self.assertRaises(parity_proposal.ContractError):
                parity_proposal.validate_dispatch(payload)

    def test_requires_distinct_inventory_artifact_commit(self):
        payload = baseline_payload()
        payload["inventoryCommitSha"] = payload["sourceCommitSha"]
        with self.assertRaisesRegex(parity_proposal.ContractError, "distinct"):
            parity_proposal.validate_dispatch(payload)

    def test_requires_distinct_handoff_artifact_commit(self):
        payload = baseline_payload()
        payload["handoffCommitSha"] = payload["sourceCommitSha"]
        with self.assertRaisesRegex(parity_proposal.ContractError, "implementation baseline"):
            parity_proposal.validate_dispatch(payload)

    def test_inventory_review_url_must_be_canonical_source_pull_request(self):
        for value in (
            "https://github.com/Azure/other/pull/100",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/issues/100",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/100/",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/100?diff=split",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/100#issuecomment-1",
        ):
            payload = baseline_payload()
            payload["inventoryReviewUrl"] = value
            with self.subTest(value=value), self.assertRaises(parity_proposal.ContractError):
                parity_proposal.validate_dispatch(payload)

    def test_assessment_id_must_match_source_pull_request(self):
        payload = assessment_payload()
        payload["sourcePrNumber"] = 137
        with self.assertRaisesRegex(parity_proposal.ContractError, "identify"):
            parity_proposal.validate_dispatch(payload)


class HandoffAndInventoryTests(unittest.TestCase):
    def test_requires_approved_schema_valid_exact_handoff(self):
        payload = baseline_payload()
        handoff = approved_handoff(payload)
        parity_proposal.validate_handoff(payload, handoff, STRICT_TEST_SCHEMA)

        handoff["approval"]["status"] = "pending"
        with self.assertRaisesRegex(parity_proposal.ContractError, "approved"):
            parity_proposal.validate_handoff(payload, handoff, STRICT_TEST_SCHEMA)

    def test_accepts_canonical_source_pull_request_approval_evidence(self):
        payload = baseline_payload()
        for fragment in (
            "",
            "#issuecomment-5375280499",
            "#pullrequestreview-123",
            "#discussion_r456",
        ):
            handoff = approved_handoff(payload)
            handoff["approval"]["approvalUrl"] = (
                "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/147" + fragment
            )
            with self.subTest(fragment=fragment):
                parity_proposal.validate_handoff(payload, handoff, STRICT_TEST_SCHEMA)

    def test_rejects_unrelated_or_malformed_approval_evidence_url(self):
        payload = baseline_payload()
        for value in (
            "https://github.com/Azure/other/pull/147",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/issues/147",
            "https://example.com/Azure/bicep-ptn-aiml-landing-zone/pull/147",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/0",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/147/",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/147?diff=split",
            "https://github.com/Azure/bicep-ptn-aiml-landing-zone/pull/147#files",
        ):
            handoff = approved_handoff(payload)
            handoff["approval"]["approvalUrl"] = value
            with self.subTest(value=value), self.assertRaises(parity_proposal.ContractError):
                parity_proposal.validate_handoff(payload, handoff, STRICT_TEST_SCHEMA)

    def test_schema_validator_rejects_unknown_handoff_fields(self):
        payload = baseline_payload()
        handoff = approved_handoff(payload)
        handoff["unexpected"] = True
        with self.assertRaisesRegex(parity_proposal.ContractError, "unknown fields"):
            parity_proposal.validate_handoff(payload, handoff, STRICT_TEST_SCHEMA)

    def test_baseline_inventory_uses_exact_bytes_and_commits(self):
        payload = baseline_payload()
        inventory = {
            "baseline": {
                "id": payload["provenanceId"],
                "status": "active",
                "source": {"repository": payload["sourceRepository"], "commitSha": payload["sourceCommitSha"]},
                "terraform": {"repository": payload["targetRepository"], "commitSha": payload["targetCommitSha"]},
            },
            "capabilities": [{"id": "ai-foundry-account"}],
        }
        inventory_bytes = json.dumps(inventory, indent=2).encode()
        payload["inventoryDigest"] = hashlib.sha256(inventory_bytes).hexdigest()
        parity_proposal.validate_inventory(payload, inventory_bytes, inventory)

        with self.assertRaisesRegex(parity_proposal.ContractError, "exact inventory bytes"):
            parity_proposal.validate_inventory(payload, inventory_bytes + b"\n", inventory)

    def test_missing_capability_is_rejected(self):
        payload = assessment_payload()
        inventory = {
            "baseline": {
                "status": "active",
                "source": {"repository": payload["sourceRepository"], "commitSha": payload["sourceCommitSha"]},
                "terraform": {"repository": payload["targetRepository"], "commitSha": payload["targetCommitSha"]},
            },
            "capabilities": [],
        }
        with self.assertRaisesRegex(parity_proposal.ContractError, "absent"):
            parity_proposal.validate_inventory(payload, b"{}", inventory)


def inventory_for(payload):
    return {
        "baseline": {
            "id": payload["provenanceId"],
            "status": "active",
            "source": {"repository": payload["sourceRepository"], "commitSha": payload["sourceCommitSha"]},
            "terraform": {"repository": payload["targetRepository"], "commitSha": payload["targetCommitSha"]},
        },
        "capabilities": [{"id": "ai-foundry-account"}],
    }


class RemoteStateClient:
    def __init__(self, payload, *, bad_branch=False, bad_ancestor=False, missing_path=None):
        self.payload = payload
        self.bad_branch = bad_branch
        self.bad_ancestor = bad_ancestor
        self.missing_path = missing_path
        handoff = approved_handoff(payload)
        self.handoff_bytes = json.dumps(handoff, indent=2).replace("\n", "\r\n").encode()
        self.schema_bytes = json.dumps(STRICT_TEST_SCHEMA).encode()
        inventory = inventory_for(payload)
        self.inventory_bytes = json.dumps(inventory, indent=2).encode()
        self.files = {
            (payload["handoffPath"], payload["handoffCommitSha"]): self.handoff_bytes,
            (payload["handoffSchemaPath"], payload["handoffCommitSha"]): self.schema_bytes,
            (parity_proposal.INVENTORY_PATH, payload.get("inventoryCommitSha")): self.inventory_bytes,
        }
        self.reachable = []
        self.ancestor = []

    def request(self, method, path, body=None):
        if method == "GET" and path == f"/repos/{parity_proposal.TARGET_REPOSITORY}":
            return {"default_branch": "main"}
        raise AssertionError((method, path, body))

    def resolve_commit(self, repository, ref):
        if repository == parity_proposal.TARGET_REPOSITORY and ref == "main":
            return CURRENT_HEAD_SHA
        return ref

    def require_ancestor(self, repository, ancestor, descendant, label):
        self.ancestor.append((repository, ancestor, descendant, label))
        if self.bad_ancestor:
            raise parity_proposal.ContractError("target_baseline_not_ancestor")

    def require_reachable(self, repository, commit, ref):
        self.reachable.append((repository, commit, ref))
        if self.bad_branch and commit == self.payload["handoffCommitSha"]:
            raise parity_proposal.ContractError("not reachable")

    def get_file(self, repository, path, commit, maximum):
        if path == self.missing_path:
            raise parity_proposal.ContractError("artifact_fetch_failed: 404")
        value = self.files[(path, commit)]
        if len(value) > maximum:
            raise parity_proposal.ContractError("oversized")
        return value


class RemoteStateTests(unittest.TestCase):
    def valid_client(self):
        payload = baseline_payload()
        inventory_bytes = json.dumps(inventory_for(payload), indent=2).encode()
        payload["inventoryDigest"] = hashlib.sha256(inventory_bytes).hexdigest()
        client = RemoteStateClient(payload)
        payload["handoffDigest"] = hashlib.sha256(parity_proposal.lf_normalize(client.handoff_bytes)).hexdigest()
        client.payload = payload
        return payload, client

    def test_fetches_handoff_and_schema_only_at_artifact_commit_and_accepts_ancestor(self):
        payload, client = self.valid_client()
        handoff, inventory, target_head = parity_proposal.validate_remote_state(client, payload)
        self.assertEqual(payload["handoffId"], handoff["id"])
        self.assertEqual(payload["provenanceId"], inventory["baseline"]["id"])
        self.assertEqual(CURRENT_HEAD_SHA, target_head)
        self.assertIn(
            (parity_proposal.SOURCE_REPOSITORY, payload["handoffCommitSha"], "develop"),
            client.reachable,
        )
        self.assertEqual(
            (
                parity_proposal.TARGET_REPOSITORY,
                payload["targetCommitSha"],
                CURRENT_HEAD_SHA,
                "target_baseline_not_ancestor",
            ),
            client.ancestor[0],
        )

    def test_alignment_does_not_infer_or_fetch_inventory_from_source_baseline(self):
        payload = assessment_payload()
        client = RemoteStateClient(payload)
        payload["handoffDigest"] = hashlib.sha256(parity_proposal.lf_normalize(client.handoff_bytes)).hexdigest()
        handoff, inventory, target_head = parity_proposal.validate_remote_state(client, payload)
        self.assertEqual(payload["handoffId"], handoff["id"])
        self.assertIsNone(inventory)
        self.assertEqual(CURRENT_HEAD_SHA, target_head)

    def test_rejects_404_at_handoff_commit(self):
        payload, client = self.valid_client()
        client.missing_path = payload["handoffPath"]
        with self.assertRaisesRegex(parity_proposal.ContractError, "artifact_fetch_failed"):
            parity_proposal.validate_remote_state(client, payload)

    def test_rejects_handoff_commit_outside_allowlisted_branch(self):
        payload, client = self.valid_client()
        client.bad_branch = True
        with self.assertRaisesRegex(parity_proposal.ContractError, "not reachable"):
            parity_proposal.validate_remote_state(client, payload)

    def test_lf_normalized_digest_accepts_crlf_but_rejects_changed_bytes(self):
        payload, client = self.valid_client()
        parity_proposal.validate_remote_state(client, payload)
        payload["handoffDigest"] = "0" * 64
        with self.assertRaisesRegex(parity_proposal.ContractError, "handoff_digest_mismatch"):
            parity_proposal.validate_remote_state(client, payload)

    def test_rejects_schema_mismatch_from_same_artifact_commit(self):
        payload, client = self.valid_client()
        schema = copy.deepcopy(STRICT_TEST_SCHEMA)
        schema["required"].append("requiredByNewSchema")
        client.files[(payload["handoffSchemaPath"], payload["handoffCommitSha"])] = json.dumps(schema).encode()
        with self.assertRaisesRegex(parity_proposal.ContractError, "missing required field"):
            parity_proposal.validate_remote_state(client, payload)

    def test_rejects_non_ancestor_target_baseline(self):
        payload, client = self.valid_client()
        client.bad_ancestor = True
        with self.assertRaisesRegex(parity_proposal.ContractError, "target_baseline_not_ancestor"):
            parity_proposal.validate_remote_state(client, payload)


class GitHubClientTests(unittest.TestCase):
    def test_request_uses_the_provided_token(self):
        class Response:
            def __enter__(self):
                return self

            def __exit__(self, *_):
                return False

            def read(self):
                return b"{}"

        with mock.patch.object(parity_proposal.urllib.request, "urlopen", return_value=Response()) as urlopen:
            parity_proposal.GitHubClient("test-token").request("GET", "/test")
        request = urlopen.call_args.args[0]
        self.assertEqual("Bearer test-token", request.get_header("Authorization"))


class FakeGitHubClient:
    def __init__(self, pulls=None, issues=None, comments=None, pull_detail=None):
        self.pulls = pulls or []
        self.issues = issues or []
        self.comments = comments or []
        self.pull_detail = pull_detail
        self.posts = []

    def request(self, method, path, body=None):
        if method == "GET" and "/pulls/" in path:
            return self.pull_detail
        if method == "GET" and "/pulls?" in path:
            return self.pulls
        if method == "GET" and "/issues?" in path:
            return self.issues
        if method == "POST":
            self.posts.append((path, body))
            return {"html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/issues/99"}
        raise AssertionError((method, path))

    def get_paginated(self, path, page_size=100, maximum_pages=10):
        if "/pulls?" in path:
            return self.pulls
        if "/issues?" in path:
            return self.issues
        if "/comments" in path:
            return self.comments
        raise AssertionError(path)


class IdempotencyTests(unittest.TestCase):
    def test_duplicate_dispatch_returns_existing_proposal(self):
        payload = baseline_payload()
        marker = "\n".join(
            (
                parity_proposal.proposal_marker(payload["handoffId"]),
                parity_proposal.artifact_marker(payload["handoffCommitSha"]),
            )
        )
        client = FakeGitHubClient(
            pulls=[{"body": marker, "html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/42"}]
        )
        proposal, tracker, drift = parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertTrue(proposal.endswith("/pull/42"))
        self.assertEqual("", tracker)
        self.assertFalse(drift)
        self.assertEqual([], client.posts)

    def test_duplicate_dispatch_returns_existing_tracker(self):
        payload = baseline_payload()
        marker = "\n".join(
            (
                parity_proposal.proposal_marker(payload["handoffId"]),
                parity_proposal.artifact_marker(payload["handoffCommitSha"]),
            )
        )
        client = FakeGitHubClient(
            issues=[{"body": marker, "html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/issues/42"}]
        )
        proposal, tracker, drift = parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertEqual("", proposal)
        self.assertTrue(tracker.endswith("/issues/42"))
        self.assertFalse(drift)

    def test_recorded_proposal_url_wins_without_listing_or_writing(self):
        payload = baseline_payload()
        handoff = approved_handoff(payload)
        handoff["terraformPullRequestUrl"] = (
            "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/41"
        )
        url = handoff["terraformPullRequestUrl"]
        body = "\n".join(
            (
                parity_proposal.proposal_marker(payload["handoffId"]),
                parity_proposal.artifact_marker(payload["handoffCommitSha"]),
            )
        )
        client = FakeGitHubClient(pull_detail={"html_url": url, "body": body})
        proposal, tracker, drift = parity_proposal.find_existing(client, payload, handoff)
        self.assertTrue(proposal.endswith("/pull/41"))
        self.assertEqual("", tracker)
        self.assertFalse(drift)

    def test_recorded_proposal_url_must_carry_handoff_marker(self):
        payload = baseline_payload()
        handoff = approved_handoff(payload)
        url = "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/41"
        handoff["terraformPullRequestUrl"] = url
        client = FakeGitHubClient(
            pull_detail={
                "html_url": url,
                "body": parity_proposal.artifact_marker(payload["handoffCommitSha"]),
            }
        )
        with self.assertRaisesRegex(parity_proposal.ContractError, "missing the handoff marker"):
            parity_proposal.find_existing(client, payload, handoff)

    def test_changed_artifact_commit_reports_drift_once_and_opens_no_second_proposal(self):
        payload = baseline_payload()
        body = "\n".join(
            (
                parity_proposal.proposal_marker(payload["handoffId"]),
                parity_proposal.artifact_marker("9" * 40),
            )
        )
        url = "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/42"
        client = FakeGitHubClient(pulls=[{"body": body, "html_url": url}])
        proposal, tracker, drift = parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertEqual(url, proposal)
        self.assertEqual("", tracker)
        self.assertTrue(drift)
        self.assertEqual(1, len(client.posts))
        self.assertIn("artifact drift", client.posts[0][1]["body"].lower())

        drift_marker = f"<!-- parity-artifact-drift: {payload['handoffCommitSha']} -->"
        client = FakeGitHubClient(
            pulls=[{"body": body, "html_url": url}],
            comments=[{"body": drift_marker}],
        )
        parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertEqual([], client.posts)

    def test_complete_issue_payload_assigns_canonical_copilot_agent(self):
        payload = baseline_payload()
        issue = parity_proposal.build_issue(payload, approved_handoff(payload), CURRENT_HEAD_SHA)
        self.assertEqual(
            {"title", "body", "assignees", "agent_assignment"},
            set(issue),
        )
        self.assertEqual(["copilot-swe-agent[bot]"], issue["assignees"])
        self.assertEqual(
            {
                "target_repo": parity_proposal.TARGET_REPOSITORY,
                "base_branch": parity_proposal.TARGET_REF,
                "custom_agent": "parity-proposal",
                "custom_instructions": issue["agent_assignment"]["custom_instructions"],
            },
            issue["agent_assignment"],
        )

    def test_issue_propagates_dispatch_approved_digest(self):
        payload = baseline_payload()
        issue = parity_proposal.build_issue(payload, approved_handoff(payload), CURRENT_HEAD_SHA)
        marker = parity_proposal.digest_marker(payload["handoffDigest"])
        instructions = issue["agent_assignment"]["custom_instructions"]
        self.assertIn(marker, issue["body"])
        self.assertIn(marker, instructions)
        self.assertIn(payload["handoffDigest"], issue["body"])
        self.assertIn(payload["handoffDigest"], instructions)
        self.assertIn("normalize CRLF and CR line endings to LF", instructions)

    def test_issue_instructions_create_draft_only_boundary(self):
        payload = baseline_payload()
        issue = parity_proposal.build_issue(payload, approved_handoff(payload), CURRENT_HEAD_SHA)
        text = issue["body"] + issue["agent_assignment"]["custom_instructions"]
        self.assertIn("draft pull request", text)
        self.assertIn("do not merge", text.lower())
        self.assertIn("standalone-standard", text)
        self.assertIn("standalone-network-isolated", text)
        self.assertIn("hub-spoke", text)
        self.assertIn(parity_proposal.proposal_marker(payload["handoffId"]), text)
        self.assertIn(parity_proposal.artifact_marker(payload["handoffCommitSha"]), text)
        self.assertIn(parity_proposal.digest_marker(payload["handoffDigest"]), text)
        self.assertIn(parity_proposal.target_head_marker(CURRENT_HEAD_SHA), text)
        self.assertIn("Branch from current target `main` head", text)
        self.assertIn("PMNFR2", text)
        self.assertIn("direct Azure/azapi resources", text)
        self.assertIn("external non-AVM modules are prohibited", text)
        self.assertIn("avm pre-commit", text)
        self.assertIn("avm pr-check", text)
        self.assertIn("avm test unit", text)
        self.assertIn("avm test integration", text)
        self.assertIn("avm test e2e", text)
        self.assertIn("upstream managed AVM CI", text)
        self.assertIn("release/*", text)
        self.assertIn("status **blocked**", text)

    def test_outputs_report_blocked_merge_evidence(self):
        payload = baseline_payload()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            summary = Path(directory) / "summary"
            parity_proposal.write_outputs(
                str(output),
                str(summary),
                "",
                "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/issues/99",
                payload,
                False,
                False,
            )
            self.assertIn("evidence_status=blocked", output.read_text(encoding="utf-8"))
            self.assertIn(f"handoff_digest=sha256:{payload['handoffDigest']}", output.read_text(encoding="utf-8"))
            self.assertIn("Merge evidence status: `blocked`", summary.read_text(encoding="utf-8"))
            self.assertIn(f"sha256:{payload['handoffDigest']}", summary.read_text(encoding="utf-8"))


class WorkflowSecurityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = (ROOT / ".github" / "workflows" / "parity-proposal.yml").read_text(encoding="utf-8")
        cls.agent = (ROOT / ".github" / "agents" / "parity-proposal.agent.md").read_text(encoding="utf-8")

    def test_trigger_permissions_timeout_concurrency_and_action_pins(self):
        self.assertIn("repository_dispatch:", self.workflow)
        self.assertIn("- parity-proposal-requested", self.workflow)
        self.assertNotIn("pull_request:", self.workflow)
        self.assertIn("contents: read", self.workflow)
        self.assertIn("timeout-minutes: 10", self.workflow)
        self.assertIn("github.event.client_payload.handoffId", self.workflow)
        for line in self.workflow.splitlines():
            if "uses:" in line:
                reference = line.split("@", 1)[1].split()[0]
                self.assertRegex(reference, r"^[0-9a-f]{40}$")

    def test_workflow_has_no_secret_or_reverse_write(self):
        self.assertNotIn("secrets.", self.workflow)
        self.assertNotIn("contents: write", self.workflow)
        self.assertNotIn("id-token: write", self.workflow)

    def test_agent_has_explicit_evidence_and_operational_boundaries(self):
        for expected in (
            "Never merge, deploy, release",
            "hub-spoke",
            "standalone-standard",
            "standalone-network-isolated",
            "Do not claim functional parity",
            "No automatic reverse write",
        ):
            if expected == "No automatic reverse write":
                docs = (ROOT / "docs" / "parity-proposal.md").read_text(encoding="utf-8")
                self.assertIn(expected, docs)
            else:
                self.assertIn(expected, self.agent)

        docs = (ROOT / "docs" / "parity-proposal.md").read_text(encoding="utf-8")
        combined = (self.agent + docs).lower()
        for expected in (
            "PMNFR2",
            "direct `Azure/azapi` resources",
            "external non-AVM modules",
            "avm pre-commit",
            "avm pr-check",
            "upstream managed AVM CI",
            "release/*",
            "status `blocked`",
            "parity-handoff-digest",
            "copilot-swe-agent[bot]",
        ):
            self.assertIn(expected.lower(), combined)

    def test_workflow_reports_blocked_evidence_status(self):
        self.assertIn("steps.proposal.outputs.evidence_status", self.workflow)
        self.assertIn("steps.proposal.outputs.handoff_digest", self.workflow)
        self.assertIn("Merge evidence status:", self.workflow)


if __name__ == "__main__":
    unittest.main()
