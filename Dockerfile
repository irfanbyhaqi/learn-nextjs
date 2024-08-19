# Stage 1: Build the application
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy all project files
COPY . .

# Build the application in standalone mode
RUN npm run build && npm prune --production

# Stage 2: Serve the application
FROM node:18-alpine AS runner

# Set environment variables
ENV NODE_ENV=production

# Set working directory
WORKDIR /app

# Copy the built application from the builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/next.config.mjs ./next.config.mjs

# Expose the port
EXPOSE 3000

# Start the Next.js application
CMD ["npm", "start"]
