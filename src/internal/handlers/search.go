package handlers

import (
	"net/http"
	"product-api/internal/catalog"
)

// SearchCatalog is the interface for the product search catalog.
type SearchCatalog interface {
	Search(query string) catalog.SearchResult
}

// RegisterSearchRoutes adds GET /products/search and GET /health. Register before GET /products/ so search is matched.
func RegisterSearchRoutes(mux *http.ServeMux, c SearchCatalog) {
	mux.HandleFunc("GET /products/search", searchProducts(c))
	mux.HandleFunc("GET /health", healthCheck)
}

func searchProducts(c SearchCatalog) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		query := r.URL.Query().Get("q")
		result := c.Search(query)
		writeJSON(w, http.StatusOK, result)
	}
}

// healthCheck returns 200 OK for ALB health checks.
func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
