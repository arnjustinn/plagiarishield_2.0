import os
import json
import random
from tqdm import tqdm
import nltk

# Download NLTK resources for English synonym replacement
from nltk.corpus import wordnet
nltk.download("wordnet")
nltk.download("omw-1.4")

# --------------------------
# Paths
# --------------------------
# Paths (relative to project root)
ORIGINAL_DIR_EN = "../data/originals"
PLAGIARIZED_DIR_EN = "../data/plagiarized"
ORIGINAL_DIR_TL = "../data/originals_tl"
PLAGIARIZED_DIR_TL = "../data/plagiarized_tl"

AUGMENTED_JSON_PATH = "../data/generated_dataset_multilingual.json"


TARGET_SAMPLES_PER_CLASS = 500  # 500 per class → ~1,000 total

# --------------------------
# Load texts
# --------------------------
def load_texts(folder):
    texts = []
    for filename in sorted(os.listdir(folder)):
        if filename.endswith(".txt"):
            with open(os.path.join(folder, filename), "r", encoding="utf-8") as f:
                content = f.read().strip()
                if content:
                    texts.append(content)
    return texts

original_texts = load_texts(ORIGINAL_DIR_EN) + load_texts(ORIGINAL_DIR_TL)
plag_texts = load_texts(PLAGIARIZED_DIR_EN) + load_texts(PLAGIARIZED_DIR_TL)

print(f"Loaded {len(original_texts)} original and {len(plag_texts)} plagiarized texts.")

# --------------------------
# Augmentation functions
# --------------------------

def shuffle_sentences(text):
    sentences = text.split(". ")
    random.shuffle(sentences)
    return ". ".join(sentences)

def minor_edits(text):
    """Small edits: remove commas, lowercase some words, add extra spacing."""
    new_text = text.replace(",", "")
    words = new_text.split()
    for i in range(len(words)):
        if random.random() < 0.05:
            words[i] = words[i].lower()
        if random.random() < 0.02:
            words[i] = words[i] + " "
    return " ".join(words)

def synonym_replacement(text, n=2):
    """Replace up to n English words with synonyms. Skip Tagalog words."""
    words = text.split()
    new_words = words.copy()
    indices = list(range(len(words)))
    random.shuffle(indices)
    replaced = 0
    for i in indices:
        word = words[i]
        # Only attempt replacement if word has English synsets
        syns = wordnet.synsets(word)
        if not syns:
            continue
        lemmas = [l.name() for s in syns for l in s.lemmas() if "_" not in l.name()]
        lemmas = [l for l in lemmas if l.lower() != word.lower()]
        if lemmas:
            new_words[i] = random.choice(lemmas)
            replaced += 1
        if replaced >= n:
            break
    return " ".join(new_words)

def augment_text(text, num_aug=5):
    augmented = []
    for _ in range(num_aug):
        new_text = text
        # Sentence shuffle
        if random.random() < 0.7:
            new_text = shuffle_sentences(new_text)
        # Minor edits
        if random.random() < 0.7:
            new_text = minor_edits(new_text)
        # Synonym replacement for English text (skip Tagalog)
        if any(char.isascii() for char in new_text):
            if random.random() < 0.5:
                new_text = synonym_replacement(new_text, n=random.randint(1,3))
        augmented.append(new_text)
    return augmented

# --------------------------
# Generate dataset for a class
# --------------------------
def generate_class(texts, label):
    class_samples = []
    while len(class_samples) < TARGET_SAMPLES_PER_CLASS:
        text = random.choice(texts)
        # Original text itself
        class_samples.append({"text": text, "label": label})
        # Augmented versions
        aug_texts = augment_text(text, num_aug=3)
        for at in aug_texts:
            class_samples.append({"text": at, "label": label})
        # Limit to target
        if len(class_samples) > TARGET_SAMPLES_PER_CLASS:
            class_samples = class_samples[:TARGET_SAMPLES_PER_CLASS]
    return class_samples

# --------------------------
# Build dataset
# --------------------------
dataset = []

print("🔹 Augmenting original texts...")
dataset += generate_class(original_texts, 0)

print("🔹 Augmenting plagiarized texts...")
dataset += generate_class(plag_texts, 1)

# Shuffle final dataset
random.shuffle(dataset)

# Save JSON
with open(AUGMENTED_JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(dataset, f, ensure_ascii=False, indent=2)

print(f"✅ Augmented multilingual dataset saved to {AUGMENTED_JSON_PATH}")
print(f"Total samples: {len(dataset)} (Original + Plagiarized)")
