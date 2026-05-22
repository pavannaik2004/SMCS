"""
db_client.py — PostgreSQL + pgvector connection and queries.

Responsibilities:
  • Provide a connection pool (psycopg2 + pgvector register_vector)
  • Store embeddings: UPDATE complaints SET embedding = <vector> WHERE id = <uuid>
  • Query similar complaints: SELECT ... ORDER BY embedding <=> query_vec LIMIT 5
  • Ensure the `embedding` column exists (idempotent migration helper)

pgvector vector dimensions: 768  (gemini-embedding-001)
"""

import os
import logging
from contextlib import contextmanager
from typing import Generator

import psycopg2
import psycopg2.pool
from pgvector.psycopg2 import register_vector
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

DATABASE_URL: str = os.getenv("DATABASE_URL", "")
SIMILARITY_THRESHOLD: float = float(os.getenv("SIMILARITY_THRESHOLD", "0.75"))
EMBEDDING_DIM: int = 768

# ── Connection pool (created lazily on first use) ────────────────────────────
_pool: psycopg2.pool.ThreadedConnectionPool | None = None


def _get_pool() -> psycopg2.pool.ThreadedConnectionPool:
    global _pool
    if _pool is None:
        if not DATABASE_URL:
            raise RuntimeError("DATABASE_URL is not set in environment.")
        _pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=5,
            dsn=DATABASE_URL,
        )
        logger.info("PostgreSQL connection pool created.")
    return _pool


@contextmanager
def get_conn() -> Generator:
    """Yield a psycopg2 connection from the pool, registering pgvector on it."""
    pool = _get_pool()
    conn = pool.getconn()
    try:
        register_vector(conn)   # enables <=> operator + Python list ↔ vector
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        pool.putconn(conn)


# ── Idempotent migration: ensure embedding column exists ─────────────────────

def ensure_embedding_column() -> None:
    """
    Add the pgvector `embedding vector(768)` column to complaints if absent.
    Safe to call multiple times.
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                # Enable pgvector extension (no-op if already enabled)
                cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
                # Add column only if not present
                cur.execute(
                    """
                    ALTER TABLE complaints
                    ADD COLUMN IF NOT EXISTS embedding vector(%s);
                    """,
                    (EMBEDDING_DIM,),
                )
        logger.info("embedding column ensured (vector(%d)).", EMBEDDING_DIM)
    except Exception as exc:
        # Log but don't crash startup — DB may not be reachable yet
        logger.warning("ensure_embedding_column failed (non-fatal): %s", exc)


# ── Store embedding for a complaint ──────────────────────────────────────────

def store_embedding(complaint_id: str, embedding: list[float]) -> bool:
    """
    UPDATE complaints SET embedding = %s::vector WHERE id = %s

    Returns True on success, False on failure.
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE complaints SET embedding = %s::vector WHERE id = %s",
                    (embedding, complaint_id),
                )
                if cur.rowcount == 0:
                    logger.warning(
                        "store_embedding: no complaint found with id=%s", complaint_id
                    )
                    return False
        return True
    except Exception as exc:
        logger.error("store_embedding failed for id=%s: %s", complaint_id, exc)
        return False


# ── Query similar complaints (pgvector cosine distance) ──────────────────────

def find_similar_complaints(
    embedding: list[float],
    zone_id: str | None = None,
    limit: int = 5,
) -> list[dict]:
    """
    Find complaints with cosine similarity >= SIMILARITY_THRESHOLD.

    Args:
        embedding: 768-d query vector
        zone_id:   Optional zone filter (matches complaints in same zone)
        limit:     Max rows to return from DB before threshold filtering

    Returns:
        List of dicts with keys: id, complaintNumber, title, status, score
        Already filtered to score >= SIMILARITY_THRESHOLD, sorted desc.
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                if zone_id:
                    sql = """
                        SELECT
                            id,
                            "complaintNumber",
                            title,
                            status,
                            1 - (embedding <=> %s::vector) AS score
                        FROM complaints
                        WHERE
                            embedding IS NOT NULL
                            AND status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
                            AND "zoneId" = %s
                        ORDER BY score DESC
                        LIMIT %s
                    """
                    cur.execute(sql, (embedding, zone_id, limit))
                else:
                    sql = """
                        SELECT
                            id,
                            "complaintNumber",
                            title,
                            status,
                            1 - (embedding <=> %s::vector) AS score
                        FROM complaints
                        WHERE
                            embedding IS NOT NULL
                            AND status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
                        ORDER BY score DESC
                        LIMIT %s
                    """
                    cur.execute(sql, (embedding, limit))

                rows = cur.fetchall()

        results = []
        for row in rows:
            c_id, complaint_number, title, status, score = row
            if score >= SIMILARITY_THRESHOLD:
                results.append(
                    {
                        "id": str(c_id),
                        "complaintNumber": complaint_number,
                        "title": title,
                        "status": status,
                        "score": round(float(score), 4),
                    }
                )
        return results

    except Exception as exc:
        logger.error("find_similar_complaints failed: %s", exc)
        return []


# ── Get duplicate group ID for a complaint ───────────────────────────────────

def get_duplicate_group_id(complaint_id: str) -> str | None:
    """Return the duplicateGroupId of a complaint (may be None)."""
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    'SELECT "duplicateGroupId" FROM complaints WHERE id = %s',
                    (complaint_id,),
                )
                row = cur.fetchone()
                return row[0] if row else None
    except Exception as exc:
        logger.error("get_duplicate_group_id failed: %s", exc)
        return None
