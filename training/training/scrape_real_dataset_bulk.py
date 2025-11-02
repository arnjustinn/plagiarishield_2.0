import os
import json
import random
from newspaper import Article
from tqdm import tqdm
import feedparser
import requests
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
import nltk
from nltk.corpus import wordnet
from langdetect import detect

nltk.download("wordnet")
nltk.download("omw-1.4")

DATA_JSON_PATH = "../data/generated_dataset_multilingual.json"
TARGET_SAMPLES_PER_CLASS = 5000
MAX_CHARS_PER_CHUNK = 1500

ENGLISH_NEWS_SITES = [
    "https://www.bbc.com/news",
    "https://www.cnn.com",
    "https://en.wikipedia.org/wiki/Climate_change",
]

TAGALOG_NEWS_SITES = [
    "https://www.rappler.com",
    "https://news.abs-cbn.com",
    "https://tl.wikipedia.org/wiki/Pagbabago_ng_klima",
    "https://tl.wikipedia.org/wiki/Pilipinas",
    "https://tl.wikipedia.org/wiki/Maynila"
]

RSS_FEEDS = {
    "https://www.bbc.com/news": ["https://feeds.bbci.co.uk/news/rss.xml"],
    "https://www.cnn.com": ["https://rss.cnn.com/rss/edition.rss"],
    "https://www.rappler.com": ["https://feeds.rappler.com/rappler/news"],
}

# -------------------
# AUGMENTATION FUNCTIONS
# -------------------
def shuffle_sentences(text):
    """Randomly shuffle sentences to simulate reordering."""
    sentences = text.split(". ")
    random.shuffle(sentences)
    return ". ".join(sentences)

def minor_edits(text):
    """Apply small random edits (remove commas, change case, spacing)."""
    new_text = text.replace(",", "")
    words = new_text.split()
    for i in range(len(words)):
        if random.random() < 0.05:
            words[i] = words[i].lower()
        if random.random() < 0.02:
            words[i] += " "
    return " ".join(words)

def synonym_replacement(text, n=2):
    """Replace up to n words with synonyms (English only)."""
    words = text.split()
    new_words = words.copy()
    indices = list(range(len(words)))
    random.shuffle(indices)
    replaced = 0
    for i in indices:
        syns = wordnet.synsets(words[i])
        if not syns:
            continue
        lemmas = [l.name() for s in syns for l in s.lemmas() if "_" not in l.name()]
        lemmas = [l for l in lemmas if l.lower() != words[i].lower()]
        if lemmas:
            new_words[i] = random.choice(lemmas)
            replaced += 1
        if replaced >= n:
            break
    return " ".join(new_words)

def detect_language(text):
    """Use langdetect to identify if text is Tagalog or English."""
    try:
        lang = detect(text)
        if lang in ("tl", "fil"):
            return "tl"
        elif lang.startswith("en"):
            return "en"
    except:
        pass
    # fallback: simple heuristic
    non_ascii_ratio = sum(1 for c in text if ord(c) > 128) / max(1, len(text))
    return "tl" if non_ascii_ratio > 0.2 else "en"

def augment_text(text, num_aug=3):
    """Create augmented variants of a text. Synonym replacement for English only."""
    lang = detect_language(text)
    augmented = []
    for _ in range(num_aug):
        new_text = text
        if random.random() < 0.7:
            new_text = shuffle_sentences(new_text)
        if random.random() < 0.7:
            new_text = minor_edits(new_text)
        # Only apply synonym replacement for English text
        if lang == "en" and any(char.isascii() for char in new_text):
            if random.random() < 0.5:
                new_text = synonym_replacement(new_text, n=random.randint(1, 3))
        augmented.append(new_text)
    return augmented

# -------------------
# SCRAPING UTILITIES
# -------------------
def scrape_article(url):
    """Scrape full article text and split into clean chunks."""
    try:
        article = Article(url)
        article.download()
        article.parse()
        text = article.text.strip()
        if not text or len(text) < 80:
            return []

        chunks = []
        current_chunk = []
        current_len = 0

        # Split by sentences to maintain coherence
        for sentence in text.split(". "):
            sentence = sentence.strip()
            if not sentence:
                continue
            if current_len + len(sentence) > MAX_CHARS_PER_CHUNK:
                chunks.append(". ".join(current_chunk).strip())
                current_chunk = []
                current_len = 0
            current_chunk.append(sentence)
            current_len += len(sentence)

        if current_chunk:
            chunks.append(". ".join(current_chunk).strip())

        return [c for c in chunks if len(c) > 50]

    except Exception as e:
        return []

def extract_urls_from_rss(rss_urls):
    urls = []
    for feed in rss_urls:
        parsed = feedparser.parse(feed)
        for entry in parsed.entries:
            urls.append(entry.link)
    return urls

def extract_urls_from_sitemap(sitemap_url):
    urls = []
    try:
        r = requests.get(sitemap_url)
        tree = ET.fromstring(r.content)
        for elem in tree.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc"):
            urls.append(elem.text)
    except:
        pass
    return urls

# -------------------
# DATASET GENERATION
# -------------------
def generate_class(texts, label, target_samples=TARGET_SAMPLES_PER_CLASS):
    """Build balanced class dataset with augmentation."""
    class_samples = []
    if not texts:
        return class_samples

    while len(class_samples) < target_samples:
        text = random.choice(texts)
        class_samples.append({"text": text, "label": label})
        for at in augment_text(text, num_aug=3):
            class_samples.append({"text": at, "label": label})
        if len(class_samples) > target_samples:
            class_samples = class_samples[:target_samples]
    return class_samples

# -------------------
# MAIN PIPELINE
# -------------------
if __name__ == "__main__":
    dataset = []

    # English scraping
    english_texts = []
    for site in ENGLISH_NEWS_SITES:
        rss_urls = RSS_FEEDS.get(site, [])
        urls = extract_urls_from_rss(rss_urls)
        for url in tqdm(urls, desc=f"Scraping {site}"):
            english_texts += scrape_article(url)
    print(f"Loaded {len(english_texts)} English chunks.")

    # Tagalog scraping
    tagalog_texts = []
    for site in TAGALOG_NEWS_SITES:
        tagalog_texts += scrape_article(site)
    print(f"Loaded {len(tagalog_texts)} Tagalog chunks.")

    # Generate dataset
    dataset += generate_class(english_texts, 0)
    dataset += generate_class(english_texts, 1)
    dataset += generate_class(tagalog_texts, 0)
    dataset += generate_class(tagalog_texts, 1)

    random.shuffle(dataset)

    os.makedirs(os.path.dirname(DATA_JSON_PATH), exist_ok=True)
    with open(DATA_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(dataset, f, ensure_ascii=False, indent=2)

    print(f"✅ Saved {len(dataset)} samples to {DATA_JSON_PATH}")
