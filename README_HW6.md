# CS6650 Homework 6 — Product Search & Performance (branch `hw6`)

This branch adds the **product search service** (Part 2) and supports **horizontal scaling** (Part 3). The same server still exposes the HW5 Product API (create/list/get by ID). Screenshots for the report are provided in a separate screenshots zip file.

---

## Part 2: Product search

### What’s included

- **Catalog:** 100,000 products generated at startup (stored in `sync.Map`).
  - Name: `"Product [Brand] [ID]"` (e.g. `"Product Alpha 1"`).
  - Category: rotated from `["Electronics", "Books", "Home", "Sports", "Clothing", "Toys", "Garden", "Automotive"]`.
  - Brand: rotated from `["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Omega"]`.
- **Search:** `GET /products/search?q=<query>`
  - Each request checks **exactly 100 products** then stops (bounded iteration).
  - Matches **name** and **category** (case-insensitive).
  - Returns up to **20 results** plus `total_found` and `search_time`.
- **Health:** `GET /health` returns 200 OK (used by ALB in Part 3).

### Run locally (Docker)

From the repo root:

```bash
docker build -t product-api .
docker run -p 8080:8080 product-api
```

Then in another terminal:

```bash
# Single search
curl -s "http://localhost:8080/products/search?q=Alpha" | jq .
curl -s "http://localhost:8080/health"
```

(Alternatively, from `src/`: `go build -o server . && ./server`.)

### Load testing (Part 2)

Uses **FastHttpUser** and `locustfile_search.py`:

```bash
# Install Locust if needed: pip install locust
locust -f locustfile_search.py --host=http://localhost:8080
```

- **Test 1 (baseline):** 5 users, 2 minutes.  
- **Test 2 (breaking point):** 50 users, 3 minutes.

For AWS, set host to your ECS/ALB URL (e.g. `http://<alb-dns>:80` or task public IP with port 8080).

### ECS config (Part 2)

- **CPU:** 256 units (0.25 vCPU)  
- **Memory:** 512 MB  
- **Tasks:** 1  

Same Terraform as HW5; no changes required for Part 2.

### Part 2 Load Test Results (summary)

**Target:** ECS Fargate, 1 task, 256 CPU / 512 MB. Host: `http://35.87.91.87:8080` (task public IP).

| Test | Users | Duration | Requests | RPS | Avg (ms) | Median | 95% (ms) | Failures |
|------|-------|----------|----------|-----|----------|--------|----------|----------|
| Baseline | 5 | 3 min | 11,144 | ~62 | 105 | 91 | 170 | 0 |
| Higher load | 50 | 3 min | 25,136 | ~140 | 109 | 95 | 170 | 0 |

**CloudWatch (ECS service → Health and metrics):**

- **Light / post-deploy:** CPU ~4%, Memory ~7% (single task idle or light traffic).
- **Under load (e.g. 5 users, 2 min):** CPU spike to ~24%, Memory ~12%; after load stops, CPU drops back.

**Interpretation for Part 2 report:**

- **Resource limit:** CPU increases with load while memory stays relatively flat → **CPU** is the bottleneck, not memory.
- **Response times:** With 256 CPU / 1 task, avg latency stays ~105–109 ms; no failures. Baseline (5 users, 2 min) vs higher load (50 users, 3 min) shows increased throughput and CPU; 50 users stresses the single task.
- **Scale vs optimize:** The workload is fixed (100 products checked per search). Improving behavior under higher load means **adding compute** (more CPU per task or more tasks via Part 3), not changing the search algorithm.

**Artifacts:** `Locust_FastHTTPHW6_Report.html`, `Locust_FastHTTPHW6-50_Report.html`. Screenshots (Locust and CloudWatch) are provided in the screenshots zip file.

---

## Part 3: Horizontal scaling (ALB + Auto Scaling)

### What’s included

- **ALB:** Application Load Balancer (port 80), forwards to target group.
- **Target group:** IP type (Fargate), HTTP 8080, health check path `/health`, interval 30 s, healthy threshold 2.
- **ECS service:** Registered with the target group; **min 2**, **max 4** tasks; **70% CPU** target tracking; scale-out/scale-in cooldown 300 s.

### Deploy Part 3

From repo root:

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

After apply, get the ALB URL for load testing:

```bash
terraform output alb_url
# e.g. http://product-api-alb-xxxxx.us-west-2.elb.amazonaws.com
```

### Load test against ALB

Use the ALB URL (port 80) as the Locust host:

```bash
locust -f locustfile_search.py --host=http://<ALB_DNS_NAME>
# Or: --host=$(cd terraform && terraform output -raw alb_dns_name)  (then add http:// in UI)
```

Run the same test that stressed Part 2 (e.g. 50 users, 3 min). Watch:

- **ECS:** Service → Tasks (count should scale 2 → 3 → 4 under load).
- **Target group:** EC2 → Target Groups → healthy targets.
- **CloudWatch:** CPU per instance; compare response times to Part 2.

### Resilience test

During a load test: ECS → Tasks → select a running task → **Stop**. Confirm the target group marks it unhealthy, traffic continues to other tasks, and the load test keeps succeeding.

### Part 3 results (summary)

| Metric | Part 2 (1 task, 50 users) | Part 3 (ALB, 2 tasks, 50 users) |
|--------|---------------------------|----------------------------------|
| Requests | 25,136 | 24,961 |
| RPS | ~140 | ~139 |
| Avg (ms) | 109 | 110.7 |
| Failures | 0 | 0 |

**Report:** `Locust_FastHTTPHW6Part3-50users_Report.html`. Full write-up including Part 3: `HW6_Part2_Report.md` (sections 7–11).

---

## Code locations

| What            | Where |
|-----------------|--------|
| Search product model | `src/internal/models/search.go` |
| Catalog (100k, sync.Map, search) | `src/internal/catalog/catalog.go` |
| Search + health handlers | `src/internal/handlers/search.go` |
| Search Locust file | `locustfile_search.py` |
| **Part 3:** ALB module | `terraform/modules/alb/` |
| **Part 3:** ECS (load_balancer + auto scaling) | `terraform/modules/ecs/main.tf` |
| **Part 3:** Root wiring | `terraform/main.tf`, `terraform/variables.tf`, `terraform/outputs.tf` |
