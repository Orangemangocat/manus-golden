# Manus Multi-Agent Orchestrator - Knowledge Base

## System Overview

The Manus Multi-Agent Orchestrator is a distributed system that coordinates multiple AI agents to handle system administration tasks. It consists of three main services that work together to process requests and execute tasks.

### Architecture Components

#### 1. **manus-orchestrator** (Port 8080)
- **Purpose:** Central coordination service that manages task queues and routes jobs to appropriate agents
- **Technology:** FastAPI/Uvicorn (Python)
- **Location:** `/opt/manus-orchestrator/`
- **Main File:** `app.py`
- **Configuration:** `config.yaml`
- **Service:** `manus-orchestrator.service`

#### 2. **manus-agent**
- **Purpose:** General-purpose agent for executing system administration tasks
- **Technology:** Python
- **Location:** `/opt/manus-agent/`
- **Main File:** `agent.py`
- **Configuration:** `config.yaml`
- **Service:** `manus-agent.service`

#### 3. **manus-chatgpt-agent**
- **Purpose:** AI-powered agent using ChatGPT for task analysis, planning, and risk assessment
- **Technology:** Python with OpenAI API
- **Location:** `/opt/manus-chatgpt-agent/`
- **Main File:** `chatgpt_agent.py`
- **Configuration:** `config.yaml`
- **Service:** `manus-chatgpt-agent.service`

---

## API Endpoints Reference

### Orchestrator API (http://localhost:8080/api/v1)

All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

#### Job Management
- **`POST /api/v1/jobs/poll`** - Agents poll for available jobs
  - Request body: `{"agent_type": "chatgpt", "server_id": "web-1"}`
  - Response: `{"job": {...}}` or `{"job": null}` if no jobs available

- **`POST /api/v1/jobs/result`** - Agents submit job results
  - Request body: `{"task_id": "...", "result": {...}}`

#### Request Management
- **`POST /api/v1/requests`** - Submit new requests to the orchestrator
- **`GET /api/v1/requests/{request_id}`** - Get request result by ID
- **`POST /api/v1/approve`** - Approve pending requests

#### Agent Management
- **`POST /api/v1/agents/heartbeat`** - Agents send heartbeat signals
- **`GET /api/v1/agents/status`** - Get status of all registered agents

#### System Status
- **`GET /api/v1/queue/status`** - Get current task queue status
- **`GET /api/v1/collaboration/sessions`** - Get active collaboration sessions

#### Collaboration
- **`POST /api/v1/collaboration/request`** - Request collaboration between agents

---

## Authentication

### JWT Token Structure

All services use **RS256** JWT tokens for authentication.

**Token Payload:**
```json
{
  "sub": "{server_id}:{agent_type}",
  "aud": "manus-orchestrator",
  "exp": <timestamp + 300>,
  "iat": <timestamp>,
  "agent_type": "chatgpt",
  "server_id": "web-1"
}
```

**Private Keys:**
- Orchestrator: `/opt/manus-orchestrator/keys/jwk_private.pem`
- Manus Agent: `/opt/manus-agent/jwk_private.pem`
- ChatGPT Agent: `/opt/manus-chatgpt-agent/jwk_private.pem`

**Generating Admin Token:**
```bash
sudo manus-admin token
```

---

## File Locations

### Service Directories
```
/opt/manus-orchestrator/     # Orchestrator service
/opt/manus-agent/            # Manus agent service
/opt/manus-chatgpt-agent/    # ChatGPT agent service
```

### Configuration Files
```
/opt/manus-orchestrator/config.yaml
/opt/manus-agent/config.yaml
/opt/manus-chatgpt-agent/config.yaml
```

### Log Files
```
/var/log/manus-orchestrator.log
/var/log/manus-agent.log
/var/log/manus-chatgpt-agent.log
```

**Note:** Logs are also available via systemd journal:
```bash
sudo journalctl -u manus-orchestrator.service -f
sudo journalctl -u manus-agent.service -f
sudo journalctl -u manus-chatgpt-agent.service -f
```

### Virtual Environments
```
/opt/manus-orchestrator/.venv/
/opt/manus-agent/.venv/
/opt/manus-chatgpt-agent/.venv/
```

### Admin Tool
```
/usr/local/bin/manus-admin
```

---

## Common Operations

### Using manus-admin

The `manus-admin` command provides convenient management of the orchestrator system.

#### Check System Status
```bash
sudo manus-admin status
```

#### Service Management
```bash
sudo manus-admin start       # Start all services
sudo manus-admin stop        # Stop all services
sudo manus-admin restart     # Restart all services
```

#### View Logs
```bash
sudo manus-admin logs orchestrator
sudo manus-admin logs agent
sudo manus-admin logs chatgpt
```

