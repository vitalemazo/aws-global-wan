# AI Orchestration for Network Operations

Complete guide for using AI (Claude, GPT-4, or custom LLM) as a single orchestrator to manage AWS Global WAN infrastructure.

## Overview

Instead of multiple human teams (networking, security, compliance), a **single AI agent** can:
- Monitor all infrastructure (CloudWatch, logs, metrics)
- Detect issues automatically (anomalies, security threats)
- Make decisions based on context (severity, compliance, cost)
- Execute changes (Terraform, AWS APIs, alerts)
- Document everything (runbooks, incident reports, compliance docs)

## AI Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ AI Orchestrator (Claude / GPT-4 / Custom LLM)                  │
│                                                                  │
│ Capabilities:                                                    │
│  1. Natural Language Understanding (parse alerts, tickets)      │
│  2. Context Awareness (query logs, metrics, documentation)      │
│  3. Decision Making (evaluate options, assess risk)             │
│  4. Code Generation (Terraform, Python, bash scripts)           │
│  5. Execution (run commands, update infrastructure)             │
│  6. Learning (improve from past incidents, feedback)            │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ Input Layer (Event Driven)                                      │
│                                                                  │
│  CloudWatch Alarms → EventBridge → Lambda → AI Agent           │
│  GuardDuty Findings → EventBridge → Lambda → AI Agent          │
│  VPC Flow Logs → S3 → Athena → AI Agent                        │
│  User Requests → Slack → API Gateway → Lambda → AI Agent       │
│  Scheduled Tasks → EventBridge (cron) → Lambda → AI Agent      │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ Decision Engine (AI Logic)                                      │
│                                                                  │
│  1. Parse Input: What happened? (alarm, request, threat)        │
│  2. Gather Context: Query logs, metrics, documentation          │
│  3. Assess Impact: Critical? Production? Compliance risk?       │
│  4. Evaluate Options: Auto-fix? Scale? Block? Alert human?      │
│  5. Check Approvals: Auto-approved or needs human review?       │
│  6. Generate Plan: Step-by-step remediation                     │
│  7. Simulate: Predict outcome (cost, downtime, risk)            │
│  8. Execute: Run plan (if approved)                             │
│  9. Document: Log everything for audit                          │
│  10. Learn: Update knowledge base for future                    │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ Execution Layer (Actions)                                       │
│                                                                  │
│  Terraform:                                                      │
│    - Update firewall rules                                      │
│    - Scale infrastructure                                       │
│    - Deploy new VPCs                                            │
│                                                                  │
│  AWS APIs:                                                       │
│    - Block security groups                                      │
│    - Update route tables                                        │
│    - Revoke IAM permissions                                     │
│                                                                  │
│  Notifications:                                                  │
│    - Slack alerts                                               │
│    - PagerDuty incidents                                        │
│    - Email reports                                              │
│                                                                  │
│  Documentation:                                                  │
│    - Update runbooks                                            │
│    - Generate compliance reports                                │
│    - Create incident post-mortems                               │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation: AI Lambda Function

### Core AI Agent (Python + Anthropic Claude API)

