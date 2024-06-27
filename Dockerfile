FROM alpine:latest AS builder

ARG SIMD=1

# Step 1: Update and install dependencies
RUN apk update && apk upgrade && \
    apk add curl gcc g++ musl-dev cmake make

# Step 2: Install Rust
RUN curl -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain nightly -y

# Step 3: Set environment variables
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build

# Step 4: Copy necessary files
COPY Cargo.toml Cargo.lock ./
COPY .cargo ./.cargo/

# Step 5: Create dummy main.rs for initial build
RUN mkdir src/ && echo 'fn main() {}' > ./src/main.rs

# Step 6: Build the project
RUN if [ "$SIMD" == '0' ]; then \
        cargo build --release --no-default-features --features no-simd; \
    else \
        cargo build --release; \
    fi

# Step 7: Clean up and prepare for the final build
RUN rm -f target/release/deps/gateway_proxy*
COPY ./src ./src

# Step 8: Final build
RUN if [ "$TARGET_CPU" == 'x86-64' ]; then \
        cargo build --release --no-default-features --features no-simd; \
    else \
        cargo build --release; \
    fi && \
    cp target/release/gateway-proxy /gateway-proxy && \
    strip /gateway-proxy

# Final stage
FROM scratch
COPY --from=builder /gateway-proxy /gateway-proxy

CMD ["./gateway-proxy"]
