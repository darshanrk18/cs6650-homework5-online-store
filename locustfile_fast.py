"""
Locust load tests for the Product API — FastHttpUser variant.
Run: locust -f locustfile_fast.py --host=http://localhost:8080
Use the same --host and same test params as locustfile.py (HttpUser) to compare RPS and latency.
"""

import random
import string

from locust import FastHttpUser, task, between


def random_string(length=8):
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=length))


class ProductFastHttpUser(FastHttpUser):
    """FastHttpUser: uses geventhttpclient, typically lower overhead at high concurrency."""
    wait_time = between(0.5, 1.5)

    def on_start(self):
        self.client.post(
            "/products",
            json={
                "name": f"Product-{random_string(6)}",
                "description": "Load test product",
                "price": round(random.uniform(1.0, 100.0), 2),
                "quantity": random.randint(0, 1000),
            },
            headers={"Content-Type": "application/json"},
        )

    @task(3)
    def list_products(self):
        self.client.get("/products")

    @task(2)
    def get_product(self):
        self.client.get(f"/products/{random.randint(1, 100)}", name="/products/[id]")

    @task(1)
    def create_product(self):
        self.client.post(
            "/products",
            json={
                "name": f"Item-{random_string(8)}",
                "price": round(random.uniform(0.5, 200.0), 2),
                "quantity": random.randint(0, 500),
            },
            headers={"Content-Type": "application/json"},
        )
