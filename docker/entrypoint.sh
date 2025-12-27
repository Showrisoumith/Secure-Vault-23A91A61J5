#!/bin/sh

# This script runs inside the container
echo "Waiting for local blockchain node to start..."

# Give the blockchain service time to initialize
# In a real-world scenario, you might use a 'wait-for-it' script
sleep 5

echo "Starting deployment to local network..."

# Run the deployment script targeting the local network
npm run deploy:local