#### API Operations
```bash
sudo manus-admin token       # Generate admin JWT token
sudo manus-admin test        # Test API connectivity
sudo manus-admin queue       # Show task queue status
sudo manus-admin agents      # Show agent status
```

#### System Maintenance
```bash
sudo manus-admin fix         # Fix common issues (permissions, dependencies)
sudo manus-admin info        # Show system information
```

### Manual Service Management

```bash
# Check service status
sudo systemctl status manus-orchestrator.service
sudo systemctl status manus-agent.service
sudo systemctl status manus-chatgpt-agent.service

# Start/stop/restart individual services
sudo systemctl start manus-orchestrator.service
sudo systemctl stop manus-chatgpt-agent.service
sudo systemctl restart manus-agent.service

# Enable/disable services at boot
sudo systemctl enable manus-orchestrator.service
sudo systemctl disable manus-agent.service

# View service logs
sudo journalctl -u manus-orchestrator.service -n 100 --no-pager
sudo journalctl -u manus-chatgpt-agent.service -f  # Follow logs
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: 405 Method Not Allowed

**Symptoms:**
```
INFO: 127.0.0.1:xxxxx - "GET /api/v1/jobs/poll HTTP/1.1" 405 Method Not Allowed
```

**Cause:** Agent is using the wrong HTTP method (GET instead of POST)

**Solution:**
Check the agent code to ensure it's using POST for polling:
```python
# Correct:
return self.make_request('POST', '/api/v1/jobs/poll', data)

# Incorrect:
return self.make_request('GET', '/api/v1/jobs/poll', params)
```

---

#### Issue: 404 Not Found

**Symptoms:**
```
ERROR - Request failed: 404 Client Error: Not Found for url: http://127.0.0.1:8080/api/v1/tasks/poll
```

**Cause:** Agent is calling a non-existent endpoint

**Common Mistakes:**
- `/api/v1/tasks/poll` → Should be `/api/v1/jobs/poll`
- `/api/v1/tasks/result` → Should be `/api/v1/jobs/result`

**Solution:**
Verify the endpoint path matches the orchestrator's API specification.

---

#### Issue: 401 Unauthorized

**Symptoms:**
```
< HTTP/1.1 401 Unauthorized
```

**Cause:** Missing or invalid JWT token

**Solution:**
1. Verify JWT private key exists and is readable
2. Check token generation logic
3. Ensure token includes correct audience (`manus-orchestrator`)
4. Verify token hasn't expired (default: 5 minutes)

```bash
# Test token generation
sudo manus-admin token

# Check private key permissions
ls -la /opt/manus-*/jwk_private.pem
```

---

#### Issue: 422 Unprocessable Entity

**Symptoms:**
```
ERROR - Request failed: 422 Client Error: Unprocessable Entity
```

**Cause:** Request body doesn't match expected schema

**Common Causes:**
- Missing required fields
- Wrong data types
- Trying to submit results for `None` task

**Solution:**
Verify request payload matches the expected schema. For job results:
```python
# Correct format:
data = {
    'task_id': task_id,  # Must not be None
    'result': result     # Must be a valid dict
}
```

---

#### Issue: Agent Processing Empty Tasks

**Symptoms:**
```
INFO - Processing task None: None
ERROR - Failed to submit result for task None
```

**Cause:** Agent not properly checking if a job is available before processing

**Solution:**
Ensure proper validation of poll response:
```python
# Correct:
response = self.poll_for_tasks()
if response and response.get('job'):
    task = response['job']
    self.process_task(task)

# Incorrect:
task = self.poll_for_tasks()
if task:  # This passes even when task = {"job": None}
    self.process_task(task)
```

---

#### Issue: Service Won't Start

**Symptoms:**
```
● manus-chatgpt-agent.service - failed
```

**Diagnostic Steps:**
```bash
# Check service status
sudo systemctl status manus-chatgpt-agent.service

# View recent logs
sudo journalctl -u manus-chatgpt-agent.service -n 50

# Check for Python errors
sudo journalctl -u manus-chatgpt-agent.service | grep -i error

# Verify configuration file
sudo cat /opt/manus-chatgpt-agent/config.yaml

# Check file permissions
ls -la /opt/manus-chatgpt-agent/
```

**Common Causes:**
1. Missing Python dependencies
2. Invalid configuration file (YAML syntax errors)
3. Missing or incorrect private key file
4. Permission issues

**Solution:**
```bash
# Run the fix command
sudo manus-admin fix

