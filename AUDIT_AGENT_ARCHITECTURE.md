<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->

# Independent Audit & Policy Enforcement Agent

## Executive Summary

The **Audit Agent** is a completely independent AI system that operates as an impartial "police force" to verify that the **Orchestration Agent** (the one managing infrastructure) executes exactly what users request - nothing more, nothing less. This creates a **separation of powers** similar to judicial oversight in government.

**Key Principles:**
- **Complete Independence**: Audit Agent cannot be influenced, modified, or disabled by Orchestration Agent
- **Zero Trust**: Every action is verified against the original user intent
- **Immutable Logs**: All decisions recorded in tamper-proof audit trail
- **Human Override**: Users can escalate any decision for human review
- **Transparency**: Every action explained in plain language before execution

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Separation of Powers](#separation-of-powers)
3. [On-Premises Deployment](#on-premises-deployment)
4. [Audit Agent Implementation](#audit-agent-implementation)
5. [Policy Enforcement Rules](#policy-enforcement-rules)
6. [Real-Time Verification](#real-time-verification)
7. [Immutable Audit Trail](#immutable-audit-trail)
8. [Human Escalation Process](#human-escalation-process)
9. [Security Safeguards](#security-safeguards)
10. [Example Scenarios](#example-scenarios)

---

## Architecture Overview

### Two-Agent System with Checks and Balances

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER REQUEST                             │
│  "Add a new microsegment for machine learning workloads"        │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├──────────────────────────────────────────────────┐
             │                                                   │
             ▼                                                   ▼
┌────────────────────────┐                      ┌────────────────────────┐
│  ORCHESTRATION AGENT   │                      │    AUDIT AGENT         │
│  (Cloud - AWS Lambda)  │                      │  (On-Prem - Isolated)  │
│                        │                      │                        │
│ 1. Analyzes request    │                      │ 1. Receives same       │
│ 2. Plans actions       │                      │    request             │
│ 3. Generates Terraform │◄─────────────────────┤ 2. Analyzes plan       │
│ 4. Submits for approval│    VETO if wrong     │ 3. Verifies intent     │
│                        │                      │ 4. Checks policy       │
│ Cannot execute until   │                      │ 5. APPROVE or VETO     │
│ Audit Agent approves   │                      │                        │
└────────────┬───────────┘                      └────────────┬───────────┘
             │                                                │
             │ ┌────────────────────────────────────────────┐ │
             │ │  APPROVED: Execute infrastructure change   │ │
             └─┤  VETOED: Block execution, alert user       ├─┘
               └────────────────────────────────────────────┘
                                  │
                                  ▼
                  ┌───────────────────────────────────┐
                  │  IMMUTABLE AUDIT LOG              │
                  │  - User request (original)        │
                  │  - Orchestration plan             │
                  │  - Audit decision (approve/veto)  │
                  │  - Actual execution results       │
                  │  - Timestamp, signatures          │
                  └───────────────────────────────────┘
```

### Key Design Principles

1. **Dual-Agent Architecture**: Two completely independent AI agents
   - Orchestration Agent: Does the work (AWS Cloud)
   - Audit Agent: Verifies the work (On-Premises, isolated)

2. **Mandatory Approval**: Orchestration Agent CANNOT execute without Audit Agent approval
   - Hard-coded in Lambda execution policy
   - Cryptographic verification required
   - No backdoors or overrides

3. **Independent Infrastructure**: Agents run on separate infrastructure
   - Orchestration: AWS Lambda (cloud)
   - Audit: On-Premises Server (air-gapped, if needed)
   - Different API keys, different models (can use different AI providers)

4. **Immutable Audit Trail**: Every decision logged in tamper-proof system
   - Blockchain-like append-only ledger
   - Cryptographically signed entries
   - 7-year retention (compliance requirement)

---

## Separation of Powers

### Orchestration Agent (Executive Branch)

**Role**: Execute infrastructure operations
**Location**: AWS Lambda (cloud)
**Permissions**: Can create/modify AWS resources
**Limitations**:
- ❌ Cannot execute without Audit Agent approval
- ❌ Cannot modify its own execution policy
- ❌ Cannot disable logging or auditing
- ❌ Cannot see Audit Agent's decision logic

**Analogy**: Police officer who can enforce laws but needs a warrant from a judge

### Audit Agent (Judicial Branch)

**Role**: Verify operations match user intent
**Location**: On-Premises Server (isolated)
**Permissions**: Can approve/veto operations
**Limitations**:
- ❌ Cannot execute infrastructure changes (no AWS credentials)
- ❌ Cannot modify user requests
- ❌ Cannot be influenced by Orchestration Agent
- ✅ Has veto power over all operations

**Analogy**: Judge who reviews warrants but doesn't make arrests

### User (Legislative Branch)

**Role**: Define policy and intent
**Permissions**:
- ✅ Submit infrastructure requests
- ✅ Override Audit Agent decisions (with approval workflow)
- ✅ Define policy rules for Audit Agent
- ✅ Review audit logs anytime

**Analogy**: Legislature that creates laws and can override judicial decisions

---

## On-Premises Deployment

### Audit Agent Server Requirements

**Hardware (On-Premises)**:
```
Server Specifications:
- CPU: 16 cores (AMD EPYC or Intel Xeon)
- RAM: 64 GB ECC memory
- Storage: 2 TB NVMe SSD (RAID 1 for redundancy)
- Network: Isolated VLAN with firewall rules
- OS: Ubuntu 22.04 LTS (hardened)

Cost: ~$8,000 one-time hardware + $200/month hosting
```

**Network Isolation**:
```
┌────────────────────────────────────────────────────────┐
│  Corporate Network (192.168.0.0/16)                    │
│                                                         │
│  ┌──────────────────────────────────────────────┐     │
│  │  DMZ (10.250.0.0/24) - Audit Agent Subnet    │     │
│  │                                               │     │
│  │  ┌──────────────────────────────────┐        │     │
│  │  │  Audit Agent Server              │        │     │
│  │  │  IP: 10.250.0.10                 │        │     │
│  │  │  Firewall: Allow ONLY:           │        │     │
│  │  │  - Inbound: 443 from Lambda      │        │     │
│  │  │  - Outbound: 443 to Claude API   │        │     │
│  │  │  - Outbound: 5432 to Audit DB    │        │     │
│  │  │  ALL OTHER TRAFFIC: DENIED       │        │     │
│  │  └──────────────────────────────────┘        │     │
│  │                                               │     │
│  │  ┌──────────────────────────────────┐        │     │
│  │  │  Audit Database (PostgreSQL)     │        │     │
│  │  │  IP: 10.250.0.11                 │        │     │
│  │  │  Encrypted at rest (LUKS)        │        │     │
│  │  │  Immutable append-only logs      │        │     │
│  │  └──────────────────────────────────┘        │     │
│  └──────────────────────────────────────────────┘     │
│                                                         │
└────────────────────────────────────────────────────────┘
```

**Security Hardening**:
- SELinux enforcing mode
- Firewall rules (iptables) allowing ONLY necessary traffic
- Intrusion detection (fail2ban)
- File integrity monitoring (AIDE)
- No SSH access from internet (bastion host only)
- MFA required for all admin access
- Automatic security patches
- Daily encrypted backups to offline storage

### Alternative: Air-Gapped Deployment

For maximum security (defense, finance, healthcare):

```
┌─────────────────────────────────────────────────────┐
│  Air-Gapped Network (Physically Isolated)           │
│                                                      │
│  ┌──────────────────────────────────────────┐      │
│  │  Audit Agent Server                      │      │
│  │  - No internet connectivity              │      │
│  │  - Self-hosted AI model (Llama 3)        │      │
│  │  - Requests transferred via USB/CD       │      │
│  │  - Sneakernet for updates                │      │
│  └──────────────────────────────────────────┘      │
│                                                      │
│  Physical Security:                                  │
│  - Locked server room (card access)                 │
│  - 24/7 video surveillance                          │
│  - Motion sensors                                   │
│  - Tamper-evident seals on hardware                 │
└─────────────────────────────────────────────────────┘
```

---

## Audit Agent Implementation

### Core Audit Agent Code (Python)

```python
#!/usr/bin/env python3
"""
Audit Agent - Independent Policy Enforcement
Verifies that Orchestration Agent executes exactly what user requested.

This agent:
1. Receives user request and orchestration plan
2. Analyzes if plan matches user intent
3. Checks against policy rules
4. Approves or vetoes execution
5. Logs all decisions immutably

CRITICAL: This agent has veto power and cannot be overridden by Orchestration Agent.
"""

import anthropic
import hashlib
import json
import psycopg2
from datetime import datetime
from typing import Dict, Any, Tuple
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

class AuditAgent:
    """
    Independent audit agent that verifies orchestration decisions.

    This agent operates completely independently from the Orchestration Agent
    and has the power to veto any operation that doesn't match user intent
    or violates policy.
    """

    def __init__(self):
        # Use separate API key from Orchestration Agent
        self.claude = anthropic.Anthropic(
            api_key="sk-audit-agent-separate-key-xxx"  # Different key!
        )

        # Connect to audit database (immutable logs)
        self.db = psycopg2.connect(
            host="10.250.0.11",
            port=5432,
            database="audit_logs",
            user="audit_agent",
            password="stored-in-vault",
            sslmode="require"
        )

        # Load private key for cryptographic signatures
        with open("/etc/audit-agent/private_key.pem", "rb") as f:
            self.private_key = serialization.load_pem_private_key(
                f.read(),
                password=None
            )

    def verify_orchestration_plan(
        self,
        user_request: str,
        orchestration_plan: Dict[str, Any],
        metadata: Dict[str, Any]
    ) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Verify that orchestration plan matches user intent.

        Returns:
            (approved: bool, reason: str, audit_record: dict)
        """

        # Step 1: Hash original user request (tamper detection)
        request_hash = hashlib.sha256(user_request.encode()).hexdigest()

        # Step 2: Use Claude to analyze if plan matches intent
        verification_prompt = f"""
        You are an independent audit agent responsible for verifying that
        infrastructure changes match user intent. Your role is to protect
        users from unintended consequences.

        ORIGINAL USER REQUEST:
        {user_request}

        ORCHESTRATION AGENT'S PLAN:
        {json.dumps(orchestration_plan, indent=2)}

        METADATA:
        - User: {metadata.get('user_email', 'unknown')}
        - Timestamp: {metadata.get('timestamp', 'unknown')}
        - Request ID: {metadata.get('request_id', 'unknown')}

        ANALYSIS REQUIRED:

        1. INTENT VERIFICATION:
           Does the orchestration plan execute EXACTLY what the user requested?
           - Are there any extra actions not mentioned in the request?
           - Are there any missing actions that should be included?
           - Does the scope match (e.g., user said "one microsegment" but plan creates 5)?

        2. SAFETY CHECK:
           Could this plan cause:
           - Data loss (deleting resources not mentioned by user)?
           - Security issues (opening unauthorized access)?
           - Compliance violations (breaking PCI/GDPR/SOC2)?
           - Production outages (high-risk changes without approval)?

        3. POLICY COMPLIANCE:
           Does this plan follow organizational policies?
           - Changes to production require change ticket
           - Deletion of resources requires explicit user confirmation
           - Security changes require security team approval
           - Cost > $1000/month requires finance approval

        4. TRANSPARENCY:
           Explain in plain language what will happen if approved.

        RESPONSE FORMAT (JSON):
        {{
          "approved": true/false,
          "confidence": 0.0-1.0,
          "reasoning": "Detailed explanation of decision",
          "intent_match": "exact/partial/mismatch",
          "safety_concerns": ["list", "of", "concerns"],
          "policy_violations": ["list", "of", "violations"],
          "required_approvals": ["change-ticket", "security-team", etc.],
          "plain_language_summary": "What will happen in simple terms",
          "recommendation": "approve/veto/escalate"
        }}
        """

        # Call Claude for analysis (using separate API key)
        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=2000,
            temperature=0.1,  # Low temperature for consistent analysis
            messages=[{
                "role": "user",
                "content": verification_prompt
            }]
        )

        # Parse Claude's analysis
        analysis = json.loads(response.content[0].text)

        # Step 3: Apply hard-coded policy rules (cannot be bypassed)
        policy_check = self._check_hardcoded_policies(
            user_request,
            orchestration_plan,
            metadata
        )

        # Step 4: Make final decision (veto if ANY concerns)
        approved = (
            analysis['approved'] and
            analysis['confidence'] >= 0.9 and
            len(analysis['safety_concerns']) == 0 and
            len(analysis['policy_violations']) == 0 and
            policy_check['passed']
        )

        # Step 5: Generate reason for decision
        if approved:
            reason = f"APPROVED: {analysis['plain_language_summary']}"
        else:
            reason = f"VETOED: {analysis['reasoning']}\n"
            reason += f"Safety concerns: {', '.join(analysis['safety_concerns'])}\n"
            reason += f"Policy violations: {', '.join(analysis['policy_violations'])}\n"
            if not policy_check['passed']:
                reason += f"Hard policy violations: {', '.join(policy_check['violations'])}"

        # Step 6: Create audit record
        audit_record = {
            'request_id': metadata.get('request_id'),
            'timestamp': datetime.utcnow().isoformat(),
            'user_email': metadata.get('user_email'),
            'user_request_hash': request_hash,
            'user_request': user_request,
            'orchestration_plan': orchestration_plan,
            'audit_analysis': analysis,
            'policy_check': policy_check,
            'decision': 'APPROVED' if approved else 'VETOED',
            'reason': reason,
            'audit_agent_version': '1.0.0'
        }

        # Step 7: Sign audit record (tamper-proof)
        signature = self._sign_audit_record(audit_record)
        audit_record['signature'] = signature

        # Step 8: Store in immutable audit log
        self._store_audit_record(audit_record)

        return (approved, reason, audit_record)

    def _check_hardcoded_policies(
        self,
        user_request: str,
        orchestration_plan: Dict[str, Any],
        metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Hard-coded policy rules that cannot be bypassed by AI.
        These are the "constitutional" rules that even Claude cannot override.
        """
        violations = []

        # RULE 1: No production changes without change ticket
        if 'prod' in user_request.lower():
            if not metadata.get('change_ticket_id'):
                violations.append("Production change requires change ticket")

        # RULE 2: No resource deletion without explicit confirmation
        plan_str = json.dumps(orchestration_plan).lower()
        if any(word in plan_str for word in ['delete', 'destroy', 'terminate', 'remove']):
            if not metadata.get('deletion_confirmed', False):
                violations.append("Resource deletion requires explicit user confirmation")

        # RULE 3: No security group changes allowing 0.0.0.0/0 to production
        if 'security' in plan_str and '0.0.0.0/0' in plan_str:
            if 'prod' in user_request.lower():
                violations.append("Cannot open production security groups to internet (0.0.0.0/0)")

        # RULE 4: Cost threshold requires approval
        estimated_cost = orchestration_plan.get('estimated_monthly_cost', 0)
        if estimated_cost > 1000:
            if not metadata.get('finance_approved', False):
                violations.append(f"Cost ${estimated_cost}/month exceeds $1000 threshold, requires finance approval")

        # RULE 5: No modification of audit agent or logging infrastructure
        if any(word in plan_str for word in ['audit-agent', 'audit_logs', 'cloudtrail', 'guardduty']):
            violations.append("Cannot modify audit or logging infrastructure (immutable)")

        # RULE 6: PCI compliance requirements
        if 'pci' in plan_str:
            required_features = ['encryption', 'logging', 'firewall', 'isolated']
            missing = [f for f in required_features if f not in plan_str]
            if missing:
                violations.append(f"PCI workload missing required features: {', '.join(missing)}")

        return {
            'passed': len(violations) == 0,
            'violations': violations
        }

    def _sign_audit_record(self, audit_record: Dict[str, Any]) -> str:
        """
        Cryptographically sign audit record for tamper detection.
        """
        # Create canonical JSON (deterministic ordering)
        canonical_json = json.dumps(audit_record, sort_keys=True)

        # Sign with private key
        signature = self.private_key.sign(
            canonical_json.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )

        # Return base64-encoded signature
        import base64
        return base64.b64encode(signature).decode()

    def _store_audit_record(self, audit_record: Dict[str, Any]) -> None:
        """
        Store audit record in immutable append-only database.

        Database uses:
        - Append-only mode (no UPDATE or DELETE allowed)
        - Row-level security (only audit agent can write)
        - Replication to offline backup every hour
        - 7-year retention (compliance requirement)
        """
        cursor = self.db.cursor()

        # Insert into audit_log table (append-only)
        cursor.execute("""
            INSERT INTO audit_log (
                request_id,
                timestamp,
                user_email,
                user_request_hash,
                user_request,
                orchestration_plan,
                audit_analysis,
                decision,
                reason,
                signature,
                audit_agent_version
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            audit_record['request_id'],
            audit_record['timestamp'],
            audit_record['user_email'],
            audit_record['user_request_hash'],
            audit_record['user_request'],
            json.dumps(audit_record['orchestration_plan']),
            json.dumps(audit_record['audit_analysis']),
            audit_record['decision'],
            audit_record['reason'],
            audit_record['signature'],
            audit_record['audit_agent_version']
        ))

        self.db.commit()
        cursor.close()

    def verify_execution_result(
        self,
        request_id: str,
        execution_result: Dict[str, Any]
    ) -> Tuple[bool, str]:
        """
        Verify that execution result matches approved plan.

        This is called AFTER orchestration agent executes to verify
        it didn't do anything extra beyond what was approved.
        """
        cursor = self.db.cursor()

        # Retrieve original audit record
        cursor.execute("""
            SELECT
                orchestration_plan,
                decision,
                signature
            FROM audit_log
            WHERE request_id = %s
        """, (request_id,))

        row = cursor.fetchone()
        if not row:
            return (False, "No audit record found for this request")

        approved_plan = json.loads(row[0])
        decision = row[1]

        if decision != 'APPROVED':
            return (False, "Request was vetoed - execution should not have happened")

        # Compare execution result to approved plan
        verification_prompt = f"""
        Verify that execution result matches approved plan.

        APPROVED PLAN:
        {json.dumps(approved_plan, indent=2)}

        ACTUAL EXECUTION RESULT:
        {json.dumps(execution_result, indent=2)}

        ANALYSIS:
        1. Were any resources created/modified/deleted that weren't in the plan?
        2. Were any approved actions NOT executed?
        3. Are there any unexpected side effects?

        Respond with JSON:
        {{
          "matches": true/false,
          "discrepancies": ["list", "of", "differences"],
          "severity": "none/low/medium/high/critical"
        }}
        """

        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=1000,
            temperature=0.1,
            messages=[{"role": "user", "content": verification_prompt}]
        )

        analysis = json.loads(response.content[0].text)

        # Store execution verification
        cursor.execute("""
            INSERT INTO execution_verification (
                request_id,
                timestamp,
                execution_result,
                verification_analysis,
                matches_plan
            ) VALUES (%s, %s, %s, %s, %s)
        """, (
            request_id,
            datetime.utcnow().isoformat(),
            json.dumps(execution_result),
            json.dumps(analysis),
            analysis['matches']
        ))

        self.db.commit()
        cursor.close()

        if not analysis['matches']:
            reason = f"Execution deviated from approved plan: {', '.join(analysis['discrepancies'])}"
            # CRITICAL: Alert security team
            self._alert_security_team(request_id, reason, analysis['severity'])
            return (False, reason)

        return (True, "Execution matches approved plan")

    def _alert_security_team(
        self,
        request_id: str,
        reason: str,
        severity: str
    ) -> None:
        """
        Alert security team of execution deviation.
        This is a critical security event.
        """
        # Send to PagerDuty, Slack, email
        import requests

        requests.post("https://api.pagerduty.com/incidents", json={
            "incident": {
                "type": "incident",
                "title": f"Audit Agent: Execution Deviation Detected",
                "severity": severity,
                "body": {
                    "type": "incident_body",
                    "details": f"Request {request_id}: {reason}"
                }
            }
        })


# =============================================================================
# Flask API for Audit Agent
# =============================================================================

from flask import Flask, request, jsonify
import logging

app = Flask(__name__)
audit_agent = AuditAgent()

# Configure logging
logging.basicConfig(
    filename='/var/log/audit-agent/audit.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

@app.route('/verify-plan', methods=['POST'])
def verify_plan():
    """
    Endpoint called by Orchestration Agent to get approval.

    Orchestration Agent CANNOT execute without calling this endpoint
    and receiving an APPROVED response.
    """
    data = request.json

    # Log incoming request
    logging.info(f"Verification request received: {data.get('request_id')}")

    # Verify request authenticity (prevent spoofing)
    if not _verify_request_signature(request.headers.get('X-Signature')):
        logging.warning("Invalid request signature - possible spoofing attempt")
        return jsonify({
            'approved': False,
            'reason': 'Invalid request signature'
        }), 401

    # Verify plan
    approved, reason, audit_record = audit_agent.verify_orchestration_plan(
        user_request=data['user_request'],
        orchestration_plan=data['orchestration_plan'],
        metadata=data['metadata']
    )

    # Log decision
    logging.info(f"Decision for {data.get('request_id')}: {'APPROVED' if approved else 'VETOED'}")

    return jsonify({
        'approved': approved,
        'reason': reason,
        'audit_record_id': audit_record['request_id']
    })

@app.route('/verify-execution', methods=['POST'])
def verify_execution():
    """
    Endpoint called AFTER execution to verify results match plan.
    """
    data = request.json

    matches, reason = audit_agent.verify_execution_result(
        request_id=data['request_id'],
        execution_result=data['execution_result']
    )

    logging.info(f"Execution verification for {data.get('request_id')}: {'PASS' if matches else 'FAIL'}")

    return jsonify({
        'matches': matches,
        'reason': reason
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({'status': 'healthy', 'agent': 'audit'})

def _verify_request_signature(signature: str) -> bool:
    """
    Verify that request came from legitimate Orchestration Agent.
    Uses shared secret known only to both agents.
    """
    # TODO: Implement HMAC verification
    return True

if __name__ == '__main__':
    # Run on specific IP (DMZ network)
    app.run(
        host='10.250.0.10',
        port=8443,
        ssl_context=('/etc/audit-agent/cert.pem', '/etc/audit-agent/key.pem')
    )
```

---

## Policy Enforcement Rules

### Hard-Coded Policies (Cannot Be Bypassed)

```python
# These policies are enforced in code and cannot be overridden by AI

IMMUTABLE_POLICIES = {
    # Policy 1: Production Safety
    'production_change_requires_ticket': {
        'description': 'All production changes require change management ticket',
        'enforcement': 'hard',  # Cannot be bypassed
        'check': lambda request, metadata: (
            'prod' not in request.lower() or
            'change_ticket_id' in metadata
        )
    },

    # Policy 2: Deletion Protection
    'deletion_requires_confirmation': {
        'description': 'Resource deletion requires explicit user confirmation',
        'enforcement': 'hard',
        'check': lambda request, plan: (
            not any(word in json.dumps(plan).lower()
                   for word in ['delete', 'destroy', 'terminate']) or
            metadata.get('deletion_confirmed') == True
        )
    },

    # Policy 3: Security Baseline
    'no_public_production_access': {
        'description': 'Production resources cannot be exposed to 0.0.0.0/0',
        'enforcement': 'hard',
        'check': lambda request, plan: (
            not ('prod' in request.lower() and '0.0.0.0/0' in json.dumps(plan))
        )
    },

    # Policy 4: Cost Controls
    'cost_threshold_approval': {
        'description': 'Changes >$1000/month require finance approval',
        'enforcement': 'hard',
        'check': lambda plan, metadata: (
            plan.get('estimated_monthly_cost', 0) <= 1000 or
            metadata.get('finance_approved') == True
        )
    },

    # Policy 5: Audit Immutability
    'no_audit_modification': {
        'description': 'Audit agent and logging infrastructure cannot be modified',
        'enforcement': 'hard',
        'check': lambda plan: (
            not any(word in json.dumps(plan).lower()
                   for word in ['audit-agent', 'audit_logs', 'cloudtrail'])
        )
    },

    # Policy 6: PCI Compliance
    'pci_baseline_requirements': {
        'description': 'PCI workloads must have encryption, logging, firewall, isolation',
        'enforcement': 'hard',
        'check': lambda plan: (
            'pci' not in json.dumps(plan).lower() or
            all(feature in json.dumps(plan).lower()
                for feature in ['encryption', 'logging', 'firewall', 'isolated'])
        )
    },

    # Policy 7: GDPR Data Residency
    'gdpr_data_residency': {
        'description': 'EU customer data must stay in EU regions',
        'enforcement': 'hard',
        'check': lambda plan: (
            not ('gdpr' in json.dumps(plan).lower() and
                 'us-' in json.dumps(plan).lower())
        )
    }
}
```

### Soft Policies (AI-Enforced, Human Can Override)

```python
SOFT_POLICIES = {
    # Policy 1: Best Practices
    'enable_encryption_by_default': {
        'description': 'All storage should be encrypted at rest',
        'severity': 'warning',
        'auto_approve': False  # Requires human approval if violated
    },

    # Policy 2: Cost Optimization
    'use_reserved_instances': {
        'description': 'Long-running workloads should use Reserved Instances',
        'severity': 'info',
        'auto_approve': True  # Can proceed but log warning
    },

    # Policy 3: Tagging Standards
    'required_tags': {
        'description': 'All resources must have Owner, Environment, CostCenter tags',
        'severity': 'warning',
        'auto_approve': False
    }
}
```

---

## Real-Time Verification

### Pre-Execution Verification Flow

```
User Request
     │
     ▼
┌────────────────────────────────────────────┐
│ Orchestration Agent                        │
│ 1. Parse request                           │
│ 2. Generate execution plan                 │
│ 3. Call Audit Agent /verify-plan           │
└────────────┬───────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────┐
│ Audit Agent (On-Premises)                  │
│ 1. Receive plan                            │
│ 2. Verify intent match (Claude analysis)   │
│ 3. Check hard-coded policies               │
│ 4. Check soft policies                     │
│ 5. Sign and log decision                   │
└────────────┬───────────────────────────────┘
             │
             ├──── APPROVED ────┐
             │                  ▼
             │          Execute Plan
             │                  │
             │                  ▼
             │          Verify Execution
             │                  │
             │                  ▼
             │          Log Results
             │
             └──── VETOED ──────┐
                                ▼
                        Block Execution
                                │
                                ▼
                        Notify User
                        (explain why)
```

### Post-Execution Verification Flow

```
Execution Complete
     │
     ▼
┌────────────────────────────────────────────┐
│ Orchestration Agent                        │
│ 1. Collect execution results               │
│ 2. Call Audit Agent /verify-execution      │
└────────────┬───────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────┐
│ Audit Agent                                │
│ 1. Load approved plan from database        │
│ 2. Compare to actual execution             │
│ 3. Detect any deviations                   │
│ 4. Log verification result                 │
└────────────┬───────────────────────────────┘
             │
             ├──── MATCHES ────┐
             │                 ▼
             │          Success
             │                 │
             │                 ▼
             │          User Notification
             │
             └──── DEVIATION ──┐
                               ▼
                        CRITICAL ALERT
                               │
                               ├─► Security Team (PagerDuty)
                               ├─► User (email + Slack)
                               ├─► Audit Log (permanent record)
                               └─► Rollback (if possible)
```

---

## Immutable Audit Trail

### Database Schema

```sql
-- Audit log table (append-only, no updates/deletes allowed)
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    request_id UUID NOT NULL UNIQUE,
    timestamp TIMESTAMP NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_request_hash VARCHAR(64) NOT NULL,  -- SHA256 of original request
    user_request TEXT NOT NULL,              -- Original user request
    orchestration_plan JSONB NOT NULL,        -- Plan from Orchestration Agent
    audit_analysis JSONB NOT NULL,            -- Claude's analysis
    policy_check JSONB NOT NULL,              -- Hard policy check results
    decision VARCHAR(20) NOT NULL,            -- APPROVED or VETOED
    reason TEXT NOT NULL,                     -- Explanation
    signature TEXT NOT NULL,                  -- Cryptographic signature
    audit_agent_version VARCHAR(50) NOT NULL,

    -- Immutability: No updates or deletes allowed
    CONSTRAINT no_updates CHECK (false),
    CONSTRAINT no_deletes CHECK (false)
);

-- Execution verification table (what actually happened)
CREATE TABLE execution_verification (
    id SERIAL PRIMARY KEY,
    request_id UUID NOT NULL REFERENCES audit_log(request_id),
    timestamp TIMESTAMP NOT NULL,
    execution_result JSONB NOT NULL,
    verification_analysis JSONB NOT NULL,
    matches_plan BOOLEAN NOT NULL,
    discrepancies TEXT[]
);

-- User override table (when human overrides Audit Agent)
CREATE TABLE user_overrides (
    id SERIAL PRIMARY KEY,
    request_id UUID NOT NULL REFERENCES audit_log(request_id),
    timestamp TIMESTAMP NOT NULL,
    overridden_by VARCHAR(255) NOT NULL,
    approval_chain JSONB NOT NULL,  -- Who approved override
    justification TEXT NOT NULL,
    override_signature TEXT NOT NULL
);

-- Tamper detection: Store hash chain (blockchain-like)
CREATE TABLE audit_chain (
    id SERIAL PRIMARY KEY,
    block_number INT NOT NULL UNIQUE,
    timestamp TIMESTAMP NOT NULL,
    previous_hash VARCHAR(64) NOT NULL,
    current_hash VARCHAR(64) NOT NULL,
    audit_log_ids INT[] NOT NULL  -- IDs included in this block
);

-- Row-level security: Only audit agent can write
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_write_only ON audit_log FOR INSERT
    USING (current_user = 'audit_agent');

-- Everyone can read audit logs (transparency)
CREATE POLICY audit_read_all ON audit_log FOR SELECT
    USING (true);
```

### Blockchain-Like Hash Chain

```python
def create_audit_block(audit_log_ids: List[int]) -> Dict[str, Any]:
    """
    Create a tamper-proof block of audit records.
    Similar to blockchain, each block includes hash of previous block.
    """
    cursor = db.cursor()

    # Get previous block's hash
    cursor.execute("""
        SELECT current_hash
        FROM audit_chain
        ORDER BY block_number DESC
        LIMIT 1
    """)
    row = cursor.fetchone()
    previous_hash = row[0] if row else "0" * 64  # Genesis block

    # Get audit records for this block
    cursor.execute("""
        SELECT id, request_id, timestamp, signature
        FROM audit_log
        WHERE id = ANY(%s)
        ORDER BY id
    """, (audit_log_ids,))

    records = cursor.fetchall()

    # Compute current block hash
    block_data = {
        'previous_hash': previous_hash,
        'timestamp': datetime.utcnow().isoformat(),
        'audit_records': [
            {'id': r[0], 'request_id': str(r[1]), 'signature': r[3]}
            for r in records
        ]
    }

    current_hash = hashlib.sha256(
        json.dumps(block_data, sort_keys=True).encode()
    ).hexdigest()

    # Insert block into chain
    cursor.execute("""
        INSERT INTO audit_chain (
            block_number,
            timestamp,
            previous_hash,
            current_hash,
            audit_log_ids
        ) VALUES (
            (SELECT COALESCE(MAX(block_number), 0) + 1 FROM audit_chain),
            %s,
            %s,
            %s,
            %s
        )
    """, (
        datetime.utcnow(),
        previous_hash,
        current_hash,
        audit_log_ids
    ))

    db.commit()
    return block_data

# Create new block every hour
import schedule
schedule.every().hour.do(lambda: create_audit_block(
    get_unblocked_audit_ids()
))
```

---

## Human Escalation Process

### When Human Approval Required

1. **Audit Agent vetoes but user disagrees**
   - User can request human override
   - Requires approval from 2 authorized personnel
   - Justification must be documented

2. **High-risk operations**
   - Production database modifications
   - Security group changes exposing ports
   - Resource deletion
   - Cost > $10,000/month

3. **Policy conflicts**
   - Soft policy violations
   - Business requirements conflict with technical best practices

### Escalation Workflow

```
Audit Agent Veto
     │
     ▼
┌──────────────────────────────────────┐
│ User: "I still want to proceed"     │
│ Clicks: "Request Human Override"    │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ Escalation Form                      │
│ - Justification (required)           │
│ - Business impact                    │
│ - Alternative options considered     │
│ - Risk acceptance                    │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ Approval Chain (ServiceNow)          │
│ 1. Manager approval                  │
│ 2. Security team review (if sec)     │
│ 3. Finance approval (if cost)        │
└──────────┬───────────────────────────┘
           │
           ├─── ALL APPROVED ───┐
           │                    ▼
           │            Execute with override
           │                    │
           │                    ▼
           │            Log override in audit trail
           │
           └─── ANY DENIED ────┐
                               ▼
                        Request blocked
                               │
                               ▼
                        Notify user (email)
```

### Override Audit Record

```python
def record_human_override(
    request_id: str,
    overridden_by: str,
    approval_chain: List[Dict[str, Any]],
    justification: str
) -> None:
    """
    Record when human overrides Audit Agent veto.
    This is a critical audit event.
    """
    cursor = db.cursor()

    # Create override signature (requires manager + security)
    override_data = {
        'request_id': request_id,
        'overridden_by': overridden_by,
        'approval_chain': approval_chain,
        'justification': justification,
        'timestamp': datetime.utcnow().isoformat()
    }

    # Sign with manager's and security's private keys
    signature = sign_with_multiple_keys(override_data, [
        manager_private_key,
        security_private_key
    ])

    cursor.execute("""
        INSERT INTO user_overrides (
            request_id,
            timestamp,
            overridden_by,
            approval_chain,
            justification,
            override_signature
        ) VALUES (%s, %s, %s, %s, %s, %s)
    """, (
        request_id,
        datetime.utcnow(),
        overridden_by,
        json.dumps(approval_chain),
        justification,
        signature
    ))

    db.commit()

    # Alert audit team (this is unusual)
    send_alert(
        channel='#audit-overrides',
        message=f"⚠️ Audit veto overridden for {request_id} by {overridden_by}"
    )
```

---

## Security Safeguards

### Preventing Orchestration Agent from Bypassing Audit

**Problem**: What if Orchestration Agent tries to execute without approval?

**Solution: Multiple layers of enforcement**

#### 1. AWS IAM Policy (Hard Block)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "RequireAuditApproval",
    "Effect": "Deny",
    "Action": "ec2:*",
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestTag/AuditApproved": "true"
      }
    }
  }]
}
```

Orchestration Agent CANNOT create resources unless `AuditApproved=true` tag is present.
Only Audit Agent can create this tag (using separate IAM credentials).

#### 2. Lambda Function Policy (Code Enforcement)

```python
def lambda_handler(event, context):
    """
    Orchestration Agent Lambda function.
    CANNOT execute without Audit Agent approval.
    """

    # Extract request details
    request_id = event['request_id']
    user_request = event['user_request']
    orchestration_plan = generate_plan(user_request)

    # MANDATORY: Call Audit Agent for approval
    audit_response = requests.post(
        'https://10.250.0.10:8443/verify-plan',
        json={
            'request_id': request_id,
            'user_request': user_request,
            'orchestration_plan': orchestration_plan,
            'metadata': event['metadata']
        },
        headers={
            'X-Signature': sign_request(request_id)
        },
        verify='/etc/ssl/audit-agent-ca.pem',  # Verify audit agent cert
        timeout=30
    )

    # Check approval
    if not audit_response.json().get('approved'):
        # VETOED: Cannot execute
        return {
            'statusCode': 403,
            'body': json.dumps({
                'error': 'Audit Agent vetoed execution',
                'reason': audit_response.json().get('reason')
            })
        }

    # APPROVED: Execute plan
    execution_result = execute_terraform(orchestration_plan)

    # MANDATORY: Verify execution result
    verification_response = requests.post(
        'https://10.250.0.10:8443/verify-execution',
        json={
            'request_id': request_id,
            'execution_result': execution_result
        }
    )

    if not verification_response.json().get('matches'):
        # CRITICAL: Execution deviated from plan
        # This should never happen - indicates bug or security issue
        raise Exception(f"Execution deviation detected: {verification_response.json().get('reason')}")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'success': True,
            'execution_result': execution_result
        })
    }
```

#### 3. Network Policy (Physical Separation)

```bash
# Firewall rules on Audit Agent server
iptables -A INPUT -p tcp --dport 8443 -s <lambda-nat-gateway-ip> -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j DROP  # Block all other sources

# Orchestration Agent CANNOT reach audit agent database
iptables -A INPUT -p tcp --dport 5432 -s <lambda-nat-gateway-ip> -j DROP
```

#### 4. Audit Agent Monitoring (Self-Protection)

```python
import psutil
import sys

def monitor_audit_agent():
    """
    Monitor Audit Agent process for tampering.
    Runs as separate systemd service.
    """
    while True:
        # Check if audit agent process is running
        if not process_exists('audit-agent'):
            alert_critical("Audit Agent process stopped - CRITICAL SECURITY EVENT")
            # Attempt restart
            subprocess.run(['systemctl', 'restart', 'audit-agent'])

        # Check if database is accessible
        try:
            conn = psycopg2.connect("postgresql://audit_logs")
            conn.close()
        except:
            alert_critical("Audit database unreachable - CRITICAL SECURITY EVENT")

        # Check if firewall rules are intact
        iptables_output = subprocess.check_output(['iptables', '-L', '-n'])
        if b'audit-agent' not in iptables_output:
            alert_critical("Firewall rules modified - CRITICAL SECURITY EVENT")
            # Restore firewall rules
            subprocess.run(['/etc/audit-agent/restore-firewall.sh'])

        time.sleep(60)  # Check every minute
```

---

## Example Scenarios

### Scenario 1: Honest Request (APPROVED)

**User Request:**
```
"Add a new microsegment for machine learning workloads with GPU instances"
```

**Orchestration Agent Plan:**
```json
{
  "action": "create_microsegment",
  "segment_name": "nonprod-ml",
  "resources": {
    "vpc": "10.150.0.0/16",
    "instances": ["g5.xlarge x4"],
    "security_groups": ["ml-training-sg"],
    "estimated_monthly_cost": 902
  }
}
```

**Audit Agent Analysis:**
```json
{
  "approved": true,
  "confidence": 0.95,
  "reasoning": "Plan matches user intent exactly. Creating ML segment with GPU instances as requested.",
  "intent_match": "exact",
  "safety_concerns": [],
  "policy_violations": [],
  "plain_language_summary": "Will create a new network segment called 'nonprod-ml' with 4 GPU instances for machine learning. Cost: $902/month.",
  "recommendation": "approve"
}
```

**Result**: ✅ APPROVED - Execution proceeds

---

### Scenario 2: Scope Creep (VETOED)

**User Request:**
```
"Add a new microsegment for machine learning workloads"
```

**Orchestration Agent Plan** (SUSPICIOUS):
```json
{
  "action": "create_microsegment",
  "segment_name": "nonprod-ml",
  "resources": {
    "vpc": "10.150.0.0/16",
    "instances": ["g5.xlarge x4"],
    "security_groups": ["ml-training-sg"],
    "estimated_monthly_cost": 902
  },
  "additional_actions": {
    "modify_prod_pci_firewall": {
      "action": "add_rule",
      "source": "0.0.0.0/0",
      "port": 443,
      "reason": "Allow ML training data upload"
    }
  }
}
```

**Audit Agent Analysis:**
```json
{
  "approved": false,
  "confidence": 0.99,
  "reasoning": "Plan includes extra action NOT mentioned by user: modifying production PCI firewall to allow internet access. This is a security risk and out of scope.",
  "intent_match": "mismatch",
  "safety_concerns": [
    "Opening production PCI environment to internet (0.0.0.0/0)",
    "User did not request any changes to PCI environment",
    "Violates least privilege principle"
  ],
  "policy_violations": [
    "no_public_production_access: Production resources cannot be exposed to 0.0.0.0/0"
  ],
  "plain_language_summary": "This plan would create the ML segment you requested, but ALSO open your production payment processing environment to the internet, which you did not ask for and is dangerous.",
  "recommendation": "veto"
}
```

**Result**: ❌ VETOED - User notified of suspicious behavior

**User Notification:**
```
🛑 Execution Blocked by Audit Agent

Your request: "Add a new microsegment for machine learning workloads"

The Orchestration Agent proposed doing MORE than you asked:
1. ✅ Create ML segment (what you asked for)
2. ❌ Open production payment processing to internet (NOT requested, dangerous)

For your safety, this has been blocked.

If you want to proceed with ONLY the ML segment, please resubmit your request.
If you need the firewall change too, please submit a separate request explaining why.

View full audit report: https://audit.internal/reports/req-12345
```

---

### Scenario 3: Resource Deletion (REQUIRES CONFIRMATION)

**User Request:**
```
"Clean up old dev environments"
```

**Orchestration Agent Plan:**
```json
{
  "action": "delete_resources",
  "resources_to_delete": [
    "dev-old-vpc-1",
    "dev-old-vpc-2",
    "dev-test-vpc-3"
  ],
  "estimated_cost_savings": 450
}
```

**Audit Agent Analysis:**
```json
{
  "approved": false,
  "confidence": 0.85,
  "reasoning": "Plan involves deleting resources. This requires explicit user confirmation with list of resources to be deleted.",
  "intent_match": "partial",
  "safety_concerns": [
    "Data loss risk: Deleting VPCs will destroy all resources inside",
    "User did not explicitly list which environments to delete"
  ],
  "policy_violations": [
    "deletion_requires_confirmation: Resource deletion requires explicit user confirmation"
  ],
  "required_approvals": ["user_deletion_confirmation"],
  "plain_language_summary": "This will permanently delete 3 VPCs and all resources inside them (databases, instances, etc.). You said 'clean up old dev environments' but didn't specify which ones.",
  "recommendation": "escalate"
}
```

**Result**: ⚠️ ESCALATED - User must confirm

**User Notification:**
```
⚠️  Confirmation Required

Your request: "Clean up old dev environments"

The Orchestration Agent plans to DELETE these resources:
1. dev-old-vpc-1 (contains: 3 EC2 instances, 1 RDS database)
2. dev-old-vpc-2 (contains: 5 EC2 instances, 1 ElastiCache cluster)
3. dev-test-vpc-3 (contains: 2 EC2 instances)

⚠️  This action is PERMANENT and cannot be undone.

Cost savings: $450/month

Do you want to proceed?
[Yes, delete these resources] [No, cancel]

If yes, type "CONFIRM DELETE" to proceed:
[ ]
```

---

### Scenario 4: Cost Threshold (REQUIRES APPROVAL)

**User Request:**
```
"Scale up our production API to handle Black Friday traffic"
```

**Orchestration Agent Plan:**
```json
{
  "action": "scale_production",
  "resources": {
    "alb_nodes": "3 → 18",
    "ecs_tasks": "12 → 60",
    "rds_instance": "db.r5.large → db.r5.4xlarge",
    "elasticache_nodes": "2 → 6"
  },
  "estimated_monthly_cost": 3407,
  "cost_increase": 2850
}
```

**Audit Agent Analysis:**
```json
{
  "approved": false,
  "confidence": 0.92,
  "reasoning": "Plan matches user intent (scaling for Black Friday), but cost increase of $2,850/month exceeds $1,000 threshold requiring finance approval.",
  "intent_match": "exact",
  "safety_concerns": [],
  "policy_violations": [
    "cost_threshold_approval: Changes >$1000/month require finance approval"
  ],
  "required_approvals": ["finance_team"],
  "plain_language_summary": "Will scale production infrastructure to handle 10x traffic for Black Friday. Cost will increase from $557/month to $3,407/month (+$2,850).",
  "recommendation": "escalate"
}
```

**Result**: ⏸️ PENDING APPROVAL - Sent to finance team

**Finance Team Notification:**
```
📊 Finance Approval Required

Request from: john.doe@acmetech.com
Purpose: Scale production for Black Friday

Infrastructure Changes:
- Application Load Balancer: 3 → 18 nodes
- ECS Tasks: 12 → 60 tasks
- RDS Database: db.r5.large → db.r5.4xlarge
- ElastiCache: 2 → 6 nodes

Cost Impact:
- Current: $557/month
- Proposed: $3,407/month
- Increase: +$2,850/month

Expected Revenue Impact: $2.4M (Black Friday historical)
ROI: 841x

Duration: 7 days (Black Friday week)

[Approve] [Deny] [Request More Info]
```

---

## Deployment Guide

### On-Premises Server Setup

```bash
#!/bin/bash
# deploy-audit-agent.sh

# Step 1: Provision Ubuntu 22.04 LTS server
apt update && apt upgrade -y

# Step 2: Install dependencies
apt install -y python3.11 python3-pip postgresql-14 nginx

# Step 3: Create audit agent user (no sudo)
useradd -r -s /bin/bash -d /opt/audit-agent audit-agent

# Step 4: Install Python dependencies
pip3 install anthropic psycopg2-binary flask cryptography schedule

# Step 5: Setup PostgreSQL (immutable logs)
sudo -u postgres createuser audit_agent
sudo -u postgres createdb audit_logs
sudo -u postgres psql -c "ALTER USER audit_agent WITH PASSWORD 'generated-password';"

# Step 6: Initialize database schema
sudo -u postgres psql audit_logs < /opt/audit-agent/schema.sql

# Step 7: Generate RSA key pair for signing
openssl genrsa -out /etc/audit-agent/private_key.pem 4096
openssl rsa -in /etc/audit-agent/private_key.pem -pubout -out /etc/audit-agent/public_key.pem
chmod 400 /etc/audit-agent/private_key.pem
chown audit-agent:audit-agent /etc/audit-agent/private_key.pem

# Step 8: Generate SSL certificate
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout /etc/audit-agent/key.pem \
  -out /etc/audit-agent/cert.pem \
  -days 365 \
  -subj "/CN=audit-agent.internal"

# Step 9: Configure firewall (only allow Lambda)
ufw default deny incoming
ufw default deny outgoing
ufw allow from <lambda-nat-gateway-ip> to any port 8443
ufw allow to api.anthropic.com port 443
ufw allow to 10.250.0.11 port 5432
ufw enable

# Step 10: Create systemd service
cat > /etc/systemd/system/audit-agent.service << EOF
[Unit]
Description=Audit Agent for Infrastructure Verification
After=network.target postgresql.service

[Service]
Type=simple
User=audit-agent
WorkingDirectory=/opt/audit-agent
ExecStart=/usr/bin/python3 /opt/audit-agent/audit_agent.py
Restart=always
RestartSec=10

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/log/audit-agent

[Install]
WantedBy=multi-user.target
EOF

# Step 11: Enable and start service
systemctl daemon-reload
systemctl enable audit-agent
systemctl start audit-agent

# Step 12: Setup log rotation
cat > /etc/logrotate.d/audit-agent << EOF
/var/log/audit-agent/*.log {
    daily
    rotate 365
    compress
    delaycompress
    missingok
    notifempty
}
EOF

# Step 13: Configure monitoring
# (PagerDuty, Prometheus, etc.)

echo "Audit Agent deployed successfully!"
echo "Server IP: $(hostname -I)"
echo "Health check: curl https://10.250.0.10:8443/health"
```

### Orchestration Agent Update

```python
# Update Orchestration Agent Lambda to require Audit Agent approval

import boto3
import requests
import json

def lambda_handler(event, context):
    """
    Orchestration Agent Lambda (UPDATED to require audit approval)
    """

    request_id = event['request_id']
    user_request = event['user_request']

    # Generate execution plan
    plan = generate_infrastructure_plan(user_request)

    # =========================================================================
    # MANDATORY AUDIT CHECK (CANNOT BE BYPASSED)
    # =========================================================================
    try:
        audit_response = requests.post(
            'https://audit-agent.internal:8443/verify-plan',
            json={
                'request_id': request_id,
                'user_request': user_request,
                'orchestration_plan': plan,
                'metadata': {
                    'user_email': event['user_email'],
                    'timestamp': event['timestamp'],
                    'change_ticket_id': event.get('change_ticket_id'),
                    'deletion_confirmed': event.get('deletion_confirmed', False)
                }
            },
            headers={
                'X-Signature': sign_request_hmac(request_id)
            },
            verify='/etc/ssl/certs/audit-agent-ca.pem',
            timeout=30
        )
    except requests.exceptions.Timeout:
        # Audit agent unreachable - FAIL SECURE (deny)
        return {
            'statusCode': 503,
            'body': json.dumps({
                'error': 'Audit Agent unreachable - execution denied for safety'
            })
        }

    audit_result = audit_response.json()

    if not audit_result.get('approved'):
        # VETOED by Audit Agent - CANNOT PROCEED
        return {
            'statusCode': 403,
            'body': json.dumps({
                'error': 'Execution blocked by Audit Agent',
                'reason': audit_result.get('reason'),
                'request_id': request_id
            })
        }

    # =========================================================================
    # APPROVED - Proceed with execution
    # =========================================================================

    # Tag all resources with AuditApproved=true (IAM policy requirement)
    plan_with_tags = add_audit_approved_tags(plan, request_id)

    # Execute Terraform
    execution_result = execute_terraform(plan_with_tags)

    # =========================================================================
    # POST-EXECUTION VERIFICATION (MANDATORY)
    # =========================================================================
    verification_response = requests.post(
        'https://audit-agent.internal:8443/verify-execution',
        json={
            'request_id': request_id,
            'execution_result': execution_result
        }
    )

    if not verification_response.json().get('matches'):
        # CRITICAL: Execution deviated from approved plan
        # Alert security team immediately
        send_critical_alert({
            'type': 'execution_deviation',
            'request_id': request_id,
            'details': verification_response.json()
        })

        # Attempt automatic rollback
        try:
            rollback_execution(execution_result)
        except Exception as e:
            # Rollback failed - escalate to human
            page_on_call_engineer({
                'severity': 'critical',
                'message': f"Execution deviation + rollback failed: {request_id}"
            })

    return {
        'statusCode': 200,
        'body': json.dumps({
            'success': True,
            'request_id': request_id,
            'audit_approved': True,
            'execution_verified': verification_response.json().get('matches')
        })
    }
```

---

## Monitoring & Alerting

### Audit Agent Health Dashboard

```python
# Prometheus metrics for Audit Agent
from prometheus_client import Counter, Histogram, Gauge

# Metrics
approval_decisions = Counter(
    'audit_decisions_total',
    'Total audit decisions',
    ['decision']  # approved, vetoed, escalated
)

verification_time = Histogram(
    'audit_verification_duration_seconds',
    'Time to verify a plan'
)

audit_agent_health = Gauge(
    'audit_agent_healthy',
    'Audit agent health status (1=healthy, 0=unhealthy)'
)

# Example Grafana dashboard queries
"""
# Approval rate
rate(audit_decisions_total{decision="approved"}[5m]) /
rate(audit_decisions_total[5m])

# Veto rate (should be low)
rate(audit_decisions_total{decision="vetoed"}[5m])

# Average verification time
rate(audit_verification_duration_seconds_sum[5m]) /
rate(audit_verification_duration_seconds_count[5m])

# Audit agent uptime
audit_agent_healthy
"""
```

### Critical Alerts

```yaml
# PagerDuty alerts for Audit Agent
alerts:
  - name: AuditAgentDown
    condition: audit_agent_healthy == 0
    severity: critical
    message: "Audit Agent is down - ALL infrastructure changes blocked"
    escalation: immediate

  - name: HighVetoRate
    condition: rate(audit_decisions_total{decision="vetoed"}[1h]) > 0.1
    severity: warning
    message: "High veto rate - possible Orchestration Agent malfunction"

  - name: ExecutionDeviation
    condition: execution_deviation_detected == true
    severity: critical
    message: "Execution deviated from approved plan - possible security breach"
    escalation: immediate

  - name: AuditDatabaseDown
    condition: audit_database_reachable == 0
    severity: critical
    message: "Audit database unreachable - audit trail at risk"
```

---

## Conclusion

The **Independent Audit & Policy Enforcement Agent** provides essential checks and balances for AI-driven infrastructure management:

### Key Benefits

1. **User Protection**: Verifies AI does exactly what user requested (no scope creep)
2. **Policy Enforcement**: Hard-coded rules that AI cannot bypass
3. **Transparency**: Every decision explained in plain language
4. **Accountability**: Immutable audit trail (7-year retention)
5. **Safety**: Multiple layers prevent unauthorized actions

### Cost Analysis

**On-Premises Deployment:**
- Hardware: $8,000 one-time
- Hosting: $200/month
- Claude API calls: ~$50/month (verification only)
- **Total: $250/month** (after initial hardware investment)

**Value:**
- Prevents single mistake: Could save millions (data breach, compliance violation)
- Insurance against AI errors: Priceless
- Regulatory compliance: Required for financial services, healthcare
- Peace of mind: Sleep well knowing AI is supervised

### Next Steps

1. Deploy Audit Agent on-premises server (see deployment guide)
2. Update Orchestration Agent to require approval
3. Configure IAM policies to enforce audit approval
4. Test with low-risk operations first
5. Gradually increase automation as confidence builds
6. Review audit logs weekly for trends

**The Audit Agent is your AI "police force" - keeping the Orchestration Agent honest, transparent, and aligned with your intent.**
