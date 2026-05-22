"""
routers/embed.py — POST /embed

Called by Node.js *after* a complaint is saved to PostgreSQL.
Generates a 768-d embedding via Gemini and stores it in
complaints.embedding (pgvector vector(768)).

This endpoint is internal — never called directly by Flutter.
"""

import logging

from fastapi import APIRouter, HTTPException
from models.schemas import EmbedRequest, EmbedResponse
from services.gemini_client import embed_text
from services.db_client import store_embedding

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Embed"])


@router.post("/embed", response_model=EmbedResponse)
async def embed(req: EmbedRequest) -> EmbedResponse:
    """
    Generate and persist an embedding for a complaint.

    Steps:
      1. Call Gemini to produce a 768-d vector for `text`.
      2. UPDATE complaints SET embedding = vector WHERE id = complaintId.

    Returns success=False (not a 4xx/5xx) if either step fails,
    so Node.js can continue without blocking the user.
    """
    text = req.text.strip()
    complaint_id = req.complaintId.strip()

    if not text or not complaint_id:
        return EmbedResponse(success=False, dimensions=0)

    # Step 1 — generate embedding
    embedding = await embed_text(text)
    if not embedding:
        logger.error("embed: Gemini returned empty embedding for complaintId=%s", complaint_id)
        return EmbedResponse(success=False, dimensions=0)

    # Step 2 — persist to DB
    ok = store_embedding(complaint_id, embedding)
    if not ok:
        logger.error("embed: failed to store embedding for complaintId=%s", complaint_id)
        return EmbedResponse(success=False, dimensions=len(embedding))

    return EmbedResponse(success=True, dimensions=len(embedding))
