#!/bin/sh
set -e  # Exit on any error

echo "Starting deployment..."
# Step 1: Build new image with a temporary tag
echo "Building new image..."
docker build --no-cache -t pypi-server:new .

# Step 2: Stop and remove old container if it exists
OLD_CONTAINER=$(docker ps -q -f name=pypi-server)
if [ ! -z "$OLD_CONTAINER" ]; then
    echo "Stopping and removing old container..."
    docker stop pypi-server || true
    docker rm pypi-server || true
fi

# Step 3: Start new container
echo "Starting new container..."
docker run -d \
  --restart unless-stopped \
  -p 8010:8010 \
  --name pypi-server \
  -v ~/pypi_packages:/pypi_packages \
  pypi-server:new

# Step 4: Verify new container is running
if [ ! "$(docker ps -q -f name=pypi-server)" ]; then
    exit 1
fi

# Step 5: Clean up everything
echo "Deployment successful. Cleaning up..."
docker tag pypi-server:new pypi-server:latest
docker rmi pypi-server:new
docker system prune -f