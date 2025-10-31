# AI Orchestrator - User Request Examples

This document provides real-world examples of infrastructure questions and requests that users can ask the AI orchestrator. The AI handles these requests autonomously without requiring manual JSON configuration files or admin intervention.

---

## Table of Contents

1. [Security Incidents & Threats](#security-incidents--threats)
2. [Scalability & Capacity](#scalability--capacity)
3. [B2B Vendor Access](#b2b-vendor-access)
4. [Firewall Configuration](#firewall-configuration)
5. [Failover & High Availability](#failover--high-availability)
6. [Multi-Domain Complex Requests](#multi-domain-complex-requests)
7. [Emergency Scenarios](#emergency-scenarios)

---

## Security Incidents & Threats

### Example 1: Suspicious Traffic Detection

**User Request:**
```
"I'm seeing unusual traffic from IP 203.0.113.45 trying to access our
production database. Can you investigate and block if necessary?"
```

**AI Response:**
```
✓ Analyzed VPC Flow Logs for IP 203.0.113.45
✓ Found 847 connection attempts to prod-pci RDS in last 15 minutes
✓ IP belongs to known botnet (Shodan scanner)
✓ No successful connections (blocked by security groups)

ACTION TAKEN (Auto-approved - Severity 7/10):
- Added IP 203.0.113.0/24 to Network Firewall blocklist
- Created CloudWatch alarm for this subnet
- Notified #security-alerts on Slack

PREVENTION:
- Recommend enabling GuardDuty for automated threat detection
- Consider implementing AWS WAF with rate limiting

Incident ID: SEC-2025-001847
Documentation: https://wiki.internal/incidents/SEC-2025-001847
```

### Example 2: Credential Leak Response

**User Request:**
```
"GitHub is showing that we accidentally committed AWS credentials to our
public repo 20 minutes ago. Emergency lockdown needed!"
```

**AI Response:**
```
EMERGENCY PROTOCOL ACTIVATED

✓ Identified leaked credentials: AKIAIOSFODNN7EXAMPLE
✓ Credentials belong to: prod-api-service-account
✓ Last used: 2 minutes ago (active threat!)

IMMEDIATE ACTIONS TAKEN (Auto-approved - Severity 10/10):
1. Revoked IAM credentials (completed in 3 seconds)
2. Created new credentials with rotation
3. Blocked all API calls from old credentials (Network Firewall)
4. Analyzed CloudTrail for unauthorized actions:
   - 14 S3 GetObject calls to prod-data-bucket
   - 2 RDS DescribeDBInstances calls
   - 0 destructive actions detected

5. Rotated all secrets in AWS Secrets Manager for affected services
6. Updated ECS task definitions with new credentials
7. Triggered rolling deployment of affected services

HUMAN REVIEW REQUIRED:
- Review S3 access logs for the 14 GetObject calls
- Determine if data breach notification is needed
- Consider rotating database passwords as precaution

Incident ID: SEC-2025-001848
Estimated recovery time: 8 minutes
Status: ✓ Contained, monitoring for 24 hours
```

### Example 3: DDoS Attack Mitigation

**User Request:**
```
"Our public ALB is getting hammered with traffic. Is this an attack?"
```

**AI Response:**
```
DDoS ATTACK DETECTED

✓ Analyzed ALB metrics (last 10 minutes):
  - Request rate: 847,000 req/sec (normal: 2,400 req/sec)
  - 352x increase
  - Source: 4,847 unique IPs across 23 countries
  - Pattern: HTTP GET flood targeting /api/search

MITIGATION IN PROGRESS (Auto-approved - Severity 9/10):

Phase 1 (Completed - 45 seconds):
- Enabled AWS Shield Advanced DDoS protection
- Activated CloudFront rate limiting (100 req/5min per IP)
- Added WAF rule: block requests without User-Agent

Phase 2 (In Progress - 2 minutes):
- Analyzing attack signatures with GuardDuty
- Identified 89% of traffic from Tor exit nodes
- Adding Tor IP ranges to Network Firewall blocklist

Phase 3 (Pending):
- Implement CAPTCHA challenge for suspicious requests
- Scale ALB capacity from 3 → 12 nodes

CURRENT STATUS:
- Malicious traffic: 847k → 34k req/sec (96% reduction)
- Legitimate traffic: flowing normally
- Application response time: 180ms → 95ms (improving)

Estimated time to full mitigation: 5 minutes
Cost of attack mitigation: ~$47 (Shield + WAF + scaling)
```

---

## Scalability & Capacity

### Example 4: Automatic Scaling Request

**User Request:**
```
"Our Black Friday sale starts in 3 days. Can you scale up our infrastructure
to handle 10x normal traffic?"
```

**AI Response:**
```
BLACK FRIDAY SCALING PLAN

Current Capacity Analysis:
- Normal traffic: 2,400 req/sec
- Target capacity: 24,000 req/sec (10x)
- Current resources: ALB (3 nodes), ECS (12 tasks), RDS (db.r5.large)

SCALING PLAN (Requires approval):

Infrastructure Changes:
1. Application Load Balancer
   - Scale from 3 → 18 nodes
   - Enable connection draining (300s)
   - Cost: +$432/day

2. ECS Service (prod-api)
   - Scale from 12 → 60 tasks
   - Increase CPU reservation: 2 vCPU → 4 vCPU per task
   - Enable auto-scaling (target: 70% CPU)
   - Cost: +$1,247/day

3. RDS Database
   - Upgrade: db.r5.large → db.r5.4xlarge
   - Create 3 read replicas (currently 1)
   - Enable Performance Insights
   - Cost: +$876/day

4. ElastiCache Redis
   - Scale from 2 → 6 nodes
   - Enable cluster mode
   - Cost: +$342/day

5. Network Firewall
   - Increase capacity: 10 TB/day → 40 TB/day
   - Add 2 additional AZs
   - Cost: +$510/day

Total Daily Cost: +$3,407 (for 7 days = $23,849)

Timeline:
- RDS upgrade: 15 minutes (minimal downtime)
- ECS scaling: immediate
- Network Firewall: 30 minutes
- Full readiness: 45 minutes

Would you like me to:
A) Execute this plan now
B) Schedule for 48 hours before sale (2025-11-28 00:00 UTC)
C) Modify the plan
```

**User Follow-up:**
```
"Option B - schedule it. Also add CloudFront in front of our ALB."
```

**AI Response:**
```
✓ Scheduled scaling for 2025-11-28 00:00 UTC
✓ Added CloudFront distribution to plan:
  - Origin: prod-alb.example.com
  - Edge locations: All (225 locations)
  - Cache policy: Optimized for dynamic content
  - Additional cost: +$890/day

Updated Total Cost: +$4,297/day for 7 days = $30,079
Expected ROI: $2.4M revenue (historical Black Friday)

SCHEDULED ACTIONS:
- 2025-11-27 22:00 UTC: Pre-warming (gradual scale-up)
- 2025-11-28 00:00 UTC: Full capacity deployment
- 2025-11-28 06:00 UTC: Validation tests
- 2025-12-05 00:00 UTC: Automatic scale-down

I'll send you a reminder 24 hours before execution.
Monitoring dashboard: https://cloudwatch.aws.amazon.com/dashboard/black-friday-2025
```

### Example 5: Cost Optimization

**User Request:**
```
"Our AWS bill went up 40% this month. What's going on and how do we fix it?"
```

**AI Response:**
```
COST ANALYSIS COMPLETE

Total Spend: $47,293 (previous: $33,847) - 39.7% increase

TOP COST DRIVERS:

1. Network Firewall: +$8,942 (65% of increase)
   - Traffic: 8.5 TB/day (80% utilization)
   - Root cause: New vendor B2B connections routing through firewall

   OPTIMIZATION:
   ✓ Implemented AWS PrivateLink for top 5 SaaS vendors:
     - Stripe API: 2.1 TB/day → PrivateLink (bypass firewall)
     - Salesforce: 0.8 TB/day → PrivateLink
     - Snowflake: 0.4 TB/day → PrivateLink

   Projected savings: $4,200/month
   Estimated traffic reduction: 38%

2. RDS Read Replicas: +$2,847
   - 3 replicas running 24/7
   - Analysis: Only needed during business hours (8am-6pm EST)

   OPTIMIZATION:
   ✓ Implemented replica scheduling:
     - Start: 7:30 AM EST (pre-warm)
     - Stop: 6:30 PM EST
     - Weekend: 1 replica only

   Projected savings: $1,680/month (59% reduction)

3. Unused EBS Volumes: +$1,284
   - Found 47 unattached EBS volumes (orphaned from terminated instances)
   - Total: 18.4 TB of unused storage

   ACTION TAKEN (Auto-approved):
   ✓ Created snapshots of all volumes
   ✓ Deleted unattached volumes older than 30 days
   ✓ Implemented automatic cleanup policy

   Immediate savings: $1,284/month

4. Over-provisioned NAT Gateways: +$892
   - 6 NAT Gateways across 3 AZs
   - Average utilization: 12%

   OPTIMIZATION:
   ✓ Reduced from 6 → 3 NAT Gateways (1 per AZ)
   ✓ Enabled NAT Gateway auto-scaling

   Projected savings: $446/month

TOTAL MONTHLY SAVINGS: $7,610 (16% reduction)
Estimated next month bill: $39,683

Would you like me to implement these optimizations?
```

---

## B2B Vendor Access

### Example 6: New Vendor Onboarding

**User Request:**
```
"We just signed a contract with DataVault Inc for backup services. They need
access to our S3 production-backups bucket. Can you set this up securely?"
```

**AI Response:**
```
B2B VENDOR ONBOARDING: DataVault Inc

SECURITY ANALYSIS:
✓ Verified company: DataVault Inc (datavault.io)
✓ SOC 2 Type II certified
✓ Industry: Cloud backup services
✓ Use case: Read/write access to S3 backups

PROPOSED CONFIGURATION:

1. Access Method: Cloudflare Tunnel (Zero Trust)
   - Hostname: datavault.tunnel.acmetech.com
   - Authentication: Email-based (datavault.io domain)
   - MFA: Required (Cloudflare Access)

2. S3 Bucket Policy (Least Privilege):
   ```json
   {
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::123456789012:role/b2b-datavault-role"
     },
     "Action": [
       "s3:GetObject",
       "s3:PutObject",
       "s3:ListBucket"
     ],
     "Resource": [
       "arn:aws:s3:::production-backups",
       "arn:aws:s3:::production-backups/*"
     ],
     "Condition": {
       "StringEquals": {
         "sts:ExternalId": "datavault-prod-2025-a8c9d2"
       },
       "IpAddress": {
         "aws:SourceIp": "10.250.10.0/24"
       }
     }
   }
   ```

3. Monitoring & Alerts:
   - CloudWatch alarm: S3 GetObject rate > 1000/min
   - VPC Flow Logs: All traffic logged to S3
   - CloudTrail: API call auditing
   - Retention: 90 days (compliance requirement)

4. Network Segmentation:
   - VPC: b2b-vendors (isolated from production)
   - Segment: prod-b2b-dmz
   - Network Firewall rules: S3 endpoints only (block all other traffic)

5. Vendor Access Portal:
   - URL: https://datavault.tunnel.acmetech.com
   - Credentials: IAM role with ExternalId
   - Connection guide: Auto-generated

ONBOARDING STEPS (8 minutes):

✓ Phase 1: Infrastructure (Auto-approved)
  - Created b2b-datavault-role IAM role
  - Created S3 bucket policy
  - Created Cloudflare Tunnel route
  - Created Network Firewall rules

✓ Phase 2: Testing (Auto-approved)
  - Verified S3 access from tunnel
  - Tested MFA authentication
  - Validated rate limiting (1000 requests/min)

→ Phase 3: Vendor Notification (Requires approval)
  - Send welcome email to: ops@datavault.io
  - Include: Connection guide, credentials, support contact

Would you like me to send the vendor notification email?

ESTIMATED COST:
- Cloudflare Tunnel: $5/month
- S3 API calls: ~$12/month (estimated)
- Network Firewall: $0 (existing capacity)
Total: ~$17/month
```

**User Follow-up:**
```
"Yes send the email. Also they need access to our PostgreSQL database
for backup verification."
```

**AI Response:**
```
✓ Email sent to ops@datavault.io with connection instructions

ADDITIONAL REQUEST: PostgreSQL Database Access

⚠️  SECURITY CONCERN DETECTED:
Database access for external vendors is HIGH RISK. Analyzing...

RISK ASSESSMENT:
- Database: prod-pci-postgres (CONTAINS PCI DATA)
- Compliance: PCI-DSS Level 1
- Current access: Internal only (prod-api segment)
- Proposed access: External vendor (B2B DMZ)

SECURE ALTERNATIVE (Recommended):

Instead of direct database access, implement:

1. RDS Snapshot Export to S3
   - Automated daily snapshot
   - Export to S3 bucket: production-db-exports
   - DataVault accesses snapshots (not live database)
   - Zero risk of data modification
   - PCI compliance maintained

2. If Real-Time Access Required:
   - Use RDS Proxy with IAM authentication
   - Create read-only replica in B2B DMZ
   - Replica contains MASKED PCI data (anonymized)
   - Network Firewall: PostgreSQL port 5432 only
   - Connection time-limited (4 hours max)
   - Require MFA re-authentication every hour

RECOMMENDATION: Option 1 (Snapshot Export)
- Meets backup verification requirements
- Zero security risk
- PCI compliant
- Cost: $8/month (S3 storage)

Would you like me to:
A) Implement snapshot export (recommended)
B) Set up read-only replica with masking
C) Discuss with security team first
```

### Example 7: Vendor Access Revocation

**User Request:**
```
"We terminated our contract with CloudOps Solutions. Remove all their access
immediately."
```

**AI Response:**
```
VENDOR OFFBOARDING: CloudOps Solutions

CURRENT ACCESS INVENTORY:
✓ Scanned all IAM roles, policies, and resources
✓ Found 8 access points:

1. Cloudflare Tunnel: cloudops.tunnel.acmetech.com
   - Status: ACTIVE
   - Last used: 2 hours ago
   - Authenticated users: 3 (mike.johnson@, lisa.rodriguez@, admin@)

2. IAM Role: b2b-cloudops-role
   - Status: ACTIVE
   - Permissions: RDS read-only, S3 read-only
   - AssumeRole calls: 847 (last 30 days)

3. S3 Bucket Policy: production-logs
   - Policy: Allows cloudops IAM role
   - Last access: 4 hours ago

4. RDS Proxy: cloudops-db-proxy
   - Database: prod-general-postgres
   - Connection pool: 2 active connections
   - Last query: 2 hours ago

5. Network Firewall: Allow rule for CloudOps
   - Rule: cloudops-db-access
   - Traffic: 847 MB (last 30 days)

6. Cloudflare Access Policy: cloudops-solutions.io domain
   - Users: 3 authorized emails
   - MFA sessions: 2 active

7. CloudWatch Log Group: /b2b/cloudops
   - Logs: 4.2 GB (last 30 days)
   - Retention: 90 days

8. VPC Flow Logs: cloudops traffic
   - Source: 10.250.11.0/24 (B2B DMZ)
   - Destination: prod-general segment

REVOCATION PLAN (IMMEDIATE):

✓ Phase 1: Disable Access (Completed - 12 seconds)
  1. Deleted Cloudflare Tunnel route
  2. Revoked IAM role (b2b-cloudops-role)
  3. Removed S3 bucket policy statement
  4. Deleted RDS Proxy connection
  5. Deleted Network Firewall allow rule
  6. Removed Cloudflare Access policy
  7. Terminated 2 active database connections

✓ Phase 2: Audit & Archive (Completed - 45 seconds)
  1. Exported CloudTrail logs (last 90 days)
  2. Exported VPC Flow Logs
  3. Created S3 archive: s3://audit-logs/cloudops-termination-2025-10-31/
  4. Generated access report (PDF)

→ Phase 3: Monitoring (In Progress - 24 hours)
  1. Watching for access attempts
  2. CloudWatch alarm: Alert on any cloudops@ email auth attempts
  3. GuardDuty: Monitor for unauthorized access

→ Phase 4: Data Retention (Scheduled)
  1. CloudWatch logs retained for 90 days (compliance)
  2. S3 audit archive retained for 7 years
  3. Scheduled deletion: 2032-10-31

VERIFICATION:
✓ Tested access from cloudops domain: ❌ DENIED (expected)
✓ Tested IAM AssumeRole: ❌ ACCESS DENIED (expected)
✓ Tested database connection: ❌ CONNECTION REFUSED (expected)

STATUS: ✅ ALL ACCESS REVOKED
Time to complete: 57 seconds
Access report: s3://audit-logs/cloudops-termination-2025-10-31/report.pdf

No active sessions remain. Monitoring for 24 hours for unauthorized attempts.
```

---

## Firewall Configuration

### Example 8: Allow New SaaS Provider

**User Request:**
```
"Our engineering team needs to access the new AI service from Anthropic for
code reviews. Can you allow api.anthropic.com?"
```

**AI Response:**
```
FIREWALL RULE REQUEST: Anthropic API

SECURITY ANALYSIS:
✓ Domain: api.anthropic.com
✓ Service: Claude API (AI assistant)
✓ Reputation: Legitimate (Anthropic PBC)
✓ SSL Certificate: Valid (issued by DigiCert)
✓ Use case: Code review automation

CURRENT FIREWALL STATUS:
❌ Blocked by default-deny policy
❌ No existing allow rule for anthropic.com

PROPOSED CONFIGURATION:

1. Network Firewall Rule (Domain Allowlist):
   ```
   Rule: allow-anthropic-api
   Protocol: HTTPS (443)
   Domain: .anthropic.com
   Action: PASS
   Priority: 100

   Allowed Subdomains:
   - api.anthropic.com (API endpoint)
   - console.anthropic.com (Web console)
   ```

2. Access Restrictions:
   - Source segments: prod-api, nonprod-dev, nonprod-test
   - Blocked segments: prod-pci, prod-data (data protection)
   - Rate limit: 10,000 requests/hour per application

3. Monitoring:
   - CloudWatch Logs: All API calls logged
   - Alert: Traffic > 50 GB/day (cost protection)
   - Alert: Unusual access patterns (security)

4. Data Loss Prevention (DLP):
   ⚠️  WARNING: AI services may process sensitive data

   RECOMMENDED SAFEGUARDS:
   - Block requests containing: SSN, credit card patterns
   - Implement AWS Macie scanning for S3 data
   - Require data anonymization before API calls
   - Add CloudFront with WAF for request filtering

IMPLEMENTATION (Auto-approved - Low risk):

✓ Created Network Firewall rule: allow-anthropic-api
✓ Updated domain allowlist: +anthropic.com
✓ Created CloudWatch alarms (traffic + cost)
✓ Added to firewall documentation

TESTING:
✓ Test from prod-api: ✅ ALLOWED (200 OK)
✓ Test from prod-pci: ❌ BLOCKED (expected)
✓ Test from nonprod-dev: ✅ ALLOWED (200 OK)

STATUS: ✅ ACTIVE
Effective immediately

USAGE TRACKING:
- Current traffic: 0 requests
- Estimated cost: ~$15/month (API calls)
- Review date: 2025-11-30 (30-day review)

Note: I've also added anthropic.com to your SaaS inventory for future
PrivateLink consideration if traffic increases.
```

### Example 9: Emergency Block

**User Request:**
```
"URGENT: Block all traffic to Russia and China immediately. We're seeing
attacks from those regions."
```

**AI Response:**
```
EMERGENCY GEOLOCATION BLOCK

⚠️  HIGH-IMPACT CHANGE DETECTED
This will block ALL traffic from Russia (RU) and China (CN)

IMPACT ANALYSIS (15 seconds):

Legitimate Traffic Analysis (Last 30 days):
- Russia: 47 requests (0.002% of total traffic)
  - 89% automated bots
  - 11% potential customers
- China: 1,284 requests (0.05% of total traffic)
  - 76% automated bots
  - 24% potential customers

Malicious Traffic (Last 24 hours):
- Russia: 34,847 requests (DDoS attack)
  - 98% from data centers (not residential)
  - Pattern: HTTP GET flood
- China: 8,923 requests (port scanning)
  - 100% from cloud providers
  - Pattern: Shodan/Masscan

RECOMMENDATION: Block data center IPs only (preserve legitimate traffic)

EMERGENCY BLOCK IMPLEMENTED (Auto-approved - Severity 9/10):

✓ Phase 1: Immediate Block (Completed - 8 seconds)
  1. AWS WAF: Geo-blocking rule created
     - Countries: RU, CN
     - Action: BLOCK
     - Response: 403 Forbidden

  2. Network Firewall: IP blocklist updated
     - Russia data center ranges: 847 subnets
     - China data center ranges: 2,193 subnets
     - Source: AWS Threat Intelligence feed

  3. CloudFront: Geo-restriction enabled
     - Blocked countries: RU, CN
     - Whitelist: All other countries

✓ Phase 2: Monitoring (Active)
  - CloudWatch alarm: Monitor for block evasion (VPN/proxy)
  - GuardDuty: Threat detection enabled
  - VPC Flow Logs: Analyzing blocked connection attempts

RESULTS (First 60 seconds):
- Blocked requests: 8,473 (from RU/CN)
- Attack traffic: 98% reduction
- Legitimate traffic lost: ~0.05% (24 requests/day)
- Application performance: Normal (120ms avg response)

STATUS: ✅ ATTACK MITIGATED

FOLLOW-UP ACTIONS:

1. Review Legitimate Traffic Loss:
   - 24 requests/day from China (potential customers)
   - Consider: Selective unblock for verified IPs
   - Alternative: CAPTCHA challenge instead of block

2. Long-term Strategy:
   - Implement rate limiting (preserve legitimate, block attacks)
   - Consider AWS Shield Advanced (automated DDoS protection)
   - Add Bot Management (distinguish humans from bots)

3. Estimated Duration:
   - Emergency block: Active indefinitely
   - Review date: 2025-11-07 (7 days)
   - Automatic unblock: Disabled (requires human approval)

Would you like me to:
A) Keep the full geo-block (current configuration)
B) Replace with CAPTCHA challenge for RU/CN (allow humans)
C) Implement rate limiting instead of block
```

### Example 10: Application-Specific Firewall

**User Request:**
```
"Our new payment processing service needs really tight firewall rules. It
should ONLY talk to Stripe API and our database. Nothing else."
```

**AI Response:**
```
MICROSEGMENTED FIREWALL: Payment Service

APPLICATION PROFILE:
- Name: payment-processor
- Environment: Production (PCI-DSS)
- Segment: prod-pci
- Instance: ECS Fargate (4 tasks)

ZERO TRUST CONFIGURATION:

Current State Analysis:
✓ Scanned existing security groups
✓ Found overly permissive rules:
  - Egress: 0.0.0.0/0 (ALL TRAFFIC) ⚠️  HIGH RISK
  - Ingress: 10.0.0.0/8 (entire VPC) ⚠️  MEDIUM RISK

PROPOSED CONFIGURATION (Least Privilege):

1. Security Group: payment-processor-sg

   INGRESS (WHO can connect TO payment service):
   ```hcl
   # ONLY API tier can initiate connections
   {
     from_port = 8443
     to_port = 8443
     protocol = "tcp"
     source_security_group = "prod-api-tier-sg"
     description = "API tier to payment processor (HTTPS)"
   }
   ```

   EGRESS (WHERE payment service can connect TO):
   ```hcl
   # Rule 1: Stripe API only
   {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     prefix_list_id = "pl-stripe-api"  # Managed prefix list
     description = "Payment processor to Stripe API"
   }

   # Rule 2: RDS Database only
   {
     from_port = 5432
     to_port = 5432
     protocol = "tcp"
     source_security_group = "prod-pci-database-sg"
     description = "Payment processor to PostgreSQL"
   }

   # Rule 3: Internal DNS only
   {
     from_port = 53
     to_port = 53
     protocol = "udp"
     cidr_blocks = ["10.0.0.2/32"]  # VPC DNS resolver
     description = "DNS resolution"
   }

   # NO OTHER EGRESS ALLOWED (implicit deny)
   ```

2. Network Firewall Rules (prod-pci segment):

   ```
   # Stateful rule: Allow Stripe API domains only
   pass tcp $HOME_NET any -> $EXTERNAL_NET 443 (
     msg:"Payment processor to Stripe API";
     flow:to_server,established;
     tls.sni; content:"api.stripe.com";
     sid:100001;
   )

   # Stateful rule: Block all other external domains
   drop tcp $HOME_NET any -> $EXTERNAL_NET 443 (
     msg:"Payment processor unauthorized HTTPS - BLOCKED";
     flow:to_server,established;
     sid:100002;
   )

   # Stateful rule: Alert on DNS queries (anomaly detection)
   alert udp any 53 -> any any (
     msg:"Payment processor DNS query";
     content:"|00 01 00 00 00 00 00 00|";
     sid:100003;
   )
   ```

3. Stripe API Managed Prefix List:
   ```
   Prefix List: pl-stripe-api
   Entries:
   - 54.187.174.169/32 (Stripe API endpoint 1)
   - 54.187.205.235/32 (Stripe API endpoint 2)
   - 54.187.216.72/32 (Stripe API endpoint 3)
   - 54.241.31.99/32 (Stripe API endpoint 4)
   - 54.241.31.102/32 (Stripe API endpoint 5)

   Auto-update: Enabled (AWS IP Ranges service)
   ```

4. Database Connection: RDS Proxy
   ```
   - Endpoint: payment-db-proxy.prod-pci.internal
   - Authentication: IAM (no passwords)
   - Connection pooling: Max 10 connections
   - Idle timeout: 5 minutes
   - Query logging: Enabled (CloudWatch)
   ```

IMPLEMENTATION (Requires approval - PCI environment):

Changes to be made:
1. Remove existing overly permissive security group rules
2. Create new microsegmented security groups
3. Update ECS task definition with new security groups
4. Create Network Firewall rules for prod-pci segment
5. Create Stripe API managed prefix list
6. Deploy RDS Proxy for database connections
7. Update IAM roles for RDS Proxy authentication

TESTING PLAN (Before production deployment):
1. Deploy to nonprod-test environment
2. Verify Stripe API connectivity
3. Verify database connectivity
4. Verify DNS resolution
5. Test blocked connections (should fail):
   - api.example.com (not Stripe) → ❌ BLOCKED
   - 8.8.8.8 (Google DNS) → ❌ BLOCKED
   - Internet websites → ❌ BLOCKED

ROLLBACK PLAN:
- Backup current security group rules
- Keep old security groups for 7 days
- One-click rollback available

PCI COMPLIANCE VERIFICATION:
✓ Requirement 1.2.1: Restrict inbound/outbound traffic - COMPLIANT
✓ Requirement 1.3.4: No direct routes between Internet and cardholder data - COMPLIANT
✓ Requirement 10.2.7: Log all access to payment data - COMPLIANT (RDS Proxy logs)

ESTIMATED DOWNTIME: Zero (rolling deployment)
RISK LEVEL: Medium (PCI environment, requires testing)

Would you like me to:
A) Deploy to nonprod-test first (recommended)
B) Schedule production deployment
C) Show me the security group comparison
```

---

## Failover & High Availability

### Example 11: Regional Failover Test

**User Request:**
```
"I want to test our disaster recovery plan. Can you simulate a us-east-1
region failure?"
```

**AI Response:**
```
DISASTER RECOVERY TEST: us-east-1 Region Failure

⚠️  THIS IS A DESTRUCTIVE TEST
This will simulate a complete us-east-1 region failure affecting production systems.

PRE-TEST CHECKLIST:

Current Architecture (us-east-1):
✓ Core Network: 12 attachments (prod + nonprod)
✓ Applications: 47 ECS services
✓ Databases: 8 RDS instances (Multi-AZ)
✓ Load Balancers: 12 ALBs
✓ Daily traffic: 2.4M requests
✓ Current health: 100% (all systems operational)

Failover Architecture (us-west-2):
✓ Core Network: Standby attachments (ready)
✓ Applications: 47 ECS services (scaled to 0, ready to scale)
✓ Databases: 8 RDS read replicas (replication lag: 2 seconds)
✓ Load Balancers: 12 ALBs (configured, no traffic)
✓ Route 53: Health checks configured (active-passive)

FAILOVER PLAN:

Phase 1: Trigger Failure Simulation (Manual)
- Modify Route 53 health check to fail us-east-1
- This will trigger automatic DNS failover

Phase 2: Automatic Failover (< 60 seconds)
1. Route 53 detects health check failure
2. DNS TTL expires (60 seconds)
3. Traffic routes to us-west-2 ALBs
4. CloudWatch alarm triggers Lambda function
5. Lambda promotes RDS read replicas to primary
6. Lambda scales ECS services from 0 → production capacity

Phase 3: Validation (Manual)
- Verify application accessibility
- Verify database connectivity
- Verify data consistency
- Performance testing

Phase 4: Restoration (Manual)
- Restore us-east-1 when ready
- Failback to primary region

SAFETY MEASURES:
✓ Test window: 2025-10-31 22:00-23:00 UTC (low traffic period)
✓ Customer notification: Status page updated
✓ Team availability: On-call engineers notified
✓ Rollback plan: Immediate DNS revert available
✓ Data backup: Snapshots taken (last 5 minutes)

EXPECTED BEHAVIOR:

Services During Failover:
- Website: 30-60 seconds downtime (DNS propagation)
- API: 30-60 seconds downtime (DNS propagation)
- Background jobs: Paused during failover, resume automatically
- Payments: Queued (Stripe idempotency), processed after failover
- User sessions: Preserved (DynamoDB global table)

Data Consistency:
- RDS replication lag: 2 seconds (acceptable)
- DynamoDB: Global table (automatic sync)
- S3: Multi-region replication (already synchronized)
- ElastiCache: Warmed after failover (5 minutes)

MONITORING:

Real-Time Dashboard:
- Route 53 health check status
- DNS query rates (per region)
- ALB target health (both regions)
- RDS replication lag
- Application error rates
- Customer-facing status page

Alerts:
- Slack: #incident-response channel
- PagerDuty: On-call engineers
- Email: Stakeholders list

ESTIMATED COSTS:
- Test execution: $0 (using existing resources)
- us-west-2 running during test: ~$120/hour
- Total test cost: ~$120 (1 hour test)

POST-TEST DELIVERABLES:
1. Failover timeline report (actual vs expected)
2. Performance comparison (us-east-1 vs us-west-2)
3. Lessons learned document
4. Updated runbook with improvements

RISK ASSESSMENT:
- Probability of test failure: 15% (DNS caching, application issues)
- Impact if test fails: Medium (can revert to us-east-1 immediately)
- Customer impact: Low (60 second outage during low-traffic period)
- Data loss risk: Zero (read replicas synchronized)

APPROVALS REQUIRED:
- Engineering Manager: ⏳ Pending
- CTO: ⏳ Pending
- Customer Success: ⏳ Pending (notify customers)

Would you like me to:
A) Request approvals and schedule the test
B) Run the test immediately (override approvals)
C) Show me the detailed technical runbook
D) Cancel the test
```

### Example 12: Database Failover

**User Request:**
```
"Our primary Postgres database in us-east-1a just went down. What's happening?"
```

**AI Response:**
```
DATABASE INCIDENT: prod-pci-postgres

INCIDENT DETECTED: 2025-10-31 14:23:47 UTC

✓ CloudWatch alarm triggered: RDS_Instance_Down
✓ Automatic response initiated
✓ Incident ID: DB-2025-001923

INCIDENT DETAILS:

Primary Database:
- Instance: prod-pci-postgres-primary
- AZ: us-east-1a
- Status: ❌ UNAVAILABLE
- Last heartbeat: 14:23:45 UTC (2 seconds ago)
- Failure reason: AZ-level outage (AWS event)

AWS Service Health Dashboard:
✓ Confirmed: us-east-1a partial outage
✓ Affected services: RDS, EC2
✓ AWS ETA: 30-45 minutes

AUTOMATIC FAILOVER (IN PROGRESS):

✓ Phase 1: Detection (Completed - 2 seconds)
  - RDS Multi-AZ detected primary failure
  - Health check failed 3 consecutive times
  - Automatic failover initiated

✓ Phase 2: Promote Standby (In Progress - 15 seconds elapsed)
  - Promoting standby in us-east-1b to primary
  - DNS update: prod-pci-postgres.xxxxx.us-east-1.rds.amazonaws.com
  - Expected completion: 30-45 seconds total

→ Phase 3: Validation (Pending)
  - Test database connectivity
  - Verify replication lag (should be 0)
  - Validate application connectivity

→ Phase 4: Monitoring (Pending)
  - Watch for connection errors
  - Monitor query performance
  - Verify data consistency

CURRENT STATUS:

Applications:
- payment-processor: ⏳ WAITING (connection pool retrying)
- api-service: ⏳ WAITING (connection pool retrying)
- background-workers: ⏳ PAUSED (graceful shutdown)

Connection Pools:
- Active connections: 0 (disconnected)
- Waiting queries: 47 (queued)
- Failed queries: 0 (thanks to connection retry logic)

Data Consistency:
✓ Last transaction: 14:23:45 UTC
✓ Replication lag: 0 seconds (before failure)
✓ No data loss detected

LIVE UPDATES (Streaming):

14:23:47 - Primary instance unhealthy
14:23:49 - Automatic failover initiated
14:23:52 - Standby instance promoting
14:24:01 - DNS update in progress
14:24:08 - New primary instance online
14:24:12 - Applications reconnecting...

✅ FAILOVER COMPLETE (Total time: 25 seconds)

POST-FAILOVER STATUS:

New Primary Database:
- Instance: prod-pci-postgres-standby (now primary)
- AZ: us-east-1b ✅ HEALTHY
- Status: ✅ AVAILABLE
- Connections: 47 (all reconnected)
- Query performance: Normal (avg 12ms)

Applications:
- payment-processor: ✅ HEALTHY (23/23 tasks connected)
- api-service: ✅ HEALTHY (18/18 tasks connected)
- background-workers: ✅ HEALTHY (resumed processing)

Data Verification:
✓ Last transaction before failover: Confirmed in new primary
✓ Transaction log: Consistent
✓ Replication: Re-establishing to new standby in us-east-1c
✓ Data loss: ZERO

Customer Impact:
- Requests failed during failover: 47 requests
- Duration: 25 seconds
- Automatic retry: 45 requests succeeded (96% recovery)
- Manual retry needed: 2 requests (payment transactions)

NEXT STEPS:

Immediate (Automated):
✓ Created new standby instance in us-east-1c
✓ Replication: Active (lag: 1 second, improving)
✓ Monitoring: Enhanced monitoring enabled (1 minute intervals)

Short-term (1 hour):
→ Full health check of new primary
→ Performance comparison (before vs after)
→ Verify all application connections
→ Review query logs for errors

Long-term (24 hours):
→ Root cause analysis (why us-east-1a failed)
→ Review AWS support ticket
→ Update runbook with learnings
→ Quarterly DR test scheduled

COST IMPACT:
- Additional standby instance: $0 (Multi-AZ included)
- Enhanced monitoring: $3/month
- Total impact: Minimal

STATUS: ✅ INCIDENT RESOLVED
Total downtime: 25 seconds
Data loss: ZERO
Customer impact: Minimal (96% automatic recovery)

Incident report will be generated in 1 hour.
Dashboard: https://cloudwatch.aws.amazon.com/dashboard/db-failover-2025-10-31
```

---

## Multi-Domain Complex Requests

### Example 13: End-to-End New Application Deployment

**User Request:**
```
"We're launching a new customer portal. It needs:
- Public-facing website (high traffic expected)
- API backend with database
- Redis for sessions
- Should be PCI compliant
- Need vendor access for our payment processor integration partner
- Must handle 50k concurrent users

Can you set all this up?"
```

**AI Response:**
```
NEW APPLICATION DEPLOYMENT: Customer Portal

ARCHITECTURE ANALYSIS:

Requirements Summary:
✓ Public website (Next.js/React assumed)
✓ API backend (REST/GraphQL)
✓ PostgreSQL database
✓ Redis session store
✓ PCI-DSS compliance required
✓ B2B vendor access (payment integration)
✓ Capacity: 50,000 concurrent users
✓ Expected traffic: ~125,000 requests/min (2,100 req/sec)

PROPOSED ARCHITECTURE:

1. Network Segmentation
   ```
   ┌─────────────────────────────────────────────────┐
   │  Internet Gateway                                │
   └──────────────┬──────────────────────────────────┘
                  │
   ┌──────────────▼──────────────────────────────────┐
   │  CloudFront CDN + WAF                            │
   │  - Rate limiting: 1000 req/min per IP            │
   │  - DDoS protection (Shield Standard)             │
   │  - Edge locations: 225 globally                  │
   └──────────────┬──────────────────────────────────┘
                  │
   ┌──────────────▼──────────────────────────────────┐
   │  Application Load Balancer                       │
   │  - Segment: prod-pci                             │
   │  - SSL/TLS termination (ACM certificate)         │
   │  - Health checks: /health (30s interval)         │
   └──────────────┬──────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
   ┌────▼────┐         ┌────▼────┐
   │ Web Tier│         │ API Tier│
   │ ECS     │────────▶│ ECS     │
   │ 30 tasks│         │ 20 tasks│
   └─────────┘         └────┬────┘
                            │
                   ┌────────┴────────┐
                   │                 │
              ┌────▼────┐       ┌────▼────┐
              │Database │       │ Redis   │
              │RDS Proxy│       │Cluster  │
              │         │       │6 nodes  │
              └────┬────┘       └─────────┘
                   │
            ┌──────▼──────┐
            │  PostgreSQL  │
            │  Multi-AZ    │
            │db.r5.2xlarge │
            └──────────────┘
   ```

2. Infrastructure Components

   **Compute (ECS Fargate):**
   - Web tier: 30 tasks × 2 vCPU = 60 vCPU
   - API tier: 20 tasks × 4 vCPU = 80 vCPU
   - Auto-scaling: 50% CPU target
   - Total: 140 vCPU, 280 GB RAM

   **Database (RDS PostgreSQL):**
   - Instance: db.r5.2xlarge (8 vCPU, 64 GB RAM)
   - Multi-AZ: Enabled (automatic failover)
   - Storage: 500 GB gp3 (12,000 IOPS)
   - Read replicas: 2 (for reporting/analytics)
   - Backup: Daily snapshots, 30-day retention
   - Encryption: AES-256 (at rest + in transit)

   **Cache (ElastiCache Redis):**
   - Node type: cache.r5.large
   - Nodes: 6 (across 3 AZs)
   - Cluster mode: Enabled (sharding)
   - Memory: 384 GB total
   - Estimated sessions: 50,000 concurrent users

   **Load Balancer:**
   - Type: Application Load Balancer
   - Capacity: 12 LCUs (load balancer units)
   - Target groups: Web tier, API tier
   - Health checks: HTTP /health (5 sec timeout)

   **CDN (CloudFront):**
   - Origins: ALB (dynamic), S3 (static assets)
   - Cache behaviors:
     - Static assets: 24 hour TTL
     - API responses: No cache
     - Web pages: 5 minute TTL
   - SSL certificate: ACM (auto-renewed)

3. PCI Compliance Configuration

   **Network Security:**
   - Segment: prod-pci (isolated from other workloads)
   - Security groups: 3-tier (ALB → Web → API → Database)
   - Network Firewall: Stateful rules (allow Stripe, block all other egress)
   - VPC Flow Logs: All traffic logged (90-day retention)

   **Data Protection:**
   - Database encryption: AES-256 (KMS managed)
   - Secrets management: AWS Secrets Manager
   - IAM authentication: RDS Proxy with IAM
   - No database passwords in code

   **Compliance Monitoring:**
   - AWS Config: PCI-DSS conformance pack
   - GuardDuty: Threat detection
   - CloudTrail: API audit logs (7-year retention)
   - Security Hub: Centralized compliance dashboard

   **Access Control:**
   - MFA required: All admin access
   - Session timeout: 15 minutes (idle)
   - Password policy: 12+ chars, complexity required
   - Least privilege: IAM roles with minimal permissions

4. B2B Vendor Access (Payment Integration Partner)

   **Cloudflare Tunnel:**
   - Hostname: payment-partner.tunnel.acmetech.com
   - Access: API tier only (read-only database via RDS Proxy)
   - Authentication: SSO (partner domain email)
   - MFA: Required (Cloudflare Access)

   **API Endpoint for Vendor:**
   ```
   POST https://payment-partner.tunnel.acmetech.com/api/v1/process-payment

   Authentication: Bearer token (IAM role with ExternalId)
   Rate limit: 1000 requests/minute
   Allowed methods: POST, GET (no DELETE/PUT)
   ```

   **Security:**
   - Separate IAM role: b2b-payment-partner-role
   - ExternalId: payment-partner-prod-2025-<random>
   - VPC: b2b-vendors (isolated)
   - Network Firewall: Allow API tier only

5. Monitoring & Alerts

   **CloudWatch Alarms:**
   - ECS CPU > 70% → Auto-scale up
   - ECS CPU < 30% → Auto-scale down
   - ALB 5xx errors > 1% → PagerDuty alert
   - RDS connections > 90% → Alert + scale read replicas
   - Redis memory > 80% → Alert + scale cluster
   - API latency > 500ms → Alert

   **Dashboards:**
   - Application performance: Response times, error rates
   - Infrastructure health: CPU, memory, disk, network
   - Security: WAF blocks, firewall drops, failed auth attempts
   - Cost: Daily spend by service

IMPLEMENTATION PLAN:

Phase 1: Infrastructure (30 minutes)
✓ Create VPC attachments in prod-pci segment
✓ Deploy RDS PostgreSQL database
✓ Deploy ElastiCache Redis cluster
✓ Create RDS Proxy
✓ Create ALB with target groups
✓ Configure security groups (3-tier)

Phase 2: Application Deployment (20 minutes)
✓ Build Docker images (Web + API)
✓ Push to ECR (Elastic Container Registry)
✓ Create ECS task definitions
✓ Deploy ECS services (Web tier: 30 tasks, API tier: 20 tasks)
✓ Configure auto-scaling policies

Phase 3: CDN & DNS (15 minutes)
✓ Create CloudFront distribution
✓ Configure SSL certificate (ACM)
✓ Create Route 53 records:
  - portal.acmetech.com → CloudFront
  - api.portal.acmetech.com → ALB

Phase 4: B2B Vendor Access (10 minutes)
✓ Create Cloudflare Tunnel
✓ Create IAM role for payment partner
✓ Configure Network Firewall rules
✓ Send onboarding email to partner

Phase 5: Monitoring & Compliance (15 minutes)
✓ Enable AWS Config (PCI-DSS pack)
✓ Enable GuardDuty
✓ Create CloudWatch dashboards
✓ Configure alarms and notifications
✓ Enable VPC Flow Logs

Phase 6: Testing & Validation (30 minutes)
✓ Load testing: Verify 50k concurrent users
✓ Security testing: Penetration test (automated)
✓ Failover testing: Simulate AZ failure
✓ Vendor access testing: Test payment partner connection

Total Implementation Time: ~2 hours

COST ESTIMATE:

Monthly Recurring Costs:
- ECS Fargate (Web + API): $1,247/month
- RDS PostgreSQL (Multi-AZ): $876/month
- ElastiCache Redis (6 nodes): $684/month
- Application Load Balancer: $43/month
- CloudFront CDN: $420/month (estimated traffic)
- VPC (NAT Gateway, endpoints): $96/month
- Network Firewall: $510/month
- Monitoring (CloudWatch, logs): $87/month
- B2B Cloudflare Tunnel: $5/month
- Data transfer: ~$340/month

Total: ~$4,308/month

One-Time Costs:
- SSL certificate: $0 (ACM free)
- Load testing: $50 (temporary infrastructure)
- Security testing: $200 (automated scan)

CAPACITY VALIDATION:

50,000 Concurrent Users:
- Expected RPS: 2,100 requests/second
- Web tier capacity: 3,000 RPS (30 tasks × 100 RPS/task)
- API tier capacity: 2,000 RPS (20 tasks × 100 RPS/task)
- Database capacity: 5,000 connections (RDS Proxy pooling)
- Redis capacity: 384 GB (50k sessions × ~7 MB/session)

Headroom: 30-40% spare capacity for traffic spikes

SECURITY VALIDATION:

PCI-DSS Requirements:
✓ Requirement 1: Firewall configuration (Network Firewall + Security Groups)
✓ Requirement 2: No default passwords (IAM + Secrets Manager)
✓ Requirement 3: Protect stored data (KMS encryption)
✓ Requirement 4: Encrypt transmission (TLS 1.3)
✓ Requirement 5: Anti-virus (GuardDuty)
✓ Requirement 6: Secure development (code review + static analysis)
✓ Requirement 7: Restrict access (least privilege IAM)
✓ Requirement 8: Unique IDs (IAM users + MFA)
✓ Requirement 9: Physical access (AWS responsibility)
✓ Requirement 10: Track access (CloudTrail + VPC Flow Logs)
✓ Requirement 11: Security testing (automated scans)
✓ Requirement 12: Security policy (documented)

STATUS: ✅ PCI-DSS COMPLIANT

APPROVAL REQUIRED:

This is a HIGH-IMPACT deployment requiring:
- Budget approval: $4,308/month ongoing cost
- Security review: PCI-DSS compliance verification
- Architecture review: Engineering manager approval
- Vendor contracts: Payment partner NDA + contract

Would you like me to:
A) Create detailed Terraform configuration for review
B) Deploy to nonprod-staging for testing first (recommended)
C) Request approvals and schedule production deployment
D) Show me alternative architectures (lower cost options)
```

### Example 14: Security + Scalability + Cost Optimization

**User Request:**
```
"Our application is growing fast but we're burning money. Can you review our
entire infrastructure and optimize for security, performance, AND cost?"
```

**AI Response:**
```
COMPREHENSIVE INFRASTRUCTURE REVIEW

ANALYSIS COMPLETE (Scanned 847 resources across 4 AWS accounts)

---

## EXECUTIVE SUMMARY

Current State:
- Monthly cost: $47,293
- Security score: 72/100 (medium risk)
- Performance: 95th percentile latency: 450ms (target: <200ms)
- Availability: 99.89% (target: 99.95%)

Optimized State:
- Projected monthly cost: $31,847 (33% reduction = $15,446/month saved)
- Security score: 94/100 (low risk)
- Performance: 95th percentile latency: 180ms (20% improvement)
- Availability: 99.97% (improved)

**Total Annual Savings: $185,352**

---

## SECURITY FINDINGS & FIXES

### Critical (Fix immediately)

**Finding 1: Overly Permissive Security Groups**
```
Location: prod-api-sg (sg-0a1b2c3d4e5f6)
Risk: HIGH
Issue: Egress rule allows 0.0.0.0/0 (entire Internet)

Current Rule:
{
  "Type": "egress",
  "Protocol": "-1",  # ALL protocols
  "CidrBlocks": ["0.0.0.0/0"]  # Entire Internet
}

Impact: API servers can connect anywhere (data exfiltration risk)
```

**Fix (Auto-approved):**
```hcl
# Replace with least-privilege rules
egress {
  # Allow only necessary destinations
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = [
    "10.0.0.0/8"  # Internal VPC only
  ]
}

egress {
  # Stripe API (managed prefix list)
  from_port = 443
  to_port = 443
  protocol = "tcp"
  prefix_list_ids = ["pl-stripe-api"]
}

# Database connection
egress {
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  security_groups = [aws_security_group.database.id]
}
```

✓ Applied to 12 security groups
✓ Security score: 72 → 81 (+9 points)

**Finding 2: Unencrypted S3 Buckets**
```
Location: prod-user-uploads (s3://prod-user-uploads-acmetech)
Risk: HIGH
Issue: Server-side encryption NOT enabled
```

**Fix (Auto-approved):**
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

✓ Applied to 8 S3 buckets
✓ Security score: 81 → 87 (+6 points)

**Finding 3: IAM Users with Access Keys (Should use IAM Roles)**
```
Location: 23 IAM users with long-lived access keys
Risk: MEDIUM
Issue: Access keys can be leaked (prefer temporary credentials)
Oldest key: 847 days old (user: john.doe@acmetech.com)
```

**Fix (Requires approval - affects 23 users):**
```
Migration Plan:
1. Create IAM roles for each use case
2. Update applications to use IAM roles (ECS task roles)
3. Rotate access keys → temporary credentials (STS)
4. Delete access keys after 30-day grace period

Timeline: 2 weeks
User training: Required
Documentation: Will be provided
```

✓ Security score: 87 → 94 (+7 points)

---

## COST OPTIMIZATION FINDINGS

### High-Impact Savings

**Optimization 1: Unused Resources**
```
Found: 47 resources not used in 30+ days
Total waste: $4,847/month
```

Breakdown:
- 18 EBS volumes (unattached): $1,284/month
  - Action: Create snapshots, delete volumes

- 12 Elastic IPs (unassociated): $43/month
  - Action: Release IPs

- 5 NAT Gateways (idle): $225/month
  - Usage: <1 GB/month (could use single NAT Gateway)
  - Action: Consolidate to 3 NAT Gateways

- 8 RDS snapshots (manual, old): $342/month
  - Age: 120+ days old
  - Action: Delete (automated snapshots exist)

- 4 Load Balancers (no targets): $172/month
  - Action: Delete unused ALBs

**Total Savings: $4,847/month** ✓ Auto-approved (backups created)

**Optimization 2: Right-Sizing Instances**
```
Found: 23 over-provisioned instances
Total waste: $3,247/month
```

Example:
```
Instance: prod-api-service (ECS Fargate)
Current: 4 vCPU, 8 GB RAM
Average usage: CPU 18%, Memory 32%
Recommendation: 2 vCPU, 4 GB RAM (50% cost reduction)

Instance: prod-database (RDS)
Current: db.r5.2xlarge (8 vCPU, 64 GB)
Average usage: CPU 23%, Memory 41%
Recommendation: db.r5.xlarge (4 vCPU, 32 GB)
Savings: $438/month (50% reduction)
```

✓ Right-sized 23 instances
**Total Savings: $3,247/month**

**Optimization 3: Reserved Instances & Savings Plans**
```
Current: 100% On-Demand pricing
Opportunity: 3-year Reserved Instances (RI) for stable workloads
```

Analysis:
- RDS databases: Running 24/7 for 2+ years (stable)
- ECS Fargate: Baseline capacity stable (peak varies)

Recommendation:
- RDS Reserved Instances: $7,200/year (vs $10,512 on-demand)
  - Savings: $3,312/year = $276/month

- Fargate Savings Plans: $14,400/year (vs $18,720 on-demand)
  - Savings: $4,320/year = $360/month

**Total Savings: $636/month** (after 1-year commitment)

**Optimization 4: S3 Lifecycle Policies**
```
Found: 4.2 TB of S3 data in Standard storage class
Age analysis: 78% of objects >90 days old (infrequently accessed)
Current cost: $96/TB/month = $403/month
```

Recommendation:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id = "archive-old-logs"
    status = "Enabled"

    transition {
      days = 30
      storage_class = "STANDARD_IA"  # Infrequent Access
    }

    transition {
      days = 90
      storage_class = "GLACIER_IR"  # Glacier Instant Retrieval
    }

    expiration {
      days = 365  # Delete after 1 year
    }
  }
}
```

**Savings:**
- 30-90 days: Standard → Standard-IA ($0.0125/GB vs $0.023/GB) = 46% savings
- 90+ days: Standard-IA → Glacier IR ($0.004/GB vs $0.0125/GB) = 68% savings

**Total Savings: $1,847/month**

**Optimization 5: CloudFront Cache Hit Ratio**
```
Current cache hit ratio: 67% (target: 90%+)
Unnecessary origin requests: 33% (could be cached)
Cost: Data transfer from ALB to CloudFront: $420/month
```

Recommendation:
```
# Optimize cache behaviors
Cache-Control headers: max-age=3600 (static assets)
Query string forwarding: Disabled (unless required)
Cookie forwarding: Only necessary cookies

# Add Lambda@Edge for dynamic content caching
Response header modification: Add Cache-Control headers
```

**Potential Savings: $869/month** (reduce origin requests by 60%)

---

## PERFORMANCE IMPROVEMENTS

### Finding 1: Database Query Optimization

**Issue:** Slow queries detected
```
Query: SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC
Execution time: 847ms (target: <100ms)
Frequency: 23,000 queries/day
Impact: High (user-facing)
```

**Fix:**
```sql
-- Add missing index
CREATE INDEX idx_orders_user_created
ON orders(user_id, created_at DESC);

-- Optimize query (don't SELECT *)
SELECT id, order_number, total, status, created_at
FROM orders
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 50;
```

✓ Applied 8 missing indexes
✓ Reduced query time: 847ms → 23ms (97% improvement)

### Finding 2: N+1 Query Problem

**Issue:** API endpoint /users/{id}/orders makes 47 database queries
```
Request trace:
1. SELECT * FROM users WHERE id = ?           (1 query)
2. SELECT * FROM orders WHERE user_id = ?     (1 query)
3. For each order:
   SELECT * FROM order_items WHERE order_id = ?  (45 queries)

Total: 47 queries per API call
```

**Fix:** Use eager loading
```python
# Before (N+1 problem)
user = User.query.get(user_id)
orders = Order.query.filter_by(user_id=user_id).all()
for order in orders:
    items = OrderItem.query.filter_by(order_id=order.id).all()

# After (eager loading)
user = User.query.get(user_id)
orders = Order.query.filter_by(user_id=user_id) \
    .options(joinedload(Order.items)) \
    .all()
# Only 2 queries total (1 for orders, 1 for all items)
```

✓ Reduced API latency: 450ms → 180ms (60% improvement)

### Finding 3: Redis Cache Misses

**Issue:** Redis cache hit ratio: 67% (target: 95%+)
```
Cache misses: 33% of requests hit database
Root cause: Cache TTL too short (60 seconds)
```

**Fix:**
```python
# Increase cache TTL based on data change frequency
redis.setex(
    f"user:{user_id}",
    3600,  # 1 hour (was 60 seconds)
    json.dumps(user_data)
)

# Add cache warming for popular data
@celery.task
def warm_cache():
    popular_users = get_popular_user_ids()  # Top 1000 users
    for user_id in popular_users:
        cache_user_data(user_id)
```

✓ Cache hit ratio: 67% → 94% (reduces database load by 27%)

---

## AVAILABILITY IMPROVEMENTS

### Finding 1: Single Point of Failure

**Issue:** NAT Gateway in single AZ (us-east-1a)
```
Risk: If us-east-1a fails, all outbound traffic blocked
Frequency: 2 outages in past 12 months
Impact: HIGH (affects all applications)
```

**Fix:**
```hcl
# Deploy NAT Gateway in each AZ
resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id
}

resource "aws_nat_gateway" "az3" {
  allocation_id = aws_eip.nat_az3.id
  subnet_id     = aws_subnet.public_az3.id
}

# Update route tables (each private subnet routes to NAT in same AZ)
```

✓ Availability: 99.89% → 99.97% (reduces outages by 80%)
✓ Cost: +$90/month (worth it for improved reliability)

### Finding 2: No Auto-Scaling for Database

**Issue:** RDS instance fixed size (no auto-scaling for traffic spikes)
```
Peak traffic: 5x normal (during business hours)
Risk: Database connection exhaustion
```

**Fix:**
```hcl
# Enable RDS Proxy with auto-scaling
resource "aws_db_proxy" "app" {
  name                   = "prod-app-proxy"
  engine_family         = "POSTGRESQL"
  auth {
    iam_auth = "REQUIRED"
  }

  # Auto-scale connection pool
  require_tls = true

  # Distribute connections across read replicas
  target_db_instance_identifier = aws_db_instance.primary.id
}

# Add read replicas for scale-out
resource "aws_db_instance" "replica" {
  count                  = 2
  replicate_source_db    = aws_db_instance.primary.id
  instance_class         = "db.r5.large"
  publicly_accessible    = false
  auto_minor_version_upgrade = true
}
```

✓ Database connection capacity: 100 → 1,000 connections
✓ Read query offloading: 60% of queries → read replicas

---

## IMPLEMENTATION PLAN

### Phase 1: Quick Wins (0 downtime, high ROI)
**Duration: 24 hours**
**Savings: $6,694/month**

✓ Delete unused resources (EBS, EIPs, old snapshots)
✓ Apply S3 lifecycle policies
✓ Fix security group overly permissive rules
✓ Enable S3 encryption
✓ Add database indexes

**Status: ✅ AUTO-APPROVED & DEPLOYED**

### Phase 2: Application Changes (requires code deploy)
**Duration: 1 week**
**Savings: $3,247/month**
**Performance: 60% latency reduction**

→ Right-size ECS tasks and RDS instances
→ Fix N+1 queries in application code
→ Optimize Redis caching
→ Add Lambda@Edge for CloudFront
→ Deploy read replicas + RDS Proxy

**Status: ⏳ PENDING APPROVAL**
- Requires: Code review, staging deployment, load testing
- Risk: LOW (rolling deployment, easy rollback)

### Phase 3: Long-term Commitments (requires budget approval)
**Duration: Immediate (1-click purchase)**
**Savings: $636/month (after commitment)**

→ Purchase Reserved Instances (3-year commitment)
→ Purchase Fargate Savings Plans (1-year commitment)

**Status: ⏳ PENDING CFO APPROVAL**
- Upfront cost: $21,600 (1-year prepaid Savings Plan)
- ROI: 20% savings over on-demand
- Break-even: 12 months

### Phase 4: Architecture Changes (requires planning)
**Duration: 2 weeks**
**Savings: $869/month**
**Availability: +0.08%**

→ Deploy NAT Gateways in all AZs
→ Implement multi-region failover (optional)
→ Add Lambda@Edge caching
→ Migrate IAM users → IAM roles

**Status: ⏳ PENDING ARCHITECTURE REVIEW**
- Requires: Engineering manager approval, runbook updates
- Risk: MEDIUM (infrastructure changes)

---

## SUMMARY

**Total Monthly Savings: $15,446**
**Total Annual Savings: $185,352**

**Security Improvements:**
- Score: 72 → 94 (+22 points)
- Critical issues resolved: 3
- Compliance: PCI-DSS gaps closed

**Performance Improvements:**
- API latency: 450ms → 180ms (60% faster)
- Database queries: 97% faster (with indexes)
- Cache hit ratio: 67% → 94% (27% more cache hits)

**Availability Improvements:**
- Uptime: 99.89% → 99.97% (+0.08%)
- Single points of failure: 3 → 0
- Failover time: 45 seconds → 25 seconds

**Implementation Timeline:**
- Phase 1 (quick wins): ✅ DEPLOYED (24 hours)
- Phase 2 (app changes): 1 week
- Phase 3 (commitments): Immediate (pending CFO)
- Phase 4 (architecture): 2 weeks

**Approval Required:**
- [ ] Engineering Manager: Phase 2 & 4 code/architecture changes
- [ ] CFO: Phase 3 Reserved Instance purchases
- [ ] CISO: Security changes (IAM migration)

Would you like me to:
A) Proceed with Phase 2 (deploy to staging for testing)
B) Generate detailed cost breakdown for CFO
C) Create security compliance report for CISO
D) Show me the detailed Terraform changes
```

---

## Emergency Scenarios

### Example 15: Data Breach Response

**User Request:**
```
"EMERGENCY: We found malware on one of our production servers. Forensics team
needs the instance isolated but preserved for investigation."
```

**AI Response:**
```
SECURITY INCIDENT: Malware Detection

EMERGENCY PROTOCOL ACTIVATED

Incident ID: SEC-2025-CRITICAL-001999
Severity: 10/10 (CRITICAL)
Response: IMMEDIATE ISOLATION

---

AFFECTED RESOURCE:

Instance Details:
- Instance ID: i-0a1b2c3d4e5f6g7h8
- Name: prod-api-worker-23
- Segment: prod-api
- IP: 10.100.5.47
- Role: Background job processor
- Last activity: 3 minutes ago

Current State:
- Status: Running
- Active connections: 12
- Outbound traffic: 847 MB/hour (ABNORMAL - usually 12 MB/hour)
- Destinations: Unknown IPs in Russia, China (SUSPICIOUS)

---

IMMEDIATE ACTIONS TAKEN (Auto-approved - 18 seconds):

✓ Step 1: NETWORK ISOLATION (Completed - 3 seconds)
  - Replaced security group with forensics-isolation-sg:
    - Ingress: DENY ALL
    - Egress: DENY ALL
  - Blocked at Network Firewall
  - Terminated active connections (12 connections dropped)

✓ Step 2: PRESERVE EVIDENCE (Completed - 8 seconds)
  - Created EBS snapshot: snap-0x1y2z3a4b5c6d7e8
  - Created AMI: ami-incident-001999-forensics
  - Enabled termination protection
  - Disabled auto-scaling (prevent replacement)
  - Tagged: forensics-do-not-delete

✓ Step 3: MEMORY CAPTURE (Completed - 7 seconds)
  - Created memory dump via SSM: /var/forensics/memory-dump-001999.raw
  - Copied to S3: s3://security-forensics/incident-001999/memory.raw
  - Size: 16 GB (complete RAM image)

✓ Step 4: LOG PRESERVATION (Completed - 5 seconds)
  - Exported CloudWatch logs (last 7 days)
  - Exported VPC Flow Logs (last 7 days)
  - Exported CloudTrail (last 90 days)
  - Location: s3://security-forensics/incident-001999/logs/

---

MALWARE ANALYSIS (Initial):

Suspicious Indicators:
1. Outbound connections to known C2 servers:
   - 203.0.113.89 (Russia) - Confirmed botnet controller
   - 198.51.100.42 (China) - Known malware staging server

2. Modified system files:
   - /usr/bin/systemd-networkd (modified 2 hours ago)
   - /etc/cron.d/system-update (created 2 hours ago - SUSPICIOUS)
   - /tmp/.hidden-mining (Bitcoin mining executable)

3. Unusual processes:
   - PID 8473: /tmp/.hidden-mining (CPU 95% - CRYPTOCURRENCY MINING)
   - PID 8492: /usr/bin/systemd-networkd (network backdoor)

4. Data exfiltration detected:
   - 3.2 GB uploaded to 203.0.113.89 (last 2 hours)
   - File types: Database dumps, application logs, environment variables

⚠️  **CRITICAL: Database credentials may be compromised**

---

CONTAINMENT STATUS:

✅ Instance isolated (no network access)
✅ Evidence preserved (snapshots, memory, logs)
✅ Malware activity stopped (no outbound connections)
✅ Forensics team notified (Slack #security-incidents)

---

IMPACT ASSESSMENT:

Affected Systems:
- Direct: 1 instance (prod-api-worker-23)
- Potential: 47 instances in prod-api segment (same IAM role)

Compromised Credentials (HIGH PRIORITY):
- IAM role: prod-api-worker-role
  - Permissions: S3 read/write, RDS connect, Secrets Manager read
  - Last used: 3 minutes ago (by malware)
  - Credential exposure: HIGH RISK

- Database credentials: prod-app-postgres
  - Username: api_user
  - Password: Stored in Secrets Manager (malware may have accessed)
  - Last query: 2 hours ago (malware activity)

- API keys: Stripe, Anthropic, AWS
  - Location: Environment variables (malware accessed)
  - Exposure: CONFIRMED (found in exfiltrated data)

Data Exposure:
- Database dumps: 3.2 GB uploaded (contains customer data)
- Compliance: PCI-DSS breach reporting required (cardholder data)
- GDPR: Notification required (EU customer data)
- Timeline: 72 hours to notify regulators

---

AUTOMATED RESPONSE ACTIONS:

✓ Credential Rotation (Completed - 45 seconds)
  1. Revoked IAM role credentials (all 47 instances)
  2. Rotated database password (Secrets Manager)
  3. Revoked Stripe API key (new key generated)
  4. Revoked Anthropic API key (new key generated)
  5. Rotated AWS access keys (all related roles)
  6. Forced re-authentication (all user sessions)

✓ Lateral Movement Prevention (Completed - 30 seconds)
  1. Isolated entire prod-api segment (Network Firewall)
  2. Blocked known malicious IPs (WAF + Network Firewall)
  3. Enabled GuardDuty threat detection (continuous monitoring)
  4. Scan all 47 instances for malware (running now)

✓ Backup Verification (Completed - 2 minutes)
  1. Latest clean backup: 4 hours ago (before infection)
  2. Backup integrity: VERIFIED (no malware detected)
  3. Recovery point: 2025-10-31 10:00 UTC
  4. Data loss: ~4 hours of transactions (minimal)

---

RECOVERY PLAN:

Phase 1: Forensics (4 hours)
→ Security team investigates isolated instance
→ Malware reverse engineering
→ Determine initial infection vector
→ Identify all compromised systems

Phase 2: Clean Rebuild (2 hours)
→ Terminate infected instance (after forensics complete)
→ Deploy new instance from clean AMI
→ Apply security patches
→ Restore from verified backup (4 hours ago)
→ Verify no malware present

Phase 3: Hardening (1 hour)
→ Implement additional security controls:
  - AWS Systems Manager Session Manager (no SSH keys)
  - IMDSv2 required (prevent credential theft)
  - Runtime security monitoring (Falco/GuardDuty Runtime)
  - Network segmentation (isolate background workers)

Phase 4: Monitoring (Ongoing)
→ Enhanced threat detection (24-48 hours)
→ Watch for reinfection attempts
→ Monitor for credential misuse
→ Review all API logs for suspicious activity

---

COMPLIANCE & LEGAL:

Required Notifications:
1. PCI-DSS Breach (IMMEDIATE)
   - Contact: PCI acquiring bank
   - Timeline: Within 24 hours
   - Status: ⏳ Legal team notified

2. GDPR Breach (72 hours)
   - Contact: EU data protection authorities
   - Affected users: ~1,200 EU customers
   - Status: ⏳ Drafting notification

3. State Breach Notification Laws (varies by state)
   - Contact: Affected customers in CA, NY, TX, etc.
   - Timeline: 30-60 days
   - Status: ⏳ Legal team coordinating

4. Cyber Insurance Claim
   - Provider: [Your Insurance Company]
   - Status: ⏳ Incident report being prepared

---

FORENSICS EVIDENCE PACKAGE:

Location: s3://security-forensics/incident-001999/

Contents:
- memory-dump.raw (16 GB) - Complete RAM image
- ebs-snapshot (snap-0x1y2z3a4b5c6d7e8) - Full disk image
- ami-backup (ami-incident-001999-forensics) - Bootable image
- cloudwatch-logs/ (847 MB) - Application logs
- vpc-flow-logs/ (2.1 GB) - Network traffic logs
- cloudtrail-logs/ (342 MB) - API audit logs
- malware-samples/ - Extracted malicious files
  - /tmp/.hidden-mining (Bitcoin miner)
  - /usr/bin/systemd-networkd (backdoor)
  - /etc/cron.d/system-update (persistence mechanism)

Chain of Custody:
- Created: 2025-10-31 14:47:23 UTC
- Created by: AI Orchestrator (automated)
- S3 Object Lock: Enabled (cannot be deleted/modified for 7 years)
- Access logs: Enabled (track who accesses evidence)

---

INCIDENT TIMELINE:

10:00 UTC - Initial infection (estimated, based on file timestamps)
10:15 UTC - Malware establishes C2 connection (VPC Flow Logs)
10:30 UTC - Credentials exfiltrated (CloudTrail shows Secrets Manager access)
12:00 UTC - Database dump begins (3.2 GB uploaded over 2 hours)
14:45 UTC - GuardDuty alert triggered (unusual outbound traffic)
14:47 UTC - AI Orchestrator responds (isolation begins)
14:47:18 UTC - Instance isolated (network cut off)
14:47:45 UTC - Evidence preserved (snapshots created)
14:48:32 UTC - Credentials rotated (all compromised keys revoked)
14:50:00 UTC - Incident response team notified

Total time from detection to containment: 3 minutes 18 seconds

---

ESTIMATED COSTS:

Incident Response:
- Forensics storage (S3): $47/month (7-year retention)
- Legal fees: $15,000 (estimated)
- Breach notification: $8,000 (mail + email service)
- PCI forensics investigation: $25,000 (required for PCI breach)
- Credit monitoring (affected customers): $84,000 (1 year, 1200 customers)
- Potential fines: $50,000 - $500,000 (PCI + GDPR)

Recovery:
- New instance deployment: $0 (existing capacity)
- Credential rotation: $0 (automated)
- Enhanced monitoring (30 days): $1,200

Total Estimated Cost: $183,247 - $633,247

---

IMMEDIATE ACTION ITEMS:

Human Tasks (URGENT):
- [ ] Legal: Contact PCI acquiring bank (ASAP)
- [ ] Legal: Draft GDPR breach notification (72 hour deadline)
- [ ] Security: Begin forensic investigation of isolated instance
- [ ] Security: Review exfiltrated data (determine customer impact)
- [ ] Communications: Draft customer notification (pending legal review)
- [ ] Executive: Brief CEO/Board on incident

AI Monitoring (ACTIVE):
✓ Scanning all 47 instances in prod-api segment for malware
✓ Monitoring for reinfection attempts (GuardDuty enhanced)
✓ Watching for compromised credential usage (CloudTrail analysis)
✓ Tracking C2 server communications (Network Firewall logs)

---

STATUS: 🔴 CRITICAL INCIDENT - CONTAINED

**Instance isolated:** ✅ Complete
**Evidence preserved:** ✅ Complete
**Credentials rotated:** ✅ Complete
**Malware activity:** ✅ STOPPED
**Data exfiltration:** ✅ BLOCKED
**Forensics:** ⏳ In progress
**Recovery:** ⏳ Pending forensics completion
**Compliance:** ⏳ Legal team coordinating

Next update: 1 hour (or immediately if new findings)

War room: #incident-001999 (Slack)
Incident commander: security-oncall@acmetech.com
Forensics lead: [Will be assigned by security team]

---

I'm continuing to monitor all systems. I'll notify you immediately of:
- New malware detections
- Compromised credential usage attempts
- Reinfection attempts
- Forensics findings

Do you need me to:
A) Provide real-time monitoring dashboard
B) Generate detailed forensics report
C) Prepare customer communication templates
D) Coordinate with external incident response firm
```

---

---

## Cloud WAN & Microsegmentation Scaling

### Example 16: Add New Microsegment

**User Request:**
```
"We need a new segment for our machine learning workloads. They need GPU
instances and access to our data lake in S3, but isolated from production."
```

**AI Response:**
```
NEW MICROSEGMENT: Machine Learning

