import React, { useContext, useState, useMemo } from "react";

/* Create our Environment Context
   It's easier to just define this once and reuse in 
   the Components where Context is needed */

const EnvContext = React.createContext();

// Custom Hook to use our Context
export function useEnvContext() {
  return useContext(EnvContext);
}

/**
 * Fetch active backend from localStorage with fallback to 'mongo'
 * @returns {string} The active backend identifier
 */
function fetchActiveBackend() {
  const stored = localStorage.getItem("activeBackend");
  if (stored === null) {
    localStorage.setItem("activeBackend", "mongo");
    return "mongo";
  }
  return stored;
}

/**
 * Provider for environment context with backend selection
 * @param {Object} props - Component props
 * @param {React.ReactNode} props.children - Child components
 */
export function EnvProvider({ children }) {
  const [activeBackend, setActiveBackend] = useState(fetchActiveBackend);

  // Memoize context value to prevent unnecessary re-renders
  const contextValue = useMemo(() => [activeBackend, setActiveBackend], [activeBackend]);

  return (
    <EnvContext.Provider value={contextValue}>
      {children}
    </EnvContext.Provider>
  );
}
