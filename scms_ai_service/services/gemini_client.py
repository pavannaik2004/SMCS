"""
gemini_client.py — Wrapper around Google GenAI SDK (google-genai).

Handles:
  • Grammar correction  (gemini-2.0-flash, JSON output)
  • Complaint categorization (gemini-2.0-flash, JSON output)
  • Text embedding  (models/gemini-embedding-004, 768-d vectors)

ALL calls are wrapped in try/except — callers always get a safe value on failure.

Note: Uses the new google-genai SDK (not the deprecated google-generativeai).
"""

import os
import json
import logging
import re

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

logger = logging.getLogger(__name__)

# ── Configure client once ────────────────────────────────────────────────────
_api_key = os.getenv("GEMINI_API_KEY", "")
_client: genai.Client | None = None

if _api_key:
    _client = genai.Client(api_key=_api_key)
else:
    logger.warning("GEMINI_API_KEY not set — Gemini calls will fail gracefully.")

# Model identifiers
_TEXT_MODEL = "gemini-2.0-flash"
_EMBED_MODEL = "models/gemini-embedding-004"  # 768-d, SEMANTIC_SIMILARITY task

# ── Categories known to the system ───────────────────────────────────────────
CATEGORIES = [
    "Electrical",
    "Plumbing",
    "Civil",
    "IT/Network",
    "Housekeeping",
    "Security",
    "Mess/Cafeteria",
    "Transport",
    "Library",
    "Sports",
    "Other",
]

# Mapping category name → department name (used when DB lookup is unavailable)
CATEGORY_DEPT_MAP: dict[str, str] = {
    "Electrical":     "Electrical Department",
    "Plumbing":       "Civil & Maintenance Department",
    "Civil":          "Civil & Maintenance Department",
    "IT/Network":     "IT Department",
    "Housekeeping":   "Housekeeping Department",
    "Security":       "Security Department",
    "Mess/Cafeteria": "Mess Committee",
    "Transport":      "Transport Department",
    "Library":        "Library Department",
    "Sports":         "Sports Department",
    "Other":          "Administration",
}


# ─────────────────────────────────────────────────────────────────────────────
#  Helper: safely parse JSON from Gemini response text
# ─────────────────────────────────────────────────────────────────────────────

def _extract_json(text: str) -> dict:
    """
    Strip markdown code fences (```json ... ```) before parsing JSON.
    """
    cleaned = re.sub(r"```(?:json)?\s*", "", text).strip().rstrip("`").strip()
    return json.loads(cleaned)


def _generate(prompt: str) -> str:
    """Call Gemini text generation; raise on any error."""
    if _client is None:
        raise RuntimeError("Gemini client not initialised (GEMINI_API_KEY missing).")
    response = _client.models.generate_content(
        model=_TEXT_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        ),
    )
    return response.text


# ─────────────────────────────────────────────────────────────────────────────
#  Grammar Correction
# ─────────────────────────────────────────────────────────────────────────────

async def grammar_correct(text: str) -> dict:
    """
    Returns:
        {"correctedText": str, "hasCorrections": bool}

    Falls back to {"correctedText": text, "hasCorrections": False} on any error.
    """
    default = {"correctedText": text, "hasCorrections": False}

    try:
        prompt = f"""You are a grammar correction assistant for complaint submissions at an engineering college.
Correct ONLY grammar and spelling errors. Do NOT change the meaning, add new information, or alter technical terms.
Return ONLY valid JSON in this exact format:
{{"correctedText": "...", "hasCorrections": true}}

Original text:
{text}
"""
        raw = _generate(prompt)
        data = _extract_json(raw)
        return {
            "correctedText": data.get("correctedText", text),
            "hasCorrections": bool(data.get("hasCorrections", False)),
        }
    except Exception as exc:
        logger.error("grammar_correct failed: %s", exc)
        return default


# ─────────────────────────────────────────────────────────────────────────────
#  Complaint Categorization
# ─────────────────────────────────────────────────────────────────────────────

async def categorize_complaint(text: str) -> dict:
    """
    Returns:
        {
            "suggestedCategory":  str,   # one of CATEGORIES
            "suggestedSeverity":  str,   # HIGH | MEDIUM | LOW
            "confidenceScore":    float, # 0.0 – 1.0
            "reasoning":          str
        }

    Falls back to safe defaults on any error.
    """
    default = {
        "suggestedCategory": "Other",
        "suggestedSeverity": "MEDIUM",
        "confidenceScore": 0.0,
        "reasoning": "Categorization unavailable.",
    }

    try:
        categories_str = ", ".join(CATEGORIES)
        prompt = f"""You are a complaint categorization system for an engineering college.
Available categories: {categories_str}

Analyze this complaint and return ONLY valid JSON:
{{
  "suggestedCategory": "<one of the categories above>",
  "suggestedSeverity": "<HIGH|MEDIUM|LOW>",
  "confidenceScore": <0.0 to 1.0>,
  "reasoning": "<one concise sentence>"
}}

Severity guidelines:
  HIGH   — safety hazard, affects many people, urgent infrastructure failure
  MEDIUM — inconvenient but not dangerous, routine maintenance
  LOW    — minor cosmetic or non-urgent issue

Complaint: {text}
"""
        raw = _generate(prompt)
        data = _extract_json(raw)

        category = data.get("suggestedCategory", "Other")
        if category not in CATEGORIES:
            category = "Other"

        severity = data.get("suggestedSeverity", "MEDIUM").upper()
        if severity not in ("HIGH", "MEDIUM", "LOW"):
            severity = "MEDIUM"

        return {
            "suggestedCategory": category,
            "suggestedSeverity": severity,
            "confidenceScore": float(data.get("confidenceScore", 0.0)),
            "reasoning": str(data.get("reasoning", "")),
        }
    except Exception as exc:
        logger.error("categorize_complaint failed: %s", exc)
        return default


# ─────────────────────────────────────────────────────────────────────────────
#  Text Embedding
# ─────────────────────────────────────────────────────────────────────────────

async def embed_text(text: str) -> list[float]:
    """
    Generate a 768-dimensional semantic similarity embedding using
    gemini-embedding-004.

    Returns an empty list on failure (callers must handle this).
    """
    try:
        if _client is None:
            raise RuntimeError("Gemini client not initialised (GEMINI_API_KEY missing).")

        result = _client.models.embed_content(
            model=_EMBED_MODEL,
            contents=text,
            config=types.EmbedContentConfig(
                task_type="SEMANTIC_SIMILARITY",
            ),
        )
        # result.embeddings is a list of ContentEmbedding objects
        return list(result.embeddings[0].values)
    except Exception as exc:
        logger.error("embed_text failed: %s", exc)
        return []
