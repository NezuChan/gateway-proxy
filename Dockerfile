FROM debian:latest AS builder

ARG SIMD=1

# Step 1: Update and install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl gcc g++ cmake make

# Step 2: Install Rust
RUN curl -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain nightly -y

# Step 3: Set environment variables
ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup component add rust-src --toolchain nightly-aarch64-unknown-linux-gnu

WORKDIR /build

# Step 4: Copy necessary files
COPY Cargo.toml Cargo.lock ./

# Step 5: Create dummy main.rs for initial build
RUN mkdir src/ && echo 'fn main() {}' > ./src/main.rs

# Step 6: Build the project
RUN cargo build --no-default-features --features no-simd --release;

# Step 7: Clean up and prepare for the final build
RUN rm -f target/release/deps/gateway_proxy*
COPY ./src ./src

# Step 8: Final build
RUN cargo build --no-default-features --features no-simd --release && \
    ls -l target/release && \
    cp target/release/gateway-proxy /gateway-proxy && \
    strip /gateway-proxy

# Final stage
FROM scratch
COPY --from=builder /gateway-proxy /gateway-proxy

CMD ["./gateway-proxy"]
