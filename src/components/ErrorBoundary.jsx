import React from 'react';
import { Box, Heading, Text, Button, VStack } from '@chakra-ui/react';
import { datadogRum } from '@datadog/browser-rum';

/**
 * Error boundary component that catches JavaScript errors in child components
 * and displays a fallback UI while logging errors to Datadog
 */
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  /**
   * Update state when an error is caught
   * @param {Error} error - The error that was thrown
   * @returns {Object} New state object
   */
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  /**
   * Log error details to Datadog and console
   * @param {Error} error - The error that was thrown
   * @param {Object} errorInfo - Additional error information from React
   */
  componentDidCatch(error, errorInfo) {
    this.setState({ errorInfo });
    
    // Log to Datadog RUM with enhanced context
    datadogRum.addError(error, {
      context: 'error_boundary',
      componentStack: errorInfo.componentStack,
      errorBoundary: this.props.fallbackComponent || 'ErrorBoundary',
      timestamp: new Date().toISOString()
    });

    // Log to console for development
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  /**
   * Reset error state to allow retry
   */
  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  render() {
    if (this.state.hasError) {
      // Custom fallback UI or default error UI
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.handleReset);
      }

      return (
        <Box
          p={6}
          borderRadius="md"
          bg="red.50"
          borderColor="red.200"
          borderWidth={1}
          maxW="md"
          mx="auto"
          mt={8}
        >
          <VStack spacing={4} align="center">
            <Heading size="md" color="red.600">
              Something went wrong
            </Heading>
            <Text color="red.600" textAlign="center">
              An error occurred while rendering this component. The error has been logged for investigation.
            </Text>
            {this.props.showDetails && this.state.error && (
              <Text fontSize="sm" color="gray.600" fontFamily="mono">
                {this.state.error.message}
              </Text>
            )}
            <Button 
              colorScheme="red" 
              variant="outline" 
              onClick={this.handleReset}
              size="sm"
            >
              Try Again
            </Button>
          </VStack>
        </Box>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;