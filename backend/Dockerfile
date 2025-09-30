# Stage 1: Build dependencies
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Create final production image
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
COPY . .

EXPOSE 3000
CMD ["node", "index.js"]
