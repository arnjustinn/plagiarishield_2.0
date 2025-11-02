import json

def clean_multilingual_dataset(input_path, output_path):
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    cleaned = []
    for item in data:
        text = item["text"].strip()
        if len(text.split()) > 3:
            cleaned.append({"text": text, "label": item["label"]})

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    print(f"✅ Cleaned dataset saved to {output_path} (kept {len(cleaned)} samples)")
