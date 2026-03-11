# Tahap 1: Build tahap (Compile Vue.js menjadi HTML/JS/CSS static)
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json dan package-lock.json (jika ada)
COPY package*.json ./

# Install dependencies (gunakan ci jika ada packgelock)
RUN npm install

# Copy seluruh source code
COPY . .

# Build app (menghasilkan folder /app/dist)
RUN npm run build

# Tahap 2: Server tahap (Gunakan Nginx ringan untuk serve file static)
FROM nginx:alpine

# Copy hasil build dari tahap 1 ke folder public Nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Pamerkan port 80
EXPOSE 80

# Jalankan Nginx
CMD ["nginx", "-g", "daemon off;"]
