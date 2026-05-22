FROM node:20-alpine AS builder
WORKDIR /app

# Build-time env vars — baked into compiled JS by SvelteKit ($env/static/private)
ARG SITE_NAME
ARG JWT_ACCESS_SECRET
ARG MODE
ARG CONTACT_EMAIL
ARG TIME_ZONE
ARG AUTH_EMAIL
ARG AUTH_EMAIL_PW
ARG SMTP_HOST
ARG SMTP_PORT

ENV SITE_NAME=$SITE_NAME \
    JWT_ACCESS_SECRET=$JWT_ACCESS_SECRET \
    MODE=$MODE \
    CONTACT_EMAIL=$CONTACT_EMAIL \
    TIME_ZONE=$TIME_ZONE \
    AUTH_EMAIL=$AUTH_EMAIL \
    AUTH_EMAIL_PW=$AUTH_EMAIL_PW \
    SMTP_HOST=$SMTP_HOST \
    SMTP_PORT=$SMTP_PORT

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