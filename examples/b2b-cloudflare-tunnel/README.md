# B2B Integration via Cloudflare Tunnel

This example demonstrates how to provide **secure vendor access** to AWS resources (S3, databases, Redis, APIs) using **Cloudflare Tunnel with Zero Trust authentication**.

## NEW: All Ports and Protocols Support

As of **2025-10-28**, Cloudflare Access now supports **all ports and protocols** (not just HTTP/HTTPS):
- ✅ **Databases** (PostgreSQL, MySQL, SQL Server)
- ✅ **Redis** (ElastiCache)
- ✅ **SSH** (bastion hosts)
- ✅ **Any TCP/UDP service**

**Reference**: https://developers.cloudflare.com/changelog/2025-10-28-access-application-support-for-all-ports-and-protocols/

## Why Cloudflare Tunnel for B2B?

### Traditional VPN Problems
- ❌ Vendors need VPN client software
- ❌ Complex firewall rules (port forwarding, NAT)
- ❌ VPN credentials get shared/stolen
- ❌ No per-resource access control
- ❌ Difficult to revoke access quickly

### Cloudflare Tunnel Benefits
- ✅ **Zero Trust**: No VPN needed - authentication via SSO (Google, Okta, etc.)
- ✅ **No inbound firewall rules**: cloudflared initiates outbound connection to Cloudflare
- ✅ **Per-resource access control**: Different vendors can access different resources
- ✅ **Session-based**: Access expires after X hours
- ✅ **Instant revocation**: Remove vendor email from list = immediate access loss
- ✅ **Audit logs**: Cloudflare logs every connection attempt
- ✅ **Works anywhere**: Vendors access from browser or CLI

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Vendor (anywhere in the world)                              │
│   ↓                                                          │
│ Browser: https://s3.tunnel.company.com                      │
│ CLI:     cloudflared access tcp --hostname db.tunnel...     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Cloudflare Network                                          │
│   - Zero Trust authentication (SSO)                         │
│   - Access policies (email, domain, group)                  │
│   - DDoS protection                                         │
│   - Audit logs                                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ AWS - b2b-vendors VPC Segment                               │
│   ↓                                                          │
│ ECS Fargate (cloudflared daemon)                            │
│   ├── Container 1: cloudflared                              │
│   ├── Container 2: s3-proxy (for presigned URLs)            │
│   ↓                                                          │
│ VPC Endpoint → S3 Bucket (vendor files)                     │
│ RDS Proxy    → PostgreSQL (read-only replica)               │
│ ElastiCache  → Redis cluster                                │
│ Internal ALB → API endpoints                                │
└─────────────────────────────────────────────────────────────┘
```

## What Gets Created

### Cloudflare Resources
- **1 Cloudflare Tunnel** (persistent connection from AWS to Cloudflare)
- **4 Access Applications** (S3, Database, Redis, API)
- **Access Policies** (who can access what, when)

### AWS Resources
- **1 S3 Bucket** with versioning, encryption, lifecycle policies
- **1 RDS Proxy** for read-only database access
- **1 ECS Fargate Cluster** running cloudflared (2 tasks for HA)
- **Security Groups** allowing cloudflared → resources
- **CloudTrail** logging all S3 operations
- **CloudWatch Alarms** for high CPU, connections, errors

### Vendor Access URLs
- **S3**: `https://s3.tunnel.company.com` (web interface)
- **Database**: `tcp://db.tunnel.company.com:5432` (via cloudflared CLI)
- **Redis**: `tcp://redis.tunnel.company.com:6379` (via cloudflared CLI)
- **API**: `https://api.tunnel.company.com` (REST API)

## Prerequisites

### 1. Cloudflare Account Setup

1. **Sign up for Cloudflare Zero Trust** (free tier available):
   - Go to: https://dash.cloudflare.com/
   - Navigate to: **Zero Trust** → **Access** → **Tunnels**

