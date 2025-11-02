#!/bin/bash
echo "🚀 Starting PlagiariShield Multilingual API..."
uvicorn api.api_multilingual:app --host 0.0.0.0 --port 8000 --reload
