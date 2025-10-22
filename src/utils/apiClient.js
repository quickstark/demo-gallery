import axios from 'axios';

// Create axios instance with default configuration
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  timeout: 30000,
  withCredentials: true, // Enable sending cookies for Authelia auth
  headers: {
    'Content-Type': 'application/json',
  }
});

// Request interceptor for auth
apiClient.interceptors.request.use(
  (config) => {
    // Check if we need authentication
    const useAuth = import.meta.env.VITE_USE_AUTH === 'true';
    
    if (useAuth) {
      // Option 1: Basic Authentication (if username and password are provided)
      const username = import.meta.env.VITE_AUTH_USERNAME;
      const password = import.meta.env.VITE_AUTH_PASSWORD;
      
      if (username && password) {
        // Create Basic Auth header
        const basicAuth = btoa(`${username}:${password}`);
        config.headers['Authorization'] = `Basic ${basicAuth}`;
        
        // Add custom header that your API/Authelia might recognize
        config.headers['X-Auth-User'] = username;
      } 
      // Option 2: API Key authentication (fallback)
      else {
        const apiKey = import.meta.env.VITE_API_KEY;
        if (apiKey) {
          config.headers['X-API-Key'] = apiKey;
        }
      }
    }
    // If no auth needed, just return the config as-is
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for auth errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized - redirect to Authelia login
      const currentUrl = window.location.href;
      const authUrl = `https://auth.quickstark.com/?rd=${encodeURIComponent(currentUrl)}`;
      
      // Option 1: Auto-redirect to login
      // window.location.href = authUrl;
      
      // Option 2: Show error and let user decide
      console.error('Authentication required. Please login.');
      
      // You could also emit an event or update global state here
      // to show a login modal or notification
    }
    return Promise.reject(error);
  }
);

export default apiClient;
