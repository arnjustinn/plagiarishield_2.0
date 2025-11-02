# train_multilingual.py (patched)
import os
import json
import random
import numpy as np
from tqdm import tqdm
from sentence_transformers import SentenceTransformer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, LSTM, Dense, Dropout
from tensorflow.keras.optimizers import Adam
from sklearn.model_selection import train_test_split
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
from sklearn.metrics import classification_report
import pickle

# --------------------------
# CONFIG
# --------------------------
DATA_JSON_PATH = "../data/generated_dataset_multilingual.json"
TOKENIZER_PATH = "../models/tokenizer_v9_multilingual.pkl"
MODEL_PATH = "../models/plagiarism_model_v9_multilingual.keras"
EMBEDDINGS_PATH = "../models/saved_reference_embeddings_multilingual.npy"

TARGET_SAMPLES_PER_CLASS = 1000  # per language per label (used in generator)
MAX_LEN = 300
EMBEDDING_DIM = 100  # for embedding layer
VOCAB_SIZE = 20000
NUM_AUG = 3
RANDOM_SEED = 42

random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# --------------------------
# LOAD DATA
# --------------------------
with open(DATA_JSON_PATH, "r", encoding="utf-8") as f:
    raw_dataset = json.load(f)

# Separate by language (simple heuristic)
english_texts = [item["text"] for item in raw_dataset if all(ord(c) < 128 or c.isspace() for c in item["text"])]
tagalog_texts = [item["text"] for item in raw_dataset if any(ord(c) > 128 for c in item["text"])]

print(f"English: {len(english_texts)} | Tagalog: {len(tagalog_texts)}")

# --------------------------
# AUGMENTATION (simple)
# --------------------------
def shuffle_sentences(text):
    sentences = text.split(". ")
    random.shuffle(sentences)
    return ". ".join(sentences)

def minor_edits(text):
    new_text = text.replace(",", "")
    words = new_text.split()
    for i in range(len(words)):
        if random.random() < 0.05:
            words[i] = words[i].lower()
        if random.random() < 0.02:
            words[i] = words[i] + " "
    return " ".join(words)

def augment_text(text, num_aug=NUM_AUG):
    augmented = []
    for _ in range(num_aug):
        new_text = text
        if random.random() < 0.7:
            new_text = shuffle_sentences(new_text)
        if random.random() < 0.7:
            new_text = minor_edits(new_text)
        augmented.append(new_text)
    return augmented

def generate_class(texts, label, target_samples=TARGET_SAMPLES_PER_CLASS):
    samples = []
    if not texts:
        return samples
    while len(samples) < target_samples:
        text = random.choice(texts)
        samples.append({"text": text, "label": label})
        for aug in augment_text(text):
            samples.append({"text": aug, "label": label})
        if len(samples) > target_samples:
            samples = samples[:target_samples]
    return samples

# --------------------------
# BUILD DATASET
# --------------------------
dataset = []

print("🔹 Generating English samples...")
dataset += generate_class(english_texts, 0)  # original
dataset += generate_class(english_texts, 1)  # plagiarized

print("🔹 Generating Tagalog samples...")
dataset += generate_class(tagalog_texts, 0)  # original
dataset += generate_class(tagalog_texts, 1)  # plagiarized

random.shuffle(dataset)
print(f"Total dataset: {len(dataset)} samples")

# Simple safety: ensure we have some samples
if len(dataset) < 10:
    raise ValueError("Dataset is too small. Check DATA_JSON_PATH or scraping output.")

# --------------------------
# TOKENIZATION
# --------------------------
from tensorflow.keras.preprocessing.text import Tokenizer

tokenizer = Tokenizer(num_words=VOCAB_SIZE, oov_token="<OOV>")
tokenizer.fit_on_texts([item["text"] for item in dataset])

os.makedirs(os.path.dirname(TOKENIZER_PATH), exist_ok=True)
with open(TOKENIZER_PATH, "wb") as f:
    pickle.dump(tokenizer, f)
print(f"✅ Tokenizer saved to {TOKENIZER_PATH}")

sequences = tokenizer.texts_to_sequences([item["text"] for item in dataset])
X = pad_sequences(sequences, maxlen=MAX_LEN, padding="post", truncating="post")
y = np.array([item["label"] for item in dataset])

# --------------------------
# TRAIN / VALID SPLIT
# --------------------------
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.12, random_state=RANDOM_SEED, stratify=y)
print(f"Train samples: {len(X_train)} | Val samples: {len(X_val)}")

# --------------------------
# BUILD LSTM MODEL
# --------------------------
model = Sequential()
model.add(Embedding(VOCAB_SIZE, EMBEDDING_DIM, input_length=MAX_LEN))
model.add(LSTM(128, return_sequences=False))
model.add(Dropout(0.2))
model.add(Dense(1, activation="sigmoid"))

model.compile(optimizer=Adam(1e-3), loss="binary_crossentropy", metrics=["accuracy"])
print(model.summary())

# --------------------------
# TRAIN (with callbacks)
# --------------------------
os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
checkpoint = ModelCheckpoint(MODEL_PATH, monitor="val_loss", save_best_only=True, verbose=1)
early = EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True, verbose=1)

history = model.fit(
    X_train, y_train,
    epochs=20,
    batch_size=64,
    validation_data=(X_val, y_val),
    callbacks=[early, checkpoint]
)
print(f"✅ LSTM training complete. Best model saved to {MODEL_PATH}")

# --------------------------
# EVALUATE
# --------------------------
y_pred_prob = model.predict(X_val, verbose=0).ravel()
y_pred = (y_pred_prob >= 0.5).astype(int)
print("Validation classification report:")
print(classification_report(y_val, y_pred, digits=4))

# --------------------------
# PRECOMPUTE TRANSFORMER EMBEDDINGS (reference set)
# --------------------------
transformer_model = SentenceTransformer("paraphrase-multilingual-mpnet-base-v2")
reference_texts = [item["text"] for item in dataset]
print("Computing transformer embeddings for reference texts (this may take a while)...")
reference_embeddings = transformer_model.encode(reference_texts, convert_to_numpy=True, show_progress_bar=True, batch_size=64)
os.makedirs(os.path.dirname(EMBEDDINGS_PATH), exist_ok=True)
np.save(EMBEDDINGS_PATH, reference_embeddings)
print(f"✅ Transformer embeddings saved to {EMBEDDINGS_PATH}")