# Or manually:
sudo chown -R manus-agent:manus-agent /opt/manus-chatgpt-agent
sudo chmod 600 /opt/manus-chatgpt-agent/config.yaml
sudo chmod 600 /opt/manus-chatgpt-agent/jwk_private.pem
```

---

#### Issue: OpenAI API Errors

**Symptoms:**
```
ERROR - Failed to initialize OpenAI client
```

**Cause:** Invalid or missing OpenAI API key

**Solution:**
1. Check API key in configuration:
```bash
sudo cat /opt/manus-chatgpt-agent/config.yaml | grep api_key
```

2. Verify API key is valid and has credits
3. Test OpenAI connection:
```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Agent Development Guidelines

### Creating a New Agent

When developing a new agent for the orchestrator:

#### 1. Required Methods

```python
class NewAgent:
    def __init__(self):
        self.config = self.load_config()
        self.orchestrator_url = self.config['orchestrator']['url']
        self.private_key = self.load_private_key()
        
    def generate_jwt_token(self) -> str:
        """Generate JWT token for authentication"""
        payload = {
            'sub': f'{self.server_id}:{self.agent_type}',
            'aud': 'manus-orchestrator',
            'exp': int(time.time()) + 300,
            'iat': int(time.time()),
            'agent_type': self.agent_type,
            'server_id': self.server_id
        }
        return jwt.encode(payload, self.private_key, algorithm='RS256')
    
    def poll_for_tasks(self) -> Optional[Dict]:
        """Poll orchestrator for new tasks"""
        data = {
            'agent_type': self.agent_type,
            'server_id': self.server_id
        }
        return self.make_request('POST', '/api/v1/jobs/poll', data)
    
    def submit_result(self, task_id: str, result: Dict[str, Any]) -> bool:
        """Submit task result to orchestrator"""
        data = {
            'task_id': task_id,
            'result': result
        }
        response = self.make_request('POST', '/api/v1/jobs/result', data)
        return response is not None
    
    def send_heartbeat(self) -> bool:
        """Send heartbeat to orchestrator"""
        data = {
            'agent_type': self.agent_type,
            'server_id': self.server_id,
            'status': 'active',
            'timestamp': int(time.time())
        }
        response = self.make_request('POST', '/api/v1/agents/heartbeat', data)
        return response is not None
```

#### 2. Main Loop Pattern

```python
def run(self):
    """Main agent loop"""
    while True:
        try:
            # Send heartbeat if needed
            if time.time() - self.last_heartbeat > self.heartbeat_interval:
                self.send_heartbeat()
            
            # Poll for tasks
            response = self.poll_for_tasks()
            if response and response.get('job'):
                task = response['job']
                result = self.process_task(task)
                self.submit_result(task['id'], result)
            
            time.sleep(self.poll_interval)
            
        except Exception as e:
            self.logger.error(f"Error: {e}")
            time.sleep(self.poll_interval)
```

#### 3. Critical Considerations

**Always use POST for job endpoints:**
- ✅ `POST /api/v1/jobs/poll`
- ✅ `POST /api/v1/jobs/result`
- ❌ Never use GET for these endpoints

**Validate poll responses:**
```python
# Always check if job is not None
if response and response.get('job'):
    # Process job
```

**Handle authentication properly:**
- Generate fresh JWT tokens (they expire in 5 minutes)
- Include proper audience claim
- Use RS256 algorithm

**Error handling:**
- Don't process None tasks
- Implement exponential backoff on errors
- Log all errors with context

---

## Configuration Reference

### Orchestrator Configuration (`/opt/manus-orchestrator/config.yaml`)

```yaml
server:
  host: "0.0.0.0"
  port: 8080
  
jwt:
  private_key: keys/jwk_private.pem
  public_key: keys/jwk_public.pem
  audience: manus-orchestrator
  
logging:
  level: INFO
  file: /var/log/manus-orchestrator.log
```

### Agent Configuration (`/opt/manus-chatgpt-agent/config.yaml`)

```yaml
server_id: web-1
poll_interval_seconds: 5
heartbeat_interval: 30
api_key: "sk-..."

orchestrator:
  url: "http://127.0.0.1:8080"
  audience: manus-orchestrator

jwt:
  private_key: jwk_private.pem

openai:
  model: "gpt-4"
  max_tokens: 4096
  temperature: 0.1
  timeout: 30

agent:
  max_concurrent_tasks: 3
  task_timeout: 300
  retry_attempts: 3
  retry_delay: 5

logging:
  level: "INFO"
  file: "/var/log/manus-chatgpt-agent.log"
  max_size: "10MB"
  backup_count: 5
```

---

## Deployment Checklist

When deploying or updating the orchestrator system:

### Pre-Deployment
- [ ] Backup current configuration files
- [ ] Backup current code files
- [ ] Note current service status
- [ ] Review recent logs for issues

### Deployment
- [ ] Update code files in `/opt/manus-*/`
- [ ] Verify file permissions (owner: `manus-agent:manus-agent`)
- [ ] Verify configuration files are valid YAML
- [ ] Check JWT private keys exist and are readable
- [ ] Reload systemd: `sudo systemctl daemon-reload`
- [ ] Restart services: `sudo manus-admin restart`