ARCHITECTURE ANALYSIS:

Workload Requirements:
✓ GPU instances (g5.xlarge or larger)
✓ S3 data lake access (read-only for training data)
✓ Isolated from production (no prod-* segment access)
✓ High bandwidth (model training = large datasets)
✓ Cost optimization (spot instances for training)

PROPOSED MICROSEGMENT CONFIGURATION:

Segment Name: nonprod-ml
Environment: Non-production
Isolation Level: HIGH
Approved Communications:
- → shared-services (DNS, monitoring)
- → prod-data (S3 via PrivateLink, read-only)
- → Internet (PyPI, Docker Hub, ML model repos)

Network Configuration:
```hcl
# Core Network Policy Update
resource "aws_networkmanager_core_network_policy_attachment" "ml_segment" {
  core_network_id = var.core_network_id
  policy_document = jsonencode({
    segments = [
      {
        name = "nonprod-ml"
        description = "Machine Learning training and inference"
        require-attachment-acceptance = false
        isolate-attachments = true
        edge-locations = ["us-east-1", "us-west-2"]  # GPU availability
      }
    ]

    segment-actions = [
      # Allow nonprod-ml → shared-services (DNS, logging)
      {
        action = "share"
        mode = "attachment-route"
        segment = "nonprod-ml"
        share-with = ["shared-services"]
      },

      # Allow nonprod-ml → Internet (ML libraries)
      {
        action = "send-to"
        mode = "single-hop"
        segment = "nonprod-ml"
        destinations = ["0.0.0.0/0"]
        via = {
          network-function-groups = ["inspection-vpc"]
        }
      },

      # BLOCK nonprod-ml → prod-* (data protection)
      {
        action = "deny"
        mode = "attachment-route"
        segment = "nonprod-ml"
        destinations = ["prod-pci", "prod-general", "prod-api", "prod-data"]
      }
    ]
  })
}

# VPC for ML workloads
resource "aws_ec2_transit_gateway_vpc_attachment" "ml_vpc" {
  subnet_ids         = aws_subnet.ml_private[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.ml.id

  tags = {
    Name = "ml-vpc-attachment"
    Segment = "nonprod-ml"
    Environment = "non-production"
    Workload = "machine-learning"
  }
}

# IPAM Pool for ML segment (automatic CIDR allocation)
resource "aws_vpc_ipam_pool_cidr" "ml" {
  ipam_pool_id = aws_vpc_ipam_pool.nonprod.id
  cidr         = "10.150.0.0/16"  # Dedicated range for ML

  cidr_authorization_context {
    message   = "ML segment CIDR allocation"
    signature = "approved-by-network-team"
  }
}
```

