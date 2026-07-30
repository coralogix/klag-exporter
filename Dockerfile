FROM 529726762838.dkr.ecr.eu-north-1.amazonaws.com/internal/rust-ubi10:latest AS rust

WORKDIR /app
COPY rust-toolchain.toml .
RUN cargo version

FROM rust AS source

WORKDIR /app
COPY . /app
RUN cargo copy-skeleton --target-dir /base

FROM rust AS build

WORKDIR /app
COPY --from=source /base .
RUN --mount=type=ssh --mount=type=secret,id=known_hosts,target=/root/.ssh/known_hosts \
    cargo build-dependencies --locked --release
COPY --from=source /app .
RUN --mount=type=ssh --mount=type=secret,id=known_hosts,target=/root/.ssh/known_hosts \
    cargo build --locked --release

FROM 529726762838.dkr.ecr.eu-north-1.amazonaws.com/internal/rust-service-ubi10:latest

WORKDIR /app
COPY --from=build --chmod=555 /app/target/release/klag-exporter /app

ENTRYPOINT [ "/app/klag-exporter" ]
CMD [ "--config", "/app/config.toml" ]
