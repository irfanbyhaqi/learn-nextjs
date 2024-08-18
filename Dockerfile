# Gunakan Node.js sebagai base image
FROM node:18-alpine AS builder

# Set environment variables
ENV NODE_ENV=production

# Tentukan working directory
WORKDIR /app

# Copy file package.json dan package-lock.json ke working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy seluruh project files ke dalam container
COPY . .

# Build aplikasi Next.js dalam mode standalone
RUN npm run build

# Gunakan stage baru untuk menjalankan aplikasi
FROM node:18-alpine AS runner

WORKDIR /app

# Copy file yang dibutuhkan dari stage sebelumnya
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Expose port yang akan digunakan oleh aplikasi
EXPOSE 3000

# Jalankan aplikasi
CMD ["node", "server.js"]
