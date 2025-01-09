import runpod

def handler(event):
    input_data = event.get('input', {})
    instruction = input_data.get('instruction', '')
    
    # Simulate processing (replace with your model inference logic)
    result = f"Processed instruction: {instruction}"
    
    return {"result": result}

if __name__ == '__main__':
    runpod.serverless.start({'handler': handler})
