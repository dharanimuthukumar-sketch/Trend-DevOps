FROM node:18-alpine

WORKDIR /app

# Copy the static production build assets directly into the container workspace
COPY dist/ ./dist

# Install a lightweight static file serving server globally
RUN npm install -g serve

# Expose the mandatory project port
EXPOSE 3000

# Bind execution parameters specifically to target port 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
