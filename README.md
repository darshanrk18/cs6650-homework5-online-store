# CS6650 Homework 5 — Simple Online Store (Product API)

Product API for the e-commerce system: create and retrieve products. Implements the **Product** portion of the OpenAPI spec.

## Repository layout

| What | Where |
|------|--------|
| **API specification** | [`api.yaml`](api.yaml) (OpenAPI 3.0; use with [Swagger Editor](https://editor.swagger.io/)) |
| **Server code** | [`src/`](src/) — Go HTTP server |
| **Dockerfile** | [`Dockerfile`](Dockerfile) (repo root) |
| **Infrastructure (Terraform)** | Fork [CS6650_2b_demo](https://github.com/RuidiH/CS6650_2b_demo) and follow its README; point the image to this repo’s build if desired. |

---

## Deploying on a new machine

### Prerequisites

- **Go 1.22+** (for local run; developed with Go 1.25)
- **Docker** (for container run)
- **Terraform** + AWS CLI configured (for AWS ECS/ECR; see infra repo)

### 1. Run locally

```bash
cd src
go build -o server .
./server
```

Server listens on `:8080` (override with `PORT` env, e.g. `PORT=3000 ./server`).

### 2. Run with Docker

From the **repository root**:

```bash
docker build -t product-api .
docker run -p 8080:8080 product-api
```

Then use `http://localhost:8080` for the examples below.

### Part II — Verify locally and with Docker

1. **Confirm `api.yaml`**  
   If the course provided a different OpenAPI spec, replace [`api.yaml`](api.yaml) and adjust the server if needed. Ours matches the Product endpoints described in this README.

2. **Run and test locally**
   ```bash
   cd src
   go build -o server .
   ./server
   ```
   In another terminal, run the verification script (checks 200, 201, 400, 404):
   ```bash
   chmod +x scripts/verify-api.sh   # once
   ./scripts/verify-api.sh
   ```
   Or run the [curl examples](#example-requests-and-response-codes) below by hand.

3. **Build and run with Docker**
   From the **repository root**:
   ```bash
   docker build -t product-api .
   docker run -p 8080:8080 product-api
   ```
   In another terminal, run the same verification:
   ```bash
   ./scripts/verify-api.sh
   ```
   To test against a different host (e.g. after AWS deploy): `BASE_URL=http://your-host:8080 ./scripts/verify-api.sh`

4. **Capture examples for submission**  
   The section [Example requests and response codes](#example-requests-and-response-codes) documents 200, 201, 400, and 404. Use those curls or record the same in Postman and add screenshots or an exported collection to your submission.

### 3. Deploy to AWS (Terraform)

1. Fork and clone the [CS6650_2b_demo](https://github.com/RuidiH/CS6650_2b_demo) repo.
2. Follow its README to install Terraform and configure AWS.
3. Build and push your Docker image to the ECR repo created by Terraform, then update the ECS service to use that image (or integrate this repo’s `Dockerfile` into the pipeline described in the demo).

---

## API base URL

- **Local / Docker:** `http://localhost:8080`
- **AWS (after deploy):** use the URL from Terraform output (e.g. load balancer or service URL).

---

## Example requests and response codes

All examples use `curl`. You can import these into [Postman](https://www.postman.com/) or use a Postman collection export.

### **200 OK** — List products

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8080/products
```

Example response body: `[]` or a JSON array of products.

### **200 OK** — Get product by ID

With seed data, IDs 1–5 exist. Example:

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8080/products/1
```

### **201 Created** — Create product

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Widget","description":"A useful widget","price":9.99,"quantity":100}'
```

### **400 Bad Request** — Invalid input (missing name)

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"price":5.0}'
```

### **400 Bad Request** — Invalid input (negative price)

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Thing","price":-1}'
```

### **400 Bad Request** — Invalid JSON or wrong Content-Type

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d 'not json'
```

### **404 Not Found** — Product ID does not exist

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8080/products/nonexistent-id-12345
```

### **404 Not Found** — Wrong path

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8080/unknown
```

### **500 Internal Server Error**

The API may return 500 on unexpected server errors (e.g. panics). Not demonstrated here; see [HTTP status codes](https://http.cat/) for reference.

---

## Load testing (Locust)

See [`locustfile.py`](locustfile.py). Run the server, then:

```bash
pip install locust
locust -f locustfile.py --host=http://localhost:8080
```

Open the web UI (default http://localhost:8089), set users and spawn rate, and run tests. Compare **HttpUser** vs **FastHttpUser** and document results (screenshots, RPS, latency) for your report.

---

## Design notes

- **In-memory store:** Products are kept in a map + slice (by ID and insertion order). No persistence across restarts.
- **Validation:** POST requires non-empty `name` and `price >= 0`; `quantity` if present must be `>= 0`.
- **IDs:** Auto-generated numeric IDs (1, 2, …) for simplicity.

Use `.gitignore` to exclude binaries, `.tfstate`, `.env`, and secrets; keep the repo small and safe.

---

## Exploration questions (design & Terraform)

- **Scalable backend for the full store API:** The full `api.yaml` includes many resources (products, orders, users, etc.). A scalable design could use: (1) **service-per-domain** (Product, Order, User, Inventory) with separate deployables and DBs; (2) **API gateway** for routing and rate limiting; (3) **databases** chosen per service (e.g. relational for orders, document or key-value for catalog); (4) **async messaging** (e.g. SQS/Kafka) for order fulfillment and events; (5) **caching** (e.g. Redis) for hot product data; (6) **horizontal scaling** behind a load balancer. This is design-only; not implemented here.

- **Terraform as declarative:** Declarative means you describe the *desired state* (e.g. “one ECR repo, one ECS service”) and Terraform figures out *how* to get there. In an imperative approach you’d write “run this AWS CLI command, then that one.” Declarative helps by: (1) **idempotency** — apply again and you stay in the desired state; (2) **drift detection** — Terraform can see if someone changed resources in the console; (3) **readable, reviewable** infrastructure as code. You still run `terraform apply` as a command, but the *language* is “what should exist,” not “do step 1, step 2.”
