# HW6 Report: Performance Bottlenecks (Part 2) & Horizontal Scaling (Part 3)

**Product Search Service — Load Testing, Resource Analysis, and ALB + Auto Scaling**

Screenshots are provided in a separate zip file; the report refers to “screenshots” where applicable without file paths.

---

## Significant Changes and How They Helped

This section documents every major change made for HW6 (Part 2 and Part 3), what problem each addressed, and how it helped.

### Application (Part 2)

| Change | What we did | Why it helped |
|--------|-------------|----------------|
| **Search product model** | Added `SearchProduct` (ID, Name, Category, Description, Brand) in `src/internal/models/search.go`. | Matches the assignment’s searchable schema; name and category are used for matching. |
| **100k-product catalog** | New package `src/internal/catalog/catalog.go`: 100,000 products generated at startup, stored in `sync.Map` with an ordered key slice. | Simulates a realistic in-memory footprint; `sync.Map` gives thread-safe reads for concurrent search requests. |
| **Bounded search (100 per request)** | Each search iterates exactly 100 products (via the key slice), then stops; we count every product *checked*, not just matches. | Models fixed compute per request (e.g. “run 100 checks”); makes CPU the predictable bottleneck and clarifies “scale vs optimize.” |
| **Search endpoint** | `GET /products/search?q=<query>`: case-insensitive match on name and category; returns up to 20 results plus `total_found` and `search_time`. | Delivers the required API shape and measurable latency for load tests. |
| **Health endpoint** | `GET /health` returns 200 OK. | Required for ALB target group health checks in Part 3; no health check would mean targets stay unhealthy. |
| **Registration order** | Search and health routes registered before the generic `/products/` route so `/products/search` and `/health` are matched correctly. | Ensures the right handler runs for search and health. |

### Load testing (Part 2)

| Change | What we did | Why it helped |
|--------|-------------|----------------|
| **Locust script** | `locustfile_search.py`: FastHttpUser, random choice from common terms (Product, Alpha, Electronics, etc.), short wait between requests. | Reproducible load on the search endpoint; FastHttpUser reduces client overhead so we measure server CPU. |
| **Baseline and stress tests** | Test 1: 5 users, 2–3 min. Test 2: 50 users, 3 min. | Baseline shows “normal” CPU and latency; 50 users stresses one task and shows the limit without scaling. |
| **CloudWatch (service-level)** | Used ECS → Service → Health and metrics (not cluster-level, which is empty for Fargate). | Gave CPU and memory curves; showed CPU rising with load and memory flat → CPU is the bottleneck. |

### Infrastructure (Part 3)

| Change | What we did | Why it helped |
|--------|-------------|----------------|
| **Network: VPC output** | Added `vpc_id` output in `terraform/modules/network/outputs.tf`. | ALB and target group must be created in a VPC; the ALB module needs this. |
| **ALB module** | New `terraform/modules/alb/`: ALB (port 80), ALB security group (allow 80 from internet), target group (IP, 8080, `/health`, 30 s, healthy threshold 2), listener (80 → target group). | Single entry point for traffic; distributes load across tasks; health checks remove bad targets from rotation. |
| **ALB → task security** | Rule: allow ALB security group to ECS task security group on port 8080. | Fargate tasks listen on 8080; without this rule the ALB could not reach the containers. |
| **ECS ↔ ALB** | ECS service gets `load_balancer` block (target group ARN, container name, container port) and `health_check_grace_period_seconds` (60). | Registers task IPs with the target group so the ALB can send traffic; grace period avoids killing tasks before they pass health checks. |
| **Desired count 2** | Root variable `ecs_count` default set to 2. | Part 3 starts with two tasks so we immediately have capacity and can run the “same load as Part 2” test against the ALB. |
| **Auto scaling** | `aws_appautoscaling_target` (min 2, max 4) and `aws_appautoscaling_policy` (target 70% CPU, 300 s cooldowns). | Under higher load, CPU goes up and ECS adds tasks (up to 4); when load drops, it scales in. Cooldowns avoid flapping. |
| **Outputs** | `alb_dns_name` and `alb_url` in `terraform/outputs.tf`. | Gives the exact URL to use as the Locust host for Part 3. |

### Testing and evidence (Part 3)

| Change | What we did | Why it helped |
|--------|-------------|----------------|
| **Same load test vs ALB** | 50 users, ~3 min, host = ALB URL (port 80). | Direct comparison with Part 2 (one task); shows the system handles the same load with 2 tasks and no failures. |
| **Resilience test** | During load, stop one ECS task; watch target group and Locust. | Shows that one failing task does not take down the service; traffic continues to the other task(s). |

### Documentation and artifacts

