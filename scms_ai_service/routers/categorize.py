"""
routers/categorize.py — POST /categorize

Uses Gemini to determine:
  • Complaint category (Electrical, Plumbing, IT/Network …)
  • Suggested severity (HIGH / MEDIUM / LOW)
  • Confidence score (0.0 – 1.0)
  • Reasoning text

The router maps the returned category name to IDs using an in-memory map
(no DB round-trip) so it works even when the DB is unavailable.
"""

import logging

from fastapi import APIRouter
from models.schemas import CategorizeRequest, CategorizeResponse
from services.gemini_client import categorize_complaint, CATEGORY_DEPT_MAP

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Categorize"])

# Stable slug → UUID-style IDs (matches seed data from Prem's migrations)
# These are placeholder IDs — replace with real UUIDs once Prem seeds the DB.
CATEGORY_ID_MAP: dict[str, str] = {
    "Electrical":     "cat-electrical",
    "Plumbing":       "cat-plumbing",
    "Civil":          "cat-civil",
    "IT/Network":     "cat-it-network",
    "Housekeeping":   "cat-housekeeping",
    "Security":       "cat-security",
    "Mess/Cafeteria": "cat-mess",
    "Transport":      "cat-transport",
    "Library":        "cat-library",
    "Sports":         "cat-sports",
    "Other":          "cat-other",
}

DEPT_ID_MAP: dict[str, str] = {
    "Electrical Department":           "dept-electrical",
    "Civil & Maintenance Department":  "dept-civil",
    "IT Department":                   "dept-it",
    "Housekeeping Department":         "dept-housekeeping",
    "Security Department":             "dept-security",
    "Mess Committee":                  "dept-mess",
    "Transport Department":            "dept-transport",
    "Library Department":              "dept-library",
    "Sports Department":               "dept-sports",
    "Administration":                  "dept-admin",
}


@router.post("/categorize", response_model=CategorizeResponse)
async def categorize(req: CategorizeRequest) -> CategorizeResponse:
    """
    Returns AI-suggested category, severity, confidence score, and reasoning.

    Safe defaults (category=Other, severity=MEDIUM, confidence=0.0) are
    returned if Gemini is unavailable.
    """
    text = req.text.strip()

    if not text:
        return CategorizeResponse(
            suggestedCategoryName="Other",
            suggestedCategoryId=CATEGORY_ID_MAP["Other"],
            suggestedSeverity="MEDIUM",
            confidenceScore=0.0,
            reasoning="Empty complaint text.",
        )

    # Call Gemini (safe defaults on failure)
    result = await categorize_complaint(text)

    category_name: str = result.get("suggestedCategory", "Other")
    severity: str = result.get("suggestedSeverity", "MEDIUM")
    confidence: float = result.get("confidenceScore", 0.0)
    reasoning: str = result.get("reasoning", "")

    # Look up IDs
    category_id = CATEGORY_ID_MAP.get(category_name, CATEGORY_ID_MAP["Other"])
    dept_name = CATEGORY_DEPT_MAP.get(category_name, "Administration")
    dept_id = DEPT_ID_MAP.get(dept_name, "dept-admin")

    return CategorizeResponse(
        suggestedCategoryId=category_id,
        suggestedCategoryName=category_name,
        suggestedDepartmentId=dept_id,
        suggestedSeverity=severity,
        confidenceScore=confidence,
        reasoning=reasoning,
    )
