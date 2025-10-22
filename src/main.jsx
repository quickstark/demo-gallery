import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./index.css";

import { ChakraProvider, createSystem, defaultConfig } from "@chakra-ui/react";

const system = createSystem(defaultConfig, {
  theme: {
    tokens: {
      colors: {
        brand: {
          50: { value: "#f7fafc" },
          100: { value: "#edf2f7" },
          200: { value: "#e2e8f0" },
          300: { value: "#cbd5e0" },
          400: { value: "#a0aec0" },
          500: { value: "#718096" },
          600: { value: "#4a5568" },
          700: { value: "#2d3748" },
          800: { value: "#1a202c" },
          900: { value: "#171923" },
        },
        accent: {
          50: { value: "#fffbeb" },
          100: { value: "#fef3c7" },
          200: { value: "#fde68a" },
          300: { value: "#fcd34d" },
          400: { value: "#fbbf24" },
          500: { value: "#f59e0b" },
          600: { value: "#d97706" },
          700: { value: "#b45309" },
          800: { value: "#92400e" },
          900: { value: "#78350f" },
        }
      },
      fonts: {
        heading: { value: 'Inter, system-ui, sans-serif' },
        body: { value: 'Inter, system-ui, sans-serif' },
      },
      spacing: {
        xs: { value: "0.5rem" },
        sm: { value: "1rem" },
        md: { value: "1.5rem" },
        lg: { value: "2rem" },
        xl: { value: "3rem" },
      }
    }
  },
  globalCss: {
    body: {
      bg: 'gray.900',
      color: 'white',
      fontFamily: 'body',
      lineHeight: '1.6',
    },
    '*': {
      boxSizing: 'border-box',
    },
    'html': {
      scrollBehavior: 'smooth',
    },
    // Enhanced focus styles for accessibility
    '*:focus-visible': {
      outline: '2px solid',
      outlineColor: 'accent.400',
      outlineOffset: '2px',
    },
  }
});

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <ChakraProvider value={system}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </ChakraProvider>
  </React.StrictMode>
);
