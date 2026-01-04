import os
import time
import requests
import json
from flask import Flask, render_template_string, request, jsonify, Response, stream_with_context
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

BFL_API_KEY = os.getenv("BLACK_FOREST_LABS_KEY")
BASE_URL = "https://api.bfl.ai/v1"

app = Flask(__name__)

# Directory to save generated images
OUTPUT_DIR = "static/generated"
os.makedirs(OUTPUT_DIR, exist_ok=True)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FLUX Image Generator</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; padding-top: 50px; }
        .container { max-width: 800px; }
        .card { margin-bottom: 20px; }
        #results { display: flex; flex-wrap: wrap; gap: 20px; margin-top: 20px; }
        .image-card { width: 300px; }
        .image-card img { width: 100%; height: auto; border-radius: 8px; }
        .progress-log { font-family: monospace; background: #212529; color: #0dfd05; padding: 10px; border-radius: 5px; height: 150px; overflow-y: auto; font-size: 0.8rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="mb-4">FLUX Image Generator</h1>
        
        <div class="card p-4">
            <form id="gen-form">
                <div class="mb-3">
                    <label class="form-label">Prompt</label>
                    <textarea class="form-control" id="prompt" rows="3" required>A simple geometric cube, 3D render, minimalist</textarea>
                </div>
                <div class="row">
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Width</label>
                        <input type="number" class="form-control" id="width" value="1024" step="16">
                    </div>
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Height</label>
                        <input type="number" class="form-control" id="height" value="1024" step="16">
                    </div>
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Count</label>
                        <input type="number" class="form-control" id="count" value="1" min="1" max="10">
                    </div>
                    <div class="col-md-3 mb-3">
                        <label class="form-label">Model</label>
                        <select class="form-select" id="model">
                            <option value="flux-2-pro">Pro</option>
                            <option value="flux-2-max">Max</option>
                            <option value="flux-2-flex">Flex</option>
                        </select>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary" id="submit-btn">Generate</button>
            </form>
        </div>

        <div id="active-tasks"></div>
        <div id="results"></div>
    </div>

    <script>
        const form = document.getElementById('gen-form');
        const resultsDiv = document.getElementById('results');
        const activeTasksDiv = document.getElementById('active-tasks');

        form.onsubmit = async (e) => {
            e.preventDefault();
            const prompt = document.getElementById('prompt').value;
            const width = document.getElementById('width').value;
            const height = document.getElementById('height').value;
            const count = document.getElementById('count').value;
            const model = document.getElementById('model').value;

            for (let i = 0; i < count; i++) {
                startTask(prompt, width, height, model, i + 1, count);
            }
        };

        async function startTask(prompt, width, height, model, index, total) {
            const taskIdDisplay = `task-${Date.now()}-${index}`;
            const taskCard = document.createElement('div');
            taskCard.className = 'card p-3 mb-3';
            taskCard.id = taskIdDisplay;
            taskCard.innerHTML = `
                <h6>Generating Image ${index}/${total}...</h6>
                <div class="progress-log" id="log-${taskIdDisplay}">Starting task...</div>
            `;
            activeTasksDiv.prepend(taskCard);
            const logDiv = document.getElementById(`log-${taskIdDisplay}`);

            try {
                const response = await fetch('/generate', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({prompt, width, height, model})
                });
                
                const data = await response.json();
                if (!data.id) {
                    logDiv.innerHTML += `\nError: ${data.error || 'Failed to start task'}`;
                    return;
                }

                const eventSource = new EventSource(`/progress/${data.id}?polling_url=${encodeURIComponent(data.polling_url)}`);
                
                eventSource.onmessage = (event) => {
                    const statusData = JSON.parse(event.data);
                    logDiv.innerHTML += `\nStatus: ${statusData.status}...`;
                    logDiv.scrollTop = logDiv.scrollHeight;

                    if (statusData.status === 'Ready') {
                        eventSource.close();
                        logDiv.innerHTML += `\nSUCCESS! Image Ready.`;
                        displayImage(statusData.sample, prompt);
                        taskCard.remove();
                    } else if (statusData.status === 'Failed') {
                        eventSource.close();
                        logDiv.innerHTML += `\nFAILED!`;
                    }
                };

                eventSource.onerror = (err) => {
                    logDiv.innerHTML += `\nError in SSE stream.`;
                    eventSource.close();
                };

            } catch (err) {
                logDiv.innerHTML += `\nNetwork Error: ${err.message}`;
            }
        }

        function displayImage(url, prompt) {
            const card = document.createElement('div');
            card.className = 'image-card card p-2';
            card.innerHTML = `
                <img src="${url}" target="_blank">
                <p class="small mt-2">${prompt.substring(0, 50)}...</p>
                <a href="${url}" target="_blank" class="btn btn-sm btn-outline-secondary">Open Original</a>
            `;
            resultsDiv.prepend(card);
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/generate', methods=['POST'])
def generate():
    data = request.json
    prompt = data.get('prompt')
    width = int(data.get('width', 1024))
    height = int(data.get('height', 1024))
    model = data.get('model', 'flux-2-pro')

    if not BFL_API_KEY:
        return jsonify({"error": "API Key missing"}), 500

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

    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code != 200:
            return jsonify({"error": response.text}), response.status_code
        return jsonify(response.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/progress/<task_id>')
def progress(task_id):
    polling_url = request.args.get('polling_url')
    
    def generate_events():
        headers = {
            "accept": "application/json",
            "x-key": BFL_API_KEY
        }
        
        while True:
            try:
                response = requests.get(polling_url, headers=headers)
                if response.status_code != 200:
                    yield f"data: {json.dumps({'status': 'Error', 'message': response.text})}\n\n"
                    break
                
                result = response.json()
                status = result.get("status")
                
                # Send update to client
                if status == "Ready":
                    # Include the sample URL in the SSE message
                    yield f"data: {json.dumps({'status': 'Ready', 'sample': result.get('result', {}).get('sample')})}\n\n"
                    break
                elif status == "Failed":
                    yield f"data: {json.dumps({'status': 'Failed'})}\n\n"
                    break
                else:
                    yield f"data: {json.dumps({'status': status})}\n\n"
                
                time.sleep(2)
            except Exception as e:
                yield f"data: {json.dumps({'status': 'Error', 'message': str(e)})}\n\n"
                break

    return Response(stream_with_context(generate_events()), mimetype='text/event-stream')

if __name__ == '__main__':
    print("Starting Flask server on http://127.0.0.1:5000")
    app.run(debug=True, port=5000)
