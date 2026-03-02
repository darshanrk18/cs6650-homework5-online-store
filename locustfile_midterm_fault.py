"""
Midterm Mastery Part II — Step III: Load script that mixes normal search with fault triggers.
Use only when FAULT_INJECTION_ENABLED=true on the server.

Run: locust -f locustfile_midterm_fault.py --host=http://<alb_dns_name>

- Normal search (weight 94): most traffic.
- Flaky (weight 5): circuit breaker demo; some 500 then 503 when circuit open.
- Crash (weight 1): ~1% of requests; each hit kills one ECS task. Kept low so that
  with 2 tasks only one task is usually killed and the other keeps serving (fixed scenario).
"""
import random
from locust import FastHttpUser, task, between

NORMAL_TERMS = ["Product", "Alpha", "Electronics", "Books", "Home", "Beta", "Gamma"]


class MidtermFaultUser(FastHttpUser):
    wait_time = between(0.1, 0.3)

    @task(weight=94)
    def search_normal(self):
        q = random.choice(NORMAL_TERMS)
        self.client.get(f"/products/search?q={q}", name="/products/search?q=[normal]")

    @task(weight=5)
    def search_flaky(self):
        self.client.get("/products/search?q=flaky", name="/products/search?q=flaky")

    @task(weight=1)
    def search_crash(self):
        self.client.get("/products/search?q=crash", name="/products/search?q=crash")