2. **Create a tunnel**:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create acme-b2b-tunnel
   ```

   Copy the tunnel token (you'll need it for `cloudflare_tunnel_token` variable)

3. **Configure identity providers**:
   - Go to: **Settings** → **Authentication**
   - Add: Google Workspace, Okta, Azure AD, or email OTP

4. **Create API token**:
   - Go to: **My Profile** → **API Tokens**
   - Create token with: **Account - Cloudflare Zero Trust - Edit**

### 2. AWS Resources

This example assumes you already have:
- A VPC in the `b2b-vendors` segment
- A production RDS database (will create read-only proxy)
- A Redis cluster (ElastiCache)
- An internal API endpoint (ALB)

### 3. Terraform

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Cloudflare Provider ~> 4.0

## Deployment

### Step 1: Set Variables

Create `terraform.tfvars`:

```hcl
# Company
company_name = "acme"

# Cloudflare
cloudflare_api_token    = "YOUR_CLOUDFLARE_API_TOKEN"
cloudflare_account_id   = "abcdef1234567890"
cloudflare_zone_id      = "1234567890abcdef"
cloudflare_tunnel_token = "YOUR_TUNNEL_TOKEN_FROM_STEP_1"
tunnel_domain           = "tunnel.acme.com"

# Cloudflare identity providers (get IDs from dashboard)
cloudflare_idp_ids = [
  "google-workspace-id",
  "okta-id"
]

# Vendor access control
vendor_emails = [
  "support@vendor.com",
  "engineer@partner-company.com"
]

vendor_domains = [
  "vendor.com",
  "partner-company.com"
]

# Database
database_identifier    = "production-postgres"
database_engine_family = "POSTGRESQL"

# Redis
redis_replication_group_id = "production-redis"

# API
internal_api_endpoint = "internal-api-1234567890.us-east-1.elb.amazonaws.com"

# Monitoring
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:cloudwatch-alarms"
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Configure DNS

Add CNAME records in Cloudflare DNS:

```
s3.tunnel.acme.com    CNAME   <tunnel-id>.cfargotunnel.com
db.tunnel.acme.com    CNAME   <tunnel-id>.cfargotunnel.com
redis.tunnel.acme.com CNAME   <tunnel-id>.cfargotunnel.com
api.tunnel.acme.com   CNAME   <tunnel-id>.cfargotunnel.com
```

(Terraform outputs will show you the exact CNAME target)

### Step 4: Test Vendor Access

#### S3 Access (Web Browser)

1. Vendor opens: `https://s3.tunnel.acme.com`
2. Cloudflare prompts for authentication (Google, Okta, etc.)
3. Vendor logs in with their email
4. If email is in `vendor_emails` or matches `vendor_domains`, access granted
5. Vendor sees web interface for file upload/download
6. Session expires after 8 hours

#### Database Access (CLI)

1. Vendor installs cloudflared:
   ```bash
   # macOS
   brew install cloudflare/cloudflare/cloudflared

   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
   sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
   sudo chmod +x /usr/local/bin/cloudflared
   ```

2. Vendor runs tunnel:
   ```bash
   cloudflared access tcp --hostname db.tunnel.acme.com --url localhost:5432
   ```

3. Browser opens for authentication (same as S3)

4. Once authenticated, vendor connects database client:
   ```bash
   psql -h localhost -p 5432 -U vendor_readonly -d production
   ```

5. Vendor has read-only access to database via RDS Proxy

#### Redis Access (CLI)

```bash
# Start tunnel
cloudflared access tcp --hostname redis.tunnel.acme.com --url localhost:6379

# Connect Redis client
redis-cli -h localhost -p 6379

# Run commands (read-only)
> GET some_key
> HGETALL user:123
```

#### API Access (Browser or CLI)

```bash
# Browser
https://api.tunnel.acme.com/health

# CLI (with authentication)
curl https://api.tunnel.acme.com/health \
  --header "CF-Access-Client-Id: YOUR_CLIENT_ID" \
  --header "CF-Access-Client-Secret: YOUR_CLIENT_SECRET"
```

## Access Control

### Email-Based Access

```hcl
vendor_emails = [
  "engineer@vendor.com"
]
```

Only this specific email can access.

### Domain-Based Access

```hcl
vendor_domains = [
  "vendor.com"
]
```

Anyone with `@vendor.com` email can access.

### Group-Based Access

Create groups in Cloudflare dashboard:

1. Go to: **Zero Trust** → **Settings** → **Groups**
2. Create group: "Vendor Support Engineers"
3. Add rules: Email ends with `@vendor.com` AND email is verified

