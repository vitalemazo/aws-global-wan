# Operations Guide - AWS Global WAN

Complete operational documentation for managing, monitoring, and scaling the AWS Global WAN infrastructure with microsegmentation.

## Table of Contents
1. [Team Responsibilities](#team-responsibilities)
2. [Security Controls & Microsegmentation](#security-controls--microsegmentation)
3. [Traffic Flow (Ingress/Egress)](#traffic-flow-ingressegress)
4. [Inspection VPC Architecture](#inspection-vpc-architecture)
5. [Failover & High Availability](#failover--high-availability)
6. [Network Firewall Configuration](#network-firewall-configuration)
7. [Scaling Operations](#scaling-operations)
8. [AI Orchestration](#ai-orchestration)
9. [Troubleshooting Playbooks](#troubleshooting-playbooks)
10. [Change Management](#change-management)

---

## Team Responsibilities

### Option 1: Human Teams

#### Central Networking Team (Owner: Network Engineering)
**Responsibilities**:
- Manage Core Network and IPAM pools
- Configure Cloud WAN policies and segments
- Maintain Inspection VPCs and Network Firewall
- Handle cross-account RAM sharing
- Monitor global network health
- Incident response for network-wide issues

**Key Tasks**:
- Weekly: Review CloudWatch metrics, check for capacity issues
- Monthly: Update firewall rules based on threat intelligence
- Quarterly: Audit segment policies and access controls
- On-demand: Provision new segments, troubleshoot routing issues

**Tools**:
- AWS Cloud WAN Console
- Network Manager
- CloudWatch Dashboards
- Terraform (for infrastructure changes)

**Escalation Path**:
- L1: NOC (monitoring alerts)
- L2: Network Engineers (troubleshooting)
- L3: Network Architects (design changes)

#### Security Team (Owner: InfoSec)
**Responsibilities**:
- Define security policies for microsegments
- Manage Network Firewall rule groups
- Review VPC Flow Logs and firewall logs
- Approve vendor access (B2B integrations)
- Conduct security audits and penetration testing

**Key Tasks**:
- Daily: Review firewall DROP logs, investigate anomalies
- Weekly: Audit vendor access logs (Cloudflare + CloudTrail)
- Monthly: Update threat intelligence feeds
- Quarterly: Penetration testing of segment isolation

**Tools**:
- AWS Network Firewall Console
- GuardDuty
- Security Hub
- CloudTrail
- Athena (for log analysis)

**Escalation Path**:
- L1: Security Analysts (alert triage)
- L2: Security Engineers (incident response)
- L3: CISO (major incidents, policy changes)

#### Application Teams (Owner: Dev/DevOps)
**Responsibilities**:
- Deploy applications to landing zones
- Configure security groups for 3-tier architecture
- Monitor application-level metrics
- Request new VPC attachments to Core Network

**Key Tasks**:
- Per deployment: Run terraform apply for landing zone
- Daily: Monitor application logs and metrics
- Weekly: Review security group rules for least privilege
- On-demand: Request new segment or firewall rule

**Tools**:
- Terraform (landing zone modules)
- Application-specific monitoring (Datadog, New Relic)
- AWS Console (limited to their accounts)

**Escalation Path**:
- L1: Application Support (user issues)
- L2: DevOps (infrastructure issues)
- L3: Central Networking (network connectivity issues)

#### Compliance Team (Owner: Compliance/Audit)
**Responsibilities**:
- Ensure PCI-DSS, SOC 2, HIPAA compliance
- Review audit logs (VPC Flow, CloudTrail, Firewall)
- Document controls for auditors
- Approve architecture changes

**Key Tasks**:
- Quarterly: Generate compliance reports (access logs, config changes)
- Annually: Work with external auditors
- On-demand: Review new segment requests for compliance

**Tools**:
- AWS Config
- CloudTrail (with Athena queries)
- AWS Audit Manager
- Compliance dashboard (custom)

### Option 2: AI Orchestrator (Single Point of Control)

#### AI Agent Architecture
```
┌─────────────────────────────────────────────────────────────┐
│ AI Orchestrator (Claude, GPT-4, etc.)                      │
│                                                              │
│ Capabilities:                                                │
│ - Analyze CloudWatch metrics and logs                       │
│ - Detect anomalies (traffic spikes, security issues)        │
│ - Auto-scale segments (add/remove capacity)                 │
│ - Update firewall rules based on threat intelligence        │
│ - Provision new landing zones automatically                 │
│ - Generate compliance reports                               │
│ - Troubleshoot network issues                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Input Sources:                                               │
│ - CloudWatch Alarms → JSON events                           │
│ - VPC Flow Logs → S3 → Athena                               │
│ - Network Firewall Logs → CloudWatch Logs Insights          │
│ - GuardDuty Findings → EventBridge                          │
│ - User Requests → Slack/API                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Decision Engine:                                             │
│ - Evaluate context (severity, impact, compliance)           │
│ - Check approval requirements (auto vs human review)        │
│ - Select action (scale, block, alert, remediate)            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Execution:                                                   │
│ - Terraform (infrastructure changes)                        │
│ - AWS APIs (network config, firewall rules)                 │
│ - Slack/PagerDuty (human escalation)                        │
│ - Documentation (update runbooks, audit logs)               │
└─────────────────────────────────────────────────────────────┘
```

**Example: AI Handles Security Incident**

1. **Input**: GuardDuty detects cryptocurrency mining in `prod-general` segment
   ```json
   {
     "detail-type": "GuardDuty Finding",
     "detail": {
       "severity": 8,
       "type": "CryptoCurrency:EC2/BitcoinTool.B!DNS",
       "resource": {
         "instanceDetails": {
           "networkInterfaces": [{
             "privateIpAddress": "10.103.5.42"
           }]
         }
       }
     }
   }
   ```

2. **AI Analysis**:
   - Query VPC Flow Logs: Which instance, what destinations, how long?
   - Check security groups: Is this allowed?
   - Review firewall logs: Any other suspicious traffic?
   - Assess impact: Production segment, customer-facing?

3. **AI Decision**:
   ```
   Context: Production segment, high severity, customer data at risk
   Action: IMMEDIATE ISOLATION
   Approval: Auto-approved (security policy allows)

   Plan:
   1. Update security group: Block all egress from 10.103.5.42
   2. Update firewall rule: DROP all traffic from instance
   3. Create incident ticket (JIRA)
   4. Notify security team (Slack/PagerDuty)
   5. Generate forensics report (CloudTrail + Flow Logs)
   ```

4. **AI Execution**:
   ```bash
   # Update security group
   aws ec2 revoke-security-group-egress \
     --group-id sg-abc123 \
     --ip-permissions IpProtocol=-1,CidrIp=0.0.0.0/0

   # Update firewall rule (via Terraform)
   terraform apply -var="blocked_ips=['10.103.5.42']"

   # Create incident
   curl -X POST https://api.jira.com/v2/issue \
     -d '{"summary": "GuardDuty: Crypto mining detected"}'

   # Notify team
   curl -X POST https://slack.com/api/chat.postMessage \
     -d '{"channel": "#security-alerts", "text": "🚨 Instance isolated: 10.103.5.42"}'
   ```

5. **AI Documentation**:
   ```markdown
   Incident: SEC-2025-0042
   Detected: 2025-10-31 14:32:18 UTC
   Action: Instance 10.103.5.42 isolated (egress blocked)
   Duration: 2 minutes (detection to isolation)
   Impact: 0 customers affected (isolated before data exfiltration)
   Next Steps: Security team to investigate root cause
   ```

**Approval Matrix for AI Actions**:

| Action | Severity | Auto-Approved | Requires Human Review |
|--------|----------|---------------|----------------------|
| Block malicious IP | High | ✅ Yes | ❌ No |
| Isolate compromised instance | High | ✅ Yes | ❌ No |
| Add firewall rule (block) | Medium | ✅ Yes (log to Slack) | ❌ No |
| Remove firewall rule (allow) | Medium | ❌ No | ✅ Yes (security team) |
| Create new segment | Low | ❌ No | ✅ Yes (network team) |
| Delete segment | High | ❌ No | ✅ Yes (network + security + compliance) |
| Grant vendor access | Medium | ❌ No | ✅ Yes (security team) |
| Revoke vendor access | Medium | ✅ Yes (log to Slack) | ❌ No |
| Scale capacity (add VPCs) | Low | ✅ Yes | ❌ No |
| Change core network policy | High | ❌ No | ✅ Yes (network architect) |

---

## Security Controls & Microsegmentation

### Defense in Depth - 3 Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Cloud WAN Routing (Segment Isolation)             │
│                                                              │
│ Control: Cloud WAN Core Network Policy                      │
│ Enforcement: AWS Control Plane (cannot be bypassed)         │
│ Granularity: Segment-level (prod-pci, prod-general, etc.)   │
│                                                              │
│ Example:                                                     │
│   prod-pci can ONLY route to shared-dns (10.255.1.0/24)     │
│   prod-data has NO route to internet (0.0.0.0/0)            │
│   nonprod-dev CANNOT route to any production segments       │
│                                                              │
│ How it works:                                                │
│   VPC attachment tagged with Segment="prod-pci"             │
│   → Cloud WAN assigns to prod-pci segment                   │
│   → Routing table only includes allowed destinations        │
│   → Packets to unauthorized destinations dropped at edge    │
└─────────────────────────────────────────────────────────────┘
                            ↓ (If routing allowed)
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Security Groups (Instance-Level Firewall)          │
│                                                              │
│ Control: VPC Security Groups                                │
│ Enforcement: Hypervisor (before packet reaches instance)    │
│ Granularity: Instance-level, port-specific                  │
│                                                              │
│ Example (3-Tier Architecture):                              │
│   ALB SG: Accept HTTPS from internet                        │
│   Web SG: Accept port 8080 from ALB SG only                 │
│   API SG: Accept port 8443 from Web SG only                 │
│   DB SG:  Accept port 5432 from API SG only, NO EGRESS      │
│                                                              │
│ How it works:                                                │
│   Web tier instance tries to connect to database            │
│   → Check egress rule: Does Web SG allow port 5432?         │
│   → NO (Web SG only allows port 8443 to API SG)             │
│   → Packet dropped before leaving instance                  │
│                                                              │
│   API tier instance tries to connect to database            │
│   → Check egress rule: Does API SG allow port 5432?         │
│   → YES (to DB SG)                                           │
│   → Check ingress rule: Does DB SG allow from API SG?       │
│   → YES                                                      │
│   → Packet delivered                                         │
└─────────────────────────────────────────────────────────────┘
                            ↓ (If security group allows)
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Network Firewall (Application-Layer Inspection)    │
│                                                              │
│ Control: AWS Network Firewall with Stateful Rules           │
│ Enforcement: Inspection VPC (traffic routes through)        │
│ Granularity: Domain-level, protocol-level, payload-level    │
│                                                              │
│ Example:                                                     │
│   API tier tries to reach stripe.com (external payment)     │
│   → Layer 1: Cloud WAN allows egress to 0.0.0.0/0           │
│   → Layer 2: Security group allows HTTPS egress             │
│   → Layer 3: Firewall inspects TLS SNI: "api.stripe.com"   │
│   → Check domain allowlist: Is stripe.com allowed?          │
│   → YES (in api_allowed_domains)                            │
│   → Packet forwarded to internet                            │
│                                                              │
│   API tier tries to reach malware-site.com                  │
│   → Layer 1: Allowed                                         │
│   → Layer 2: Allowed                                         │
│   → Layer 3: Firewall checks threat intel blocklist         │
│   → MATCH: malware-site.com in blocklist                    │
│   → Action: DROP + ALERT                                     │
│   → Packet dropped, CloudWatch alarm triggered              │
│                                                              │
│ Inspection Types:                                            │
│   - TLS SNI inspection (domain filtering without decrypt)   │
│   - HTTP Host header inspection                             │
│   - Suricata rules (IDS/IPS signatures)                     │
│   - Stateful flow tracking (detect port scans)              │
└─────────────────────────────────────────────────────────────┘
```

### Microsegmentation Enforcement

#### Segment: prod-pci (PCI-DSS Compliant)

**Requirements**:
- No internet egress (except whitelisted destinations)
- Cannot communicate with other production segments
- All traffic logged and alerted
- Database tier completely isolated

**Enforcement**:

**Layer 1 (Cloud WAN)**:
```json
{
  "segment": "prod-pci",
  "isolate-attachments": true,
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "prod-pci",
      "destination-cidr-blocks": ["10.255.1.0/24"],
      "via": {
        "network-function-groups": ["inspection-pci"]
      }
    }
  ]
}
```
- PCI VPCs can ONLY route to shared-dns (10.255.1.0/24)
- All traffic goes through dedicated PCI firewall (inspection-pci)
- No routes to other segments exist

**Layer 2 (Security Groups)**:
```hcl
# Database security group has ZERO egress rules
resource "aws_security_group" "pci_database" {
  name   = "pci-database-sg"
  vpc_id = aws_vpc.pci.id

  # Ingress: Accept from API tier only
  ingress {
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.pci_api.id]
  }

  # NO egress rules defined = cannot initiate any outbound connections
}
```

**Layer 3 (Network Firewall)**:
```hcl
# PCI-specific firewall: ALERT on any unexpected traffic
resource "aws_networkfirewall_rule_group" "pci_egress" {
  stateful_rule {
    action = "ALERT"
    header {
      source      = "10.100.0.0/16"  # PCI segment CIDR
      destination = "ANY"
    }
    rule_option {
      keyword  = "msg"
      settings = ["PCI segment unexpected egress - INVESTIGATION REQUIRED"]
    }
  }

  # Whitelist: Allow only shared-dns
  stateful_rule {
    action = "PASS"
    header {
      source      = "10.100.0.0/16"
      destination = "10.255.1.0/24"  # shared-dns
      port        = "53"
    }
  }
}
```

**Result**:
- PCI database can ONLY talk to PCI API tier (within same VPC)
- PCI API tier can ONLY talk to shared-dns for name resolution
- Any attempt to reach internet = dropped at Layer 1 (no route)
- Any unexpected traffic = ALERT to security team

#### Segment: nonprod-dev (Development)

**Requirements**:
- Internet access for package downloads (npm, pip, apt)
- Can communicate with other non-prod segments
- CANNOT access production segments
- More permissive firewall rules

**Enforcement**:

**Layer 1 (Cloud WAN)**:
```json
{
  "segment": "nonprod-dev",
  "isolate-attachments": false,
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "nonprod-dev",
      "destination-cidr-blocks": ["0.0.0.0/0"]
    },
    {
      "action": "send-to",
      "segment": "shared-dns"
    },
    {
      "action": "deny",
      "segment": "nonprod-dev",
      "destination-cidr-blocks": ["10.100.0.0/14"]  # All production CIDRs
    }
  ]
}
```
- Dev VPCs can reach internet (0.0.0.0/0)
- Dev VPCs can reach shared services
- Dev VPCs CANNOT reach production (10.100.0.0/14 blocked)

**Layer 2 (Security Groups)**:
```hcl
# More permissive for development
resource "aws_security_group" "dev_general" {
  name   = "dev-general-sg"
  vpc_id = aws_vpc.dev.id

  # Allow SSH from bastion
  ingress {
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.dev_bastion.id]
  }

  # Allow HTTPS egress for package downloads
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP egress (for apt, yum)
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Layer 3 (Network Firewall)**:
```hcl
# Block production CIDRs at firewall level (defense in depth)
resource "aws_networkfirewall_rule_group" "nonprod_rules" {
  stateful_rule {
    action = "DROP"
    header {
      source      = "10.10.0.0/16"    # nonprod-dev CIDR
      destination = "10.100.0.0/16"   # prod-pci CIDR
    }
    rule_option {
      keyword  = "msg"
      settings = ["BLOCKED: Dev attempting to access production"]
    }
  }
}
```

**Result**:
- Dev instances can download packages from internet
- Dev instances CANNOT reach production (blocked at Layer 1 routing)
- If routing misconfigured, Layer 3 firewall blocks as backup
- SSH access from bastion for troubleshooting

---

## Traffic Flow (Ingress/Egress)

### Ingress: Internet → Application

**Scenario**: User accesses `https://api.acmetech.com`

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: DNS Resolution                                       │
│                                                              │
│ User browser → Route 53 → Returns: ALB DNS name             │
│   api.acmetech.com → api-prod-123.us-east-1.elb.amazonaws.com │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 2: TLS Handshake                                        │
│                                                              │
│ User → ALB (public subnet)                                   │
│   - ALB terminates TLS (Certificate Manager)                │
│   - WAF inspects request (SQL injection, XSS, rate limit)   │
│   - If blocked: Return 403 Forbidden                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 3: ALB → Web Tier                                      │
│                                                              │
│ ALB (sg-alb) → Web Tier (sg-web, private subnet)            │
│   - Check: ALB SG allows egress to Web SG port 8080? YES    │
│   - Check: Web SG allows ingress from ALB SG port 8080? YES │
│   - Packet delivered to Web tier instance                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Web Tier → API Tier                                 │
│                                                              │
│ Web (sg-web) → API (sg-api, private subnet)                 │
│   - Check: Web SG allows egress to API SG port 8443? YES    │
│   - Check: API SG allows ingress from Web SG port 8443? YES │
│   - Packet delivered to API tier instance                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 5: API Tier → Database                                 │
│                                                              │
│ API (sg-api) → Database (sg-db, isolated subnet)            │
│   - Check: API SG allows egress to DB SG port 5432? YES     │
│   - Check: DB SG allows ingress from API SG port 5432? YES  │
│   - Packet delivered to database                            │
│   - Database queries data, returns result                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 6: Response Path                                        │
│                                                              │
│ Database → API → Web → ALB → User                           │
│   - Stateful: Security groups remember connection           │
│   - Response packets automatically allowed (return traffic) │
│   - ALB encrypts response (TLS)                             │
│   - User receives JSON response                             │
└─────────────────────────────────────────────────────────────┘
```

**Ingress Logs**:
- **ALB Access Logs** (S3): HTTP method, response code, latency
- **VPC Flow Logs**: ALB → Web → API → DB (all IPs, ports, packets)
- **WAF Logs**: Blocked requests (SQL injection attempts, etc.)
- **CloudWatch Metrics**: Request count, error rate, latency (p50, p99)

### Egress: Application → Internet (Inspection VPC)

**Scenario**: API tier calls `https://api.stripe.com` for payment processing

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: DNS Resolution                                       │
│                                                              │
│ API instance → Route 53 Resolver (shared-dns)               │
│   - Route table: 10.255.1.0/24 via Cloud WAN                │
│   - Query: api.stripe.com                                    │
│   - Response: 54.187.174.169                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Routing Decision (Cloud WAN)                        │
│                                                              │
│ API instance (10.101.5.42) → Stripe (54.187.174.169)        │
│   - Check segment policy: prod-api egress allowed?          │
│   - YES: via network-function-group "inspection-general"    │
│   - Route: API VPC → Cloud WAN → Inspection VPC             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Inspection VPC - Network Firewall                   │
│                                                              │
│ Packet arrives at Inspection VPC                            │
│   - Routed to Network Firewall endpoint                     │
│   - Firewall inspects TLS SNI: "api.stripe.com"            │
│   - Check domain allowlist: stripe.com in api_allowed_domains? │
│   - YES: PASS                                                │
│   - Check threat intel: stripe.com in blocklist?            │
│   - NO: PASS                                                 │
│   - Log: PASS api.stripe.com from 10.101.5.42               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 4: NAT Gateway (Internet Egress)                       │
│                                                              │
│ Inspection VPC → NAT Gateway → Internet Gateway             │
│   - NAT: 10.101.5.42 → NAT GW public IP (54.x.x.x)         │
│   - Packet sent to Stripe: 54.187.174.169                   │
│   - Stripe responds                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Response Path                                        │
│                                                              │
│ Stripe → IGW → NAT GW → Firewall → Cloud WAN → API          │
│   - Stateful: Firewall remembers outbound connection        │
│   - Response automatically allowed                           │
│   - API instance receives Stripe API response               │
└─────────────────────────────────────────────────────────────┘
```

**What if API tries to reach malicious domain?**

```
API instance → malware-site.com
  → Cloud WAN routes to Inspection VPC
  → Network Firewall inspects TLS SNI: "malware-site.com"
  → Check threat intel blocklist: MATCH
  → Action: DROP
  → CloudWatch alarm: "Malicious domain blocked"
  → Security team alerted (PagerDuty)
  → Packet dropped, connection timeout
```

**Egress Logs**:
- **Network Firewall Logs** (CloudWatch): Allowed/blocked domains
- **VPC Flow Logs**: API instance → Firewall → NAT (all IPs, ports)
- **CloudWatch Metrics**: Firewall throughput, packet drops, latency

### Egress: Database Isolation (No Internet)

**Scenario**: Database tries to reach internet (should fail)

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Database Tries Egress                               │
│                                                              │
│ Database instance (10.102.3.15) → google.com (8.8.8.8)      │
│   - Check security group: DB SG has egress rules?           │
│   - NO: Zero egress rules defined                           │
│   - Action: DROP at hypervisor (before packet leaves)       │
│   - Connection timeout                                       │
└─────────────────────────────────────────────────────────────┘

# Even if security group misconfigured:

┌─────────────────────────────────────────────────────────────┐
│ Step 2: Layer 1 Routing Check                               │
│                                                              │
│ Database instance → google.com                               │
│   - Check route table: 0.0.0.0/0 route exists?              │
│   - NO: Database subnet route table has NO default route    │
│   - Only route: 10.102.0.0/16 local (same VPC)              │
│   - Action: No route to destination                          │
│   - Connection timeout                                       │
└─────────────────────────────────────────────────────────────┘

# Even if route table misconfigured:

┌─────────────────────────────────────────────────────────────┐
│ Step 3: Layer 3 Firewall Check                              │
│                                                              │
│ Packet somehow reaches Inspection VPC                       │
│   - Firewall checks source: 10.102.0.0/16 (prod-data CIDR)  │
│   - Match rule: DROP all from database segment              │
│   - Rule option: msg "Database attempting egress - BLOCKED" │
│   - Action: DROP + ALERT                                     │
│   - CloudWatch alarm: "Database isolation violated"         │
│   - Security team alerted (CRITICAL)                        │
└─────────────────────────────────────────────────────────────┘
```

**Defense in Depth Result**:
- Layer 1 (Security Group): Blocks at hypervisor
- Layer 2 (Route Table): No route to internet
- Layer 3 (Firewall): Explicit DROP rule as backup

**If all 3 layers fail**: Network is misconfigured, requires immediate investigation.

---

## Inspection VPC Architecture

### Purpose

The Inspection VPC acts as a **centralized security checkpoint** for all inter-segment and internet-bound traffic.

**Benefits**:
- ✅ Single place to manage firewall rules (not per-VPC)
- ✅ Centralized logging and monitoring
- ✅ Cost efficiency: 1 firewall vs 50 firewalls (98% cost reduction)
- ✅ Consistent security policies across all segments

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│ Inspection VPC (10.254.0.0/16)                                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Public Subnets (10.254.0.0/24, 10.254.1.0/24)           │ │
│  │   - NAT Gateways (for internet egress)                  │ │
│  │   - Internet Gateway                                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                         ↑                                       │
│                         │                                       │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Firewall Subnets (10.254.2.0/24, 10.254.3.0/24)         │ │
│  │   - Network Firewall Endpoints                           │ │
│  │   - Stateful rule groups:                                │ │
│  │     * PCI egress (whitelist-only)                        │ │
│  │     * API egress (domain allowlist)                      │ │
│  │     * Database deny-all                                  │ │
│  │     * Threat intelligence (blocklist)                    │ │
│  │     * DDoS protection (rate limiting)                    │ │
│  └──────────────────────────────────────────────────────────┘ │
│                         ↑                                       │
│                         │                                       │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Cloud WAN Subnets (10.254.4.0/24, 10.254.5.0/24)        │ │
│  │   - Cloud WAN attachments                                │ │
│  │   - Network Function Groups:                             │ │
│  │     * inspection-general (prod, nonprod, shared)         │ │
│  │     * inspection-pci (dedicated for PCI traffic)         │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
              ↑                                       ↑
              │                                       │
    ┌─────────┴─────────┐               ┌───────────┴───────────┐
    │ Production VPCs   │               │ Non-Production VPCs   │
    │ (via Cloud WAN)   │               │ (via Cloud WAN)       │
    └───────────────────┘               └───────────────────────┘
```

### Traffic Flow Through Inspection VPC

#### Path 1: Production → Internet (Inspected)

```
prod-api VPC (10.101.0.0/16)
  → tries to reach stripe.com (54.187.174.169)
  → route table: 0.0.0.0/0 via Cloud WAN
  → Cloud WAN: segment policy says route via "inspection-general"
  → packet arrives at Inspection VPC Cloud WAN subnet (10.254.4.0/24)
  → route table in Inspection VPC: 0.0.0.0/0 via Firewall Endpoint
  → packet sent to Network Firewall (10.254.2.5)
  → Firewall inspects, logs, applies rules
  → If PASS: packet sent to NAT Gateway (10.254.0.10)
  → NAT: 10.101.5.42 → 54.x.x.x (NAT GW public IP)
  → Internet Gateway
  → Internet
  → Response: stripe.com → IGW → NAT GW → Firewall → Cloud WAN → prod-api
```

#### Path 2: PCI → Shared DNS (Dedicated Inspection)

```
prod-pci VPC (10.100.0.0/16)
  → tries to reach shared-dns (10.255.1.4)
  → route table: 10.255.1.0/24 via Cloud WAN
  → Cloud WAN: segment policy says route via "inspection-pci"
  → packet arrives at Inspection VPC (dedicated PCI firewall endpoint)
  → Firewall applies PCI-specific rules (ALERT on unexpected)
  → If PASS: packet sent to Cloud WAN
  → Cloud WAN routes to shared-dns segment
  → DNS server receives query
  → Response: DNS → Cloud WAN → Firewall (inspection-pci) → prod-pci
```

**Why dedicated PCI inspection?**
- PCI-DSS requires separate logging and monitoring
- Higher scrutiny (ALERT on any unexpected traffic)
- Compliance auditors want dedicated infrastructure
- Prevents PCI traffic mixing with general production logs

#### Path 3: Database → Internet (BLOCKED)

```
prod-data VPC (10.102.0.0/16)
  → tries to reach google.com (8.8.8.8)
  → route table: NO default route (only 10.102.0.0/16 local)
  → packet dropped (no route to destination)
  → Connection timeout

# If route misconfigured and packet reaches Inspection VPC:
  → Firewall sees source: 10.102.0.0/16
  → Match rule: "DROP all from prod-data segment"
  → Action: DROP + ALERT
  → CloudWatch alarm: "Database isolation violated"
  → Security team notified (CRITICAL incident)
```

### Inspection VPC Scaling

**Current Capacity**:
- Network Firewall: 10 Gbps throughput
- 2 AZs (high availability)
- NAT Gateway: 45 Gbps per AZ

**Scaling Triggers**:

**CloudWatch Alarm**: Firewall throughput > 8 Gbps (80% utilization)
```hcl
resource "aws_cloudwatch_metric_alarm" "firewall_throughput_high" {
  alarm_name          = "inspection-vpc-firewall-throughput-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BytesOut"
  namespace           = "AWS/NetworkFirewall"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000000000000  # 8 Gbps in bytes
  alarm_description   = "Firewall approaching capacity - scale out"

  dimensions = {
    FirewallName = "inspection-vpc-firewall"
  }
}
```

**Scaling Action** (automated via Lambda):
1. Alarm triggers Lambda: `scale_inspection_vpc`
2. Lambda evaluates:
   - Current throughput trend (last 7 days)
   - Peak traffic times (business hours vs overnight)
   - Cost impact (firewall capacity increases cost)
3. Lambda decision:
   - If sustained high throughput: Add 3rd AZ, increase firewall capacity
   - If temporary spike: Do nothing, wait 1 hour, re-evaluate
   - If consistent 90%+ utilization: Human approval required
4. Lambda executes (if auto-approved):
   ```bash
   terraform apply -var="inspection_vpc_azs=3" \
                   -var="firewall_capacity=20Gbps"
   ```
5. Lambda notifies: Slack channel `#network-ops`

**Scaling Cost**:
- Network Firewall: $0.395/hour base + $0.065/GB processed
- 10 Gbps → 20 Gbps: +$395/month base fee
- Processing 1 TB/day: +$1,950/month

---

## Failover & High Availability

### Component Redundancy

| Component | Redundancy | Failover Time | Automated |
|-----------|------------|---------------|-----------|
| **Cloud WAN Core Network** | Regional (3+ edge locations) | < 1 second | ✅ Yes |
| **Inspection VPC** | Multi-AZ (2+ AZs) | < 1 second | ✅ Yes |
| **Network Firewall** | Multi-AZ (auto-scaling) | < 1 second | ✅ Yes |
| **NAT Gateway** | Per-AZ (2+ NAT GWs) | < 1 second | ✅ Yes |
| **Route 53 Resolver** | Multi-AZ (2+ endpoints) | < 1 second | ✅ Yes |
| **Application (3-tier)** | Multi-AZ, Auto Scaling | 1-5 minutes | ✅ Yes |

### Failure Scenarios

#### Scenario 1: Network Firewall Endpoint Fails

**Detection**:
```
CloudWatch Alarm: NetworkFirewall/HealthCheckStatus = UNHEALTHY
Time: < 30 seconds
```

**Automatic Failover**:
```
1. AWS detects firewall endpoint failure (health check)
2. Route table automatically updated:
   OLD: 0.0.0.0/0 → vpce-abc123 (AZ-1 firewall endpoint)
   NEW: 0.0.0.0/0 → vpce-def456 (AZ-2 firewall endpoint)
3. Traffic re-routed to healthy endpoint
4. Duration: < 1 second (imperceptible to users)
```

**Human Action Required**: None (auto-healing)

**Monitoring**:
```
CloudWatch Metrics:
- AWS/NetworkFirewall/PacketDrop (should be 0)
- AWS/NetworkFirewall/ActiveConnections (should remain stable)
- VPC Flow Logs: Check for connection resets

Slack Notification:
"⚠️ Firewall endpoint vpce-abc123 failed, auto-failed to vpce-def456"
```

#### Scenario 2: Entire Inspection VPC AZ Fails

**Detection**:
```
AWS Health Dashboard: AZ us-east-1a experiencing connectivity issues
CloudWatch Alarms: Multiple components unreachable
Time: 1-2 minutes
```

**Automatic Failover**:
```
1. Cloud WAN detects AZ failure (BFD protocol, < 1 sec)
2. All routes via us-east-1a withdrawn
3. Traffic re-routed via us-east-1b:
   - Network Firewall (AZ-b)
   - NAT Gateway (AZ-b)
   - Cloud WAN attachment (AZ-b)
4. Application ALBs drain connections from AZ-a
5. Auto Scaling launches replacement instances in AZ-b/c
6. Duration: 1-5 minutes for full recovery
```

**Human Action Required**: None (auto-healing)

**Post-Incident**:
```
1. AWS resolves AZ issue (typically 1-4 hours)
2. Resources in AZ-a come back online
3. Cloud WAN re-adds AZ-a routes
4. Traffic load-balances across all AZs again
5. No human intervention needed
```

#### Scenario 3: Cloud WAN Edge Location Fails

**Detection**:
```
CloudWatch Alarm: CloudWAN/AttachmentState = DOWN
Affected: All attachments in us-east-1
Time: < 10 seconds
```

**Automatic Failover**:
```
1. Cloud WAN uses multiple edge locations per region:
   us-east-1a, us-east-1b, us-east-1c (each has edge)
2. If us-east-1a edge fails:
   - Attachments in us-east-1a re-connect to us-east-1b edge
   - BGP routes updated (< 1 second)
   - Traffic flows via us-east-1b
3. No data plane disruption
4. Duration: < 1 second
```

**Human Action Required**: None (AWS manages Cloud WAN redundancy)

#### Scenario 4: Complete Region Failure (Disaster Recovery)

**Detection**:
```
AWS Health Dashboard: us-east-1 region impaired
Multiple alarms across all components
Time: Immediate
```

**Manual Failover (Regional DR)**:
```
1. DNS Failover (Route 53):
   api.acmetech.com:
     OLD: api-use1-123.us-east-1.elb.amazonaws.com (UNHEALTHY)
     NEW: api-usw2-456.us-west-2.elb.amazonaws.com (HEALTHY)

   Duration: < 1 minute (health check + TTL)

2. Cloud WAN automatically routes traffic via us-west-2:
   - Core Network spans multiple regions
   - Segments exist in both us-east-1 and us-west-2
   - No action needed (Cloud WAN handles routing)

3. Data Replication:
   - RDS: Read replica in us-west-2 promoted to primary (5-10 min)
   - S3: Cross-region replication (already in us-west-2)
   - ElastiCache: Failover to us-west-2 cluster (< 1 min)

4. Application Startup:
   - Auto Scaling launches instances in us-west-2 (5-10 min)
   - Warm standby: Keep minimum instances running (faster)

5. DNS propagation: 60 seconds (TTL)

Total RTO: 10-15 minutes
Total RPO: < 1 minute (RDS replication lag)
```

**Human Action Required**:
- ✅ Promote RDS read replica (can be automated with Lambda)
- ✅ Verify application functionality in us-west-2
- ✅ Monitor for issues
- ⚠️ Update status page (status.acmetech.com)
- ⚠️ Communicate with customers (if user-facing impact)

**Runbook**: `runbooks/regional-failover.md`

---

## Network Firewall Configuration

### Firewall Rule Groups (Priority Order)

Network Firewall evaluates rules in **strict order** (cannot be changed):

```
Priority 1: PASS rules (highest priority)
Priority 2: DROP rules
Priority 3: ALERT rules
Priority 4: Default action (PASS or DROP, set per policy)
```

**Example Flow**:
```
Packet: API tier (10.101.5.42) → stripe.com (54.187.174.169)

1. Check PASS rules:
   - Match: "Allow stripe.com" (domain allowlist)
   - Action: PASS (packet forwarded)
   - Stop processing (packet allowed)

2. Never reaches DROP or ALERT rules
```

**Example Flow (Blocked)**:
```
Packet: API tier (10.101.5.42) → malware-site.com (203.0.113.5)

1. Check PASS rules:
   - No match (malware-site.com not in allowlist)

2. Check DROP rules:
   - Match: "Block threat intel domains" (malware-site.com in blocklist)
   - Action: DROP
   - Log: "Blocked malware-site.com from 10.101.5.42"
   - CloudWatch alarm triggered
   - Packet dropped
```

### Rule Group Architecture

```
┌────────────────────────────────────────────────────────────────┐
│ Firewall Policy: inspection-vpc-policy                        │
│                                                                 │
│  Rule Group 1: pci-egress (Priority: 1, Capacity: 200)        │
│    - Type: Stateful                                            │
│    - Action: PASS (whitelist-only)                             │
│    - Rule 1: PASS stripe.com                                   │
│    - Rule 2: PASS twilio.com                                   │
│    - Rule 3: ALERT * (catch-all for unexpected)               │
│                                                                 │
│  Rule Group 2: database-deny-all (Priority: 2, Capacity: 50)  │
│    - Type: Stateful                                            │
│    - Action: DROP                                              │
│    - Rule 1: DROP all from 10.102.0.0/16 (prod-data)          │
│                                                                 │
│  Rule Group 3: threat-intel (Priority: 3, Capacity: 300)      │
│    - Type: Stateful                                            │
│    - Action: DROP                                              │
│    - Blocklist: 50,000 malicious domains (updated daily)      │
│                                                                 │
│  Rule Group 4: ddos-protection (Priority: 4, Capacity: 50)    │
│    - Type: Stateful                                            │
│    - Action: DROP                                              │
│    - Rule 1: DROP if > 100 connections/min from single IP     │
│                                                                 │
│  Default Action: PASS (allow by default, deny explicit)       │
└────────────────────────────────────────────────────────────────┘
```

### Firewall Administration

#### Task 1: Add Domain to Allowlist

**Scenario**: Application team needs to integrate with Salesforce

**Request**:
```
Ticket: NET-2025-0123
From: alex.kim@acmetech.com (API Team)
Subject: Add salesforce.com to API egress allowlist

We need to integrate with Salesforce APIs:
- api.salesforce.com (OAuth)
- login.salesforce.com (Authentication)
- acmetech.salesforce.com (Instance-specific)

Business justification: CRM integration for customer data sync
Compliance review: Approved (salesforce.com SOC 2 certified)
Expected traffic: 1,000 API calls/day, < 10 MB/day
```

**Admin Action** (Network Team):

1. **Review Request**:
   - Check business justification: ✅ Valid
   - Check compliance: ✅ SOC 2 certified vendor
   - Check existing rules: salesforce.com not in allowlist

2. **Update Terraform**:
   ```hcl
   # modules/network-firewall-microsegments/variables.tf
   variable "api_allowed_domains" {
     default = [
       ".amazonaws.com",
       ".stripe.com",
       ".twilio.com",
       ".sendgrid.com",
       ".salesforce.com",  # NEW
     ]
   }
   ```

3. **Apply Change**:
   ```bash
   cd modules/network-firewall-microsegments
   terraform plan  # Review changes
   terraform apply # Apply (takes 1-2 minutes)
   ```

4. **Verify**:
   ```bash
   # Test from API tier instance
   curl -v https://api.salesforce.com
   # Should succeed

   # Check firewall logs
   aws logs filter-log-events \
     --log-group-name /aws/networkfirewall/inspection-vpc \
     --filter-pattern "salesforce.com" \
     --start-time $(date -u +%s)000
   # Should show: PASS api.salesforce.com
   ```

5. **Update Ticket**:
   ```
   Status: Resolved
   Resolution: salesforce.com added to API egress allowlist
   Effective: 2025-10-31 15:30 UTC
   Monitoring: Firewall logs show successful connections
   ```

**Time to Complete**: 10-15 minutes (including review + testing)

#### Task 2: Block Malicious Domain (Emergency)

**Scenario**: Threat intelligence feed reports new malware C2 domain

**Alert**:
```
Severity: CRITICAL
Source: AWS GuardDuty / Threat Intel Feed
Domain: evil-c2-server.xyz
IOC: Known command & control server for ransomware
Action: IMMEDIATE BLOCK
```

**Admin Action** (Security Team):

1. **Verify Threat**:
   - Check multiple threat intel sources (VirusTotal, etc.)
   - Confirm: evil-c2-server.xyz is malicious ✅

2. **Emergency Block** (via AWS CLI):
   ```bash
   # Get current threat intel rule group
   aws network-firewall describe-rule-group \
     --rule-group-arn arn:aws:network-firewall:us-east-1:123456789012:stateful-rulegroup/threat-intel

   # Update rule group (add evil-c2-server.xyz to blocklist)
   # Uses AWS CLI for speed (Terraform takes longer)
   aws network-firewall update-rule-group \
     --rule-group-arn arn:aws:network-firewall:us-east-1:123456789012:stateful-rulegroup/threat-intel \
     --rules-source-list TargetTypes=HTTP_HOST,TLS_SNI,Targets=[...,"evil-c2-server.xyz"]

   # Effective immediately (< 10 seconds)
   ```

3. **Verify Block**:
   ```bash
   # Check firewall logs for any attempts to reach evil-c2-server.xyz
   aws logs filter-log-events \
     --log-group-name /aws/networkfirewall/inspection-vpc \
     --filter-pattern "evil-c2-server.xyz"

   # If found: Which instance(s) tried to connect?
   # Isolate compromised instances immediately
   ```

4. **Update Terraform** (make permanent):
   ```hcl
   variable "threat_intelligence_blocklist" {
     default = [
       "malware-example.com",
       "phishing-site.net",
       "c2-server.org",
       "evil-c2-server.xyz",  # NEW (incident SEC-2025-0042)
     ]
   }
   ```

5. **Notify Teams**:
   ```
   Slack: #security-incidents
   "🚨 CRITICAL: evil-c2-server.xyz blocked at firewall (ransomware C2)
   All traffic blocked as of 2025-10-31 16:45 UTC
   No instances found attempting connection (proactive block)
   Incident: SEC-2025-0042"
   ```

**Time to Complete**: < 5 minutes (emergency response)

#### Task 3: Increase Firewall Capacity (Scaling)

**Scenario**: Firewall approaching capacity due to business growth

**Alert**:
```
CloudWatch Alarm: firewall-capacity-high
Metric: AWS/NetworkFirewall/ProcessedBytes
Current: 8.5 TB/day (85% of 10 TB capacity)
Trend: +15% month-over-month
Action: Scale firewall capacity
```

**Admin Action** (Network Team):

1. **Analyze Traffic**:
   ```sql
   -- Athena query on VPC Flow Logs
   SELECT
     srcaddr,
     dstaddr,
     SUM(bytes) as total_bytes
   FROM vpc_flow_logs
   WHERE date >= CURRENT_DATE - INTERVAL '7' DAY
     AND action = 'ACCEPT'
   GROUP BY srcaddr, dstaddr
   ORDER BY total_bytes DESC
   LIMIT 100
   ```

   **Results**: API tier calling external APIs (Stripe, Salesforce) = 60% of traffic

2. **Evaluate Options**:

   **Option A**: Increase firewall capacity (simple but expensive)
   - Cost: +$395/month (10 Gbps → 20 Gbps)
   - Time: 5 minutes (terraform apply)
   - Impact: No downtime

   **Option B**: Implement PrivateLink for major SaaS providers (complex but cheaper)
   - Cost: +$7/month per endpoint (Stripe, Salesforce = $14/month)
   - Time: 2-3 hours (setup PrivateLink endpoints)
   - Impact: No downtime
   - **Saves**: Traffic bypasses firewall, no capacity increase needed

3. **Decision**: Option B (PrivateLink) - better long-term

4. **Implement**:
   ```hcl
   # Add Salesforce PrivateLink endpoint
   resource "aws_vpc_endpoint" "salesforce" {
     vpc_id              = aws_vpc.api.id
     service_name        = "com.amazonaws.vpce.us-east-1.vpce-svc-salesforce"
     vpc_endpoint_type   = "Interface"
     subnet_ids          = aws_subnet.private[*].id
     private_dns_enabled = true
   }

   # Application now uses private DNS:
   # OLD: https://api.salesforce.com (via NAT + firewall)
   # NEW: https://api.salesforce.com (via PrivateLink, no firewall)
   ```

5. **Verify**:
   ```bash
   # Check firewall capacity after PrivateLink deployment
   aws cloudwatch get-metric-statistics \
     --namespace AWS/NetworkFirewall \
     --metric-name ProcessedBytes \
     --dimensions Name=FirewallName,Value=inspection-vpc-firewall \
     --start-time 2025-10-31T00:00:00Z \
     --end-time 2025-10-31T23:59:59Z \
     --period 86400 \
     --statistics Sum

   # Result: 5.2 TB/day (was 8.5 TB/day) - 38% reduction
   # No capacity increase needed!
   ```

**Time to Complete**: 2-3 hours (PrivateLink setup + testing)
**Cost Savings**: $381/month ($395 firewall upgrade vs $14 PrivateLink)

---

_Continued in next message..._
