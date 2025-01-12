# Use Python 3.9 as the base image
FROM python:3.8-slim

# Set the working directory
WORKDIR /app

# Install git to clone the repositories
RUN apt-get update && \
    apt-get install -y git ffmpeg && \
    rm -rf /var/lib/apt/lists/*
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
RUN pip install google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2
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

RUN echo 'import gdown\n\
urls = {\n\
    "net_g_67500.pth": "1Al8lEpnx2K-kDX7zL2DBcAuDnSKXACPb", \n\
}\n\
for name, id in urls.items():\n\
    url = f"https://drive.google.com/uc?id={id}"\n\
    output = f"experiments/001_ESRGAN_x4_f64b23_custom16k_500k_B16G1_wandb/models/{name}"\n\
    gdown.download(url, output, quiet=False)\n\
    print(f"Loaded {name}")' > download_net_g_67500.py

RUN echo 'import gdown\n\
urls = {\n\
    "s3fd.pth": "1uNLYCPFFmO-og3WSHyFytJQLLYOwH5uY", \n\
}\n\
for name, id in urls.items():\n\
    url = f"https://drive.google.com/uc?id={id}"\n\
    output = f"face_detection/detection/sfd/{name}"\n\
    gdown.download(url, output, quiet=False)\n\
    print(f"Loaded {name}")' > download_s3fd.py

RUN echo 'import gdown\n\
urls = {\n\
    "detection_Resnet50_Final.pth": "1gFTEVUql7YSXE_Uwf4EMONdAeL9N1kV2", \n\
    "parsing_parsenet.pth": "19aRK_JLna8a0KeUwV7LubHN3XGLyIpdX",\n\
}\n\
for name, id in urls.items():\n\
    url = f"https://drive.google.com/uc?id={id}"\n\
    output = f"Real-ESRGAN/gfpgan/weights/{name}"\n\
    gdown.download(url, output, quiet=False)\n\
    print(f"Loaded {name}")' > download_gfpgan.py
   
RUN echo 'import gdown\n\
urls = {\n\
    "RealESRGAN_x4plus.pth": "1qNIf8cJl_dQo3ivelPJVWFkApyEAGnLi", \n\
}\n\
for name, id in urls.items():\n\
    url = f"https://drive.google.com/uc?id={id}"\n\
    output = f"Real-ESRGAN/weights/{name}"\n\
    gdown.download(url, output, quiet=False)\n\
    print(f"Loaded {name}")' > download_RealESRGAN_x4plus.py

RUN mkdir -p Real-ESRGAN/gfpgan/weights
# Run the script to download the checkpoints
RUN python download_checkpoints.py
RUN python download_net_g_67500.py
RUN python download_s3fd.py
RUN python download_gfpgan.py
RUN python download_RealESRGAN_x4plus.py

# Install FastAPI and Uvicorn
RUN pip install fastapi uvicorn pydantic requests runpod

# Copy the FastAPI application code
COPY main.py .

# Start the container
CMD ["python3", "-u", "main.py"]
