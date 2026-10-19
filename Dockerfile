FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY deps_modules ./node_modules
COPY server.js ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
