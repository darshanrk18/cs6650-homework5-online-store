package handlers

import (
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"

	"product-api/internal/catalog"
	"product-api/internal/circuitbreaker"
)

// Fault injection query params (only when FAULT_INJECTION_ENABLED=true). Used for resilience testing.
const (
	queryFault = "fault" // process exit — simulates task crash
	queryCrash = "crash" // same as fault
	querySlow  = "slow"  // long sleep — simulates hung request
	queryFlaky = "flaky" // simulated flaky dependency; protected by circuit breaker
)

var (
	faultInjectionEnabled = os.Getenv("FAULT_INJECTION_ENABLED") == "true" || os.Getenv("FAULT_INJECTION_ENABLED") == "1"
	flakyBreaker         = circuitbreaker.New(5, 30*time.Second)
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
		query := strings.TrimSpace(r.URL.Query().Get("q"))

		if faultInjectionEnabled {
			switch strings.ToLower(query) {
			case queryFault, queryCrash:
				// Exit process so the container/task stops (handler panics are recovered by the HTTP server)
				os.Exit(1)
			case querySlow:
				time.Sleep(60 * time.Second)
			case queryFlaky:
				handleFlaky(w, c, query)
				return
			}
		}

		result := c.Search(query)
		writeJSON(w, http.StatusOK, result)
	}
}

// handleFlaky runs the "flaky" path through a circuit breaker: fail fast when circuit is open.
func handleFlaky(w http.ResponseWriter, c SearchCatalog, query string) {
	ok, err := flakyBreaker.Execute(func() error {
		if rand.Float32() < 0.8 {
			return errFlakyFailure
		}
		return nil
	})
	if !ok {
		writeError(w, http.StatusServiceUnavailable, "circuit open — fail fast")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "flaky dependency failed")
		return
	}
	result := c.Search(query)
	writeJSON(w, http.StatusOK, result)
}

var errFlakyFailure = &flakyErr{}

type flakyErr struct{}

func (e *flakyErr) Error() string { return "flaky dependency failed" }

// healthCheck returns 200 OK for ALB health checks.
func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
