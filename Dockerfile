#Use the official NGINX image as base
FROM nginx:latest

#Take the HTML file to display the message we want
COPY index.html /usr/share/nginx/html/

#Define the main process to keep the container running
CMD ["nginx", "-g", "daemon off;"]