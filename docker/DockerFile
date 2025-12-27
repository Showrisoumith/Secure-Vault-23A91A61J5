# Step 4: Define the environment
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy dependency files first to leverage Docker's cache
COPY package.json package-lock.json ./

# Install project dependencies
RUN npm install

# Copy the rest of the project files
COPY . .

# Compile smart contracts (ensuring they are ready before deployment)
RUN npx hardhat compile

# Set permissions for the entrypoint script
RUN chmod +x ./docker/entrypoint.sh

# Execute deployment logic at container startup
CMD ["sh", "./docker/entrypoint.sh"]