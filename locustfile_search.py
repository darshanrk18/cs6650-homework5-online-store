"""
HW6 Part 2: Load test for product search. Use FastHttpUser.
Run: locust -f locustfile_search.py --host=http://localhost:8080
Test 1 (baseline): 5 users, 2 min.  Test 2 (breaking point): 20 users, 3 min.
"""
import random
from locust import FastHttpUser, task, between

# Common search terms (name/category) for consistent behavior
SEARCH_TERMS = ["Product", "Alpha", "Electronics", "Books", "Home", "1", "Beta", "Gamma"]


class SearchFastHttpUser(FastHttpUser):
    wait_time = between(0.1, 0.3)  # minimal wait to stress the service

    @task(1)
    def search(self):
        q = random.choice(SEARCH_TERMS)
        self.client.get(f"/products/search?q={q}", name="/products/search?q=[term]")
