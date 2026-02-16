package models

// Product is the API response shape for a product.
type Product struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description,omitempty"`
	Price       float64 `json:"price"`
	Quantity    *int    `json:"quantity,omitempty"`
}

// ProductCreate is the request body for creating a product.
type ProductCreate struct {
	Name        string  `json:"name"`
	Description string  `json:"description,omitempty"`
	Price       float64 `json:"price"`
	Quantity    *int    `json:"quantity,omitempty"`
}
