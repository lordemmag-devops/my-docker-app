import React, { useState, useEffect } from 'react';
import './Chat.css';
import config from '../config';

const EMOJIS = ['😀', '😂', '😍', '🥰', '😎', '🤔', '😢', '😡', '👍', '👎', '❤️', '🔥', '💯', '🎉', '👏', '🙏'];

function Chat({ user, token, onLogout }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);

  const [showCamera, setShowCamera] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [stream, setStream] = useState(null);
  const [facingMode, setFacingMode] = useState('user');
  const [filter, setFilter] = useState('none');

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    try {
      if (!token) {
        setError('No authentication token');
        setLoading(false);
        return;
      }

      const response = await fetch(`${config.API_BASE_URL}/messages`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setMessages(data);
        setError(null);
      } else if (response.status === 401 || response.status === 403) {
        setError('Authentication failed. Please login again.');
        onLogout();
      } else {
        throw new Error(`Failed to fetch messages: ${response.status}`);
      }
    } catch (err) {
      setError('Failed to load messages. Check your connection.');
      console.error('Fetch messages error:', err);
    } finally {
      setLoading(false);
    }
  };

  const sendMessage = async (messageData = null) => {
    const data = messageData || { type: 'text', text: input.trim() };
    
    if (data.type === 'text' && !data.text) return;
    
    if (data.type === 'text') setInput('');
    setShowEmojiPicker(false);


    // Optimistically add the message
    const optimisticMessage = {
      _id: Date.now().toString(),
      sender: { username: user.username },
      ...data,
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
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error('Failed to send message');
      }

      const responseData = await response.json();
      setMessages(prevMessages =>
        prevMessages.map(msg =>
          msg._id === optimisticMessage._id ? responseData : msg
        )
      );
    } catch (err) {
      setError('Failed to send message');
      setMessages(prevMessages =>
        prevMessages.filter(msg => msg._id !== optimisticMessage._id)
      );
      console.error('Send message error:', err);
    }
  };

  const sendEmoji = (emoji) => {
    sendMessage({ type: 'emoji', emoji });
  };



  const uploadFile = async (file) => {
    setUploading(true);
    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await fetch(`${config.API_BASE_URL}/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        body: formData,
      });

      if (response.ok) {
        const message = await response.json();
        setMessages(prevMessages => [...prevMessages, message]);
      } else {
        throw new Error('Upload failed');
      }
    } catch (err) {
      setError('Failed to upload file');
      console.error('Upload error:', err);
    } finally {
      setUploading(false);
    }
  };

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    if (file) uploadFile(file);
  };

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ 
        video: { facingMode } 
      });
      setStream(mediaStream);
      setShowCamera(true);
    } catch (err) {
      setError('Camera access denied');
      console.error('Camera error:', err);
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
    setShowCamera(false);
  };

  const switchCamera = async () => {
    const newFacingMode = facingMode === 'user' ? 'environment' : 'user';
    setFacingMode(newFacingMode);
    if (stream) {
      stopCamera();
      setTimeout(() => {
        navigator.mediaDevices.getUserMedia({ 
          video: { facingMode: newFacingMode } 
        }).then(setStream);
      }, 100);
    }
  };

  const takePhoto = () => {
    const video = document.getElementById('camera-video');
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    
    // Apply filter
    if (filter !== 'none') {
      ctx.filter = getFilterCSS(filter);
    }
    
    ctx.drawImage(video, 0, 0);
    
    canvas.toBlob((blob) => {
      const file = new File([blob], `photo-${Date.now()}.jpg`, { type: 'image/jpeg' });
      uploadFile(file);
      stopCamera();
    }, 'image/jpeg', 0.9);
  };

  const getFilterCSS = (filterName) => {
    const filters = {
      grayscale: 'grayscale(100%)',
      sepia: 'sepia(100%)',
      blur: 'blur(2px)',
      brightness: 'brightness(150%)',
      contrast: 'contrast(150%)'
    };
    return filters[filterName] || 'none';
  };

  const renderMessage = (msg) => {
    if (msg.type === 'emoji') {
      return <span className="emoji-message">{msg.emoji}</span>;
    }

    if (msg.type === 'image') {
      return (
        <div className="image-message">
          <img src={`${config.API_BASE_URL}${msg.fileUrl}`} alt={msg.fileName} />
          <span className="file-name">{msg.fileName}</span>
        </div>
      );
    }
    if (msg.type === 'file') {
      return (
        <div className="file-message">
          <a href={`${config.API_BASE_URL}${msg.fileUrl}`} download={msg.fileName}>
            📎 {msg.fileName} ({(msg.fileSize / 1024).toFixed(1)}KB)
          </a>
        </div>
      );
    }
    return msg.text;
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
          <div key={msg._id} className={`message ${msg.sender.username === user.username ? 'own' : 'other'} ${msg.type}`}>
            <strong>{msg.sender.username}:</strong> {renderMessage(msg)}
          </div>
        ))}
      </div>
      <div className="chat-input">
        <div className="input-controls">
          <button className="emoji-btn" onClick={() => setShowEmojiPicker(!showEmojiPicker)}>
            😀
          </button>
          <button className="camera-btn" onClick={startCamera} disabled={uploading}>
            📷
          </button>
          <label className="file-btn">
            📁
            <input type="file" onChange={handleFileSelect} style={{display: 'none'}} disabled={uploading} />
          </label>
        </div>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
          placeholder="Type a message..."
        />
        <button onClick={() => sendMessage()} disabled={uploading}>
          {uploading ? 'Uploading...' : 'Send'}
        </button>
        
        {showEmojiPicker && (
          <div className="emoji-picker">
            {EMOJIS.map((emoji, index) => (
              <button key={index} className="emoji-option" onClick={() => sendEmoji(emoji)}>
                {emoji}
              </button>
            ))}
          </div>
        )}
        

        
        {showCamera && (
          <div className="camera-modal">
            <div className="camera-container">
              <video 
                id="camera-video" 
                autoPlay 
                playsInline 
                ref={(video) => {
                  if (video && stream) {
                    video.srcObject = stream;
                  }
                }}
                style={{ filter: getFilterCSS(filter) }}
              />
              <div className="camera-controls">
                <div className="filter-controls">
                  {['none', 'grayscale', 'sepia', 'blur', 'brightness', 'contrast'].map(f => (
                    <button 
                      key={f} 
                      className={`filter-btn ${filter === f ? 'active' : ''}`}
                      onClick={() => setFilter(f)}
                    >
                      {f}
                    </button>
                  ))}
                </div>
                <div className="camera-actions">
                  <button className="camera-action-btn" onClick={switchCamera}>
                    🔄
                  </button>
                  <button className="capture-btn" onClick={takePhoto}>
                    📷
                  </button>
                  <button className="camera-action-btn" onClick={stopCamera}>
                    ❌
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default Chat;
