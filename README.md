# Zig Backend Demo — Expenses API

## 📋 TODO

- [ ] **Use type DATE and not TEXT for the expense table**

- [ ] **Serve a static React frontend that interacts with the expenses API**
   - Use Bun for the frontend
   - Get data (request/response) through [Bun's Zig FFI](https://bun.sh/docs/api/ffi#zig) for end-to-end type safety between TypeScript and Zig

---

## 🧪 Getting Started

### Run Locally

```bash
zig build run
```

### Run with Docker

```bash
docker build -t zig-backend .
docker run --rm -p 3000:3000 zig-backend
```

---

## 🗂️ Project Structure

```text
src/
├── models/
│   └── expense.zig              # Expense data structure
├── services/
│   ├── summary_service.zig      # Business logic for summary
│   └── expense_service.zig      # Business logic for expense operations
├── endpoints/
│   ├── expense_endpoint.zig     # GET, POST, DELETE /api/expenses
│   ├── summary_endpoint.zig     # GET /api/summary
│   └── health_endpoint.zig      # GET /healthz
├── database/
│   └── sqlite.zig               # SQLite connection and setup
├── utils/                       # Helper utilities (optional)
├── config.zig
└── main.zig                     # Entry point
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
