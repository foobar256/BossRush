import os
import time
import requests
import argparse
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

BFL_API_KEY = os.getenv("BLACK_FOREST_LABS_KEY")
BASE_URL = "https://api.bfl.ai/v1"

def generate_image(prompt, width=1024, height=1024, model="flux-2-pro"):
    """
    Starts an image generation task.
    """
    if not BFL_API_KEY:
        print("Error: BLACK_FOREST_LABS_KEY not found in .env file.")
        return None

    url = f"{BASE_URL}/{model}"
    headers = {
        "accept": "application/json",
        "x-key": BFL_API_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "prompt": prompt,
        "width": width,
        "height": height,
    }

    print(f"Requesting image generation for: '{prompt}'...")
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code != 200:
        print(f"Error starting task: {response.status_code}")
        print(response.text)
        return None
    
    task_data = response.json()
    print(f"Task started: {task_data}")
    return task_data

def poll_for_result(task_data):
    """
    Polls the API until the task is complete.
    """
    task_id = task_data.get("id")
    # Prefer polling_url if provided by the API
    url = task_data.get("polling_url")
    
    if not url:
        url = f"{BASE_URL}/get_result"
        params = {"id": task_id}
    else:
        params = {} # ID is usually already in the polling_url

    headers = {
        "accept": "application/json",
        "x-key": BFL_API_KEY
    }

    print(f"Waiting for task {task_id} to complete...")
    
    # Small initial wait
    time.sleep(1)
    
    while True:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code != 200:
            print(f"Error polling task: {response.status_code}")
            print(response.text)
            # Some APIs might take a moment to register the task in the polling system
            if response.status_code == 404:
                 print("Retrying in 2 seconds (404 Task not found)...")
                 time.sleep(2)
                 continue
            return None
        
        result = response.json()
        status = result.get("status")
        
        if status == "Ready":
            print("Image is ready!")
            return result
        elif status == "Failed":
            print("Task failed.")
            print(result)
            return None
        else:
            # status could be 'Pending', 'Processing', or 'Task not found' (as seen in output)
            if status == "Task not found":
                print("Task not found in polling yet, retrying...")
            else:
                print(f"Status: {status}...")
            time.sleep(2)

def run_once(args, current_count=None):
    task_data = generate_image(args.prompt, args.width, args.height, args.model)
    if not task_data:
        return False

    result = poll_for_result(task_data)
    if result and "result" in result:
        image_url = result["result"].get("sample")
        if image_url:
            output_file = args.output
            if current_count is not None:
                name, ext = os.path.splitext(args.output)
                output_file = f"{name}_{current_count}{ext}"
            
            print(f"Downloading image from {image_url}...")
            img_data = requests.get(image_url).content
            with open(output_file, 'wb') as f:
                f.write(img_data)
            print(f"Image saved to {output_file}")
            return True
        else:
            print("No image URL found in result.")
    else:
        print("Failed to get result.")
    return False

def main():
    parser = argparse.ArgumentParser(description="Generate images using Black Forest Labs API")
    parser.add_argument("prompt", type=str, help="The prompt for image generation")
    parser.add_argument("--width", type=int, default=1024, help="Width of the image (default: 1024)")
    parser.add_argument("--height", type=int, default=1024, help="Height of the image (default: 1024)")
    parser.add_argument("--model", type=str, default="flux-2-pro", help="Model to use (default: flux-2-pro)")
    parser.add_argument("--output", type=str, default="output.jpg", help="Output filename base (default: output.jpg)")
    parser.add_argument("--count", type=int, default=1, help="Number of images to generate (default: 1)")

    args = parser.parse_args()

    if args.count > 1:
        for i in range(1, args.count + 1):
            print(f"\n--- Generating image {i} of {args.count} ---")
            run_once(args, i)
    else:
        run_once(args)

if __name__ == "__main__":
    main()
