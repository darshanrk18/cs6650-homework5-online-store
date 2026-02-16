# Build stage (run from repo root: docker build -t product-api .)
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY src/ ./
RUN CGO_ENABLED=0 go build -o /server .

# Run stage
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /
COPY --from=builder /server .
EXPOSE 8080
ENV PORT=8080
CMD ["/server"]
