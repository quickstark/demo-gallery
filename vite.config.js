import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig(({ command, mode }) => {
  // Load env file based on `mode` in the current working directory.
  // Set the third parameter to '' to load all env regardless of the `VITE_` prefix.
  const env = loadEnv(mode, process.cwd(), "");

  return {
    build: {
      sourcemap: true,
      emptyOutDir: true,
      commonjsOptions: {
        include: [
          /@kyletaylored\/datadog-rum-interceptor/,
          /react/,
          /react-dom/,
          /react-router/,
          /react-icons/,
          /fast-safe-stringify/,
          /@chakra-ui/,
          /node_modules/
        ],
        transformMixedEsModules: true,
        defaultIsModuleExports: true
      },
      rollupOptions: {
        output: {
          manualChunks: {
            react: ['react', 'react-dom'],
            router: ['react-router-dom'],
            icons: ['react-icons/fi']
          }
        },
        external: [],
        plugins: []
      }
    },
    server: {
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          res.setHeader('Document-Policy', 'js-profiling');
          next();
        });
      },
    },
    plugins: [
      react({
        jsxRuntime: 'automatic'
      }),
    ],
    resolve: {
      alias: {
        '@kyletaylored/datadog-rum-interceptor': path.resolve(__dirname, 'node_modules/@kyletaylored/datadog-rum-interceptor/dist/es/index.js'),
        'fast-safe-stringify': path.resolve(__dirname, 'node_modules/fast-safe-stringify/index.js')
      }
    },
    optimizeDeps: {
      include: [
        '@kyletaylored/datadog-rum-interceptor',
        'react',
        'react-dom',
        'react/jsx-runtime',
        'react-router-dom',
        'react-icons/fi',
        '@chakra-ui/react',
        'fast-safe-stringify'
      ],
      esbuildOptions: {
        target: 'esnext'
      },
      force: true
    },
    define: {
      global: 'globalThis'
    }
  };
});
