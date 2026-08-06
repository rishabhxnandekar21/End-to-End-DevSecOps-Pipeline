# BUILDING REACT APP

FROM node:22-alpine AS react-builder

# set working directory
WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

#SERVE WITH NGINX

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=react-builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
