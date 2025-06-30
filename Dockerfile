FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# Install dependencies for both backend and frontend into temp directory
# this will cache them and speed up future builds
FROM base AS install

# Frontend dependencies
RUN mkdir -p /temp/frontend-dev
COPY frontend/package.json frontend/bun.lock* /temp/frontend-dev/
RUN cd /temp/frontend-dev && bun install --frozen-lockfile

# Build stage
FROM base AS build-frontend
# Copy frontend dependencies
COPY --from=install /temp/frontend-dev/node_modules ./frontend/node_modules

# Copy source code
COPY . .

# Build frontend
WORKDIR /usr/src/app/frontend
RUN bun run build

FROM debian:12.11 AS build-server

ARG ZIG_VER=0.14.0

RUN apt-get update && apt-get install -y curl xz-utils sqlite3 libsqlite3-dev

RUN curl -L https://ziglang.org/download/${ZIG_VER}/zig-linux-$(uname -m)-${ZIG_VER}.tar.xz -o zig-linux.tar.xz && \
    tar xf zig-linux.tar.xz && \
    mv zig-linux-$(uname -m)-${ZIG_VER}/ /opt/zig

WORKDIR /app

COPY . .

RUN /opt/zig/zig build -Doptimize=ReleaseFast -Dcpu=baseline

FROM debian:12.11-slim

RUN apt-get update && apt-get install -y ca-certificates sqlite3

# Copy built frontend
COPY --from=build-frontend /usr/src/app/frontend/dist /public
COPY --from=build-server /app/zig-out/bin/zig_backend /server

EXPOSE 3000/tcp

CMD ["/server"]