# Stage 1: Build the application
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install --ignore-scripts

# Copy all project files
COPY . .

# Build the application in standalone mode
RUN npm run build && npm prune --production

# Stage 2: Serve the application
FROM node:18-alpine AS runner

# install pm2
#RUN export NODE_OPTIONS=--openssl-legacy-provider
#RUN npm i -g pm2@latest

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

RUN npm install --ignore-scripts

# Expose the port
EXPOSE 3000

# Start the Next.js application
# CMD ["pm2", "start", "npm", "--name", "nextjs","--","start","--port","3000","--no-daemon"]
CMD ["npm","start"]
