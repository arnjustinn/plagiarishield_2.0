# api_multilingual.py (Updated for Sentence Checking & CORS)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
import os
import numpy as np
from sentence_transformers import SentenceTransformer
from tensorflow.keras.models import load_model
import pickle
import re # Para sa sentence splitting

# Import para sa CORS
from fastapi.middleware.cors import CORSMiddleware

# for cosine computation
from sklearn.metrics.pairwise import cosine_similarity

# --------------------------
# PATHS (Relative to where uvicorn is run - the 'api haha' folder)
# --------------------------
MODEL_PATH = "models/plagiarism_model_v9_multilingual.keras"
TOKENIZER_PATH = "models/tokenizer_v9_multilingual.pkl"
EMBEDDINGS_PATH = "models/saved_reference_embeddings_multilingual.npy"
REFERENCE_TEXTS_PATH = "data/generated_dataset_multilingual.json"

# --------------------------
# LOAD RESOURCES
# --------------------------
print("⚡ Loading LSTM model...")
lstm_model = load_model(MODEL_PATH)

print("⚡ Loading tokenizer...")
with open(TOKENIZER_PATH, "rb") as f:
    tokenizer = pickle.load(f)

print("⚡ Loading reference dataset...")
with open(REFERENCE_TEXTS_PATH, "r", encoding="utf-8") as f:
    reference_texts = [item["text"] for item in json.load(f)]

print("⚡ Loading transformer model & reference embeddings...")
transformer_model = SentenceTransformer("paraphrase-multilingual-mpnet-base-v2")
if os.path.exists(EMBEDDINGS_PATH):
    reference_embeddings = np.load(EMBEDDINGS_PATH)
else:
    print("⚡ Computing reference embeddings (one-time)...")
    reference_embeddings = transformer_model.encode(reference_texts, convert_to_numpy=True, show_progress_bar=True, batch_size=64)
    np.save(EMBEDDINGS_PATH, reference_embeddings)

print(f"✅ Loaded {len(reference_texts)} reference samples.")

# --------------------------
# OPTIONAL: langdetect if available
# --------------------------
try:
    from langdetect import detect
    LANGDETECT_AVAILABLE = True
except Exception:
    LANGDETECT_AVAILABLE = False

# --------------------------
# FASTAPI SETUP
# --------------------------
app = FastAPI(title="PlagiariShield Multilingual API")

# --------------------------
# BAGONG CORS MIDDLEWARE
# Ito ay mahalaga para payagan ang koneksyon mula sa ngrok
# --------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Pinapayagan ang lahat, pwede mo limitahan sa ngrok URL mo
    allow_credentials=True,
    allow_methods=["*"],  # Pinapayagan ang lahat ng methods (POST, GET, etc.)
    allow_headers=["*"],
)

# --------------------------
# PLAGIARISM CHECK FUNCTIONS
# --------------------------
def predict_lstm(text, maxlen=300):
    from tensorflow.keras.preprocessing.sequence import pad_sequences
    seq = tokenizer.texts_to_sequences([text])
    seq_padded = pad_sequences(seq, maxlen=maxlen, padding='post', truncating='post')
    prob = lstm_model.predict(seq_padded, verbose=0)[0][0]
    return float(prob)

def predict_semantic(text):
    # encode with transformer -> numpy vector
    emb = transformer_model.encode(text, convert_to_numpy=True)
    # use sklearn cosine_similarity (robust with numpy)
    scores = cosine_similarity(emb.reshape(1, -1), reference_embeddings).flatten()
    idx = int(np.argmax(scores))
    raw_score = float(scores[idx])
    # cosine_similarity with sklearn on non-normalized vectors returns in [-1,1], so rescale to [0,1]
    semantic_score = (raw_score + 1.0) / 2.0
    return semantic_score, reference_texts[idx]

