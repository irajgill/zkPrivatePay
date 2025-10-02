# dev Dockerfile (multi-stage omitted for brevity)
FROM node:20-alpine
WORKDIR /app
COPY package.json pnpm-lock.yaml* yarn.lock* package-lock.json* ./
RUN npm i -g pnpm && pnpm i --frozen-lockfile || pnpm i
COPY tsconfig.json ./
COPY src ./src
CMD ["pnpm", "dev"]
