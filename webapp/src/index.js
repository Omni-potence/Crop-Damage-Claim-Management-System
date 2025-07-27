import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { BrowserRouter as Router } from 'react-router-dom';
import { FirebaseProvider } from './contexts/FirebaseContext'; // Re-import FirebaseProvider

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <FirebaseProvider> {/* Re-add FirebaseProvider */}
      <Router>
        <App />
      </Router>
    </FirebaseProvider>
  </React.StrictMode>
);