```python
# ai_orchestrator.py

import anthropic
import boto3
import json
from typing import Dict, List, Any

class NetworkOrchestrator:
    """
    AI-powered network orchestrator for AWS Global WAN.
    Monitors, decides, and executes network operations autonomously.
    """

    def __init__(self):
        self.claude = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
        self.ec2 = boto3.client('ec2')
        self.cloudwatch = boto3.client('cloudwatch')
        self.logs = boto3.client('logs')
        self.athena = boto3.client('athena')

        # Knowledge base (S3 bucket with documentation)
        self.knowledge_base = {
            'runbooks': 's3://acmetech-docs/runbooks/',
            'compliance': 's3://acmetech-docs/compliance/',
            'network_diagram': 's3://acmetech-docs/architecture.png',
            'terraform_modules': 's3://acmetech-terraform/modules/'
        }

    def handle_event(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main entry point for all events (alarms, requests, incidents).
        """
        event_type = self.classify_event(event)

        if event_type == 'security_incident':
            return self.handle_security_incident(event)
        elif event_type == 'capacity_alarm':
            return self.handle_capacity_alarm(event)
        elif event_type == 'user_request':
            return self.handle_user_request(event)
        elif event_type == 'scheduled_task':
            return self.handle_scheduled_task(event)
        else:
            return self.handle_unknown_event(event)

    def classify_event(self, event: Dict[str, Any]) -> str:
        """
        Use Claude to classify the event type.
        """
        prompt = f"""
        Classify this AWS event:

        Event: {json.dumps(event, indent=2)}

        Event types:
        - security_incident: GuardDuty finding, security group breach, firewall block
        - capacity_alarm: High CPU, memory, network throughput
        - user_request: Slack message, ticket, API call
        - scheduled_task: Cron job, maintenance window
        - unknown: Other

        Respond with ONLY the event type (one word).
        """

        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=50,
            messages=[{"role": "user", "content": prompt}]
        )

        return response.content[0].text.strip()

    def handle_security_incident(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle security incidents (GuardDuty, firewall blocks, etc.)
        """
        # Step 1: Gather context
        context = self.gather_security_context(event)

        # Step 2: AI decision making
        decision = self.make_security_decision(event, context)

        # Step 3: Execute if auto-approved
        if decision['auto_approved']:
            result = self.execute_security_remediation(decision)
        else:
            result = self.escalate_to_human(decision)

        # Step 4: Document
        self.document_incident(event, decision, result)

        return result

    def gather_security_context(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Query VPC Flow Logs, CloudTrail, firewall logs for context.
        """
        finding_id = event['detail']['id']
        resource_id = event['detail']['resource']['instanceDetails']['instanceId']

        # Query VPC Flow Logs (Athena)
        flow_logs_query = f"""
        SELECT srcaddr, dstaddr, srcport, dstport, protocol, bytes, packets
        FROM vpc_flow_logs
        WHERE instanceid = '{resource_id}'
          AND start >= now() - interval '1' hour
        ORDER BY start DESC
        LIMIT 1000
        """

        flow_logs = self.run_athena_query(flow_logs_query)

        # Query CloudTrail for recent API calls
        cloudtrail_query = f"""
        SELECT eventName, eventTime, userIdentity, sourceIPAddress
        FROM cloudtrail_logs
        WHERE resources[0].ARN LIKE '%{resource_id}%'
          AND eventTime >= now() - interval '24' hours
        ORDER BY eventTime DESC
        LIMIT 100
        """

        cloudtrail = self.run_athena_query(cloudtrail_query)

        # Query Network Firewall logs
        firewall_logs = self.cloudwatch.filter_log_events(
            logGroupName='/aws/networkfirewall/inspection-vpc',
            filterPattern=f'"{resource_id}"',
            startTime=int((time.time() - 3600) * 1000)  # Last 1 hour
        )

        return {
            'flow_logs': flow_logs,
            'cloudtrail': cloudtrail,
            'firewall_logs': firewall_logs['events'],
            'instance_metadata': self.get_instance_metadata(resource_id)
        }

    def make_security_decision(self, event: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Use Claude to analyze context and make security decision.
        """
        prompt = f"""
        You are a network security expert managing AWS Global WAN infrastructure.

        SECURITY INCIDENT:
        {json.dumps(event['detail'], indent=2)}

        CONTEXT:
        - VPC Flow Logs: {len(context['flow_logs'])} connections in last hour
        - CloudTrail: {len(context['cloudtrail'])} API calls in last 24 hours
        - Firewall Logs: {len(context['firewall_logs'])} firewall events
        - Instance: {context['instance_metadata']}

        SUSPICIOUS ACTIVITY:
        {self.format_suspicious_activity(context)}

        YOUR TASK:
        Analyze this incident and provide:
        1. Severity (1-10, 10 = critical)
        2. Threat assessment (what's happening?)
        3. Impact (production? customer data? compliance?)
        4. Recommended action (block, isolate, alert, ignore)
        5. Auto-approve? (can AI execute without human review?)
        6. Justification (explain your reasoning)

        Respond in JSON format:
        {{
          "severity": 8,
          "threat": "Cryptocurrency mining detected",
          "impact": "Production segment, no customer data at risk",
          "action": "isolate_instance",
          "auto_approved": true,
          "justification": "High severity, production impact, but no data exfiltration. Isolation prevents further damage. Auto-approved per security policy."
        }}
        """

        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )

        decision = json.loads(response.content[0].text)

        # Add execution plan
        if decision['action'] == 'isolate_instance':
            decision['execution_plan'] = self.generate_isolation_plan(event, context)

        return decision

    def execute_security_remediation(self, decision: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute security remediation based on AI decision.
        """
        if decision['action'] == 'isolate_instance':
            return self.isolate_instance(decision['execution_plan'])
        elif decision['action'] == 'block_ip':
            return self.block_ip(decision['execution_plan'])
        elif decision['action'] == 'revoke_access':
            return self.revoke_access(decision['execution_plan'])
        else:
            return {'status': 'error', 'message': f"Unknown action: {decision['action']}"}

    def isolate_instance(self, plan: Dict[str, Any]) -> Dict[str, Any]:
        """
        Isolate compromised instance by revoking all security group egress.
        """
        instance_id = plan['instance_id']
        security_groups = plan['security_groups']

        results = []

        for sg_id in security_groups:
            # Revoke all egress rules
            response = self.ec2.revoke_security_group_egress(
                GroupId=sg_id,
                IpPermissions=[{
                    'IpProtocol': '-1',  # All protocols
                    'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                }]
            )

            results.append({
                'sg_id': sg_id,
                'action': 'revoked_egress',
                'status': 'success'
            })

            # Notify team
            self.send_slack_alert(
                channel='#security-incidents',
                message=f'🚨 INSTANCE ISOLATED: {instance_id}\n'
                        f'Security group {sg_id} egress revoked\n'
                        f'Reason: {plan["reason"]}\n'
                        f'Duration: {time.time() - plan["start_time"]:.2f} seconds'
            )

        return {
            'status': 'success',
            'action': 'isolate_instance',
            'instance_id': instance_id,
            'results': results,
            'duration': time.time() - plan['start_time']
        }

    def handle_capacity_alarm(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle capacity alarms (high CPU, memory, network).
        """
        # Step 1: Gather metrics
        metrics = self.gather_capacity_metrics(event)

        # Step 2: AI decision
        decision = self.make_capacity_decision(event, metrics)

        # Step 3: Execute if auto-approved
        if decision['auto_approved']:
            result = self.execute_scaling(decision)
        else:
            result = self.escalate_to_human(decision)

        return result

    def make_capacity_decision(self, event: Dict[str, Any], metrics: Dict[str, Any]) -> Dict[str, Any]:
        """
        Use Claude to decide on capacity scaling.
        """
        prompt = f"""
        You are managing AWS Global WAN infrastructure capacity.

        CAPACITY ALARM:
        {json.dumps(event['detail'], indent=2)}

        METRICS (Last 7 days):
        - Current: {metrics['current']}
        - Average: {metrics['average']}
        - Peak: {metrics['peak']}
        - Trend: {metrics['trend']}
        - Cost: {metrics['cost_per_month']}

        SCALING OPTIONS:
        1. Scale out (add capacity): +${metrics['scale_out_cost']}/month
        2. Scale up (bigger instances): +${metrics['scale_up_cost']}/month
        3. Optimize (e.g., PrivateLink): +${metrics['optimize_cost']}/month (long-term savings)
        4. Do nothing (temporary spike)

        YOUR TASK:
        Decide on best scaling approach. Consider:
        - Is this sustained high usage or temporary spike?
        - What's the cost impact?
        - Can we optimize instead of scaling?
        - Business hours vs overnight traffic pattern?

        Respond in JSON format:
        {{
          "action": "optimize",
          "reasoning": "60% of traffic is Stripe API calls. Implementing PrivateLink bypasses firewall, saves capacity + cost.",
          "cost_impact": "+$14/month (PrivateLink) vs +$395/month (firewall scaling)",
          "timeline": "2-3 hours implementation",
          "auto_approved": false,
          "approval_reason": "Cost savings exceed $100/month, needs network team review"
        }}
        """

        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )

        return json.loads(response.content[0].text)

    def handle_user_request(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle user requests from Slack, tickets, or API.
        """
        # Parse natural language request
        request_text = event['text']

        # AI understands intent
        intent = self.parse_intent(request_text)

        if intent['type'] == 'add_firewall_rule':
            return self.handle_firewall_rule_request(intent, event['user'])
        elif intent['type'] == 'grant_vendor_access':
            return self.handle_vendor_access_request(intent, event['user'])
        elif intent['type'] == 'troubleshoot_connectivity':
            return self.troubleshoot_connectivity(intent)
        else:
            return self.handle_generic_request(request_text)

    def parse_intent(self, text: str) -> Dict[str, Any]:
        """
        Use Claude to understand user intent from natural language.
        """
        prompt = f"""
        Parse this network operations request:

        Request: "{text}"

        Identify:
        1. Intent type (add_firewall_rule, grant_vendor_access, troubleshoot_connectivity, etc.)
        2. Parameters (domains, IPs, user emails, segments, etc.)
        3. Urgency (normal, high, critical)
        4. Compliance risk (low, medium, high)

        Respond in JSON format:
        {{
          "type": "add_firewall_rule",
          "parameters": {{
            "domain": "salesforce.com",
            "segment": "prod-api",
            "direction": "egress"
          }},
          "urgency": "normal",
          "compliance_risk": "low",
          "reasoning": "User wants to allow API calls to Salesforce, low risk (SOC 2 certified vendor)"
        }}
        """

        response = self.claude.messages.create(
            model="claude-sonnet-4",
            max_tokens=500,
            messages=[{"role": "user", "content": prompt}]
        )

        return json.loads(response.content[0].text)

    def handle_scheduled_task(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle scheduled tasks (cron jobs, maintenance).
        """
        task_type = event['task_type']

        if task_type == 'daily_compliance_report':
            return self.generate_compliance_report()
        elif task_type == 'weekly_capacity_review':
            return self.review_capacity()
        elif task_type == 'monthly_cost_optimization':
            return self.optimize_costs()
        else:
            return {'status': 'error', 'message': f'Unknown task: {task_type}'}

    def generate_compliance_report(self) -> Dict[str, Any]:
        """
        AI generates daily compliance report.
        """
        # Query all access logs (VPC Flow, CloudTrail, Cloudflare)
        logs = self.gather_compliance_logs()

        # AI analyzes for compliance violations
        violations = self.check_compliance_violations(logs)

        # AI generates report
        report = self.create_compliance_report(logs, violations)

        # Send report
        self.send_compliance_report(report)

        return {'status': 'success', 'report_url': report['url']}

    # ... (additional helper methods)

```

