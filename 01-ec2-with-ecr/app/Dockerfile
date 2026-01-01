FROM golang:1.21-alpine AS builder
WORKDIR /app

# Copy go.mod first (for better Docker caching)
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the binary statically linked
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o main main.go
FROM scratch

# Copy ONLY the compiled binary from builder stage
COPY --from=builder /app/main /main

# Expose port
EXPOSE 8080

# Run the binary
CMD ["/main"]