| Change | What we did | Why it helped |
|--------|-------------|----------------|
| **README_HW6.md** | Separate README for the hw6 branch: setup, run (Docker), Locust, Part 2 results summary, Part 3 deploy and test steps, code locations. | Anyone on the branch can run, test, and deploy without digging through the main README. |
| **Locust reports** | Saved HTML reports for baseline, 50-user (Part 2), and 50-user vs ALB (Part 3). | Reproducible numbers (requests, RPS, latency, failures) for the report and grading. |
| **Screenshots** | Captured ECS tasks, target group health, Locust stats, CloudWatch CPU/memory and target health. | Provided in a screenshots zip; evidence for “what we did” and “how we know it worked.” |

---

## 1. Setup

- **Service:** Product search API (`GET /products/search?q=<query>`), 100k products in memory, **exactly 100 products checked per search** (bounded iteration).
- **Infrastructure:** AWS ECS Fargate, **1 task**, **256 CPU units** (0.25 vCPU), **512 MB** memory.
- **Load testing:** Locust with **FastHttpUser**, script `locustfile_search.py`. Target: task public IP (e.g. `http://35.87.91.87:8080`).

---

## 2. What Happened When Load Increased

Two tests were run against the single Fargate task:

| Test        | Users | Duration | Total requests | RPS  | Avg response (ms) | Median (ms) | 95th %ile (ms) | Failures |
|------------|-------|----------|----------------|------|------------------|------------|----------------|----------|
| Baseline   | 5     | 3 min    | 11,144         | ~62  | 105              | 91         | 170            | 0        |
| Higher load| 50    | 3 min    | 25,136         | ~140 | 109              | 95         | 170            | 0        |

**Observations:**

- **Baseline (5 users, 3 min):** 11,144 requests, ~62 RPS, avg 105 ms, median 91 ms, 95th 170 ms; 0 failures. Moderate CPU, fast responses (see `Locust_FastHTTPHW6_Report.html`).
- **Higher load (50 users, 3 min):** Throughput ~140 RPS, avg latency ~109 ms; **no failed requests**. Response time distribution stable (median ~95 ms, 95th ~170 ms). The system is **CPU-bound**; with 50 users the single task is under heavier load and CPU would approach saturation with further increases.
- As load went from 5 to 50 users, **throughput** increased and **latency** stayed in a similar range; the fix for going beyond this is **more compute** (scale), not code optimization.

*Screenshots: Locust Statistics tab for 5-user and 50-user runs (see screenshots zip). Reports: `Locust_FastHTTPHW6_Report.html`, `Locust_FastHTTPHW6-50_Report.html`.*

---

## 3. Evidence: Scale vs. Optimize — Which Resource Hits the Limit?

**Conclusion: CPU is the limiting resource; the fix is more compute (scaling), not code optimization.**

**Evidence:**

1. **CloudWatch (ECS service → Health and metrics):**
   - **Idle / light load:** CPU ~4%, Memory ~7%.
   - **Under load (e.g. 5 users, 2 min, or during 50-user test):** CPU rises sharply (e.g. to ~24% in the captured window); **Memory** increases only slightly (e.g. to ~12%) and then stays relatively flat.
   - When the load test stops, **CPU drops** back down; **Memory** remains at the higher level (catalog already loaded).

2. **Interpretation:**
   - **CPU** tracks request rate and increases with load; it is the resource that would eventually reach 100% and cap throughput or degrade latency.
   - **Memory** is dominated by the 100k-product catalog loaded at startup and does not grow with request volume. So memory is **not** the bottleneck.
   - The search logic is **fixed cost per request** (exactly 100 products checked). There is no meaningful “optimization” to reduce work per request; the only way to handle more load is **more compute** — either more CPU per task (vertical scaling) or more tasks (horizontal scaling, Part 3).

*Screenshots: ECS Service → Health and metrics — CPU and Memory utilization over the test period, including light-load and under-load (see screenshots zip).*

---

## 4. Using CloudWatch to Make Scaling Decisions

- **Where to look:** ECS → Clusters → `product-api-cluster` → Service `product-api` → **Health and metrics** tab. (Cluster-level metrics show “no data” for Fargate; service-level metrics are correct.)
- **What to monitor:** **CPU utilization** and **Memory utilization** for the service.
- **Decision rule:** If **CPU** is consistently high (e.g. >70–80%) and latency or error rate is unacceptable, the bottleneck is compute. Then:
  - **Vertical scaling:** Increase task size (e.g. 256 → 512 CPU, or more memory if needed).
  - **Horizontal scaling (Part 3):** Add more tasks behind an ALB and use auto scaling on CPU (e.g. target 70% CPU, min 2, max 4 tasks).

Memory staying flat and moderate confirms that scaling decisions should be driven by **CPU**, not memory, for this workload.

---

## 5. Stress Testing