Security Configuration:
```hcl
# Security Group for ML instances
resource "aws_security_group" "ml_training" {
  name = "ml-training-sg"
  description = "GPU instances for ML training"
  vpc_id = aws_vpc.ml.id

  # Ingress: SSH from bastion only
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = aws_security_group.ml_bastion.id
    description = "SSH from bastion"
  }

  # Ingress: Jupyter notebook from ML team VPN
  ingress {
    from_port = 8888
    to_port = 8888
    protocol = "tcp"
    cidr_blocks = ["10.250.0.0/16"]  # VPN CIDR
    description = "Jupyter notebook access"
  }

  # Egress: S3 via VPC endpoint (data lake)
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description = "S3 data lake access"
  }

  # Egress: Internet for ML libraries
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PyPI, Docker Hub, model repos"
  }
}

# Network Firewall rules for ML segment
resource "aws_networkfirewall_rule_group" "ml_rules" {
  name = "ml-segment-rules"
  type = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      # Allow ML-specific domains
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          ".pypi.org",              # Python packages
          ".pytorch.org",           # PyTorch
          ".tensorflow.org",        # TensorFlow
          ".huggingface.co",        # ML models
          ".nvidia.com",            # GPU drivers
          ".docker.io",             # Docker images
          ".githubusercontent.com", # GitHub raw content
          ".kaggle.com",            # Datasets
          ".arxiv.org"              # Research papers
        ]
      }

      # Block production data access
      stateful_rule {
        action = "DROP"
        header {
          destination = "10.100.0.0/16"  # prod-pci CIDR
          destination_port = "ANY"
          direction = "FORWARD"
          protocol = "TCP"
          source = "10.150.0.0/16"  # nonprod-ml CIDR
          source_port = "ANY"
        }
        rule_option {
          keyword = "msg"
          settings = ["ML segment attempting prod access - BLOCKED"]
        }
      }

      # Alert on large data exfiltration
      stateful_rule {
        action = "ALERT"
        header {
          destination = "ANY"
          destination_port = "443"
          direction = "FORWARD"
          protocol = "TCP"
          source = "10.150.0.0/16"
          source_port = "ANY"
        }
        rule_option {
          keyword = "msg"
          settings = ["ML segment large upload detected"]
        }
        rule_option {
          keyword = "threshold"
          settings = ["type both, track by_src, count 1000, seconds 60"]
        }
      }
    }
  }
}
```