def detect_language(text):
    if not text or len(text.strip()) < 10:
        return "en" # Default sa English kung maikli
        
    # Prefer langdetect if available
    if LANGDETECT_AVAILABLE:
        try:
            lang = detect(text)
            if lang in ("tl","fil"):
                return "tl"
            elif lang.startswith("en"):
                return "en"
            else:
                return "tl"  # treat other langs as 'tl' for thresholding (tunable)
        except Exception:
            pass
    # Fallback heuristic
    chars = [c for c in text if c.isalnum()]
    if len(chars) < 10:
        return "en"
    non_ascii = sum(1 for c in chars if ord(c) > 128)
    non_ascii_ratio = non_ascii / len(chars)
    return "tl" if non_ascii_ratio > 0.2 else "en"

def check_plagiarism_single(input_text):
    # Gumawa ng function para sa iisang text block (isang sentence)
    if not input_text or len(input_text.strip()) < 10:
        return {
            "label": "Original",
            "confidence": 0.0,
            "lstm_prob": 0.0,
            "semantic_similarity": 0.0,
            "closest_text": "",
            "combined_score": 0.0,
            "text": input_text # Idinagdag ang original text
        }

    lstm_prob = predict_lstm(input_text)
    semantic_score, closest_text = predict_semantic(input_text)

    # Weighted combination (tunable)
    weight_lstm = 0.4
    weight_semantic = 0.6
    combined_score = weight_lstm * lstm_prob + weight_semantic * semantic_score

    lang = detect_language(input_text)
    lang_closest = detect_language(closest_text)

    # Language mismatch penalty
    if lang != lang_closest:
        semantic_score *= 0.85  # 15% penalty
        combined_score = weight_lstm * lstm_prob + weight_semantic * semantic_score
        
    # conservative starting thresholds - tune with validation set
    threshold = 0.78 if lang == "tl" else 0.72

    # graded labels
    if combined_score >= threshold:
        if lstm_prob < 0.55 or semantic_score < 0.60:
            label = "Suspicious"
        else:
            label = "Plagiarized"
    elif combined_score >= (threshold - 0.10):
        label = "Suspicious"
    else:
        label = "Original"

    return {
        "label": label,
        "confidence": round(combined_score * 100, 2),
        "lstm_prob": round(lstm_prob, 3),
        "semantic_similarity": round(semantic_score, 3),
        "closest_text": closest_text,
        "combined_score": round(combined_score, 3),
        "text": input_text # Idinagdag ang original text
    }

def split_into_sentences(text):
    # Simpleng regex para mag-split sa punctuation habang kinukuha rin ang punctuation
    sentences = re.split(r'([.!?])\s*', text)
    if not sentences:
        return []
        
    # Pagsamahin muli ang sentence at ang kanyang punctuation
    result = []
    i = 0
    while i < len(sentences) - 1:
        if sentences[i].strip():
            result.append(sentences[i].strip() + sentences[i+1])
        i += 2
    
    # Kunin ang huling piraso kung may natira (na walang punctuation)
    if i < len(sentences) and sentences[i].strip():
        result.append(sentences[i].strip())
        
    return result

# --------------------------
# API Pydantic Models
# --------------------------
class PlagRequest(BaseModel):
    text: str

# --------------------------
# API Endpoints
# --------------------------

@app.post("/") # In-update ang endpoint para maging / (root)
def plagiarism_check_root(request: PlagRequest):
    return {"message": "PlagiariShield API is running. Use /check for plagiarism."}

@app.post("/check")
def plagiarism_check_list(request: PlagRequest):
    try:
        full_text = request.text
        sentences = split_into_sentences(full_text)
        
        if not sentences:
             return [] # Return ng empty list kung walang ma-process

        results = []
        for sentence in sentences:
            if sentence.strip(): # Siguraduhin na hindi blanko
                sentence_result = check_plagiarism_single(sentence)
                results.append(sentence_result)
        
        return results # Ibabalik na ngayon ay isang LIST ng results
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def root():
    return {"message": "PlagiariShield Multilingual API is running."}

