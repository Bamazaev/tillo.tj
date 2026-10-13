import hashlib
import hmac
import re
import secrets

from fastapi import Depends, Header, HTTPException

from .db import get_conn

_ITER = 120_000


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _ITER).hex()
    return f"{salt}${digest}"


def verify_password(password: str, stored: str) -> bool:
    salt, digest = stored.split("$", 1)
    check = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _ITER).hex()
    return hmac.compare_digest(check, digest)


def normalize_phone(phone: str) -> str:
    """Рақамро ба шакли +992XXXXXXXXX меорад."""
    digits = re.sub(r"\D", "", phone or "")
    if len(digits) == 9:
        digits = "992" + digits
    if not (len(digits) == 12 and digits.startswith("992")):
        raise HTTPException(422, "Неверный номер телефона (пример: +992 90 123 45 67)")
    return "+" + digits


def create_session(user_id: int) -> str:
    token = secrets.token_urlsafe(32)
    with get_conn() as conn:
        conn.execute("INSERT INTO sessions(token, user_id) VALUES (?, ?)", (token, user_id))
    return token


def public_user(row) -> dict:
    return {"id": row["id"], "name": row["name"], "phone": row["phone"], "is_shop": bool(row["is_shop"])}


def _user_from_token(authorization: str | None) -> dict | None:
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization[7:].strip()
    with get_conn() as conn:
        row = conn.execute(
            "SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token = ?",
            (token,),
        ).fetchone()
    return public_user(row) if row else None


def optional_user(authorization: str | None = Header(default=None)) -> dict | None:
    return _user_from_token(authorization)


def current_user(user: dict | None = Depends(optional_user)) -> dict:
    if not user:
        raise HTTPException(401, "Сначала войдите")
    return user
