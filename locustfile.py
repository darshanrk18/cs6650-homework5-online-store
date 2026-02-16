"""
Locust load tests for the Product API.
Run: locust -f locustfile.py --host=http://localhost:8080
Web UI: http://localhost:8089

Compare HttpUser vs FastHttpUser by switching the user class and documenting
RPS, latency, and failure rate. In many small APIs the difference is small
because request body and connection overhead dominate; FastHttpUser can show
gains under high concurrency.
"""

import random
import string

from locust import HttpUser, task, between


def random_string(length=8):
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=length))


class ProductHttpUser(HttpUser):
    """Standard HttpUser: uses requests under the hood."""
    wait_time = between(0.5, 1.5)

    def on_start(self):
        """Create a product so we have at least one to read."""
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
        # Assume IDs 1..100 might exist from previous runs or on_start
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


# Uncomment below and comment ProductHttpUser above to compare FastHttpUser.
# Install: pip install locust
# FastHttpUser is built into Locust and uses geventhttpclient for fewer connections and lower overhead.

# from locust import FastHttpUser
#
#
# class ProductFastHttpUser(FastHttpUser):
#     wait_time = between(0.5, 1.5)
#
#     def on_start(self):
#         self.client.post(
#             "/products",
#             json={
#                 "name": f"Product-{random_string(6)}",
#                 "description": "Load test product",
#                 "price": round(random.uniform(1.0, 100.0), 2),
#                 "quantity": random.randint(0, 1000),
#             },
#             headers={"Content-Type": "application/json"},
#         )
#
#     @task(3)
#     def list_products(self):
#         self.client.get("/products")
#
#     @task(2)
#     def get_product(self):
#         self.client.get(f"/products/{random.randint(1, 100)}", name="/products/[id]")
#
#     @task(1)
#     def create_product(self):
#         self.client.post(
#             "/products",
#             json={
#                 "name": f"Item-{random_string(8)}",
#                 "price": round(random.uniform(0.5, 200.0), 2),
#                 "quantity": random.randint(0, 500),
#             },
#             headers={"Content-Type": "application/json"},
#         )
