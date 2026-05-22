"""
routers/grammar.py — POST /grammar-check

Calls Gemini to correct grammar/spelling, then builds an EQUAL/DELETE/INSERT
diff using Python's stdlib difflib so the Flutter UI can render highlighted changes.
"""

import difflib
import logging

from fastapi import APIRouter
from models.schemas import GrammarRequest, GrammarResponse, GrammarDiff
from services.gemini_client import grammar_correct

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Grammar"])


def _build_diffs(original: str, corrected: str) -> list[GrammarDiff]:
    """
    Produce a word-level diff between `original` and `corrected`.

    Each token gets tagged:
      EQUAL   — unchanged word
      DELETE  — word present in original but removed in corrected
      INSERT  — word added in corrected that wasn't in original
    """
    original_words = original.split()
    corrected_words = corrected.split()

    matcher = difflib.SequenceMatcher(None, original_words, corrected_words)
    diffs: list[GrammarDiff] = []

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            diffs.append(
                GrammarDiff(type="EQUAL", text=" ".join(original_words[i1:i2]))
            )
        elif tag == "replace":
            diffs.append(
                GrammarDiff(type="DELETE", text=" ".join(original_words[i1:i2]))
            )
            diffs.append(
                GrammarDiff(type="INSERT", text=" ".join(corrected_words[j1:j2]))
            )
        elif tag == "delete":
            diffs.append(
                GrammarDiff(type="DELETE", text=" ".join(original_words[i1:i2]))
            )
        elif tag == "insert":
            diffs.append(
                GrammarDiff(type="INSERT", text=" ".join(corrected_words[j1:j2]))
            )

    return diffs


@router.post("/grammar-check", response_model=GrammarResponse)
async def grammar_check(req: GrammarRequest) -> GrammarResponse:
    """
    Accepts raw complaint text, returns grammar-corrected text plus a diff.

    Safe defaults returned if Gemini is unavailable:
      hasCorrections = false, correctedText = original text, diffs = []
    """
    original_text = req.text.strip()

    if not original_text:
        return GrammarResponse(
            hasCorrections=False,
            correctedText="",
            diffs=[],
        )

    # Call Gemini (returns safe defaults on failure)
    result = await grammar_correct(original_text)

    corrected = result["correctedText"].strip()
    has_corrections = result["hasCorrections"]

    # Build word-level diffs only when there are actual changes
    diffs: list[GrammarDiff] = []
    if has_corrections and corrected != original_text:
        diffs = _build_diffs(original_text, corrected)
    elif corrected == original_text:
        # Gemini said hasCorrections=true but text is identical — normalise
        has_corrections = False

    return GrammarResponse(
        hasCorrections=has_corrections,
        correctedText=corrected,
        diffs=diffs,
    )
