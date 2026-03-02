// Package circuitbreaker implements a simple circuit breaker for fail-fast behavior.
// Used for Midterm Mastery Part II: after N failures, circuit opens and we return immediately (no call).
package circuitbreaker

import (
	"sync"
	"time"
)

// State represents the circuit state.
type State int

const (
	StateClosed   State = iota // normal operation
	StateOpen                  // failing; reject immediately
	StateHalfOpen              // testing one request
)

// Breaker is a simple in-memory circuit breaker.
type Breaker struct {
	mu sync.Mutex

	maxFailures   int
	openTimeout   time.Duration
	failureCount  int
	lastFailure   time.Time
	state         State
}

// New creates a circuit breaker that opens after maxFailures and stays open for openTimeout.
func New(maxFailures int, openTimeout time.Duration) *Breaker {
	return &Breaker{
		maxFailures: maxFailures,
		openTimeout: openTimeout,
		state:       StateClosed,
	}
}

// Execute runs fn when the circuit allows it. If the circuit is open, Execute returns (false, nil)
// and the caller should fail fast (e.g. return 503). If fn returns an error, it's counted as a failure.
func (b *Breaker) Execute(fn func() error) (ok bool, err error) {
	b.mu.Lock()
	switch b.state {
	case StateOpen:
		if time.Since(b.lastFailure) >= b.openTimeout {
			b.state = StateHalfOpen
			b.failureCount = 0
		} else {
			b.mu.Unlock()
			return false, nil // fail fast
		}
	case StateHalfOpen:
		// allow one request through
	case StateClosed:
		// allow
	}
	b.mu.Unlock()

	err = fn()

	b.mu.Lock()
	defer b.mu.Unlock()
	if err != nil {
		b.failureCount++
		b.lastFailure = time.Now()
		if b.state == StateHalfOpen || b.failureCount >= b.maxFailures {
			b.state = StateOpen
		}
		return true, err
	}
	// success
	if b.state == StateHalfOpen {
		b.state = StateClosed
		b.failureCount = 0
	} else {
		b.failureCount = 0
	}
	return true, nil
}
