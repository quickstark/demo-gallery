import React, { useEffect } from "react";
import { useLocation } from "react-router-dom";
import { datadogRum } from "@datadog/browser-rum";

const RumViewTracker = ({ allowedViewPaths }) => {
  const location = useLocation();

  useEffect(() => {
    if (allowedViewPaths && allowedViewPaths.includes(location.pathname)) {
      datadogRum.startView({ name: location.pathname });
      console.log(`Datadog RUM: Started view - ${location.pathname} (allowed)`);
    } else {
      console.log(`Datadog RUM: View not started for ${location.pathname} (path not in allowedViewPaths or prop not provided)`);
    }
  }, [location.pathname, allowedViewPaths]); // Re-run the effect when pathname or allowedViewPaths changes

  return null; // This component does not render anything
};

export default RumViewTracker; 