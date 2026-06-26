import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    whisper_model: str = os.getenv("WHISPER_MODEL", "base")
    ytdlp_cookies: str | None = os.getenv("YTDLP_COOKIES")
    cors_origins: list[str] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.cors_origins is None:
            raw_origins = os.getenv("CORS_ORIGINS", "*")
            object.__setattr__(
                self,
                "cors_origins",
                [origin.strip() for origin in raw_origins.split(",") if origin.strip()],
            )


settings = Settings()
