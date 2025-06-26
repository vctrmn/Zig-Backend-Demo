FROM debian:12.11 AS build

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

COPY --from=build /app/zig-out/bin/zig_backend /server

EXPOSE 3000/tcp

CMD ["/server"]