FROM node:24-alpine AS builder
WORKDIR /app

RUN apk add --no-cache --virtual .build-deps python3 make g++ git

COPY package.json package-lock.json* ./
RUN npm ci --quiet

COPY . .
RUN npm run build

FROM nginx:stable-alpine AS runner
LABEL org.opencontainers.image.description="numeraid-react-ui docker image"

RUN apk add --no-cache curl

COPY --from=builder /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
