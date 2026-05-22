from pydantic import BaseModel
from typing import Optional, List


# ─────────────────────────────────────────────
#  Grammar Check
# ─────────────────────────────────────────────

class GrammarRequest(BaseModel):
    text: str


class GrammarDiff(BaseModel):
    type: str   # EQUAL | DELETE | INSERT
    text: str


class GrammarResponse(BaseModel):
    hasCorrections: bool
    correctedText: str
    diffs: List[GrammarDiff] = []


# ─────────────────────────────────────────────
#  Categorization
# ─────────────────────────────────────────────

class CategorizeRequest(BaseModel):
    text: str


class CategorizeResponse(BaseModel):
    suggestedCategoryId: Optional[str] = None
    suggestedCategoryName: Optional[str] = None
    suggestedDepartmentId: Optional[str] = None
    suggestedSeverity: str = "MEDIUM"   # HIGH | MEDIUM | LOW
    confidenceScore: float = 0.0
    reasoning: Optional[str] = None


# ─────────────────────────────────────────────
#  Embed
# ─────────────────────────────────────────────

class EmbedRequest(BaseModel):
    text: str
    complaintId: str   # Store embedding against this ID


class EmbedResponse(BaseModel):
    success: bool
    dimensions: int


# ─────────────────────────────────────────────
#  Duplicate Detection
# ─────────────────────────────────────────────

class DuplicateRequest(BaseModel):
    text: str
    zoneId: Optional[str] = None
    tags: Optional[List[str]] = None


class DuplicateMatch(BaseModel):
    id: str
    complaintNumber: str
    title: str
    status: str
    score: float


class DuplicateResponse(BaseModel):
    isDuplicate: bool
    similarCount: int = 0
    topMatch: Optional[DuplicateMatch] = None
    allMatches: List[DuplicateMatch] = []
    groupId: Optional[str] = None
