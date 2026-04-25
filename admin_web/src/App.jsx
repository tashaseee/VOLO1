import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Sidebar from './components/Sidebar';
import UsersPage from './pages/UsersPage';
import EventsPage from './pages/EventsPage';
import StatsPage from './pages/StatsPage';
import PendingOrgsPage from './pages/PendingOrgsPage';

function ProtectedLayout({ children, onLogout }) {
  return (
    <div className="app-container">
      <Sidebar onLogout={onLogout} />
      <main className="main-content">
        {children}
      </main>
    </div>
  );
}

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));

  const handleLogin = (newToken) => {
    localStorage.setItem('token', newToken);
    setToken(newToken);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken(null);
  };

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={!token ? <Login onLogin={handleLogin} /> : <Navigate to="/" />} />

        <Route path="/" element={token ? (
          <ProtectedLayout onLogout={handleLogout}>
            <StatsPage token={token} />
          </ProtectedLayout>
        ) : <Navigate to="/login" />} />

        <Route path="/pending" element={token ? (
          <ProtectedLayout onLogout={handleLogout}>
            <PendingOrgsPage token={token} />
          </ProtectedLayout>
        ) : <Navigate to="/login" />} />

        <Route path="/users" element={token ? (
          <ProtectedLayout onLogout={handleLogout}>
            <UsersPage token={token} />
          </ProtectedLayout>
        ) : <Navigate to="/login" />} />

        <Route path="/events" element={token ? (
          <ProtectedLayout onLogout={handleLogout}>
            <EventsPage token={token} />
          </ProtectedLayout>
        ) : <Navigate to="/login" />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
