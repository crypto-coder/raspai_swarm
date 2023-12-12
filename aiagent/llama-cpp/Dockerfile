# Define the image argument and provide a default value
ARG IMAGE=python:3-slim-bullseye

# Use the image as specified
FROM ${IMAGE}

# Re-declare the ARG after FROM
ARG IMAGE

# Prepare the filesystem
RUN mkdir /app
WORKDIR /app

# Update and upgrade the existing packages 
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    ninja-build \
    build-essential

# Clone the llama-cpp-python repo, including submodules
RUN git clone --recurse-submodules https://github.com/abetlen/llama-cpp-python.git /app

# Build llama-cpp-python and its dependencies
RUN python3 -m pip install --upgrade pip
RUN make deps && make build

# Make sure the AI model can be locked in memory
RUN echo "Checking ulimit during build"
RUN sed -i "`wc -l < /etc/security/limits.conf`i\\root hard memlock 7400032\\" /etc/security/limits.conf
RUN sed -i "`wc -l < /etc/security/limits.conf`i\\root soft memlock 7400032\\" /etc/security/limits.conf

# Set environment variable for the host
VOLUME /app/models
ENV MODELS_PATH=/app/models
ENV MODEL=/app/models/openchat_3.5/openchat_3.5.Q4_K_M.gguf
ENV HOST=0.0.0.0
ENV PORT=8080
ENV n_ctx=2048
ENV n_batch=512
ENV n_threads=3

# Expose a port for the server
EXPOSE 8080

# Copy the startup script
COPY ./start-reload_llama-api.sh /app

# Run the server start script
CMD ["/bin/sh", "/app/start-reload_llama-api.sh"]