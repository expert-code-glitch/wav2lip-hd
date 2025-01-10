from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import subprocess
import requests
import os
import uuid
import logging
from concurrent.futures import ThreadPoolExecutor
from fastapi.staticfiles import StaticFiles

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

app = FastAPI()
VIDEO_OUTPUT_DIR = './output_videos_wav2lip/'
os.makedirs(VIDEO_OUTPUT_DIR, exist_ok=True)
app.mount("/output_videos_wav2lip", StaticFiles(directory=VIDEO_OUTPUT_DIR), name="output_videos_wav2lip")
executor = ThreadPoolExecutor(max_workers=3)

task_status = {}

class VideoRequest(BaseModel):
    avatar_id: str
    voice_id: str

def run_command(command):
    """Run a shell command and print its output in real-time."""
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    for line in process.stdout:
        print(line, end='')

    for line in process.stderr:
        print(line, end='')

    process.stdout.close()
    process.stderr.close()
    return_code = process.wait()

    if return_code != 0:
        raise Exception(f"Command failed with return code {return_code}")

def download_file(file_id, save_path):
    """Download a file from the test file server."""
    url = f"http://188.40.57.209:8083/file/get?id={file_id}"
    logging.info(f"Downloading file from {url} to {save_path}")
    response = requests.get(url)
    if response.status_code == 200:
        with open(save_path, 'wb') as f:
            f.write(response.content)
        logging.info(f"File downloaded successfully: {save_path}")
    else:
        logging.error(f"Failed to download file: {response.status_code}")
        raise Exception(f"Failed to download file: {response.status_code}")

def process_video_task(task_id, avatar_id, voice_id):
    input_video = f"input_videos/{task_id}.mp4"
    input_audio = f"input_audios/{task_id}.mp3"
    output_videos_wav2lip = "output_videos_wav2lip"

    task_status[task_id] = "Downloading files"
    logging.info(f"Task {task_id}: Downloading files")

    try:
        download_file(avatar_id, input_video)
        download_file(voice_id, input_audio)
    except Exception as e:
        task_status[task_id] = f"Error: {str(e)}"
        logging.error(f"Task {task_id}: {str(e)}")
        return

    task_status[task_id] = "Processing video"
    logging.info(f"Task {task_id}: Processing video")

    # Create a unique temporary audio file path using task_id
    temp_audio_path = f'temp/temp_{task_id}.wav'

    if not input_audio.endswith('.wav'):
        logging.info('Extracting raw audio...')
        command = f'ffmpeg -y -i {input_audio} -strict -2 {temp_audio_path}'
        subprocess.call(command, shell=True)
        input_audio = temp_audio_path  # Update the audio path to the unique temp file

    command = (
        f"python3 inference.py --checkpoint_path 'checkpoints/wav2lip_gan.pth' "
        f"--segmentation_path 'checkpoints/face_segmentation.pth' "
        f"--sr_path 'checkpoints/esrgan_max.pth' "
        f"--face {input_video} --audio {input_audio} "
        f"--save_frames --gt_path 'data/gt' --pred_path 'data/lq' "
        f"--no_sr --no_segmentation --outfile {output_videos_wav2lip}/{task_id}.mp4 "
        f"--task_id {task_id}"  # Pass the task_id as an argument
    )
    
    run_command(command)
    task_status[task_id] = "Completed"

@app.post("/video/generate")
async def generate_video(request: VideoRequest):
    avatar_id = request.avatar_id
    voice_id = request.voice_id
    task_id = str(uuid.uuid4())
    task_status[task_id] = "Started"
    logging.info(f"Task {task_id}: Started")
    executor.submit(process_video_task, task_id, avatar_id, voice_id)
    return {"message": "Started", "task_id": task_id}

@app.get("/video/status/{task_id}")
async def get_status(task_id: str):
    status = task_status.get(task_id)
    if status is None:
        raise HTTPException(status_code=404, detail="Task ID not found")
    return {"task_id": task_id, "status": status}

@app.get("/download/{task_id}")
async def download(task_id: str):
    file_path = os.path.join(VIDEO_OUTPUT_DIR, f"{task_id}.mp4")
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type='application/octet-stream', filename=f"{task_id}.mp4")
    else:
        raise HTTPException(status_code=404, detail="File not found")

@app.delete("/video/delete/{task_id}")
async def delete_video(task_id: str):
    file_path = os.path.join(VIDEO_OUTPUT_DIR, f"{task_id}.mp4")
    if os.path.exists(file_path):
        os.remove(file_path)
        logging.info(f"Task {task_id}: File deleted successfully")
        return {"message": "File deleted successfully", "task_id": task_id}
    else:
        raise HTTPException(status_code=404, detail="File not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)