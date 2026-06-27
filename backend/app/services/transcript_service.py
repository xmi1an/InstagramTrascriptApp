import shutil
import subprocess
import tempfile
from pathlib import Path

from fastapi import HTTPException

from ..config import Settings
from .command_runner import CommandRunner


class TranscriptService:
    def __init__(self, settings: Settings, command_runner: CommandRunner | None = None) -> None:
        self._settings = settings
        self._command_runner = command_runner or CommandRunner()

    def transcribe(self, url: str) -> str:
        self._validate_url(url)
        workdir = Path(tempfile.mkdtemp(prefix="insta-transcript-"))

        try:
            audio_path = self._download_audio(url=url, workdir=workdir)
            transcript = self._run_whisper(audio_path=audio_path, workdir=workdir)
        except subprocess.CalledProcessError as error:
            details = (error.stderr or error.stdout or "Transcript generation failed.").strip()
            raise HTTPException(status_code=502, detail=details[-1000:]) from error
        finally:
            shutil.rmtree(workdir, ignore_errors=True)

        if not transcript:
            raise HTTPException(status_code=422, detail="No speech was found in this Reel.")

        return transcript

    def _validate_url(self, url: str) -> None:
        if "instagram.com" not in url:
            raise HTTPException(status_code=400, detail="Please provide an Instagram URL.")

    def _download_audio(self, url: str, workdir: Path) -> Path:
        output_template = str(workdir / "reel.%(ext)s")
        command = [
            "yt-dlp",
            "--no-playlist",
            "-f",
            "bestaudio/best",
            "-o",
            output_template,
            url,
        ]
        if self._settings.ytdlp_cookies:
            command.extend(["--cookies", self._settings.ytdlp_cookies])

        self._command_runner.run(command)

        audio_files = [path for path in workdir.iterdir() if path.name.startswith("reel.")]
        if not audio_files:
            raise HTTPException(status_code=422, detail="Could not download audio for this Reel.")

        return audio_files[0]

    def _run_whisper(self, audio_path: Path, workdir: Path) -> str:
        whisper_dir = workdir / "whisper"
        whisper_dir.mkdir(exist_ok=True)

        self._command_runner.run(
            [
                "whisper",
                str(audio_path),
                "--model",
                self._settings.whisper_model,
                "--output_format",
                "txt",
                "--output_dir",
                str(whisper_dir),
            ]
        )

        transcript_files = list(whisper_dir.glob("*.txt"))
        if not transcript_files:
            raise HTTPException(status_code=422, detail="Could not generate a transcript.")

        return transcript_files[0].read_text(encoding="utf-8").strip()
