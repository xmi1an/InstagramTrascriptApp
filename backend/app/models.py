from pydantic import BaseModel, HttpUrl


class HealthResponse(BaseModel):
    ok: bool


class TranscribeRequest(BaseModel):
    url: HttpUrl


class TranscribeResponse(BaseModel):
    transcript: str