### Lambda Function Handler

```python
# lambda_function.py

import json
from ai_orchestrator import NetworkOrchestrator

def lambda_handler(event, context):
    """
    AWS Lambda handler for AI orchestrator.
    """
    orchestrator = NetworkOrchestrator()

    try:
        result = orchestrator.handle_event(event)
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'event': event
            })
        }
```

### EventBridge Rules (Trigger AI)

```hcl
# CloudWatch Alarm → AI
resource "aws_cloudwatch_event_rule" "alarm_to_ai" {
  name        = "cloudwatch-alarm-to-ai-orchestrator"
  description = "Trigger AI orchestrator on CloudWatch alarms"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "ai_lambda" {
  rule      = aws_cloudwatch_event_rule.alarm_to_ai.name
  target_id = "AIOrchestrator"
  arn       = aws_lambda_function.ai_orchestrator.arn
}

# GuardDuty Finding → AI
resource "aws_cloudwatch_event_rule" "guardduty_to_ai" {
  name        = "guardduty-finding-to-ai-orchestrator"
  description = "Trigger AI orchestrator on GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 8, 9, 10]  # High severity only
    }
  })
}

resource "aws_cloudwatch_event_target" "ai_lambda_guardduty" {
  rule      = aws_cloudwatch_event_rule.guardduty_to_ai.name
  target_id = "AIOrchestrator"
  arn       = aws_lambda_function.ai_orchestrator.arn
}

# Scheduled Task (Daily Compliance Report)
resource "aws_cloudwatch_event_rule" "daily_compliance" {
  name                = "daily-compliance-report"
  description         = "Generate daily compliance report at 8 AM UTC"
  schedule_expression = "cron(0 8 * * ? *)"  # 8:00 AM UTC daily
}

resource "aws_cloudwatch_event_target" "ai_lambda_compliance" {
  rule      = aws_cloudwatch_event_rule.daily_compliance.name
  target_id = "AIOrchestrator"
  arn       = aws_lambda_function.ai_orchestrator.arn

  input = jsonencode({
    task_type = "daily_compliance_report"
  })
}
```

