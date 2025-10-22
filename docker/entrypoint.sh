#!/bin/sh
set -e

# Function to replace environment variables in JavaScript files
replace_env_vars() {
    echo "Injecting runtime environment variables..."
    
    # Find all JavaScript and HTML files in the build directory
    for file in /usr/share/nginx/html/assets/*.js /usr/share/nginx/html/index.html; do
        if [ -f "$file" ]; then
            echo "Processing: $file"
            
            # Replace placeholder values with actual environment variables
            # Using sed for compatibility with Alpine Linux
            sed -i "s|__VITE_API_URL__|${VITE_API_URL:-http://localhost:8000}|g" "$file"
            sed -i "s|__VITE_API_KEY__|${VITE_API_KEY:-}|g" "$file"
            sed -i "s|__VITE_AUTH_USERNAME__|${VITE_AUTH_USERNAME:-}|g" "$file"
            sed -i "s|__VITE_AUTH_PASSWORD__|${VITE_AUTH_PASSWORD:-}|g" "$file"
            sed -i "s|__VITE_ENVIRONMENT__|${VITE_ENVIRONMENT:-production}|g" "$file"
            sed -i "s|__VITE_DATADOG_APPLICATION_ID__|${VITE_DATADOG_APPLICATION_ID:-}|g" "$file"
            sed -i "s|__VITE_DATADOG_CLIENT_TOKEN__|${VITE_DATADOG_CLIENT_TOKEN:-}|g" "$file"
            sed -i "s|__VITE_DATADOG_SITE__|${VITE_DATADOG_SITE:-datadoghq.com}|g" "$file"
            sed -i "s|__VITE_DATADOG_SERVICE__|${VITE_DATADOG_SERVICE:-demo-gallery}|g" "$file"
            sed -i "s|__VITE_RELEASE__|${VITE_RELEASE:-1.0.0}|g" "$file"
        fi
    done
    
    echo "Environment variable injection complete."
}

# Create a runtime config file for debugging (optional)
create_config_info() {
    cat > /usr/share/nginx/html/config.json <<EOF
{
  "environment": "${VITE_ENVIRONMENT:-production}",
  "service": "${VITE_DATADOG_SERVICE:-demo-gallery}",
  "release": "${VITE_RELEASE:-1.0.0}",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Main execution
echo "Starting container initialization..."
echo "Environment: ${VITE_ENVIRONMENT:-production}"
echo "API URL: ${VITE_API_URL:-http://localhost:8000}"
echo "Datadog Service: ${VITE_DATADOG_SERVICE:-demo-gallery}"
echo "Release: ${VITE_RELEASE:-1.0.0}"

# Replace environment variables
replace_env_vars

# Create config info file
create_config_info

echo "Container initialization complete. Starting nginx..."

# Execute the original nginx command
exec "$@"

