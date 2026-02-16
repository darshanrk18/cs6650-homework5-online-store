package handlers

import (
	"encoding/json"
	"net/http"
	"product-api/internal/models"
	"strings"
)

const contentTypeJSON = "application/json"
const headerContentType = "Content-Type"

// ProductStore is the interface the handlers need from the product store.
type ProductStore interface {
	Create(p models.ProductCreate) (models.Product, bool)
	Get(id string) (models.Product, bool)
	List() []models.Product
}

// RegisterProductRoutes adds Product API routes to mux. s must not be nil.
func RegisterProductRoutes(mux *http.ServeMux, s ProductStore) {
	mux.HandleFunc("GET /products", listProducts(s))
	mux.HandleFunc("POST /products", createProduct(s))
	mux.HandleFunc("GET /products/", getProduct(s))
	mux.HandleFunc("GET /", health)
}

func listProducts(s ProductStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, s.List())
	}
}

func createProduct(s ProductStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get(headerContentType) != contentTypeJSON {
			writeError(w, http.StatusBadRequest, "Content-Type must be application/json")
			return
		}
		var body models.ProductCreate
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		prod, ok := s.Create(body)
		if !ok {
			writeError(w, http.StatusBadRequest, "invalid input: name required and non-empty, price must be >= 0, quantity >= 0")
			return
		}
		writeJSON(w, http.StatusCreated, prod)
	}
}

func getProduct(s ProductStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := strings.TrimPrefix(r.URL.Path, "/products/")
		if id == "" {
			writeError(w, http.StatusNotFound, "product not found")
			return
		}
		prod, ok := s.Get(id)
		if !ok {
			writeError(w, http.StatusNotFound, "product not found")
			return
		}
		writeJSON(w, http.StatusOK, prod)
	}
}

func health(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Product API OK"))
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set(headerContentType, contentTypeJSON)
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, message string) {
	w.Header().Set(headerContentType, contentTypeJSON)
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": message})
}
