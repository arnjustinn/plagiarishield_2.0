# 🌐 PlagiariShield Multilingual

An AI-powered plagiarism detection system supporting **English** and **Tagalog**, combining:
- LSTM (GloVe embeddings) for structural similarity
- SentenceTransformer (MiniLM) for semantic similarity

---

## 🏗 Folder Structure
plagiarishield_multilingual/
├── api/
├── models/
├── data/
├── training/
├── logs/

---

## ⚙️ Setup
1. **Install dependencies**
   ```bash
   pip install -r api/requirements.txt
   pip install newspaper3k tqdm nltk
   pip install lxml[html_clean] or pip install lxml_html_clean


2. **Run the generator**
    cd training
    python scrape_real_dataset_bulk.py
    python augment_dataset_multilingual.py

2. **Train the model**
    python train_multilingual.py

3. **Run the API**
    cd ..
    ./run_api.sh

**Example Request**
curl -X POST "http://localhost:8000/predict" \
-H "Content-Type: application/json" \
-d "{\"text\": \"Ang pagbabago ng klima ay malaking suliranin sa ating bansa.\"}"

**Response**
{
  "label": "Plagiarized",
  "confidence": 92.5,
  "lstm_prob": 0.88,
  "semantic_similarity": 0.94,
  "closest_label": "Plagiarized",
  "closest_text": "Ang pagbabago ng klima ay isa sa pinakamalaking problema...",
  "combined_score": 0.91
}
