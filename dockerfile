# Base
FROM node:lts-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ffmpeg python3 ca-certificates curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate

# Builder
FROM base AS builder
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

# Production Dependencies
FROM base AS prod-deps
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN pnpm install --prod --frozen-lockfile

# Deploy
FROM base AS deploy
WORKDIR /app
ENV NODE_ENV=production

COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

CMD ["node", "dist/index.js"]
