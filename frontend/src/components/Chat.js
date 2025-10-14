import React, { useState, useEffect } from 'react';
import './Chat.css';
import config from '../config';

function Chat({ user, token, onLogout }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    try {
      const response = await fetch(`${config.API_BASE_URL}/messages`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setMessages(data);
      } else {
        throw new Error('Failed to fetch messages');
      }
    } catch (err) {
      setError('Failed to load messages');
      console.error('Fetch messages error:', err);
    } finally {
      setLoading(false);
    }
  };

  const sendMessage = async () => {
    if (input.trim()) {
      const messageText = input.trim();
      setInput('');

      // Optimistically add the message
      const optimisticMessage = {
        _id: Date.now().toString(),
        sender: { username: user.username },
        text: messageText,
        timestamp: new Date(),
      };
      setMessages(prevMessages => [...prevMessages, optimisticMessage]);

      try {
        const response = await fetch(`${config.API_BASE_URL}/messages`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ text: messageText }),
        });

        if (!response.ok) {
          throw new Error('Failed to send message');
        }

        const data = await response.json();
        // Replace optimistic message with the real one
        setMessages(prevMessages =>
          prevMessages.map(msg =>
            msg._id === optimisticMessage._id ? data : msg
          )
        );
      } catch (err) {
        setError('Failed to send message');
        // Remove optimistic message on error
        setMessages(prevMessages =>
          prevMessages.filter(msg => msg._id !== optimisticMessage._id)
        );
        console.error('Send message error:', err);
      }
    }
  };

  const handleLogout = () => {
    if (onLogout) {
      onLogout();
    }
  };

  if (loading) {
    return <div className="chat-container">Loading messages...</div>;
  }

  if (error) {
    return <div className="chat-container">Error: {error}</div>;
  }

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h2>eno chat</h2>
        <div className="header-controls">
          <span>Welcome, {user.username}</span>
          <button onClick={handleLogout} className="logout-button">Logout</button>
        </div>
      </div>
      <div className="chat-messages">
        {messages.map((msg) => (
          <div key={msg._id} className={`message ${msg.sender.username === user.username ? 'own' : 'other'}`}>
            <strong>{msg.sender.username}:</strong> {msg.text}
          </div>
        ))}
      </div>
      <div className="chat-input">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
          placeholder="Type a message..."
        />
        <button onClick={sendMessage}>Send</button>
      </div>
    </div>
  );
}

export default Chat;
