# Use Python 3.9 as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install git to clone the repositories
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone the Wav2Lip-HD repository
RUN git clone https://github.com/saifhassan/Wav2Lip-HD.git

# Change to the Wav2Lip-HD directory
WORKDIR /app/Wav2Lip-HD

# Clone the Real-ESRGAN repository inside Wav2Lip-HD
RUN git clone https://github.com/xinntao/Real-ESRGAN.git

# Install the required packages for Wav2Lip-HD
RUN pip install --no-cache-dir -r requirements.txt

# Change to the Real-ESRGAN directory and install requirements
WORKDIR /app/Wav2Lip-HD/Real-ESRGAN
RUN pip install --no-cache-dir -r requirements.txt

# Optionally, expose a port if your application runs a server
# EXPOSE 5000

# Command to run your application (if applicable)
# CMD ["python", "your_script.py"]
