# ---- BASE ----
FROM node:26-alpine AS base
RUN corepack enable && corepack prepare pnpm@10.30.3 --activate

# ---- BUILDER ----
FROM base AS builder
WORKDIR /app

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/common/package.json ./packages/common/
COPY packages/socket/package.json ./packages/socket/

RUN pnpm install --frozen-lockfile --filter @rahoot/socket...

COPY packages/common/ ./packages/common/
COPY packages/socket/ ./packages/socket/

RUN pnpm build --filter @rahoot/socket

# ---- RUNNER ----
FROM node:26-alpine AS runner

WORKDIR /app

COPY --from=builder /app/packages/socket/dist/index.cjs ./index.cjs
COPY config/ ./config/

RUN adduser -D appuser && \
    chown -R appuser:appuser /app

USER appuser

ENV NODE_ENV=production
ENV PORT=3000
ENV CONFIG_PATH=/app/config

EXPOSE 3000

CMD ["node", "index.cjs"]