- **Baseline:** 5 users for 3 minutes (from `Locust_FastHTTPHW6_Report.html`; assignment suggests 2 min for Test 1).
- **Stress / breaking-point:** 50 users for 3 minutes to push the single task further and observe sustained higher RPS (~140) and confirm CPU as the limiting factor.
- **Tool:** Locust with FastHttpUser, minimal wait time between requests, random search terms (e.g. "Product", "Alpha", "Electronics") to simulate realistic search traffic.
- **Result:** No failures; latency remained stable in the tested range. CloudWatch showed CPU increasing with load while memory stayed relatively stable, supporting the conclusion that under heavier or sustained load, **CPU would hit the limit first** and scaling out (or up) is the appropriate response.

---

## 6. Summary

- **What happened when load increased:** Baseline (5 users, 3 min) had 11,144 requests, ~62 RPS, 105 ms avg; higher load (50 users, 3 min) had 25,136 requests, ~140 RPS, 109 ms avg. No failures; the system is CPU-bound.
- **Evidence for scale vs. optimize:** CPU utilization rises with load; memory stays flat. The search does fixed work per request (100 products). Therefore the solution is **more compute** (scale), not algorithm optimization.
- **CloudWatch:** Service-level CPU and Memory metrics were used to identify CPU as the bottleneck and to justify scaling decisions (vertical or horizontal).
- **Stress testing:** Baseline (5 users, 3 min; 11,144 requests, ~62 RPS) and higher load (50 users, 3 min; 25,136 requests, ~140 RPS) were run. Locust reports: `Locust_FastHTTPHW6_Report.html`, `Locust_FastHTTPHW6-50_Report.html`. Screenshots (Locust and CloudWatch) are in the screenshots zip.

---

# Part 3: Horizontal Scaling with ALB and Auto Scaling

## 7. Setup (Part 3)

- **ALB:** Application Load Balancer (port 80), forwarding to target group `product-api-tg`.
- **Target group:** IP type (Fargate), HTTP 8080, health check `/health`, interval 30 s, healthy threshold 2.
- **ECS service:** Min 2, max 4 tasks; target-tracking auto scaling on **70% CPU**; scale-out/scale-in cooldown 300 s.
- **Load test host:** ALB DNS name (e.g. `http://product-api-alb-1083986539.us-west-2.elb.amazonaws.com`).

## 8. Part 3 Load Test Results (50 users vs ALB)

Same test as Part 2 higher load (50 users, ~3 min), but traffic sent to the **ALB** so it is distributed across 2 (or more) tasks:

| Metric | Part 2 (1 task, 50 users) | Part 3 (ALB, 2 tasks, 50 users) |
|--------|---------------------------|----------------------------------|
| **Host** | Task public IP:8080 | ALB DNS (port 80) |
| **Total requests** | 25,136 | 24,961 |
| **RPS** | ~140 | ~139 |
| **Avg response (ms)** | 109 | 110.7 |
| **Median (ms)** | 95 | 97 |
| **95th %ile (ms)** | 170 | 170 |
| **Failures** | 0 | 0 |

**Source:** `Locust_FastHTTPHW6Part3-50users_Report.html` (duration 3 min 1 s, host `http://product-api-alb-1083986539.us-west-2.elb.amazonaws.com`).

**Observations:** With 2 tasks behind the ALB, the system sustained ~139 RPS and ~111 ms average latency with **0 failures**. Latency is comparable to Part 2 single-task 50-user run; load is shared across tasks. With more users or longer runs, auto scaling can add tasks (up to 4) when CPU exceeds 70%.

## 9. Role of Each Component

- **ALB:** Single entry point (port 80); distributes requests across healthy targets in the target group.
- **Target group:** Registers ECS task IPs (Fargate), health checks `/health` every 30 s; only healthy targets receive traffic.
- **Auto Scaling:** Increases task count when average CPU > 70%, decreases when below (min 2, max 4); cooldowns avoid thrashing.

## 10. Horizontal vs Vertical Scaling

- **Vertical (Part 2):** One task; scale by increasing CPU/memory (e.g. 256 → 512). Single point of failure; limited by one instance.
- **Horizontal (Part 3):** Multiple tasks behind ALB; scale by adding/removing tasks. Better availability (one task can stop; others continue); load spread across instances.

## 11. Screenshots and Evidence (Part 3)

All Part 3 screenshots are in the screenshots zip file.

- **ECS task count:** 2 desired, 2 running. Under higher load, count can scale toward 4.
- **Target group:** 2 healthy, 0 unhealthy — confirms the ALB is sending traffic to both tasks.
- **Locust vs ALB:** Statistics tab for 50 users (24,961 requests, ~139 RPS, 0% failures). Report: `Locust_FastHTTPHW6Part3-50users_Report.html`.
- **CloudWatch (Part 3):** ECS service Health and metrics — CPU and Memory with 2 tasks; load balancer target health “2 Healthy.”

**Resilience:** Stopping one task during a load test causes the target group to mark it unhealthy; traffic continues to the remaining task(s) and the load test keeps succeeding.
