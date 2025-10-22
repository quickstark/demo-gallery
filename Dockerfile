# Multi-stage build for optimized production image

# Stage 1: Build the application
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application with placeholder values
# These will be replaced at runtime by the entrypoint script
ENV VITE_API_URL=__VITE_API_URL__
ENV VITE_API_KEY=__VITE_API_KEY__
ENV VITE_AUTH_USERNAME=__VITE_AUTH_USERNAME__
ENV VITE_AUTH_PASSWORD=__VITE_AUTH_PASSWORD__
ENV VITE_ENVIRONMENT=__VITE_ENVIRONMENT__
ENV VITE_DATADOG_APPLICATION_ID=__VITE_DATADOG_APPLICATION_ID__
ENV VITE_DATADOG_CLIENT_TOKEN=__VITE_DATADOG_CLIENT_TOKEN__
ENV VITE_DATADOG_SITE=__VITE_DATADOG_SITE__
ENV VITE_DATADOG_SERVICE=__VITE_DATADOG_SERVICE__
ENV VITE_RELEASE=__VITE_RELEASE__

# Build the application
RUN yarn build

# Stage 2: Serve the application with Nginx
FROM nginx:alpine

# Install gettext for envsubst (used in entrypoint)
RUN apk add --no-cache gettext

# Copy built files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY docker/entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:80/ || exit 1

# Expose port 80
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
