import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import path from 'path'
import { execSync } from 'child_process';
import fs from 'fs';

/**
 * Vite plugin to automatically inject version from VERSION file + git commit SHA
 * This ensures a single source of truth for versioning across all environments
 */
function versionInjectionPlugin() {
  return {
    name: 'version-injection',
    config: () => {
      let version = 'unknown';
      let gitSha = 'local';
      let release = 'unknown-local';

      try {
        // Read VERSION file (single source of truth)
        const versionFile = path.join(process.cwd(), 'VERSION');
        if (fs.existsSync(versionFile)) {
          version = fs.readFileSync(versionFile, 'utf-8').trim();
        } else {
          console.warn('⚠️  VERSION file not found, using "unknown"');
        }

        // Get git commit SHA (for uniqueness)
        try {
          gitSha = execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim();
        } catch (err) {
          console.warn('⚠️  Git not available, using "local" for commit SHA');
          gitSha = 'local';
        }

        // Create release version (VERSION-SHA format, matching deploy workflow)
        release = `${version}-${gitSha}`;

        console.log(`📦 Version injection: ${release} (from VERSION file + git)`);
      } catch (err) {
        console.error('❌ Error reading version:', err.message);
      }

      return {
        define: {
          // Inject VITE_RELEASE at build time
          'import.meta.env.VITE_RELEASE': JSON.stringify(release),
        }
      };
    }
  };
}

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
      versionInjectionPlugin(), // Inject version from VERSION file + git SHA
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
