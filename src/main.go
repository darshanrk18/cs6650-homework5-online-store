// Product API server for the simple online store.
// Implements GET/POST for products per api.yaml; data stored in memory.
package main

import (
	"net/http"
	"os"
	"product-api/internal/handlers"
	"product-api/internal/store"
)

func main() {
	st := store.New()
	st.Seed()
	mux := http.NewServeMux()
	handlers.RegisterProductRoutes(mux, st)

	addr := ":8080"
	if port := os.Getenv("PORT"); port != "" {
		addr = ":" + port
	}
	http.ListenAndServe(addr, mux)
}
