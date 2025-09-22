# Multi-Service Docker Application

This project demonstrates a multi-service application built with Docker, showcasing advanced Docker features like multi-stage builds, custom base images, Docker Compose, secrets, volumes, networks, health checks, and logging. The application simulates a real-world scenario with interconnected services, optimized for performance and scalability.

## Project Overview

The application consists of five services:
- **Web Application**: A React-based frontend served via Nginx.
- **API Service**: A Node.js Express backend handling API requests.
- **Database**: A MongoDB instance for persistent data storage.
- **Cache**: A Redis instance for performance optimization.
- **Reverse Proxy**: An Nginx server to route incoming requests to the appropriate service.

## Features

- **Docker Compose**: Orchestrates all services with a single configuration file.
- **Custom Base Image**: A lightweight `base-node` image for Node.js services.
- **Multi-Stage Builds**: Optimizes the frontend image size by separating build and runtime environments.
- **Docker Network**: A bridge network (`app-net`) ensures secure communication between services.
- **Volumes**: Persistent storage for MongoDB (`db-data`) and Redis (`cache-data`).
- **Secrets**: Secure handling of sensitive data (e.g., MongoDB password via `db-password.txt`).
- **Health Checks**: Monitors service availability to ensure reliability.
- **Optimized Dockerfiles**: Reduces image sizes and build times.
- **Logging**: Configured with log rotation to manage log file sizes.

## Prerequisites

Before running the project, ensure you have the following installed:
- **Docker**: Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop) for your operating system (Windows, Mac, or Linux).
- **Docker Compose**: Included with Docker Desktop. Verify with `docker compose version`.
- **Node.js**: Required for local development of the frontend and backend. Install from [nodejs.org](https://nodejs.org) (LTS version recommended).
- **Git** (optional): For cloning or managing the project. Install from [git-scm.com](https://git-scm.com).

## Project Structure

```plaintext
my-docker-app/
├── backend/
│   ├── Dockerfile
│   ├── index.js
│   ├── package.json
│   └── ...
├── base-node/
│   ├── Dockerfile
├── frontend/
│   ├── Dockerfile
│   ├── src/
│   ├── package.json
│   └── ...
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
├── docker-compose.yml
├── db-password.txt
└── README.md
```

- `backend/`: Node.js Express API service.
- `base-node/`: Custom Node.js base image.
- `frontend/`: React frontend served by Nginx.
- `nginx/`: Nginx reverse proxy configuration.
- `docker-compose.yml`: Defines and orchestrates all services.
- `db-password.txt`: Contains the MongoDB password (secret).

## Setup Instructions

1. **Clone or Create the Project**:
   - If using Git, clone the repository:
     ```bash
     git clone <repository-url>
     cd my-docker-app
     ```
   - Alternatively, create the folder structure manually as shown above.

2. **Set Up the Frontend**:
   - Navigate to `frontend/`:
     ```bash
     cd frontend
     ```
   - Initialize a React app:
     ```bash
     npx create-react-app .
     ```
   - This creates the React project structure.

3. **Set Up the Backend**:
   - Navigate to `backend/`:
     ```bash
     cd ../backend
     ```
   - Initialize a Node.js project:
     ```bash
     npm init -y
     npm install express mongoose redis
     ```
   - Create `index.js` with the backend code (see [Backend Code](#backend-code)).

4. **Create the MongoDB Password Secret**:
   - In the main project folder, create `db-password.txt`:
     ```bash
     echo "supersecret" > db-password.txt
     ```
   - Replace "supersecret" with a secure password for production.

5. **Build and Run the Application**:
   - From the main project folder:
     ```bash
     docker compose up -d
     ```
   - This builds and starts all services in the background.
   - To view logs:
     ```bash
     docker compose logs
     ```

6. **Access the Application**:
   - Open a browser and visit:
     - Frontend: `http://localhost`
     - API: `http://localhost/api/`
   - The API should respond with "Hello from API!".

7. **Stop the Application**:
   ```bash
   docker compose down
   ```

## Configuration Details

### Docker Compose
The `docker-compose.yml` defines five services:
- `base-node`: Custom Node.js base image.
- `web`: React frontend served by Nginx.
- `api`: Node.js Express backend.
- `db`: MongoDB database.
- `cache`: Redis cache.
- `proxy`: Nginx reverse proxy.

Key features:
- **Networks**: All services use the `app-net` bridge network for communication.
- **Volumes**: `db-data` and `cache-data` ensure persistent storage.
- **Secrets**: MongoDB password is securely passed via `db-password.txt`.
- **Health Checks**: Each service has a health check to monitor status.
- **Logging**: Configured with `json-file` driver and log rotation (`max-size: "10m"`, `max-file: "3"`).

### Backend Code
Example `backend/index.js`:
```javascript
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.get('/', (req, res) => res.send('Hello from API!'));

mongoose.connect('mongodb://db:27017/mydb', { useNewUrlParser: true });
const client = redis.createClient({ host: 'cache' });
client.on('error', err => console.error('Redis error:', err));
client.connect();

app.listen(3000, () => console.log('API running'));
```

### Nginx Configuration
The `nginx/nginx.conf` routes traffic:
- `/` → `web` service (frontend).
- `/api/` → `api` service (backend).

Example:
```nginx
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://web:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        location /api/ {
            proxy_pass http://api:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_connect_timeout 10s;
            proxy_read_timeout 10s;
        }
    }
}
```


## Best Practices Demonstrated

- **Image Optimization**: Multi-stage builds for the frontend reduce image size.
- **Security**: Docker secrets for sensitive data like database passwords.
- **Reliability**: Health checks ensure services are operational.
- **Scalability**: Docker Compose and networks enable easy scaling.
- **Maintainability**: Log rotation prevents disk space issues.

## Conclusion

This is an open source project with the link: https://roadmap.sh/projects/multiservice-docker