### Slack Integration (User Requests)

```python
# slack_bot.py

from slack_bolt import App
from ai_orchestrator import NetworkOrchestrator

app = App(token=os.environ["SLACK_BOT_TOKEN"])
orchestrator = NetworkOrchestrator()

@app.message("add firewall rule")
def handle_firewall_request(message, say):
    """
    Handle firewall rule requests from Slack.
    """
    # User types: "@network-bot add firewall rule for salesforce.com in prod-api"
    request_text = message['text']
    user_email = app.client.users_info(user=message['user'])['user']['profile']['email']

    # AI processes request
    result = orchestrator.handle_user_request({
        'text': request_text,
        'user': user_email,
        'channel': message['channel']
    })

    # Respond in Slack
    if result['auto_approved']:
        say(f"✅ Firewall rule added: {result['domain']}\n"
            f"Effective: {result['timestamp']}\n"
            f"Approval: Auto-approved (security team notified)")
    else:
        say(f"⏳ Request pending approval: {result['ticket_id']}\n"
            f"Reason: {result['approval_reason']}\n"
            f"Approver: {result['approver_team']}")

@app.message("status")
def handle_status_request(message, say):
    """
    Get network status.
    """
    # AI queries metrics and generates summary
    status = orchestrator.get_network_status()

    say(f"📊 Network Status:\n"
        f"- Core Network: {status['core_network']} (all segments healthy)\n"
        f"- Inspection VPC: {status['inspection_vpc']} (8.2 TB/day, 82% capacity)\n"
        f"- Firewall: {status['firewall']} (0 critical alerts)\n"
        f"- Active Incidents: {status['incidents']} incidents\n"
        f"Last updated: {status['timestamp']}")

if __name__ == "__main__":
    app.start(port=3000)
```

