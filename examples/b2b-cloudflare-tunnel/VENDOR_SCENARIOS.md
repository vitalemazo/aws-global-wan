# Vendor Access Scenarios - Complete Examples

This document provides **complete, realistic examples** of how to configure vendor access for different B2B scenarios.

## Fictional Company: AcmeTech

**Company**: AcmeTech Inc.
**Domain**: acmetech.com
**Business**: SaaS platform for financial analytics
**AWS Account**: 123456789012
**Cloudflare Account**: a1b2c3d4e5f6g7h8i9j0

## Vendor Companies

### 1. DataSync Corp
**Website**: https://datasync-corp.com
**Email Domain**: @datasync-corp.com
**Business**: Data integration and ETL services
**Access Needed**: S3 bucket (upload daily financial reports)

**Authorized Users**:
- John Smith (john.smith@datasync-corp.com) - Lead Engineer
- Sarah Chen (sarah.chen@datasync-corp.com) - Data Analyst

### 2. CloudOps Solutions
**Website**: https://cloudops-solutions.io
**Email Domain**: @cloudops-solutions.io
**Business**: Database administration and optimization
**Access Needed**: PostgreSQL database (read-only, troubleshooting)

**Authorized Users**:
- Mike Johnson (mike.johnson@cloudops-solutions.io) - Senior DBA
- Lisa Rodriguez (lisa.rodriguez@cloudops-solutions.io) - Support Engineer

### 3. API Partners Inc
**Website**: https://apipartners.com
**Email Domain**: @apipartners.com
**Business**: Third-party API integrations
**Access Needed**: Internal API endpoints, Redis cache

**Authorized Users**:
- Alex Kim (alex.kim@apipartners.com) - Integration Architect
- Emily Watson (emily.watson@apipartners.com) - DevOps Engineer

---

## Scenario 1: DataSync Corp - Daily S3 File Uploads

### Business Context

DataSync Corp processes financial transactions for AcmeTech. Every day at 6 AM UTC, they need to upload:
- `daily_transactions_YYYYMMDD.csv` (transaction data)
- `reconciliation_YYYYMMDD.json` (reconciliation report)

### Configuration

**terraform.tfvars**:
```hcl
company_name = "acmetech"

# Allow DataSync Corp domain (all employees can access)
vendor_domains = [
  "datasync-corp.com"
]

# Or restrict to specific users only:
vendor_emails = [
  "john.smith@datasync-corp.com",
  "sarah.chen@datasync-corp.com"
]

# Enable S3 access
enable_s3_access = true
s3_tunnel_hostname = "s3.tunnel.acmetech.com"

# Session lasts 12 hours (covers overnight processing)
session_duration = "12h"
```

**DNS Setup** (in Cloudflare):
```
Type: CNAME
Name: s3.tunnel.acmetech.com
Target: 12345678-90ab-cdef-1234-567890abcdef.cfargotunnel.com
Proxy: Enabled (orange cloud)
```

### Vendor Connection Instructions

**Email to DataSync Corp**:

```
Subject: S3 File Upload Access - AcmeTech Financial Data

Hi DataSync Team,

You now have access to upload daily financial reports via Cloudflare Tunnel.

Access URL: https://s3.tunnel.acmetech.com

How to Connect:
1. Navigate to: https://s3.tunnel.acmetech.com
2. Click "Sign in with Google" (use your @datasync-corp.com email)
3. Authenticate with your Google Workspace account
4. You'll see the file upload interface

Upload Requirements:
- File format: CSV (transactions) or JSON (reconciliation)
- Naming: daily_transactions_YYYYMMDD.csv
- Max size: 500 MB per file
- Schedule: Daily at 6:00 AM UTC
- Retention: 90 days (automatic deletion after)

Automated Upload (via API):
# Install cloudflared CLI
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Authenticate once (opens browser)
cloudflared access login https://s3.tunnel.acmetech.com

# Upload file programmatically
aws s3 cp daily_transactions_20251031.csv \
  s3://acmetech-vendor-exchange/datasync-uploads/ \
  --sse AES256

Security:
- Access expires after 12 hours (re-authenticate daily)
- All uploads logged to CloudTrail
- Files must be encrypted (enforced by bucket policy)
- Versioning enabled (previous versions kept for 90 days)

Support:
- Email: it-support@acmetech.com
- Slack: #vendor-support

Best regards,
AcmeTech IT Team
```

### S3 Bucket Structure

