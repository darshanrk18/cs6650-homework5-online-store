package models

// SearchProduct is a product in the search catalog (100k items, searchable name/category).
type SearchProduct struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Category    string `json:"category"`
	Description string `json:"description"`
	Brand       string `json:"brand"`
}
