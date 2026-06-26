import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl

app = FastAPI(title="Instagram Transcript API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class TranscribeRequest(BaseModel):
    url: HttpUrl


class TranscribeResponse(BaseModel):
    transcript: str


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/transcribe", response_model=TranscribeResponse)
def transcribe(request: TranscribeRequest):
    url = str(request.url)
    if "instagram.com" not in url:
        raise HTTPException(status_code=400, detail="Please provide an Instagram URL.")

    model = os.getenv("WHISPER_MODEL", "base")
    cookies = os.getenv("YTDLP_COOKIES")
    workdir = Path(tempfile.mkdtemp(prefix="insta-transcript-"))

    try:
        output_template = str(workdir / "reel.%(ext)s")
        download_cmd = [
            "yt-dlp",
            "--no-playlist",
            "-f",
            "bestaudio/best",
            "-o",
            output_template,
            url,
        ]
        if cookies:
            download_cmd.extend(["--cookies", cookies])

        subprocess.run(download_cmd, check=True, capture_output=True, text=True)

        audio_files = [path for path in workdir.iterdir() if path.name.startswith("reel.")]
        if not audio_files:
            raise HTTPException(status_code=422, detail="Could not download audio for this Reel.")

        whisper_dir = workdir / "whisper"
        whisper_dir.mkdir(exist_ok=True)
        subprocess.run(
            [
                "whisper",
                str(audio_files[0]),
                "--model",
                model,
                "--output_format",
                "txt",
                "--output_dir",
                str(whisper_dir),
            ],
            check=True,
            capture_output=True,
            text=True,
        )

        transcript_files = list(whisper_dir.glob("*.txt"))
        if not transcript_files:
            raise HTTPException(status_code=422, detail="Could not generate a transcript.")

        transcript = transcript_files[0].read_text(encoding="utf-8").strip()
        if not transcript:
            raise HTTPException(status_code=422, detail="No speech was found in this Reel.")

        return TranscribeResponse(transcript=transcript)
    except subprocess.CalledProcessError as error:
        details = (error.stderr or error.stdout or "Transcript generation failed.").strip()
        raise HTTPException(status_code=502, detail=details[-1000:])
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
