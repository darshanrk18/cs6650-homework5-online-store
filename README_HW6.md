# CS6650 Homework 6 — Product Search & Performance (branch `hw6`)

This branch adds the **product search service** (Part 2) and supports **horizontal scaling** (Part 3). The same server still exposes the HW5 Product API (create/list/get by ID).

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

### Run locally

```bash
cd src
go build -o server .
./server
```

```bash
# Single search
curl -s "http://localhost:8080/products/search?q=Alpha" | jq .
curl -s "http://localhost:8080/health"
```

### Load testing (Part 2)

Uses **FastHttpUser** and `locustfile_search.py`:

```bash
# Install Locust if needed: pip install locust
locust -f locustfile_search.py --host=http://localhost:8080
```

- **Test 1 (baseline):** 5 users, 2 minutes.  
- **Test 2 (breaking point):** 20 users, 3 minutes.

For AWS, set host to your ECS/ALB URL (e.g. `http://<alb-dns>:80` or task public IP with port 8080).

### ECS config (Part 2)

- **CPU:** 256 units (0.25 vCPU)  
- **Memory:** 512 MB  
- **Tasks:** 1  

Same Terraform as HW5; no changes required for Part 2.

---

## Part 3: Horizontal scaling (ALB + Auto Scaling)

When implemented on this branch:

- **ALB** with target group (IP, HTTP 8080, health check `/health`).
- **Auto Scaling:** e.g. min 2, max 4 tasks, target 70% CPU.
- Run the same load test against the **ALB DNS name** and observe scaling and improved response times.

---

## Code locations

| What            | Where |
|-----------------|--------|
| Search product model | `src/internal/models/search.go` |
| Catalog (100k, sync.Map, search) | `src/internal/catalog/catalog.go` |
| Search + health handlers | `src/internal/handlers/search.go` |
| Search Locust file | `locustfile_search.py` |