```
s3://acmetech-vendor-exchange/
├── datasync-uploads/          ← DataSync Corp uploads here
│   ├── daily_transactions_20251031.csv
│   ├── daily_transactions_20251030.csv
│   └── reconciliation_20251031.json
│
├── datasync-downloads/        ← DataSync Corp downloads processed results
│   ├── processed_20251031.csv
│   └── summary_20251031.json
│
└── archive/                   ← Old files (90+ days)
    └── (automatically moved by lifecycle policy)
```

### Monitoring

**CloudWatch Alarm**: Alert if no files uploaded by 7 AM UTC

```hcl
resource "aws_cloudwatch_metric_alarm" "datasync_missing_upload" {
  alarm_name          = "datasync-missing-daily-upload"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 3600  # 1 hour
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "DataSync has not uploaded files today"

  # Check at 7 AM UTC (1 hour after expected upload)
  # If no files in last hour, alert

  dimensions = {
    BucketName = "acmetech-vendor-exchange"
    FilterId   = "datasync-uploads"
  }
}
```

**CloudTrail Query**: Show all DataSync uploads

```sql
SELECT
  eventTime,
  userIdentity.principalId,
  requestParameters.bucketName,
  requestParameters.key,
  resources[0].ARN
FROM cloudtrail_logs
WHERE eventName = 'PutObject'
  AND requestParameters.bucketName = 'acmetech-vendor-exchange'
  AND requestParameters.key LIKE 'datasync-uploads/%'
ORDER BY eventTime DESC
LIMIT 100
```

---

## Scenario 2: CloudOps Solutions - Database Troubleshooting

### Business Context

CloudOps Solutions provides 24/7 database support. When AcmeTech experiences performance issues, CloudOps needs **immediate read-only access** to query production database and identify slow queries.

**Requirements**:
- Access granted on-demand (not 24/7)
- Read-only (no data modification)
- Time-limited (4 hours per incident)
- All queries logged for audit

### Configuration

**terraform.tfvars**:
```hcl
company_name = "acmetech"

# Allow specific CloudOps DBAs only
vendor_emails = [
  "mike.johnson@cloudops-solutions.io",
  "lisa.rodriguez@cloudops-solutions.io"
]

# Enable database access
enable_database_access = true
database_tunnel_hostname = "db.tunnel.acmetech.com"
database_endpoint = "acmetech-vendor-db-proxy.proxy-abcdef123456.us-east-1.rds.amazonaws.com"
database_port = 5432

# Session lasts 4 hours (per incident)
session_duration = "4h"

# Enable time-limited access
enable_time_limited_access = true
time_limited_vendor_emails = [
  "mike.johnson@cloudops-solutions.io"
]
```

**Cloudflare Access Policy** (time restriction):

In Cloudflare Dashboard:
1. **Zero Trust** → **Access** → **Applications**
2. Select: `db.tunnel.acmetech.com`
3. Edit Policy: "Allow CloudOps DBAs"
4. Add **Require** rule:
   - **Type**: Time-based
   - **Schedule**: Monday-Sunday, 00:00-23:59 UTC
   - **Duration**: 4 hours from first login

This ensures:
- Mike can access Monday 9 AM - Monday 1 PM
- After 4 hours, must request new access
- Lisa can access independently with her own 4-hour window

### Database Setup

**Create read-only user** (run this on RDS instance):

```sql
-- Create read-only role
CREATE ROLE vendor_readonly;
GRANT CONNECT ON DATABASE production TO vendor_readonly;
GRANT USAGE ON SCHEMA public TO vendor_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO vendor_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO vendor_readonly;

-- Create users for CloudOps DBAs (IAM authentication)
CREATE USER "mike_johnson" WITH LOGIN;
GRANT vendor_readonly TO "mike_johnson";

CREATE USER "lisa_rodriguez" WITH LOGIN;
GRANT vendor_readonly TO "lisa_rodriguez";

-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = 'on';
SELECT pg_reload_conf();
```

### Vendor Connection Instructions

**Email to CloudOps Solutions**:

```
Subject: Emergency Database Access - AcmeTech Production

Hi CloudOps Team,

You now have read-only access to troubleshoot database performance issues.

Access URL: tcp://db.tunnel.acmetech.com:5432

How to Connect:

1. Install cloudflared CLI:
   # macOS
   brew install cloudflare/cloudflare/cloudflared

   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
   sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
   sudo chmod +x /usr/local/bin/cloudflared

2. Start TCP tunnel:
   cloudflared access tcp --hostname db.tunnel.acmetech.com --url localhost:5432

3. Authenticate in browser (opens automatically):
   - Sign in with mike.johnson@cloudops-solutions.io
   - Use your Okta SSO credentials

4. Connect database client (in new terminal):
   psql -h localhost -p 5432 -U mike_johnson -d production

   Or use GUI:
   - Host: localhost
   - Port: 5432
   - Database: production
   - Username: mike_johnson
   - Password: (leave blank, IAM authentication)

Database Information:
- Engine: PostgreSQL 15.3
- Size: 500 GB
- Read-only access: SELECT queries only
- Query timeout: 30 seconds
- Max connections: 5 per user

Common Troubleshooting Queries:

-- Find slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 seconds'
ORDER BY duration DESC;

-- Table sizes
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;

Security & Compliance:
- Access expires after 4 hours (automatic logout)
- All queries logged to CloudWatch
- Read-only: Cannot INSERT/UPDATE/DELETE
- Connection via RDS Proxy (production DB isolated)

Incident Response:
1. Investigate slow queries (see above)
2. Identify missing indexes
3. Recommend optimization (send to it-support@acmetech.com)
4. Access automatically revoked after 4 hours

Support:
- Emergency: +1-555-0100 (24/7 hotline)
- Email: it-support@acmetech.com

Best regards,
AcmeTech DBA Team
```

### Monitoring

**CloudWatch Dashboard**: Database Access Metrics

```hcl
resource "aws_cloudwatch_dashboard" "cloudops_db_access" {
  dashboard_name = "cloudops-database-access"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Sum", label = "Connections" }]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "CloudOps DB Connections"
        }
      },
      {
        type = "log"
        properties = {
          query = <<-EOT
            fields @timestamp, @message
            | filter @message like /mike_johnson|lisa_rodriguez/
            | sort @timestamp desc
            | limit 100
          EOT
          region = "us-east-1"
          title  = "CloudOps Query Log"
        }
      }
    ]
  })
}
```

---

## Scenario 3: API Partners Inc - API Integration

### Business Context

API Partners Inc integrates AcmeTech's financial data with third-party systems (Salesforce, QuickBooks, etc.). They need:
- **API access**: Call internal REST endpoints
- **Redis access**: Cache frequently-used data
- **Webhook endpoint**: Receive real-time updates

### Configuration

**terraform.tfvars**:
```hcl
company_name = "acmetech"

# Allow API Partners domain
vendor_domains = [
  "apipartners.com"
]

# Enable API and Redis access
enable_redis_access = true
redis_tunnel_hostname = "redis.tunnel.acmetech.com"
redis_endpoint = "acmetech-prod-redis.abc123.0001.use1.cache.amazonaws.com"
redis_port = 6379

api_endpoints = [
  {
    hostname = "api.tunnel.acmetech.com"
    service  = "http://internal-api-prod-1234567890.us-east-1.elb.amazonaws.com"
    path     = "/v1/*"  # Only /v1 endpoints
  }
]

# Session lasts 24 hours (full business day)
session_duration = "24h"
```

### API Endpoints Available

**Internal API** (via `api.tunnel.acmetech.com`):

```
GET  /v1/transactions         - List recent transactions
GET  /v1/transactions/{id}    - Get transaction details
GET  /v1/accounts             - List accounts
GET  /v1/accounts/{id}        - Get account details
POST /v1/webhooks             - Register webhook URL
GET  /v1/health               - Health check
```

### Vendor Connection Instructions

**Email to API Partners Inc**:

