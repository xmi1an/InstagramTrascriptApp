from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .models import HealthResponse, TranscribeRequest, TranscribeResponse
from .services.transcript_service import TranscriptService

app = FastAPI(title="Instagram Transcript API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

transcript_service = TranscriptService(settings=settings)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(ok=True)


@app.post("/transcribe", response_model=TranscribeResponse)
def transcribe(request: TranscribeRequest) -> TranscribeResponse:
    transcript = transcript_service.transcribe(str(request.url))
    return TranscribeResponse(transcript=transcript)