S3 Data Lake Access (Read-Only):
```hcl
# VPC Endpoint for S3 (PrivateLink)
resource "aws_vpc_endpoint" "s3_ml" {
  vpc_id = aws_vpc.ml.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = aws_route_table.ml_private[*].id

  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::data-lake-production",
        "arn:aws:s3:::data-lake-production/*"
      ]
      Condition = {
        StringEquals = {
          "aws:SourceVpce" = aws_vpc_endpoint.s3_ml.id
        }
      }
    }]
  })
}

# IAM role for ML instances (read-only S3)
resource "aws_iam_role" "ml_instance" {
  name = "ml-training-instance-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  inline_policy {
    name = "s3-readonly-data-lake"
    policy = jsonencode({
      Statement = [{
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::data-lake-production",
          "arn:aws:s3:::data-lake-production/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.ml.id
          }
        }
      },
      {
        Effect = "Deny"
        Action = "s3:PutObject"  # Explicitly deny writes
        Resource = "arn:aws:s3:::data-lake-production/*"
      }]
    })
  }
}
```

IMPLEMENTATION PLAN:

✓ Phase 1: Network Infrastructure (10 minutes)
  - Create nonprod-ml segment in Core Network policy
  - Allocate CIDR from IPAM (10.150.0.0/16)
  - Create VPC with 6 subnets (3 AZs × 2 tiers)
  - Create VPC attachment to Cloud WAN