```
Subject: API Integration Access - AcmeTech Financial Platform

Hi API Partners Team,

You now have access to our internal API and Redis cache for integration development.

=== API Access ===

Base URL: https://api.tunnel.acmetech.com/v1

Authentication:
1. Navigate to: https://api.tunnel.acmetech.com/v1/health
2. Sign in with Google (use @apipartners.com email)
3. After authentication, you'll receive:
   - CF-Access-Client-Id: abcd1234-5678-90ef-ghij-klmnopqrstuv
   - CF-Access-Client-Secret: xyz789...

4. Use in API calls:
   curl https://api.tunnel.acmetech.com/v1/transactions \
     -H "CF-Access-Client-Id: abcd1234-5678-90ef-ghij-klmnopqrstuv" \
     -H "CF-Access-Client-Secret: xyz789..." \
     -H "Content-Type: application/json"

Example Requests:

# Get recent transactions
curl https://api.tunnel.acmetech.com/v1/transactions?limit=10

# Get transaction details
curl https://api.tunnel.acmetech.com/v1/transactions/txn_abc123

# Register webhook (for real-time updates)
curl -X POST https://api.tunnel.acmetech.com/v1/webhooks \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://apipartners.com/webhooks/acmetech",
    "events": ["transaction.created", "transaction.updated"]
  }'

Rate Limits:
- 1000 requests per hour
- 10 requests per second
- If exceeded: HTTP 429 (retry after 60 seconds)

=== Redis Cache Access ===

Connection URL: tcp://redis.tunnel.acmetech.com:6379

How to Connect:

1. Start TCP tunnel:
   cloudflared access tcp --hostname redis.tunnel.acmetech.com --url localhost:6379

2. Connect Redis client:
   redis-cli -h localhost -p 6379

3. Read cached data:
   # Get transaction from cache
   GET transaction:txn_abc123

   # Get account summary
   HGETALL account:acc_xyz789

Read-Only Access:
- You can GET data from Redis
- Cannot SET/DEL (read-only permissions)
- Cache TTL: 5 minutes

Cache Key Patterns:
- transaction:{id}    - Transaction data (JSON)
- account:{id}        - Account data (JSON)
- rate_limit:{api_key} - Rate limit counters
- session:{token}     - Session data

=== Webhook Setup ===

To receive real-time updates:

1. Implement webhook endpoint (POST):
   POST https://apipartners.com/webhooks/acmetech
   Content-Type: application/json
   X-Webhook-Signature: sha256=...

2. Verify signature (HMAC-SHA256):
   secret = "webhook_secret_abc123"
   signature = HMAC-SHA256(request.body, secret)
   assert signature == request.headers['X-Webhook-Signature']

3. Event types:
   - transaction.created
   - transaction.updated
   - account.updated

Example Payload:
{
  "event": "transaction.created",
  "timestamp": "2025-10-31T14:30:00Z",
  "data": {
    "id": "txn_abc123",
    "amount": 150.00,
    "currency": "USD",
    "status": "completed"
  }
}

=== Integration Testing ===

Sandbox Environment:
- Base URL: https://sandbox-api.tunnel.acmetech.com/v1
- Test data: Pre-populated with sample transactions
- No rate limits
- Safe to experiment

Production Environment:
- Base URL: https://api.tunnel.acmetech.com/v1
- Real customer data (handle with care)
- Rate limits enforced
- PCI-compliant logging

=== Support ===

Documentation: https://docs.acmetech.com/api
Slack: #api-partners-support
Email: api-support@acmetech.com
Status Page: https://status.acmetech.com

Best regards,
AcmeTech API Team
```

### Rate Limiting Configuration

**API Gateway** (behind Cloudflare Tunnel):

```hcl
resource "aws_api_gateway_usage_plan" "api_partners" {
  name        = "api-partners-usage-plan"
  description = "Rate limits for API Partners Inc"

  throttle_settings {
    burst_limit = 20      # 20 requests in burst
    rate_limit  = 10      # 10 requests per second sustained
  }

  quota_settings {
    limit  = 1000         # 1000 requests per hour
    period = "HOUR"
  }
}
```

### Monitoring

**CloudWatch Alarm**: High API Error Rate

```hcl
resource "aws_cloudwatch_metric_alarm" "api_partners_errors" {
  alarm_name          = "api-partners-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Partners experiencing high error rate"

  dimensions = {
    ApiName = "acmetech-internal-api"
  }
}
```

---

## Access Control Matrix

| Vendor | S3 | Database | Redis | API | SSH | Session Duration |
|--------|-------|----------|-------|-----|-----|------------------|
| **DataSync Corp** | ✅ Upload/Download | ❌ | ❌ | ❌ | ❌ | 12 hours |
| **CloudOps Solutions** | ❌ | ✅ Read-only | ❌ | ❌ | ⚠️ Emergency only | 4 hours |
| **API Partners Inc** | ❌ | ❌ | ✅ Read-only | ✅ Full | ❌ | 24 hours |

## Summary

This provides **complete, realistic examples** showing:

1. **DataSync Corp**: Daily S3 file uploads with automated processing
2. **CloudOps Solutions**: On-demand database troubleshooting with time limits
3. **API Partners Inc**: API integration with Redis caching and webhooks

Each scenario includes:
- ✅ Terraform configuration
- ✅ DNS setup
- ✅ Vendor connection instructions (copy-paste ready)
- ✅ Security policies
- ✅ Monitoring and alerting
- ✅ Common queries and troubleshooting

You can use these as templates for your own vendor integrations!
