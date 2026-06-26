# Instagram Transcript App

A clean Flutter app that turns Instagram Reel links into transcripts.

## Build plan

1. **Flutter mobile UI**
   - Minimal home screen with one URL input.
   - Paste button for clipboard links.
   - Generate button with loading/error/success states.
   - Copy button for the final transcript.

2. **Share-to-app flow**
   - Android share target accepts text shared from Instagram or any app.
   - Android link handler opens Instagram URLs directly in the app.
   - The app extracts the first Instagram URL and starts transcription automatically.

3. **Transcript backend**
   - FastAPI service receives `{ "url": "..." }`.
   - Uses `yt-dlp` to download audio.
   - Uses Whisper to generate transcript text.
   - Returns `{ "transcript": "..." }` to the Flutter app.

4. **Deployment path**
   - Deploy `backend/` first.
   - Build Flutter with `TRANSCRIPT_API_URL` pointing to the backend `/transcribe` endpoint.

## Flutter app

```bash
cd src
flutter pub get
flutter test
flutter run --dart-define=TRANSCRIPT_API_URL=https://your-api.com/transcribe
```

## Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

Health check:

```bash
curl http://localhost:8000/health
```

Transcribe:

```bash
curl -X POST http://localhost:8000/transcribe \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://www.instagram.com/reel/REEL_ID/"}'
```

## Docker backend

```bash
cd backend
docker build -t instagram-transcript-api .
docker run -p 8000:8000 instagram-transcript-api
```

## Instagram cookies

Instagram can block unauthenticated downloads. If that happens, export logged-in cookies to a Netscape-format file and set:

```bash
export YTDLP_COOKIES=/path/to/cookies.txt
```

For hosted deployments, mount the cookie file securely and set `YTDLP_COOKIES` to that mounted path.
