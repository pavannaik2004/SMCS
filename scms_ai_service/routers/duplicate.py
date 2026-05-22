"""
routers/duplicate.py — POST /check-duplicate

Algorithm:
  1. Embed the incoming complaint text via Gemini (768-d vector).
  2. Query pgvector for complaints in the same zone (or globally if zoneId absent)
     that are NOT resolved/closed/rejected.
  3. Filter rows where cosine similarity >= SIMILARITY_THRESHOLD (default 0.75).
  4. Return the top match and all matches to Node.js.

Node.js uses the groupId to link duplicates together.
"""

import logging
import os

from fastapi import APIRouter
from models.schemas import (
    DuplicateRequest,
    DuplicateResponse,
    DuplicateMatch,
)
from services.gemini_client import embed_text
from services.db_client import find_similar_complaints, get_duplicate_group_id

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Duplicate"])

SIMILARITY_THRESHOLD: float = float(os.getenv("SIMILARITY_THRESHOLD", "0.75"))


@router.post("/check-duplicate", response_model=DuplicateResponse)
async def check_duplicate(req: DuplicateRequest) -> DuplicateResponse:
    """
    Checks whether an incoming complaint is a near-duplicate of existing ones.

    Safe defaults (isDuplicate=False, allMatches=[]) are returned if
    Gemini or the DB is unavailable — the user can always submit their complaint.
    """
    text = req.text.strip()

    if not text:
        return DuplicateResponse(isDuplicate=False)

    # Step 1 — embed the incoming text
    embedding = await embed_text(text)
    if not embedding:
        logger.warning("check_duplicate: embedding failed — returning no-duplicate default")
        return DuplicateResponse(isDuplicate=False)

    # Step 2 — query pgvector
    matches_raw = find_similar_complaints(
        embedding=embedding,
        zone_id=req.zoneId,
    )

    if not matches_raw:
        return DuplicateResponse(isDuplicate=False)

    # Step 3 — build response objects
    matches: list[DuplicateMatch] = [
        DuplicateMatch(
            id=m["id"],
            complaintNumber=m["complaintNumber"],
            title=m["title"],
            status=m["status"],
            score=m["score"],
        )
        for m in matches_raw
    ]

    top_match = matches[0]
    is_duplicate = top_match.score >= SIMILARITY_THRESHOLD

    # Fetch the group ID from the top-matching complaint (if it has one)
    group_id: str | None = None
    if is_duplicate:
        group_id = get_duplicate_group_id(top_match.id)

    return DuplicateResponse(
        isDuplicate=is_duplicate,
        similarCount=len(matches),
        topMatch=top_match if is_duplicate else None,
        allMatches=matches,
        groupId=group_id,
    )