```hcl
allowed_access_groups = [
  "group-id-from-cloudflare"
]
```

### Time-Limited Access

Grant temporary access (e.g., support incident):

```hcl
enable_time_limited_access = true
time_limited_vendor_emails = [
  "contractor@temp-vendor.com"
]
```

Then in Cloudflare dashboard, add time restriction:
- **Access** → **Policies** → Edit policy
- Add **Require** rule: Time-based (Mon-Fri, 9am-5pm UTC)

After incident resolved, remove email from list.

## Security Features

### 1. No VPN Needed

- ✅ Vendors don't need VPN client
- ✅ No VPN credentials to manage
- ✅ Works from any network (coffee shop, home, office)

### 2. Zero Trust Authentication

- ✅ Every request authenticated via SSO
- ✅ No trust based on network location
- ✅ MFA enforced by identity provider (Google, Okta)

### 3. No Inbound Firewall Rules

- ✅ cloudflared initiates outbound connection to Cloudflare
- ✅ No need to open ports in AWS security groups
- ✅ Impossible for attackers to directly reach AWS resources

### 4. Per-Resource Access Control

Different vendors can access different resources:

```hcl
# Vendor A: S3 + API only
cloudflare_access_policy "vendor_a" {
  include {
    email = ["vendorA@example.com"]
  }
  # Only applies to S3 and API applications
}

# Vendor B: Database only
cloudflare_access_policy "vendor_b" {
  include {
    email = ["vendorB@example.com"]
  }
  # Only applies to database application
}
```

### 5. Session Expiration

- ✅ Sessions expire after 8 hours (configurable)
- ✅ Vendor must re-authenticate after expiration
- ✅ Immediate revocation: remove email = access lost

### 6. Complete Audit Trail

Every connection logged:
- **Cloudflare Logs**: Who accessed what, when, from where
- **CloudTrail**: S3 API calls (GetObject, PutObject, etc.)
- **RDS Proxy Logs**: Database queries
- **CloudWatch Logs**: cloudflared daemon logs

### 7. Read-Only Database Access

- ✅ Vendors connect to RDS Proxy (not production database)
- ✅ RDS Proxy uses IAM authentication
- ✅ Database user has SELECT-only permissions
- ✅ Cannot INSERT, UPDATE, DELETE

## Cost Breakdown

| Component | Monthly Cost |
|-----------|--------------|
| **Cloudflare Zero Trust** (5 users) | $7/user = $35 |
| **ECS Fargate** (2 tasks, 0.5 vCPU, 1GB) | $10 |
| **RDS Proxy** | $15 |
| **S3 Storage** (100 GB) | $2.30 |
| **S3 Requests** (1M operations) | $5 |
| **CloudTrail** | $2 |
| **NAT Gateway** (for cloudflared egress) | $32 |
| **Data Transfer** (100 GB outbound) | $9 |
| **Total** | **~$110/month** |

**Compare to**:
- **Site-to-Site VPN**: $36/month + $0.05/GB = **~$41/month** (but complex setup, no audit logs)
- **Direct Connect**: $50/month + $0.02/GB = **~$52/month** (but requires physical setup, long lead time)
- **SSH Bastion**: $30/month (EC2) but no SSO, shared keys, difficult to audit

**Cloudflare Tunnel advantages**:
- ✅ SSO integration (no VPN/SSH keys)
- ✅ Per-resource access control
- ✅ Complete audit logs
- ✅ Instant setup (no hardware)
- ✅ Works from anywhere

## Monitoring

### CloudWatch Dashboards

View dashboard: **CloudWatch** → **Dashboards** → `acme-cloudflare-tunnel`

**Metrics**:
- Cloudflared CPU/Memory usage
- RDS Proxy connections
- S3 4xx/5xx errors
- ECS task health

### CloudWatch Alarms

**Email alerts sent to SNS topic when**:
- Cloudflared CPU > 80%
- Cloudflared Memory > 80%
- RDS Proxy connections > 50
- S3 4xx errors > 10/5min

### Cloudflare Logs

View logs: **Zero Trust** → **Logs** → **Access**

