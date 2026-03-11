# Tahap 1: Build tahap (Compile Vue.js menjadi HTML/JS/CSS static)
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json dan package-lock.json (jika ada)
COPY package*.json ./

# Install dependencies (gunakan ci jika ada packgelock)
RUN npm install

# Copy seluruh source code
COPY . .

# Set environment variables for build
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY

ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY

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
