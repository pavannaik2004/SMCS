"""
main.py — SCMS AI Microservice entry point.

Starts a FastAPI application on port 8000 (configurable via PORT env var).
Called ONLY by the Node.js backend — never directly by Flutter.

Endpoints:
  GET  /health          → liveness probe
  POST /grammar-check   → grammar correction + diff
  POST /categorize      → AI-powered category + severity
  POST /embed           → generate + store complaint embedding
  POST /check-duplicate → pgvector similarity search
"""

import logging
import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import grammar, categorize, embed, duplicate
from services.db_client import ensure_embedding_column

# ── Load environment variables ───────────────────────────────────────────────
load_dotenv()

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)

# ── FastAPI app ───────────────────────────────────────────────────────────────
app = FastAPI(
    title="SCMS AI Service",
    version="1.0.0",
    description=(
        "Python microservice for the Smart Complaint Management System. "
        "Handles grammar correction, AI categorization, text embeddings, "
        "and duplicate complaint detection via Google Gemini + pgvector."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ─────────────────────────────────────────────────────────────────────
# In production: restrict allow_origins to the Node.js backend's URL.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Node.js backend only in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(grammar.router)
app.include_router(categorize.router)
app.include_router(embed.router)
app.include_router(duplicate.router)


# ── Startup event ─────────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup() -> None:
    """
    Run once when the server starts.
    Ensures the pgvector `embedding` column exists in `complaints`.
    Non-fatal if DB is unreachable — service still starts normally.
    """
    logger.info("SCMS AI Service starting up …")
    ensure_embedding_column()
    logger.info("Startup complete. Listening on port %s.", os.getenv("PORT", "8000"))


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["Health"])
def health() -> dict:
    """Liveness probe — returns 200 OK immediately."""
    return {"status": "ok", "service": "scms-ai-service", "version": "1.0.0"}


# ── Dev runner ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
