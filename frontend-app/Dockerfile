FROM oven/bun:1 AS base

LABEL author="mamenesia"
LABEL name="napfi-ai"

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Accept build arguments for environment variables
ARG NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Copy environment variables or create default if not exists
RUN if [ -f .env.docker-production ]; then \
    cp .env.docker-production .env; \
    else \
    echo "NODE_ENV=production" > .env; \
    echo "NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=${NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID}" >> .env; \
    echo "# Default environment variables" >> .env; \
    fi

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1

# Set WalletConnect project ID
ENV NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID="47ef282c9343d40209929de4d60d58cb"

# Skip linting in the build process to avoid ESLint compatibility issues with Bun
RUN NODE_OPTIONS="--max_old_space_size=4096" NEXT_TELEMETRY_DISABLED=1 bunx --bun next build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
# Uncomment the following line in case you want to disable telemetry during runtime.
ENV NEXT_TELEMETRY_DISABLED=1
# Set WalletConnect project ID for runtime
ENV NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID="47ef282c9343d40209929de4d60d58cb"

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD ["node", "server.js"]