# Zig + React Fullstack Demo — Expenses Tracker

A modern fullstack expense tracking application showcasing end-to-end type safety and performance.

## 🚀 Tech Stack

### Frontend
- **React 19** with TypeScript
- **Vite** for lightning-fast development
- **Tailwind CSS 4** for modern styling
- **shadcn/ui** for beautiful components
- **Bun** as the Typescript runtime

### Backend
- **Zig** for systems-level performance
- **Zap** HTTP web framework
- **zqlite** SQLite wrapper
- **validate.zig** for request validation

### Infrastructure
- **Docker** for containerization
- **SQLite**
- **Bun workspaces** for monorepo management

## 📋 TODO

- [ ] **Use type DATE and not TEXT for the expense table**
- [ ] **Implement Bun's Zig FFI** for direct TypeScript ↔ Zig communication
- [ ] **Add expense editing functionality**

---

## 🧪 Getting Started

### Prerequisites
- [Zig 0.14.0+](https://ziglang.org/download/)
- [Bun](https://bun.sh/) 
- [Docker](https://docker.com/) (optional)

### Development (Recommended)

Run both frontend and backend in development mode:

```bash
# Install frontend dependencies
bun install

# Start both services concurrently
bun run dev
```

This will start:
- Backend server on `http://localhost:3000`
- Frontend dev server on `http://localhost:5173` (proxied to backend)

### Individual Services

**Backend only:**
```bash
bun run dev:backend
# or
zig build run
```

**Frontend only:**
```bash
bun run dev:frontend
```

### Production Build

**With Docker:**
```bash
docker build -t zig-react-expenses .
docker run --rm -p 3000:3000 zig-react-expenses
```

---

## 🗂️ Project Structure

```text
.
├── frontend/                     # React frontend
│   ├── src/
│   │   ├── components/ui/        # shadcn/ui components
│   │   ├── routes/               # React pages/routes
│   │   └── lib/                  # Utilities
│   ├── package.json
│   ├── vite.config.ts            # Vite config with API proxy
│   └── tailwind.config.js
├── src/                          # Zig backend
│   ├── models/
│   │   ├── expense.zig           # Domain models & repository
│   │   └── summary.zig           # Summary response types
│   ├── services/
│   │   ├── expense_service.zig   # Business logic
│   │   ├── summary_service.zig   # Summary calculations
│   │   └── base.zig              # Shared service utilities
│   ├── endpoints/
│   │   ├── expense_endpoint.zig  # REST API handlers
│   │   ├── summary_endpoint.zig  # Summary endpoint
│   │   └── health_endpoint.zig   # Health checks
│   ├── database/
│   │   └── sqlite.zig            # Database setup & config
│   ├── utils/
│   │   ├── validation.zig        # Request validation
│   │   ├── response.zig          # HTTP response helpers
│   │   └── endpoint_helpers.zig  # Common endpoint utilities
│   ├── config.zig                # Server configuration
│   └── main.zig                  # Application entry point
├── build.zig                     # Zig build configuration
├── Dockerfile                    # Multi-stage build
└── package.json                  # Workspace configuration
```

---

## 🌐 API Overview

```json
{
  "message": "Expenses Service API",
  "endpoints": {
    "GET /api/expenses": "List all expenses",
    "POST /api/expenses": "Add new expense",
    "GET /api/expenses/{id}": "Get specific expense",
    "DELETE /api/expenses/{id}": "Delete expense",
    "GET /api/summary": "Get expenses summary",
    "GET /healthz": "Health check"
  }
}
```

---

## 🧪 API Examples

### GET - List all expenses
```bash
curl -X GET http://localhost:3000/api/expenses
```

### POST - Add new expense
```bash
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Movie tickets","amount":15.50,"category":"Entertainment","date":"2024-12-22"}'
```

```bash
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Grocery shopping","amount":85.30,"category":"Food","date":"2024-12-21"}'
```

### GET - Get specific expense by ID
```bash
curl -X GET http://localhost:3000/api/expenses/1
```

```bash
curl -X GET http://localhost:3000/api/expenses/2
```

### DELETE - Delete expense by ID
```bash
curl -X DELETE http://localhost:3000/api/expenses/1
```

### GET - Get expenses summary
```bash
curl -X GET http://localhost:3000/api/summary
```

### GET - Health check
```bash
curl -X GET http://localhost:3000/healthz
```

### Error Examples

#### Invalid JSON format
```bash
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Invalid JSON","amount":}'
```

#### Missing required fields
```bash
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Missing amount and date"}'
```

#### Invalid amount (negative)
```bash
curl -X POST http://localhost:3000/api/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Invalid expense","amount":-10.00,"category":"Test","date":"2024-12-22"}'
```

---

## 📦 Dependencies

This project uses the following Zig packages:

* [`zap`](https://github.com/zigzap/zap) — HTTP web framework

* [`zqlite`](https://github.com/karlseguin/zqlite.zig) — SQLite wrapper for Zig

* [`validate`](https://github.com/karlseguin/validate.zig) — Simple validation library

---
