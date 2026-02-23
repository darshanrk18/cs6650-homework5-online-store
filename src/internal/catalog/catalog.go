package catalog

import (
	"fmt"
	"product-api/internal/models"
	"strings"
	"sync"
	"time"
)

const (
	totalProducts = 100_000
	searchLimit   = 100  // each search checks exactly this many products
	maxResults    = 20
)

var (
	categories = []string{"Electronics", "Books", "Home", "Sports", "Clothing", "Toys", "Garden", "Automotive"}
	brands     = []string{"Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Omega"}
)

// Catalog holds 100k products in a sync.Map with ordered keys for bounded iteration.
type Catalog struct {
	mu   sync.Map // key int (id), value *models.SearchProduct
	keys []int    // ordered list of ids so we can iterate first N
}

// New creates a catalog and fills it with 100,000 generated products.
func New() *Catalog {
	c := &Catalog{
		keys: make([]int, 0, totalProducts),
	}
	for i := 1; i <= totalProducts; i++ {
		p := &models.SearchProduct{
			ID:          i,
			Name:        fmt.Sprintf("Product %s %d", brands[(i-1)%len(brands)], i),
			Category:    categories[(i-1)%len(categories)],
			Description: fmt.Sprintf("Description for product %d", i),
			Brand:       brands[(i-1)%len(brands)],
		}
		c.mu.Store(i, p)
		c.keys = append(c.keys, i)
	}
	return c
}

// SearchResult is the response for a search.
type SearchResult struct {
	Products   []*models.SearchProduct `json:"products"`
	TotalFound int                     `json:"total_found"`
	SearchTime string                  `json:"search_time,omitempty"`
}

// Search checks exactly searchLimit (100) products, matches name and category case-insensitive,
// returns up to maxResults (20) with total_found and search_time.
func (c *Catalog) Search(query string) SearchResult {
	start := time.Now()
	query = strings.TrimSpace(strings.ToLower(query))
	products := make([]*models.SearchProduct, 0, maxResults)
	totalFound := 0
	checked := 0
	for i := 0; i < len(c.keys) && checked < searchLimit; i++ {
		id := c.keys[i]
		v, ok := c.mu.Load(id)
		if !ok {
			continue
		}
		checked++ // count EVERY product checked (required for fixed-time simulation)
		p := v.(*models.SearchProduct)
		nameMatch := query == "" || strings.Contains(strings.ToLower(p.Name), query)
		catMatch := query == "" || strings.Contains(strings.ToLower(p.Category), query)
		if nameMatch || catMatch {
			totalFound++
			if len(products) < maxResults {
				products = append(products, p)
			}
		}
	}
	elapsed := time.Since(start)
	return SearchResult{
		Products:   products,
		TotalFound: totalFound,
		SearchTime: elapsed.String(),
	}
}
