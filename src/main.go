// Product API server for the simple online store.
// Implements GET/POST for products per api.yaml; data stored in memory.
package main

import (
	"net/http"
	"os"
	"product-api/internal/catalog"
	"product-api/internal/handlers"
	"product-api/internal/store"
)

func main() {
	st := store.New()
	st.Seed()
	cat := catalog.New() // 100k products for search (HW6)
	mux := http.NewServeMux()
	handlers.RegisterSearchRoutes(mux, cat)  // register GET /products/search and GET /health first
	handlers.RegisterProductRoutes(mux, st)

	addr := ":8080"
	if port := os.Getenv("PORT"); port != "" {
		addr = ":" + port
	}
	http.ListenAndServe(addr, mux)
}
