# ==========================================
# STAGE 1: Builder
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
     gcc libpq-dev && \
     rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ==========================================
# STAGE 2: Hardened Runtime
# ==========================================
FROM python:3.11-slim

# Create dedicated non-root user
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser

# Install minimal runtime library for Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY app.py test_app.py ./

# Fix permissions
RUN chown -R appuser:appgroup /app

# Enforce non-root execution context
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
