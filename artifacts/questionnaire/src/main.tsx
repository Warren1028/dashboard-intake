import { createRoot } from "react-dom/client";
import AppRouter from "./AppRouter";
import { AuthProvider } from "./context/AuthContext";
import { firm } from "./config/firm.config";
import "./index.css";

// Expose brand colours as CSS variables so stylesheets can use var(--firm-primary) etc.
const root = document.documentElement.style;
root.setProperty("--firm-primary", firm.colors.primary);
root.setProperty("--firm-primary-dark", firm.colors.primaryDark);
root.setProperty("--firm-primary-light", firm.colors.primaryLight);
root.setProperty("--firm-secondary", firm.colors.secondary);
root.setProperty("--firm-secondary-light", firm.colors.secondaryLight);

createRoot(document.getElementById("root")!).render(
  <AuthProvider>
    <AppRouter />
  </AuthProvider>
);