## AI Decision Matrix

| Event Type | Severity | AI Can Auto-Execute | Requires Human Approval |
|------------|----------|---------------------|------------------------|
| **Malicious IP detected** | High | ✅ Block at firewall | ❌ |
| **Crypto mining detected** | High | ✅ Isolate instance | ❌ |
| **DDoS attack** | Critical | ✅ Enable rate limiting | ❌ |
| **Add firewall rule (block)** | Medium | ✅ If threat intel match | ❌ |
| **Add firewall rule (allow)** | Medium | ❌ | ✅ Security team |
| **Grant vendor access** | Medium | ❌ | ✅ Security team |
| **Revoke vendor access** | Medium | ✅ If expired/suspicious | ❌ |
| **Scale capacity (< $100/mo)** | Low | ✅ If sustained trend | ❌ |
| **Scale capacity (> $100/mo)** | Low | ❌ | ✅ Network team |
| **Create new segment** | Medium | ❌ | ✅ Network architect |
| **Delete segment** | High | ❌ | ✅ All teams (network + security + compliance) |
| **Regional failover** | Critical | ❌ | ✅ Emergency escalation |

## AI Learning & Improvement

### Feedback Loop

```python
def learn_from_incident(incident_id: str, human_feedback: str):
    """
    AI learns from human feedback on decisions.
    """
    incident = load_incident(incident_id)

    # AI reflects on decision
    prompt = f"""
    INCIDENT: {incident['summary']}

    YOUR DECISION:
    {incident['ai_decision']}

    HUMAN FEEDBACK:
    {human_feedback}

    REFLECTION:
    1. Was your decision correct? Why or why not?
    2. What did you miss in your analysis?
    3. How should you handle similar incidents in the future?
    4. Update your knowledge base with this lesson.

    Respond with updated decision criteria for future incidents.
    """

    reflection = claude.messages.create(
        model="claude-sonnet-4",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )

    # Store learning in knowledge base
    store_lesson(incident_id, reflection.content[0].text)
```

