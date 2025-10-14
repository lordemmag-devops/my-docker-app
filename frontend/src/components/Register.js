import React, { useState } from 'react';
import config from '../config'; // Import the config file
import './Register.css'; // We'll create this CSS file next

function Register({ onRegisterSuccess, onSwitchToLogin }) {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');
  const [errors, setErrors] = useState({});

  const validateForm = () => {
    const newErrors = {};
    if (!username) newErrors.username = 'Username is required';
    if (!email) newErrors.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(email)) newErrors.email = 'Email is invalid';
    if (!password) newErrors.password = 'Password is required';
    else if (password.length < 6) newErrors.password = 'Password must be at least 6 characters';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setMessage('');
    setErrors({});

    if (!validateForm()) {
      return;
    }

    try {
      console.log('Attempting to register:', { username, email, password });
      const response = await fetch(`${config.API_BASE_URL}/register`, {
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
        // Handle validation errors from the backend
        if (data.errors) {
          const apiErrors = {};
          data.errors.forEach(err => {
            apiErrors[err.path] = err.msg;
          });
          setErrors(apiErrors);
        } else {
          setMessage(data.message || 'Registration failed. Please try again.');
        }
      }
    } catch (error) {
      setMessage('Network error. Please try again later.');
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
        <p className="switch-link">
          Already have an account?{' '}
          <button
            type="button"
            className="link-button"
            onClick={onSwitchToLogin}
          >
            Login here
          </button>
        </p>
      </form>
    </div>
  );
}

export default Register;
