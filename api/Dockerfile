# using official Node.js image
FROM node:22-alpine
#alpine is a lightweight version of the image

# set working directory
WORKDIR /app

#copy package files fist
COPY package*.json ./

# install dependencies
RUN npm install

# copy all files
COPY . .

#expose api port
EXPOSE 5000

# START THE SERVER
CMD ["npm","start"]