**What's logged**:
- Who accessed (email)
- What resource (s3.tunnel.company.com, db.tunnel.company.com)
- When (timestamp)
- Where from (IP address, country)
- Allowed/Denied

**Example query**:
```
# Show all database access in last 24 hours
SELECT timestamp, user_email, hostname, action
FROM access_logs
WHERE hostname = 'db.tunnel.company.com'
  AND timestamp > now() - interval '24 hours'
ORDER BY timestamp DESC
```

### CloudTrail Logs

View logs: **CloudTrail** → **Event history**

**What's logged**:
- S3 API calls (GetObject, PutObject, DeleteObject)
- Who called (assumed IAM role from ECS task)
- Source IP (cloudflared task)
- Request parameters (bucket, key)

**Example query** (CloudTrail Insights):
```json
{
  "eventName": "PutObject",
  "resources": [{
    "ARN": "arn:aws:s3:::acme-vendor-exchange/*"
  }],
  "userIdentity": {
    "sessionContext": {
      "sessionIssuer": {
        "userName": "acme-ecs-task-role"
      }
    }
  }
}
```

## Troubleshooting

### Vendor Cannot Access S3 Web Interface

**Symptom**: Vendor opens `https://s3.tunnel.company.com` but gets 403 Forbidden

**Cause**: Vendor email not in `allowed_vendor_emails` or `allowed_vendor_domains`

**Solution**:
1. Check Cloudflare Access Logs: **Zero Trust** → **Logs** → **Access**
2. Verify vendor email matches allowed list
3. Add vendor email to `terraform.tfvars`:
   ```hcl
   vendor_emails = [
     "newvendor@example.com"
   ]
   ```
4. Run `terraform apply`

### Vendor Cannot Connect to Database via CLI

**Symptom**: `cloudflared access tcp` command times out

**Cause**: Security group blocking cloudflared → RDS Proxy

**Solution**:
1. Check security group rule: `aws ec2 describe-security-groups --group-ids <rds-proxy-sg-id>`
2. Verify rule exists allowing cloudflared SG → RDS Proxy port
3. If missing, run `terraform apply` to recreate rule

### Cloudflared Tasks Crashing

**Symptom**: ECS tasks keep restarting

**Cause**: Invalid tunnel token or secret

**Solution**:
1. Check CloudWatch Logs: `/ecs/acme-cloudflared`
2. Look for error: `failed to authenticate`
3. Regenerate tunnel token:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel delete acme-b2b-tunnel
   cloudflared tunnel create acme-b2b-tunnel
   ```
4. Update `cloudflare_tunnel_token` in `terraform.tfvars`
5. Run `terraform apply`

### High Costs

**Symptom**: AWS bill is $500/month for Cloudflare Tunnel (expected ~$110)

**Cause**: NAT Gateway data transfer (likely)

**Solution**:
1. Check NAT Gateway metrics: **VPC** → **NAT Gateways** → **Monitoring**
2. If > 100 GB/month transfer, consider:
   - Use VPC endpoints for S3 (save $0.09/GB)
   - Compress files before upload
   - Limit vendor access frequency

## Production Checklist

Before deploying to production:

- [ ] Enable MFA for all identity providers (Google, Okta)
- [ ] Set up Cloudflare Access groups (don't rely on individual emails)
- [ ] Configure time-based access restrictions (business hours only)
- [ ] Set up CloudWatch alarms with SNS notifications
- [ ] Test vendor access from external network (not corporate VPN)
- [ ] Review S3 bucket lifecycle policies (delete old files)
- [ ] Enable RDS Proxy query logging for audit
- [ ] Configure Cloudflare Access session duration (8h recommended)
- [ ] Test access revocation (remove vendor email, verify immediate lockout)
- [ ] Document vendor onboarding process

## Related Documentation

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/)
- [All Ports and Protocols Support](https://developers.cloudflare.com/changelog/2025-10-28-access-application-support-for-all-ports-and-protocols/)
- [B2B_INTEGRATION_ARCHITECTURE.md](../../B2B_INTEGRATION_ARCHITECTURE.md) - Overall B2B architecture
- [MICROSEGMENTATION_ARCHITECTURE.md](../../MICROSEGMENTATION_ARCHITECTURE.md) - Phase 8 microsegmentation
