FROM node:20-alpine AS builder
WORKDIR /app

ARG JWT_ACCESS_SECRET
ARG MODE
ARG AUTH_EMAIL
ARG AUTH_EMAIL_PW

ENV JWT_ACCESS_SECRET=$JWT_ACCESS_SECRET \
    MODE=$MODE \
    AUTH_EMAIL=$AUTH_EMAIL \
    AUTH_EMAIL_PW=$AUTH_EMAIL_PW

COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
RUN npx prisma generate
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=60s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "build/index.js"]