✓ Phase 2: Security Controls (5 minutes)
  - Create security groups (ML training, bastion)
  - Create Network Firewall rules
  - Create VPC endpoint for S3
  - Configure IAM roles (read-only data lake)

✓ Phase 3: Compute Resources (15 minutes)
  - Launch GPU instances (g5.xlarge × 4, spot)
  - Install CUDA drivers + ML frameworks
  - Configure Jupyter notebook server
  - Test S3 data lake access

✓ Phase 4: Monitoring & Cost Controls (5 minutes)
  - CloudWatch alarms (GPU utilization, costs)
  - VPC Flow Logs (traffic analysis)
  - Cost anomaly detection (spot instance failures)
  - Usage dashboard for ML team

VALIDATION TESTING:

✓ Test 1: S3 Data Lake Access
  - Read from data-lake-production: ✅ ALLOWED
  - Write to data-lake-production: ❌ DENIED (expected)
  - Access other S3 buckets: ❌ DENIED (expected)

✓ Test 2: Production Isolation
  - Connect to prod-pci database: ❌ BLOCKED (Network Firewall)
  - Connect to prod-api: ❌ BLOCKED (Cloud WAN policy)
  - Connect to shared-services: ✅ ALLOWED (DNS, monitoring)

✓ Test 3: Internet Access
  - PyPI (pip install): ✅ ALLOWED
  - PyTorch downloads: ✅ ALLOWED
  - Random websites: ❌ BLOCKED (allowlist only)

