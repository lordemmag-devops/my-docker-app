import React, { useState, useEffect } from 'react';
import './App.css';
import Register from './components/Register';
import Login from './components/Login';
import Chat from './components/Chat';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [view, setView] = useState('login'); // 'login', 'register', 'chat'

  useEffect(() => {
    // Check if user is already logged in
    const storedToken = localStorage.getItem('token');
    const storedUser = localStorage.getItem('user');

    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
      setIsAuthenticated(true);
      setView('chat');
    }
  }, []);

  const handleRegisterSuccess = () => {
    setView('login');
  };

  const handleLoginSuccess = (userData, authToken) => {
    setUser(userData);
    setToken(authToken);
    setIsAuthenticated(true);
    setView('chat');

    // Store in localStorage
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('token', authToken);
  };

  const handleLogout = () => {
    setUser(null);
    setToken(null);
    setIsAuthenticated(false);
    setView('login');

    // Clear from localStorage
    localStorage.removeItem('user');
    localStorage.removeItem('token');
  };

  return (
    <div className="App">
      {view === 'register' ? (
        <Register onRegisterSuccess={handleRegisterSuccess} onSwitchToLogin={() => setView('login')} />
      ) : view === 'login' ? (
        <Login onLoginSuccess={handleLoginSuccess} onSwitchToRegister={() => setView('register')} />
      ) : (
        <Chat user={user} token={token} onLogout={handleLogout} />
      )}
    </div>
  );
}

export default App;
