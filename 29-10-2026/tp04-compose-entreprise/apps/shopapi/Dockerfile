FROM node:20.19.5-alpine3.22@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435 AS development-deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

FROM development-deps AS test
COPY src/ ./src/
COPY test/ ./test/
RUN npm test && npm run lint

FROM node:20.19.5-alpine3.22@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435 AS production-deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund

FROM alpine:3.22.7@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f AS runtime
ARG APP_VERSION=dev
ARG GIT_SHA=local
ARG IMAGE_SOURCE=https://github.com/4d3n4n/docker-26-27
LABEL org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}"
ENV NODE_ENV=production \
    APP_VERSION=${APP_VERSION}
RUN addgroup -S -g 1000 node && adduser -S -D -H -u 1000 -G node node
COPY --from=production-deps /usr/local/bin/node /usr/local/bin/node
COPY --from=production-deps /usr/lib/libstdc++.so.6.0.33 /usr/lib/libstdc++.so.6
COPY --from=production-deps /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
WORKDIR /app
COPY --from=production-deps --chown=node:node /app/node_modules ./node_modules
COPY --from=test --chown=node:node /app/src ./src
COPY --chown=node:node package.json ./package.json
# hadolint ignore=DL3066
USER node
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=3s --start-period=2s --retries=3 \
  CMD ["node", "-e", "require('node:http').get('http://127.0.0.1:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"]
CMD ["node", "src/server.js"]