✓ Test 4: GPU Functionality
  - CUDA driver: ✅ Installed (version 12.2)
  - GPU utilization: 0% (idle, ready for training)
  - PyTorch GPU test: ✅ PASSED

COST ESTIMATE:

Monthly Recurring:
- GPU instances (g5.xlarge × 4, spot): ~$847/month (75% savings vs on-demand)
- VPC (subnets, endpoints): $32/month
- Network Firewall (shared): $0 (existing capacity)
- S3 data transfer: $0 (same region via VPC endpoint)
- CloudWatch monitoring: $23/month

Total: ~$902/month

Cost Controls:
- Spot instances: Auto-terminate if price > $0.50/hour
- Auto-shutdown: Instances stop at 6 PM EST (save 50%)
- Weekend shutdown: Saturday-Sunday (save $240/month)

STATUS: ✅ DEPLOYED (35 minutes)

New Segment Summary:
- Name: nonprod-ml
- CIDR: 10.150.0.0/16
- Instances: 4 GPU (g5.xlarge spot)
- Security: Isolated from production, read-only data lake
- Cost: $902/month (~$650/month with auto-shutdown)
- Access: ML team via VPN + Jupyter notebook

Documentation: https://wiki.internal/network/microsegments/nonprod-ml
Jupyter URL: https://ml-notebook.nonprod.acmetech.com
```

---

### Example 17: Expand to New AWS Region

**User Request:**
```
"We're opening an office in Europe. Can you extend our network to eu-west-1
with the same microsegmentation and security controls?"
```

**AI Response:**
```
MULTI-REGION EXPANSION: eu-west-1

GLOBAL NETWORK ARCHITECTURE:

Current Regions:
✓ us-east-1 (primary) - 12 segments, 47 attachments
✓ us-west-2 (DR) - 12 segments, 47 attachments (standby)

New Region:
→ eu-west-1 (Europe) - Will deploy 12 segments

Global Connectivity:
- Cloud WAN global network (automatic inter-region routing)
- Cross-region latency: ~80ms (us-east-1 ↔ eu-west-1)
- GDPR compliance: EU data stays in EU (data residency)

CLOUD WAN CORE NETWORK EXPANSION:

```hcl
# Update Core Network Policy (add EU edge locations)
resource "aws_networkmanager_core_network_policy_attachment" "global" {
  core_network_id = var.core_network_id
  policy_document = jsonencode({
    version = "2021.12"

    # Add EU edge location
    core-network-configuration = {
      vpn-ecmp-support = true
      asn-ranges = ["64512-65534"]
      edge-locations = [
        { location = "us-east-1", asn = 64512 },
        { location = "us-west-2", asn = 64513 },
        { location = "eu-west-1", asn = 64514 }  # NEW
      ]
    }

    # Replicate all 12 microsegments in EU
    segments = [
      # Production segments
      {
        name = "prod-pci"
        isolate-attachments = true
        require-attachment-acceptance = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "us-west-2" },
          { location = "eu-west-1" }  # NEW
        ]
      },
      {
        name = "prod-general"
        isolate-attachments = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "us-west-2" },
          { location = "eu-west-1" }  # NEW
        ]
      },
      {
        name = "prod-api"
        isolate-attachments = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "us-west-2" },
          { location = "eu-west-1" }  # NEW
        ]
      },
      {
        name = "prod-data"
        isolate-attachments = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "us-west-2" },
          { location = "eu-west-1" }  # NEW
        ]
      },

      # Non-production segments
      {
        name = "nonprod-dev"
        isolate-attachments = false
        edge-locations = [
          { location = "us-east-1" },
          { location = "eu-west-1" }  # NEW (no us-west-2 for nonprod)
        ]
      },
      {
        name = "nonprod-test"
        isolate-attachments = false
        edge-locations = [
          { location = "us-east-1" },
          { location = "eu-west-1" }  # NEW
        ]
      },
      {
        name = "nonprod-staging"
        isolate-attachments = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "eu-west-1" }  # NEW
        ]
      },

      # Shared services (global)
      {
        name = "shared-services"
        isolate-attachments = false
        edge-locations = [
          { location = "us-east-1" },
          { location = "us-west-2" },
          { location = "eu-west-1" }  # NEW
        ]
      },

      # B2B DMZ (global vendor access)
      {
        name = "prod-b2b-dmz"
        isolate-attachments = true
        require-attachment-acceptance = true
        edge-locations = [
          { location = "us-east-1" },
          { location = "eu-west-1" }  # NEW (vendors access from EU too)
        ]
      }
    ]

    # Attachment policies (per region)
    attachment-policies = [
      {
        rule-number = 100
        condition-logic = "or"
        conditions = [
          { type = "tag-value", key = "Region", value = "eu-west-1" },
          { type = "tag-value", key = "Region", value = "us-east-1" },
          { type = "tag-value", key = "Region", value = "us-west-2" }
        ]
        action = {
          association-method = "tag"
          tag-value-of-key = "Segment"
        }
      }
    ]

    # Cross-region routing policies
    segment-actions = [
      # Allow prod-api in ANY region → prod-data in ANY region
      {
        action = "share"
        mode = "attachment-route"
        segment = "prod-api"
        share-with = ["prod-data"]
        # Automatic cross-region routing via Cloud WAN
      },

      # GDPR data residency: Block EU prod-data → US
      {
        action = "deny"
        mode = "attachment-route"
        segment = "prod-data"
        destinations-cidr = [
          "10.100.0.0/16",  # us-east-1 prod-pci
          "10.101.0.0/16",  # us-east-1 prod-general
          "10.102.0.0/16"   # us-east-1 prod-api
        ]
        when = "tag-exists:DataResidency=EU"
      },

      # Allow shared-services cross-region (DNS, monitoring)
      {
        action = "share"
        mode = "attachment-route"
        segment = "shared-services"
        share-with = "*"  # All segments, all regions
      }
    ]
  })
}
```

IPAM ALLOCATION (EU Region):

```hcl
# Allocate /14 for entire EU region (supports 4× /16 VPCs)
resource "aws_vpc_ipam_pool" "eu_west_1" {
  ipam_scope_id = aws_vpc_ipam.global.private_default_scope_id
  locale = "eu-west-1"
  source_ipam_pool_id = aws_vpc_ipam_pool.global.id

  allocation_resource_tags = {
    Region = "eu-west-1"
    Purpose = "AcmeTech EU operations"
  }
}

resource "aws_vpc_ipam_pool_cidr" "eu_west_1" {
  ipam_pool_id = aws_vpc_ipam_pool.eu_west_1.id
  cidr = "10.200.0.0/14"  # EU CIDR block (10.200-203.x.x)
}

# Sub-pools for each segment
resource "aws_vpc_ipam_pool" "eu_prod_pci" {
  ipam_scope_id = aws_vpc_ipam.global.private_default_scope_id
  locale = "eu-west-1"
  source_ipam_pool_id = aws_vpc_ipam_pool.eu_west_1.id

  allocation_min_netmask_length = 16
  allocation_max_netmask_length = 16
  allocation_default_netmask_length = 16

  allocation_resource_tags = {
    Segment = "prod-pci"
    Region = "eu-west-1"
    Compliance = "PCI-DSS, GDPR"
  }
}

# Automatically assigned CIDRs:
# - 10.200.0.0/16: prod-pci (EU)
# - 10.201.0.0/16: prod-general (EU)
# - 10.202.0.0/16: prod-api (EU)
# - 10.203.0.0/16: prod-data (EU)
# - 10.204.0.0/16: nonprod-dev (EU)
# - 10.205.0.0/16: nonprod-test (EU)
# - 10.206.0.0/16: nonprod-staging (EU)
# - 10.207.0.0/16: shared-services (EU)
# - 10.208.0.0/16: prod-b2b-dmz (EU)
```

INSPECTION VPC (EU):

```hcl
# Deploy inspection VPC in EU (for Network Firewall)
module "inspection_vpc_eu" {
  source = "./modules/inspection-vpc"

  region = "eu-west-1"
  vpc_cidr = "10.209.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # Network Firewall configuration
  firewall_policy_arn = aws_networkfirewall_firewall_policy.global.arn

  # Same firewall rules as US (centrally managed)
  stateful_rule_groups = [
    aws_networkfirewall_rule_group.pci_rules.arn,
    aws_networkfirewall_rule_group.database_rules.arn,
    aws_networkfirewall_rule_group.ml_rules.arn,
    aws_networkfirewall_rule_group.b2b_rules.arn
  ]

  # GDPR-specific rules
  gdpr_compliance = true
  data_residency_enforcement = true

  tags = {
    Region = "eu-west-1"
    Purpose = "Inspection VPC for EU microsegments"
    Compliance = "GDPR"
  }
}

# GDPR-specific Network Firewall rules
resource "aws_networkfirewall_rule_group" "gdpr_rules" {
  name = "gdpr-data-residency-rules"
  type = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      # Block EU data → US regions
      stateful_rule {
        action = "DROP"
        header {
          destination = "10.100.0.0/14"  # US us-east-1 CIDR range
          destination_port = "ANY"
          direction = "FORWARD"
          protocol = "TCP"
          source = "10.200.0.0/14"  # EU eu-west-1 CIDR range
          source_port = "ANY"
        }
        rule_option {
          keyword = "msg"
          settings = ["GDPR violation: EU data → US transfer blocked"]
        }
        rule_option {
          keyword = "flow"
          settings = ["to_server,established"]
        }
      }

      # Alert on potential GDPR violations
      stateful_rule {
        action = "ALERT"
        header {
          destination = "ANY"
          destination_port = "443"
          direction = "FORWARD"
          protocol = "TCP"
          source = "10.200.0.0/14"  # EU CIDR
          source_port = "ANY"
        }
        rule_option {
          keyword = "msg"
          settings = ["EU data transfer - monitoring for GDPR compliance"]
        }
        rule_option {
          keyword = "threshold"
          settings = ["type both, track by_src, count 10000, seconds 60"]
        }
      }
    }
  }
}
```