### Knowledge Base (Vector Store)

```python
# Store documentation, runbooks, past incidents in vector database
# AI can query similar past incidents to improve decisions

from pinecone import Pinecone
import openai

pc = Pinecone(api_key=os.environ['PINECONE_API_KEY'])
index = pc.Index('network-knowledge')

def store_incident(incident: Dict[str, Any]):
    """
    Store incident in vector database for future reference.
    """
    # Generate embedding
    embedding = openai.Embedding.create(
        model="text-embedding-ada-002",
        input=incident['description']
    )

    # Store in Pinecone
    index.upsert([(
        incident['id'],
        embedding['data'][0]['embedding'],
        {
            'description': incident['description'],
            'decision': incident['ai_decision'],
            'outcome': incident['outcome'],
            'feedback': incident['human_feedback']
        }
    )])

def find_similar_incidents(description: str, top_k: int = 5):
    """
    Find similar past incidents for context.
    """
    # Generate embedding for query
    embedding = openai.Embedding.create(
        model="text-embedding-ada-002",
        input=description
    )

    # Query Pinecone
    results = index.query(
        vector=embedding['data'][0]['embedding'],
        top_k=top_k,
        include_metadata=True
    )

    return [match['metadata'] for match in results['matches']]
```

## Cost Analysis: Human Teams vs AI

### Current (Human Teams)

| Team | Headcount | Annual Cost |
|------|-----------|-------------|
| Network Engineers | 3 × $150k | $450k |
| Security Analysts | 2 × $130k | $260k |
| Compliance Officer | 1 × $120k | $120k |
| **Total** | **6 people** | **$830k/year** |

### With AI Orchestrator

| Component | Annual Cost |
|-----------|-------------|
| Claude API (1M tokens/day) | $50k |
| AWS Lambda (1M invocations/month) | $2k |
| Vector Database (Pinecone) | $10k |
| Human oversight (1 network architect) | $180k |
| **Total** | **$242k/year** |

**Savings**: $588k/year (71% reduction)

## Next Steps

Would you like me to:
1. Continue with more operational documentation (troubleshooting playbooks, change management)?
2. Implement a working AI orchestrator Lambda function?
3. Create detailed runbooks for common scenarios?
4. Add monitoring dashboards and alerting configuration?
