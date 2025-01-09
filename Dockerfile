# Use Python 3.9 as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install git to clone the repositories
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN pip install gdown
# Clone the Wav2Lip-HD repository
RUN git clone https://github.com/expert-code-glitch/Wav2Lip-HD1.git

# Change to the Wav2Lip-HD directory
WORKDIR /app/Wav2Lip-HD1

# Clone the Real-ESRGAN repository inside Wav2Lip-HD
RUN git clone https://github.com/xinntao/Real-ESRGAN.git

# Install the required packages for Wav2Lip-HD
RUN pip install --no-cache-dir -r requirements.txt

# Change to the Real-ESRGAN directory and install requirements
WORKDIR /app/Wav2Lip-HD1/Real-ESRGAN
RUN pip install --no-cache-dir -r requirements.txt

# Optionally, expose a port if your application runs a server
# EXPOSE 5000

# Command to run your application (if applicable)
# CMD ["python", "your_script.py"]

WORKDIR /app/Wav2Lip-HD1
RUN echo 'import gdown\n\
urls = {\n\
    "wav2lip_gan.pth": "10Iu05Modfti3pDbxCFPnofmfVlbkvrCm", \n\
    "face_segmentation.pth": "154JgKpzCPW82qINcVieuPH3fZ2e0P812",\n\
    "esrgan_max.pth": "1e5LT83YckB5wFKXWV4cWOPkVRnCDmvwQ"\n\
}\n\
for name, id in urls.items():\n\
    url = f"https://drive.google.com/uc?id={id}"\n\
    output = f"checkpoints/{name}"\n\
    gdown.download(url, output, quiet=False)\n\
    print(f"Loaded {name}")' > download_checkpoints.py

# Run the script to download the checkpoints
RUN python download_checkpoints.py