LANDING ZONE DEPLOYMENT (EU):

Deploying 9 landing zones (VPCs) in eu-west-1:

```
Landing Zone 1: prod-pci (EU)
- CIDR: 10.200.0.0/16 (auto-allocated via IPAM)
- Purpose: PCI-DSS compliant payment processing
- Compliance: PCI-DSS + GDPR
- Attachments: RDS (encrypted), ECS Fargate, ALB
- Data residency: EU only (no cross-region replication)

Landing Zone 2: prod-general (EU)
- CIDR: 10.201.0.0/16
- Purpose: General production workloads
- Compliance: GDPR
- Attachments: EC2, RDS, ElastiCache
- Replication: us-east-1 (async, GDPR-compliant)

Landing Zone 3: prod-api (EU)
- CIDR: 10.202.0.0/16
- Purpose: API gateway and microservices
- Compliance: GDPR
- Attachments: API Gateway, Lambda, ECS
- Global Accelerator: Low-latency EU user access

Landing Zone 4: prod-data (EU)
- CIDR: 10.203.0.0/16
- Purpose: Data warehousing and analytics
- Compliance: GDPR (strict data residency)
- Attachments: Redshift, S3 (EU buckets only), Glue
- Cross-region: BLOCKED (data residency requirement)

Landing Zone 5: nonprod-dev (EU)
- CIDR: 10.204.0.0/16
- Purpose: Development environment for EU team
- Attachments: EC2, RDS (test data)

Landing Zone 6: nonprod-test (EU)
- CIDR: 10.205.0.0/16
- Purpose: QA testing with EU-specific configurations

Landing Zone 7: nonprod-staging (EU)
- CIDR: 10.206.0.0/16
- Purpose: Pre-production testing (mirrors prod)

Landing Zone 8: shared-services (EU)
- CIDR: 10.207.0.0/16
- Purpose: DNS, monitoring, logging, AD
- Global: Accessible from all segments

Landing Zone 9: prod-b2b-dmz (EU)
- CIDR: 10.208.0.0/16
- Purpose: EU vendor access via Cloudflare Tunnel
- Vendors: EU-based partners only
```

DEPLOYMENT TIMELINE:

Phase 1: Core Network (15 minutes)
✓ Update Cloud WAN policy (add eu-west-1 edge location)
✓ Propagate policy to all existing attachments
✓ Verify Core Network connectivity (us ↔ eu)

Phase 2: IPAM & Networking (20 minutes)
✓ Create EU IPAM pool (10.200.0.0/14)
✓ Allocate sub-pools for each segment
✓ Deploy Inspection VPC in eu-west-1
✓ Create Network Firewall (with GDPR rules)

Phase 3: Landing Zones (90 minutes)
✓ Deploy 9 VPCs in parallel (Terraform)
✓ Create subnets (3 AZs × 2 tiers per VPC)
✓ Attach VPCs to Cloud WAN (auto-segment association)
✓ Configure route tables (via Cloud WAN routes)
✓ Create VPC endpoints (S3, RDS, etc.)

Phase 4: Security & Compliance (30 minutes)
✓ Deploy security groups (3-tier per landing zone)
✓ Enable VPC Flow Logs (90-day retention, GDPR)
✓ Enable GuardDuty (EU region)
✓ Enable AWS Config (GDPR compliance pack)
✓ Deploy CloudTrail (EU event logging)

Phase 5: Applications (Varies)
→ Migrate/deploy applications to EU landing zones
→ Configure RDS databases (eu-west-1)
→ Deploy ECS services
→ Configure ALBs and Route 53 (eu.acmetech.com)

Phase 6: Validation & Testing (60 minutes)
✓ Test cross-region connectivity (us ↔ eu)
✓ Test segment isolation (prod ↔ nonprod)
✓ Test GDPR data residency enforcement
✓ Performance testing (latency, throughput)
✓ Failover testing (multi-region DR)

TOTAL DEPLOYMENT TIME: ~3.5 hours (fully automated)

COST ESTIMATE (EU Region):

Cloud WAN:
- Core Network: $0 (already paying $255/month globally via RAM)
- Edge location: Included
- Data transfer: $0.02/GB (cross-region)
  - Estimated: 500 GB/month EU ↔ US = $10/month

IPAM:
- IPAM pool: $0 (already paying $18/month globally via RAM)

Network Firewall (EU):
- Firewall endpoint: $0.395/hour × 3 AZ = $850/month
- Data processing: $0.065/GB
  - Estimated: 5 TB/month = $332/month
- Total: $1,182/month

VPCs (9 landing zones):
- VPC itself: Free
- NAT Gateways: $32/month × 9 VPCs = $288/month
- VPC endpoints: $7/month × 9 VPCs = $63/month
- Total: $351/month

VPC Flow Logs:
- CloudWatch Logs: $0.50/GB
  - Estimated: 200 GB/month = $100/month

Monitoring:
- CloudWatch alarms: $0.10/alarm × 50 = $5/month
- GuardDuty: ~$50/month (varies by events)

TOTAL EU REGION COST: ~$1,698/month

Global Network Cost:
- Existing (us-east-1 + us-west-2): $4,308/month
- EU expansion (eu-west-1): $1,698/month
- Total: $6,006/month

Cross-Region Connectivity:

```
US East (us-east-1)  ←→  EU West (eu-west-1)
  Latency: ~80ms RTT
  Bandwidth: 10 Gbps (Cloud WAN)
  Cost: $0.02/GB

US West (us-west-2)  ←→  EU West (eu-west-1)
  Latency: ~140ms RTT
  Bandwidth: 10 Gbps (Cloud WAN)
  Cost: $0.02/GB
```

GDPR COMPLIANCE:

Data Residency Enforcement:
✓ EU customer data stored in eu-west-1 only
✓ Network Firewall blocks EU → US data transfer
✓ S3 buckets: eu-west-1 only (no cross-region replication for PII)
✓ RDS: eu-west-1 Multi-AZ (no cross-region read replicas for PII)
✓ Backup retention: 30 days (GDPR Article 17 - right to erasure)

Data Processing Agreements:
✓ AWS GDPR Data Processing Addendum (DPA) signed
✓ EU Standard Contractual Clauses (SCCs) in place
✓ Data Protection Impact Assessment (DPIA) completed

Technical Safeguards:
✓ Encryption at rest: All data (AES-256)
✓ Encryption in transit: TLS 1.3
✓ Access controls: IAM + MFA required
✓ Audit logs: CloudTrail (90-day retention minimum)
✓ Incident response: <72 hour breach notification

MONITORING DASHBOARD:

Global Network Health:
- Cloud WAN status: All edges healthy
- Cross-region latency: us-east-1 ↔ eu-west-1 = 78ms (normal)
- Bandwidth utilization: 23% (7.7 Gbps available)
- Packet loss: 0.01% (normal)

EU Region Status:
- Landing zones deployed: 9/9 ✅
- VPC attachments: 9/9 healthy
- Network Firewall: Healthy (processing 847 MB/hour)
- GDPR rules: Active (0 violations detected)
- Security score: 94/100

Cross-Region Traffic (Last 24 hours):
- us-east-1 → eu-west-1: 847 GB
- eu-west-1 → us-east-1: 423 GB (API calls, monitoring)
- Data transfer cost: $25.40/day = $762/month

STATUS: ✅ EU REGION DEPLOYED

Next Steps:
1. Application migration: Deploy EU-specific applications
2. DNS configuration: Create eu.acmetech.com subdomains
3. EU team training: Network access, GDPR policies
4. Performance optimization: Consider CloudFront EU edge locations
5. Compliance audit: Schedule external GDPR audit

Documentation: https://wiki.internal/network/regions/eu-west-1
Global Network Dashboard: https://cloudwatch.aws.amazon.com/dashboard/global-network
```

---

### Example 18: Scale Landing Zones for New Business Unit

**User Request:**
```
"Our company acquired a fintech startup. They need 5 new landing zones for
their applications, fully isolated from our existing workloads, but using
our network infrastructure."
```

**AI Response:**
```
MULTI-TENANT LANDING ZONES: Fintech Acquisition

BUSINESS REQUIREMENTS:

Acquired Company: FinPay Inc (fintech startup)
Current Infrastructure: Standalone AWS account (unmanaged)
Requirements:
- Isolated from AcmeTech existing workloads (separate business unit)
- PCI-DSS Level 1 compliant (payment card processing)
- SOC 2 Type II compliant
- Access to shared services (DNS, monitoring)
- B2B access for payment processors (Visa, Mastercard networks)
- Gradual migration from existing infrastructure

CLOUD WAN MULTI-TENANT ARCHITECTURE:

New Segments for FinPay (Isolated):

```hcl
# Core Network Policy update (add FinPay segments)
segments = [
  # ... existing AcmeTech segments ...

  # FinPay segments (completely isolated)
  {
    name = "finpay-prod-core"
    description = "FinPay production core services"
    isolate-attachments = true
    require-attachment-acceptance = true
    edge-locations = ["us-east-1", "eu-west-1"]

    # Isolated from ALL AcmeTech segments
    allow-filter = ["finpay-*", "shared-services"]
  },
  {
    name = "finpay-prod-api"
    description = "FinPay API gateway"
    isolate-attachments = true
    edge-locations = ["us-east-1", "eu-west-1"]
    allow-filter = ["finpay-*", "shared-services"]
  },
  {
    name = "finpay-prod-data"
    description = "FinPay databases (PCI data)"
    isolate-attachments = true
    require-attachment-acceptance = true
    edge-locations = ["us-east-1"]  # US only (no EU for PCI data)
    allow-filter = ["finpay-prod-api", "finpay-prod-core"]
  },
  {
    name = "finpay-nonprod"
    description = "FinPay development and testing"
    isolate-attachments = false
    edge-locations = ["us-east-1"]
    allow-filter = ["finpay-*", "shared-services"]
  },
  {
    name = "finpay-b2b"
    description = "FinPay payment processor integrations"
    isolate-attachments = true
    require-attachment-acceptance = true
    edge-locations = ["us-east-1"]
    allow-filter = ["finpay-prod-api", "shared-services"]
  }
]

# Segment actions for FinPay isolation
segment-actions = [
  # Block ALL traffic between AcmeTech and FinPay segments
  {
    action = "deny"
    mode = "attachment-route"
    segment = "finpay-*"
    destinations = [
      "prod-*",      # AcmeTech production
      "nonprod-*",   # AcmeTech non-production
      "prod-b2b-dmz" # AcmeTech B2B
    ]
  },
  {
    action = "deny"
    mode = "attachment-route"
    segment = "prod-*"
    destinations = ["finpay-*"]
  },

  # Allow FinPay → shared-services (DNS, monitoring, AD)
  {
    action = "share"
    mode = "attachment-route"
    segment = "finpay-*"
    share-with = ["shared-services"]
  },

  # Allow FinPay segments to communicate with each other
  {
    action = "share"
    mode = "attachment-route"
    segment = "finpay-prod-api"
    share-with = ["finpay-prod-core", "finpay-prod-data", "finpay-b2b"]
  }
]
```

IPAM Allocation (FinPay Isolated Pool):

```hcl
# Dedicated IPAM pool for FinPay (separate from AcmeTech)
resource "aws_vpc_ipam_pool" "finpay" {
  ipam_scope_id = aws_vpc_ipam.global.private_default_scope_id
  locale = "us-east-1"
  source_ipam_pool_id = aws_vpc_ipam_pool.global.id

  description = "FinPay Inc IP address pool (isolated)"

  allocation_resource_tags = {
    BusinessUnit = "FinPay"
    Tenant = "finpay-inc"
    Compliance = "PCI-DSS-L1, SOC2-Type2"
  }
}

resource "aws_vpc_ipam_pool_cidr" "finpay" {
  ipam_pool_id = aws_vpc_ipam_pool.finpay.id
  cidr = "10.220.0.0/14"  # FinPay CIDR (completely separate)

  # 10.220.0.0/14 = 10.220-223.x.x (supports 16× /16 VPCs)
}

# Sub-pools for each FinPay segment
resource "aws_vpc_ipam_pool" "finpay_prod_core" {
  ipam_scope_id = aws_vpc_ipam.global.private_default_scope_id
  locale = "us-east-1"
  source_ipam_pool_id = aws_vpc_ipam_pool.finpay.id

  allocation_min_netmask_length = 16
  allocation_max_netmask_length = 16

  allocation_resource_tags = {
    Segment = "finpay-prod-core"
    BusinessUnit = "FinPay"
  }
}

# Auto-allocated CIDRs:
# - 10.220.0.0/16: finpay-prod-core
# - 10.221.0.0/16: finpay-prod-api
# - 10.222.0.0/16: finpay-prod-data (PCI-DSS)
# - 10.223.0.0/16: finpay-nonprod
# - 10.224.0.0/16: finpay-b2b
```

LANDING ZONE DEPLOYMENTS:

```
Landing Zone 1: finpay-prod-core
├─ CIDR: 10.220.0.0/16
├─ Purpose: Core payment processing engine
├─ Compliance: PCI-DSS L1, SOC 2 Type II
├─ Resources:
│  ├─ ECS Fargate: Payment processor (8 tasks, high availability)
│  ├─ SQS: Transaction queue (FIFO, encrypted)
│  ├─ Lambda: Payment validation, fraud detection
│  └─ ALB: Internal load balancer (private subnets only)
├─ Security:
│  ├─ Zero egress (no internet access)
│  ├─ Ingress: finpay-prod-api only
│  └─ Network Firewall: DROP all unauthorized traffic
└─ Monitoring:
   ├─ CloudWatch: Transaction metrics, error rates
   ├─ X-Ray: Distributed tracing
   └─ GuardDuty: Threat detection

Landing Zone 2: finpay-prod-api
├─ CIDR: 10.221.0.0/16
├─ Purpose: API gateway for payment requests
├─ Compliance: PCI-DSS L1 (SAQ D)
├─ Resources:
│  ├─ API Gateway: REST API (private endpoints)
│  ├─ Lambda@Edge: Request validation, rate limiting
│  ├─ WAF: DDoS protection, bot mitigation
│  └─ CloudFront: Global distribution (PCI-compliant)
├─ Security:
│  ├─ mTLS: Client certificate authentication
│  ├─ API keys: Per-merchant credentials
│  ├─ Rate limiting: 1000 req/min per merchant
│  └─ IP allowlist: Known merchant IPs only
└─ Monitoring:
   ├─ API Gateway logs: All requests (7-year retention)
   ├─ CloudWatch Alarms: Latency >500ms, error rate >1%
   └─ AWS Shield Advanced: DDoS protection

Landing Zone 3: finpay-prod-data (PCI-DSS Cardholder Data Environment)
├─ CIDR: 10.222.0.0/16
├─ Purpose: Databases storing cardholder data (PAN, CVV)
├─ Compliance: PCI-DSS L1 (CDE - highest security)
├─ Resources:
│  ├─ RDS PostgreSQL: Payment card data (encrypted, Multi-AZ)
│  ├─ ElastiCache Redis: Session tokens (encrypted in-transit + at-rest)
│  ├─ S3: Encrypted backups (Glacier for long-term retention)
│  └─ KMS: Customer-managed keys (annual rotation)
├─ Security:
│  ├─ **ZERO EGRESS**: No internet access whatsoever
│  ├─ **ZERO INGRESS**: Only finpay-prod-api via RDS Proxy
│  ├─ IAM DB Authentication: No passwords
│  ├─ Encryption: AES-256 at rest, TLS 1.3 in transit
│  ├─ Data masking: PAN displayed as **** **** **** 1234
│  ├─ Access logging: Every query logged (immutable logs)
│  └─ Quarterly ASV scans: PCI-DSS requirement
├─ Compliance:
│  ├─ PCI-DSS Requirement 3: Protect stored cardholder data
│  ├─ PCI-DSS Requirement 4: Encrypt transmission of cardholder data
│  ├─ PCI-DSS Requirement 8: Unique IDs, no shared credentials
│  └─ PCI-DSS Requirement 10: Track all access to cardholder data
└─ Monitoring:
   ├─ Database Activity Streams: Real-time query monitoring
   ├─ CloudWatch Alarms: Connection count, CPU, storage
   ├─ GuardDuty: Unusual database access patterns
   └─ Config: Compliance drift detection

Landing Zone 4: finpay-nonprod
├─ CIDR: 10.223.0.0/16
├─ Purpose: Development, testing, staging
├─ Resources:
│  ├─ EC2: Developer workstations
│  ├─ RDS: Test databases (synthetic data, NO real PCI data)
│  └─ ECS: Staging environment (mirrors production)
├─ Security:
│  ├─ Test data generator: Fake credit card numbers (Luhn-valid but not real)
│  ├─ NO production data: Strict policy enforcement
│  └─ Network isolation: Blocked from production segments
└─ Cost optimization:
   ├─ Auto-shutdown: Stop all resources at 6 PM EST
   ├─ Weekend shutdown: Saturday-Sunday
   └─ Spot instances: 70% cost savings

Landing Zone 5: finpay-b2b (Payment Processor Networks)
├─ CIDR: 10.224.0.0/16
├─ Purpose: Integrations with Visa, Mastercard, payment gateways
├─ B2B Partners:
│  ├─ Visa: Direct connection via PrivateLink
│  ├─ Mastercard: Direct connection via PrivateLink
│  ├─ Stripe: API integration (outbound HTTPS)
│  ├─ First Data: Gateway connection (dedicated tunnel)
│  └─ PayPal: API integration (outbound HTTPS)
├─ Security:
│  ├─ Cloudflare Tunnel: Zero Trust access for partners
│  ├─ ExternalId: IAM role assumption with unique IDs
│  ├─ IP allowlist: Known payment processor IPs
│  ├─ Certificate pinning: Prevent MITM attacks
│  └─ Network Firewall: Allow only approved domains
├─ Monitoring:
│  ├─ Transaction success rate: Target >99.9%
│  ├─ Latency: Target <200ms per transaction
│  ├─ Partner uptime: Monitor Visa/Mastercard availability
│  └─ Failover: Automatic switch to backup payment processor
└─ Compliance:
   ├─ PCI-DSS Requirement 2: Change vendor defaults
   ├─ PCI-DSS Requirement 11: Regularly test security systems
   └─ Annual penetration testing
```

DEPLOYMENT PLAN:

Phase 1: Network Infrastructure (30 minutes)
✓ Update Cloud WAN policy (add 5 FinPay segments)
✓ Create FinPay IPAM pool (10.220.0.0/14)
✓ Allocate CIDRs for 5 landing zones
✓ Create isolation policies (block AcmeTech ↔ FinPay)

Phase 2: Landing Zone Deployment (60 minutes)
✓ Deploy 5 VPCs in parallel (Terraform modules)
✓ Create subnets (3 AZs × 2 tiers per VPC)
✓ Attach to Cloud WAN (auto-segment association)
✓ Configure VPC endpoints (S3, RDS, secrets manager)

Phase 3: PCI-DSS Compliance (90 minutes)
✓ Deploy AWS Config (PCI-DSS conformance pack)
✓ Enable GuardDuty (cardholder data environment monitoring)
✓ Create KMS keys (customer-managed, annual rotation)
✓ Configure VPC Flow Logs (immutable, 7-year retention)
✓ Enable CloudTrail (comprehensive audit logs)
✓ Deploy Network Firewall (finpay-prod-data strict rules)
✓ Configure security groups (zero-trust, least privilege)

Phase 4: Application Migration (Varies - weeks)
→ Migrate FinPay applications from old AWS account
→ Re-platform to ECS Fargate (containerization)
→ Migrate databases to RDS (managed, encrypted)
→ Configure RDS Proxy (IAM authentication)
→ Deploy API Gateway (private endpoints)
→ Configure monitoring and alerting

Phase 5: B2B Integration (30 minutes)
✓ Create Cloudflare Tunnel (finpay-b2b.acmetech.com)
✓ Configure Visa PrivateLink connection
✓ Configure Mastercard PrivateLink connection
✓ Create IAM roles for payment gateways (ExternalId)
✓ Configure Network Firewall (allowlist payment processor domains)

Phase 6: Compliance Validation (60 minutes)
✓ Run AWS Config rules (PCI-DSS conformance)
✓ Validate data encryption (at rest + in transit)
✓ Test segment isolation (FinPay ↔ AcmeTech blocked)
✓ Verify zero egress from finpay-prod-data
✓ Run vulnerability scan (quarterly ASV scan)
✓ Generate compliance report for QSA (PCI auditor)

TOTAL DEPLOYMENT TIME: ~4.5 hours (infrastructure ready)
Application migration: 2-4 weeks (FinPay team responsibility)

COST ESTIMATE (FinPay Landing Zones):

Network Infrastructure:
- Cloud WAN: $0 (shared via RAM, already paying)
- IPAM: $0 (shared via RAM, already paying)
- VPC (5 landing zones): Free
- NAT Gateways: $32/month × 5 VPCs = $160/month
- VPC Endpoints: $7/month × 5 VPCs = $35/month
- Network Firewall (finpay-prod-data): $395/hour = $284/month

Compute & Databases:
- ECS Fargate (prod-core): $847/month (8 tasks, high availability)
- RDS PostgreSQL (prod-data): $1,284/month (db.r5.2xlarge, Multi-AZ, encrypted)
- ElastiCache Redis: $342/month (6 nodes, cluster mode)
- Lambda: ~$150/month (payment validation, fraud detection)
- API Gateway: ~$420/month (1M requests/day)

Security & Compliance:
- KMS: $1/key/month × 10 keys = $10/month
- GuardDuty: $50/month (CDE monitoring)
- Config: $25/month (PCI conformance pack)
- CloudTrail: $30/month (7-year retention)
- VPC Flow Logs: $100/month (7-year retention)
- Shield Advanced: $3,000/month (DDoS protection, PCI requirement)
- WAF: $5/month + $1/million requests = $35/month

B2B Connectivity:
- Cloudflare Tunnel: $5/month
- PrivateLink (Visa, Mastercard): $7/hour × 2 = $100/month

Monitoring:
- CloudWatch Logs: $50/month
- CloudWatch Alarms: $0.10/alarm × 100 = $10/month
- X-Ray: $25/month (transaction tracing)

Backups & DR:
- RDS Snapshots: $0.095/GB-month × 500 GB = $47/month
- S3 Glacier: $0.004/GB-month × 2 TB = $82/month

TOTAL FINPAY COST: ~$6,908/month

Breakdown by Category:
- Infrastructure: $479/month (7%)
- Compute: $1,759/month (25%)
- Security & Compliance: $3,250/month (47%)
- B2B: $105/month (2%)
- Monitoring & Backup: $214/month (3%)
- Shield Advanced: $3,000/month (43% of security costs)

Cost Optimization Opportunities:
- Reserved Instances: 40% savings on RDS (after 1 year)
- Savings Plans: 30% savings on Fargate (after 1 year)
- Spot instances for nonprod: $200/month savings

ISOLATION VERIFICATION:

Testing AcmeTech ↔ FinPay Isolation:

✓ Test 1: AcmeTech prod-api → FinPay finpay-prod-core
  - Result: ❌ BLOCKED (Cloud WAN policy deny)
  - Expected: Blocked

✓ Test 2: FinPay finpay-prod-api → AcmeTech prod-data
  - Result: ❌ BLOCKED (Cloud WAN policy deny)
  - Expected: Blocked

✓ Test 3: FinPay finpay-prod-core → shared-services (DNS)
  - Result: ✅ ALLOWED (DNS resolution successful)
  - Expected: Allowed

✓ Test 4: FinPay finpay-prod-data → Internet
  - Result: ❌ BLOCKED (zero egress security group)
  - Expected: Blocked

✓ Test 5: FinPay finpay-prod-api → finpay-prod-data (database)
  - Result: ✅ ALLOWED (RDS connection successful)
  - Expected: Allowed

✓ Test 6: Visa network → FinPay finpay-b2b (via PrivateLink)
  - Result: ✅ ALLOWED (mTLS authentication successful)
  - Expected: Allowed

PCI-DSS COMPLIANCE STATUS:

Cardholder Data Environment (CDE): finpay-prod-data
├─ Requirement 1: Firewall configuration
│  └─ ✅ Network Firewall (zero egress, finpay-prod-api only ingress)
├─ Requirement 2: Vendor defaults
│  └─ ✅ No default passwords, custom AMIs, hardened configurations
├─ Requirement 3: Protect stored cardholder data
│  └─ ✅ AES-256 encryption (KMS), data masking, secure deletion
├─ Requirement 4: Encrypt transmission
│  └─ ✅ TLS 1.3 only, certificate pinning, no weak ciphers
├─ Requirement 5: Anti-virus
│  └─ ✅ GuardDuty (malware detection), ECS Fargate (immutable containers)
├─ Requirement 6: Secure systems
│  └─ ✅ Patch management (automated), vulnerability scanning (quarterly)
├─ Requirement 7: Restrict access
│  └─ ✅ IAM least privilege, MFA required, role-based access
├─ Requirement 8: Unique IDs
│  └─ ✅ No shared credentials, IAM users, RDS IAM authentication
├─ Requirement 9: Physical access
│  └─ ✅ AWS responsibility (SOC 2 compliant data centers)
├─ Requirement 10: Track access
│  └─ ✅ CloudTrail (all API calls), DB Activity Streams (all queries)
├─ Requirement 11: Security testing
│  └─ ✅ Quarterly ASV scans, annual penetration testing
└─ Requirement 12: Security policy
   └─ ✅ Documented policies, incident response plan, security training

STATUS: ✅ PCI-DSS L1 COMPLIANT (pending QSA audit)

MULTI-TENANT GOVERNANCE:

Cost Allocation:
- AcmeTech tags: BusinessUnit=AcmeTech
- FinPay tags: BusinessUnit=FinPay
- Cost Explorer: Separate dashboards per business unit
- Chargeback: FinPay pays for their infrastructure ($6,908/month)

Access Control:
- IAM: Separate AWS accounts (AcmeTech vs FinPay)
- Assume Role: Cross-account access with approval
- Control Tower: Landing Zone vending machine (self-service)
- Service Catalog: Pre-approved architecture patterns

Network Management:
- Cloud WAN: Shared global network (centrally managed)
- IPAM: Separate pools per business unit
- Segment isolation: Enforced via policy (not manual routes)
- Change management: AI orchestrator with approval matrix

STATUS: ✅ FINPAY LANDING ZONES DEPLOYED

Summary:
- Segments: 5 new segments (finpay-prod-core, finpay-prod-api, finpay-prod-data, finpay-nonprod, finpay-b2b)
- Landing Zones: 5 VPCs (fully isolated from AcmeTech)
- Compliance: PCI-DSS L1 + SOC 2 Type II ready
- Isolation: 100% (AcmeTech ↔ FinPay blocked)
- Shared Services: DNS, monitoring, logging (via shared-services segment)
- Cost: $6,908/month (FinPay)
- Deployment Time: 4.5 hours (infrastructure), 2-4 weeks (application migration)

Next Steps:
1. FinPay application migration (FinPay team)
2. QSA audit scheduling (PCI-DSS L1 certification)
3. Penetration testing (annual requirement)
4. Load testing (ensure 99.9% uptime SLA)
5. Runbook creation (incident response, DR procedures)

Documentation:
- Network architecture: https://wiki.internal/network/tenants/finpay
- PCI compliance: https://wiki.internal/compliance/pci-dss/finpay
- Migration guide: https://wiki.internal/migrations/finpay-acquisition
```

---

## Conclusion

These examples demonstrate the AI orchestrator's capabilities across:

1. **Security**: Incident response, threat detection, compliance
2. **Scalability**: Auto-scaling, capacity planning, traffic management
3. **B2B**: Vendor onboarding/offboarding, access control, monitoring
4. **Firewall**: Rule management, domain allowlisting, geoblocking
5. **Failover**: DR testing, automatic recovery, multi-region
6. **Cost**: Resource optimization, right-sizing, commitment planning
7. **Complex Multi-Domain**: End-to-end deployments, comprehensive reviews
8. **Cloud WAN Microsegmentation**: New segments, multi-region expansion
9. **Landing Zones**: Multi-tenant deployments, business unit isolation
10. **Regional Expansion**: Global network scaling, GDPR compliance

**Key Benefits:**
- **Speed**: Seconds to minutes (vs hours to days manually)
- **Accuracy**: No human error, consistent execution
- **24/7**: Always available, instant response
- **Learning**: Improves over time with feedback
- **Cost-effective**: $242k/year vs $830k/year for human team
- **Multi-Region**: Seamless global network expansion
- **Multi-Tenant**: Business unit isolation with shared infrastructure

**Human Oversight:**
- High-impact changes require approval
- Security incidents escalate appropriately
- Learning from human feedback
- Regular audits and reviews
- Compliance validation (PCI, GDPR, SOC 2)
