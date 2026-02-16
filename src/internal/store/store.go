package store

import (
	"product-api/internal/models"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
)

// Store holds products in memory with insertion order.
type Store struct {
	mu    sync.RWMutex
	nextID atomic.Uint64
	byID  map[string]models.Product
	order []string
}

// New returns a new in-memory product store.
func New() *Store {
	return &Store{
		byID:  make(map[string]models.Product),
		order: []string{},
	}
}

// Create validates the input, adds a product, and returns it. The second return is false if validation fails.
func (s *Store) Create(p models.ProductCreate) (models.Product, bool) {
	if strings.TrimSpace(p.Name) == "" || p.Price < 0 {
		return models.Product{}, false
	}
	q := 0
	if p.Quantity != nil {
		q = *p.Quantity
		if q < 0 {
			return models.Product{}, false
		}
	}
	id := strconv.FormatUint(s.nextID.Add(1), 10)
	prod := models.Product{
		ID:          id,
		Name:        strings.TrimSpace(p.Name),
		Description: strings.TrimSpace(p.Description),
		Price:       p.Price,
		Quantity:    &q,
	}
	s.mu.Lock()
	s.byID[id] = prod
	s.order = append(s.order, id)
	s.mu.Unlock()
	return prod, true
}

// Get returns the product by ID and whether it existed.
func (s *Store) Get(id string) (models.Product, bool) {
	s.mu.RLock()
	p, ok := s.byID[id]
	s.mu.RUnlock()
	return p, ok
}

// List returns all products in insertion order.
func (s *Store) List() []models.Product {
	s.mu.RLock()
	out := make([]models.Product, 0, len(s.order))
	for _, id := range s.order {
		out = append(out, s.byID[id])
	}
	s.mu.RUnlock()
	return out
}

// defaultSeedProducts is the initial set of products loaded on startup.
var defaultSeedProducts = []models.ProductCreate{
	{Name: "Wireless Mouse", Description: "Ergonomic wireless mouse with long battery life", Price: 29.99, Quantity: intPtr(150)},
	{Name: "USB-C Hub", Description: "7-in-1 adapter with HDMI and SD card reader", Price: 49.99, Quantity: intPtr(80)},
	{Name: "Mechanical Keyboard", Description: "RGB backlit, Cherry MX switches", Price: 129.00, Quantity: intPtr(45)},
	{Name: "Monitor Stand", Description: "Adjustable desk mount for monitors up to 32\"", Price: 59.99, Quantity: intPtr(120)},
	{Name: "Webcam HD", Description: "1080p 60fps with built-in microphone", Price: 79.99, Quantity: intPtr(60)},
}

func intPtr(n int) *int { return &n }

// Seed populates the store with default products if it is empty. Safe to call multiple times.
func (s *Store) Seed() {
	s.mu.RLock()
	empty := len(s.order) == 0
	s.mu.RUnlock()
	if !empty {
		return
	}
	for _, p := range defaultSeedProducts {
		s.Create(p)
	}
}
