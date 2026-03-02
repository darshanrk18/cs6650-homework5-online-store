"""
Midterm Part II — Load script for the FIXED scenario (2 tasks): no crash requests.
Use this to show that with 2 tasks the service is stable and most requests succeed.
Failure rate will be low (only flaky 500/503 count as fails). Then demonstrate
recovery separately (e.g. one curl to ?q=crash and screenshot target group).

Run: locust -f locustfile_midterm_fixed_only.py --host=http://<alb_dns_name>
"""
import random
from locust import FastHttpUser, task, between

NORMAL_TERMS = ["Product", "Alpha", "Electronics", "Books", "Home", "Beta", "Gamma"]


class MidtermFixedUser(FastHttpUser):
    wait_time = between(0.1, 0.3)

    @task(weight=95)
    def search_normal(self):
        q = random.choice(NORMAL_TERMS)
        self.client.get(f"/products/search?q={q}", name="/products/search?q=[normal]")

    @task(weight=5)
    def search_flaky(self):
        self.client.get("/products/search?q=flaky", name="/products/search?q=flaky")