### Post-Deployment
- [ ] Check service status: `sudo manus-admin status`
- [ ] Verify all services are RUNNING
- [ ] Verify API connectivity checks pass
- [ ] Monitor logs for errors: `sudo journalctl -u manus-*.service -f`
- [ ] Test with a sample request
- [ ] Verify agents are polling successfully (200 OK responses)

---

## Monitoring and Maintenance

### Health Checks

**Automated Status Check:**
```bash
sudo manus-admin status
```

**Expected Output:**
```
Services:
● manus-orchestrator: RUNNING
● manus-agent: RUNNING
● manus-chatgpt-agent: RUNNING

API Connectivity:
Testing Basic API... OK
Testing Agent Status API... OK

✓ All services are running
```

### Log Monitoring

**Watch for errors in real-time:**
```bash
sudo journalctl -u manus-orchestrator.service -u manus-agent.service -u manus-chatgpt-agent.service -f | grep -i error
```

**Check for 4xx/5xx errors:**
```bash
sudo journalctl -u manus-orchestrator.service --since "1 hour ago" | grep -E "40[0-9]|50[0-9]"
```

**Monitor polling activity:**
```bash
sudo journalctl -u manus-orchestrator.service -f | grep "jobs/poll"
```

### Performance Metrics

**Check queue status:**
```bash
sudo manus-admin queue
```

**Check agent status:**
```bash
sudo manus-admin agents
```

**System resource usage:**
```bash
# CPU and memory usage
ps aux | grep -E "manus|orchestrator"

# Service resource consumption
systemctl status manus-orchestrator.service | grep -E "CPU|Memory"
```

---

## Security Considerations

### File Permissions

**Critical files must have restricted permissions:**
```bash
# Private keys (600)
-rw------- 1 manus-agent manus-agent jwk_private.pem

# Configuration files (600)
-rw------- 1 manus-agent manus-agent config.yaml

# Application directories (755)
drwxr-xr-x 3 manus-agent manus-agent /opt/manus-agent
```

### JWT Token Security

- Tokens expire after 5 minutes
- Use RS256 algorithm (asymmetric)
- Never log or expose private keys
- Rotate keys periodically

### API Security

- All endpoints require authentication
- Use HTTPS in production (not HTTP)
- Implement rate limiting
- Monitor for suspicious activity

---

## Quick Reference Commands

```bash
# Status and health
sudo manus-admin status

# View logs
sudo journalctl -u manus-orchestrator.service -f
sudo journalctl -u manus-chatgpt-agent.service -n 100

# Service control
sudo systemctl restart manus-orchestrator.service
sudo systemctl status manus-agent.service

# Fix common issues
sudo manus-admin fix

# Generate admin token
sudo manus-admin token

# Test API
curl -H "Authorization: Bearer $(sudo manus-admin token)" \
  http://localhost:8080/api/v1/agents/status

# Check for errors in last hour
sudo journalctl -u manus-*.service --since "1 hour ago" | grep -i error

# Monitor polling activity
sudo journalctl -u manus-orchestrator.service -f | grep "jobs/poll"
```

---

## Version History

### Current Issues Fixed (Oct 2025)
- Fixed 405 Method Not Allowed error (GET → POST for job polling)
- Fixed 404 errors (corrected endpoint paths)
- Fixed 422 errors (proper None task validation)
- Fixed API connectivity checks (added authentication)

### Known Limitations
- Single orchestrator instance (no clustering)
- In-memory queue (not persistent across restarts)
- No built-in monitoring dashboard
- Manual scaling required

---

## Support and Resources

### Log Analysis
When reporting issues, always include:
1. Output of `sudo manus-admin status`
2. Recent logs from affected service
3. Configuration file (with sensitive data redacted)
4. Steps to reproduce the issue

### Useful Log Filters
```bash
# Show only errors
sudo journalctl -u manus-chatgpt-agent.service | grep ERROR

# Show HTTP status codes
sudo journalctl -u manus-orchestrator.service | grep -E "HTTP/1.1 [0-9]{3}"

# Show authentication failures
sudo journalctl -u manus-orchestrator.service | grep "401\|Unauthorized"
```

---

## Glossary

- **Orchestrator:** Central service that manages task distribution
- **Agent:** Worker service that executes tasks
- **Job:** A task assigned to an agent for execution
- **Poll:** Agent checking for available jobs
- **Heartbeat:** Periodic signal from agent to orchestrator indicating it's alive
- **JWT:** JSON Web Token used for authentication
- **RS256:** RSA Signature with SHA-256, asymmetric encryption algorithm

