import base64
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


def baseline_payload():
    return {
        "handoffId": "handoff-sample",
        "handoffPath": "parity/handoffs/ai-foundry/sample.json",
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

    def test_rejects_path_traversal_and_wrong_repository_or_branch(self):
        for field, value in (
            ("handoffPath", "parity/handoffs/../inventory.json"),
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
    def __init__(self, pulls=None, issues=None):
        self.pulls = pulls or []
        self.issues = issues or []
        self.posts = []

    def request(self, method, path, body=None):
        if method == "GET" and "/pulls?" in path:
            return self.pulls
        if method == "GET" and "/issues?" in path:
            return self.issues
        if method == "POST":
            self.posts.append(body)
            return {"html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/issues/99"}
        raise AssertionError((method, path))

    def get_paginated(self, path, page_size=100, maximum_pages=10):
        if "/pulls?" in path:
            return self.pulls
        if "/issues?" in path:
            return self.issues
        raise AssertionError(path)


class IdempotencyTests(unittest.TestCase):
    def test_duplicate_dispatch_returns_existing_proposal(self):
        payload = baseline_payload()
        marker = parity_proposal.proposal_marker(payload["handoffId"])
        client = FakeGitHubClient(
            pulls=[{"body": marker, "html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/42"}]
        )
        proposal, tracker = parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertTrue(proposal.endswith("/pull/42"))
        self.assertEqual("", tracker)
        self.assertEqual([], client.posts)

    def test_duplicate_dispatch_returns_existing_tracker(self):
        payload = baseline_payload()
        marker = parity_proposal.proposal_marker(payload["handoffId"])
        client = FakeGitHubClient(
            issues=[{"body": marker, "html_url": "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/issues/42"}]
        )
        proposal, tracker = parity_proposal.find_existing(client, payload, approved_handoff(payload))
        self.assertEqual("", proposal)
        self.assertTrue(tracker.endswith("/issues/42"))

    def test_recorded_proposal_url_wins_without_listing_or_writing(self):
        payload = baseline_payload()
        handoff = approved_handoff(payload)
        handoff["terraformPullRequestUrl"] = (
            "https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone/pull/41"
        )
        proposal, tracker = parity_proposal.find_existing(FakeGitHubClient(), payload, handoff)
        self.assertTrue(proposal.endswith("/pull/41"))
        self.assertEqual("", tracker)

    def test_issue_instructions_create_draft_only_boundary(self):
        payload = baseline_payload()
        issue = parity_proposal.build_issue(payload, approved_handoff(payload))
        text = issue["body"] + issue["agent_assignment"]["custom_instructions"]
        self.assertIn("draft pull request", text)
        self.assertIn("do not merge", text.lower())
        self.assertIn("standalone-standard", text)
        self.assertIn("standalone-network-isolated", text)
        self.assertIn("hub-spoke", text)
        self.assertIn(parity_proposal.proposal_marker(payload["handoffId"]), text)


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


if __name__ == "__main__":
    unittest.main()
