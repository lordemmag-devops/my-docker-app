
FROM nginx:1.25-alpine

# Copy the nginx configuration template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Nginx will automatically substitute environment variables when using the templates directory

# Expose port 80
EXPOSE 80
