import React, { useState } from 'react';
import './Register.css'; // We'll create this CSS file next

function Register({ onRegisterSuccess }) {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');

  const handleRegister = async (e) => {
    e.preventDefault();
    setMessage('');

    // Basic validation
    if (!username || !email || !password) {
      setMessage('Please fill in all fields.');
      return;
    }

    try {
      // This will be replaced with an actual API call to the backend
      console.log('Attempting to register:', { username, email, password });
      const response = await fetch('http://localhost:3000/register', { // Assuming backend runs on port 3000
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, email, password }),
      });

      const data = await response.json();

      if (response.ok) {
        setMessage('Registration successful! Redirecting to chat...');
        if (onRegisterSuccess) {
          onRegisterSuccess();
        }
      } else {
        setMessage(data.message || 'Registration failed. Please try again.');
      }
    } catch (error) {
      setMessage('Registration failed. Please try again.');
      console.error('Registration error:', error);
    }
  };

  return (
    <div className="register-container">
      <div className="register-header">
        <h2>Register for eno Chat</h2>
      </div>
      <form onSubmit={handleRegister} className="register-form">
        <div className="form-group">
          <label htmlFor="username">Username:</label>
          <input
            type="text"
            id="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Choose a username"
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="email">Email:</label>
          <input
            type="email"
            id="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Enter your email"
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="password">Password:</label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Create a password"
            required
          />
        </div>
        <button type="submit" className="register-button">Register</button>
        {message && <p className="register-message">{message}</p>}
      </form>
    </div>
  );
}

export default Register;
