import { createToaster } from "@chakra-ui/react";

// Centralized toaster configuration for consistent notifications across the app
const toaster = createToaster({
  placement: "top",
  pauseOnPageIdle: true,
  max: 5, // Limit concurrent toasts
});

/**
 * Custom hook for application-wide toast notifications
 * Provides consistent styling and behavior across all components
 * @returns {Object} Toast interface with enhanced methods
 */
export const useAppToaster = () => {
  return {
    // Standard toast creation
    create: toaster.create,
    
    // Enhanced toast methods with consistent styling
    success: (title, description, duration = 3000) => 
      toaster.create({
        title,
        description,
        status: "success",
        duration,
      }),
    
    error: (title, description, duration = 6000) => 
      toaster.create({
        title,
        description,
        status: "error",
        duration,
      }),
    
    warning: (title, description, duration = 4000) => 
      toaster.create({
        title,
        description,
        status: "warning",
        duration,
      }),
    
    info: (title, description, duration = 3000) => 
      toaster.create({
        title,
        description,
        status: "info",
        duration,
      }),

    // Quick feedback methods
    quickSuccess: (message) => 
      toaster.create({
        description: message,
        status: "success",
        duration: 2000,
      }),
    
    quickError: (message) => 
      toaster.create({
        description: message,
        status: "error",
        duration: 4000,
      }),

    // Close methods
    close: toaster.close,
    closeAll: toaster.closeAll,
  };
};