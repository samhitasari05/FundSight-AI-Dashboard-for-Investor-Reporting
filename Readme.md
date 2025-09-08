Here’s an expanded `README.md` that walks through **everything**—from parsing PDFs and embedding, to running Qdrant in Docker, to launching your Flask app with RAG. Just drop this into your project root.

brew install unoconv
brew install libreoffice

```markdown
# SiliGenius – Chip-Design Q&A Demo

A tiny end-to-end reference showing how to:

- 🔐 Gate your app with **Microsoft Entra ID / Azure AD SSO**  
- 📥 Ingest & parse PDF docs into JSONL  
- 🧠 Build embeddings & upload to **Qdrant**  
- ⚡️ Serve a **Retrieval-Augmented Generation** dashboard (Flask + LangChain + local Llama/HF model)  
- 📄 Preview your source PDFs in-browser via **PDF.js**  

---

## 📁 Repository Layout

```

siliGenius/
├── .env                         # your secrets & model settings
├── README.md
├── requirements.txt
├── templates/
│   ├── layout.html
│   ├── login.html
│   └── dashboard.html
├── static/
│   ├── css/dashboard.css
│   ├── pdfs/…                   # your source PDFs
│   └── pdfjs/                   # PDF.js web viewer files
└── src/
├── ingest/
│   ├── chipdesign\_parser.py   # PDF → JSONL
│   └── chipdesign\_embedder.py # JSONL → Qdrant embeddings
└── backend/
└── app.py               # Flask + MSAL + RAG dashboard
└── tools/
└── rag3.py              # RAG helper (Qdrant + HF model)

````

---

## 🔧 Prerequisites

- **Python** 3.9–3.12  
- `pip` & virtual-env  
- **Docker** (for Qdrant)  
- Azure AD tenant & App Registration  

---

## ⚙️ 1 · Configure `.env`

Copy `.env.example` → `.env` and fill in:

```ini
# Azure AD / Entra ID
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_CLIENT_SECRET=YOUR_SECRET_VALUE
AZURE_TENANT_ID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
AZURE_REDIRECT_URI=http://localhost:5500/authorized

# Flask
FLASK_SECRET=some-random-secret

# Vector-DB + Embeddings
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_COLLECTION=chipdesign_docs
EMBEDDINGS_MODEL=all-MiniLM-L6-v2

# Local Llama/GGUF model (optional RAG3 path)
LLM_MODEL_PATH=models/qwen2.5-3b-instruct-q4_k_m.gguf
LLM_CTX_WINDOW=2048
LLM_TEMPERATURE=0.7

# HF model (for the simpler rag3.py)
HF_MODEL_ID=google/flan-t5-small
HF_MAX_NEW_TOKENS=200
````

---

## 🚀 2 · Install Dependencies

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

---

## 🛠 3 · Start Qdrant in Docker

```bash
# pull the latest image
docker pull qdrant/qdrant

# if you already have a container named `qdrant`, stop/remove it:
docker rm -f qdrant

# start Qdrant, exposing port 6333
docker run -d --name qdrant -p 6333:6333 qdrant/qdrant
```

Verify it’s up:

```bash
curl http://localhost:6333/health
# Expect: {"status":"ok"}
```

---

## 📄 4 · Ingest & Embed Your PDFs

1. **Parse your PDF(s)** into JSONL:

   ```bash
   python src/ingest/chipdesign_parser.py \
     --input-dir static/pdfs \
     --output data/ChipDesign/parsed.jsonl
   ```

   *(This uses PyPDF2 to extract text + metadata.)*

2. **Upload embeddings** to Qdrant:

   ```bash
   python src/ingest/chipdesign_embedder.py \
     --input data/ChipDesign/parsed.jsonl \
     --collection chipdesign_docs
   ```

   *(Uses `sentence-transformers` to generate vectors and create/recreate the Qdrant collection.)*

---

## 🖥️ 5 · Run the Flask + RAG Dashboard

```bash
# Ensure .env is set and Qdrant is running:
python src/backend/app.py
```

* **Login** at [http://localhost:5500](http://localhost:5500)
* After Azure SSO, you’ll land on `/dashboard`
* Ask questions; answers are generated via your chosen RAG helper:

  * **`src/tools/rag3.py`** (HF pipeline)
  * or swap in your local Llama-cpp chain version in `app.py`

---

## 🔍 6 · PDF.js Preview Integration

We bundle Mozilla’s PDF.js under `static/pdfjs/web`.
When you click **View source (page N)**, the iframe loads:

```
/static/pdfjs/web/viewer.html?
  file=/static/pdfs/YourDoc.pdf
  #page=<<N>>
```

—so it jumps right to that page.

---

## 🐞 Troubleshooting

| Symptom                          | Fix                                                                                          |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| **500 on POST /dashboard**       | • Check Qdrant logs: `docker logs qdrant`<br>• Re-ingest & embed collection name correctness |
| **`Collection … doesn’t exist`** | • Ensure `QDRANT_COLLECTION` matches your embedder script’s collection name                  |
| **PDF parsing errors**           | • `pip install PyPDF2`<br>• Confirm your PDF isn’t encrypted                                 |
| **Azure login loops**            | • Redirect URI mismatch in Azure Portal & `.env`<br>• Check `AUTHORITY` & `TENANT_ID`        |
| **Port conflicts**               | • Another service uses 5500—stop it or change `PORT` in `app.py` & update Azure redirect URI |

---

## 🧹 Production Notes

* Replace Flask’s dev server with **Gunicorn** or **Uvicorn** behind NGINX
* Persist Qdrant data with Docker volumes
* Store secrets in Azure Key Vault / GitHub Secrets
* Scale embeddings & retrieval via remote Qdrant clusters

---

Happy hacking! 🚀
