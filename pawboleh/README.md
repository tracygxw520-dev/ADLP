# PawBoleh

PawBoleh is a Flutter UI for fashion MSMEs. Its Paw Snap tab turns a product
photo and short product brief into marketing copy, a poster, and (when the
configured generator provides one) a promo video.

## Run Paw Snap locally

Start the included PawSnap API from the parent PAW workspace first:

```powershell
cd ..\..\backend
uv run fastapi dev
```

Then launch the Flutter UI. In Chrome, use `localhost`; Android emulators can
use the default `10.0.2.2` address.

```powershell
cd ..\PowerBoleh\pawboleh
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For local browser development, make sure the API's `CORS_ORIGINS` setting
allows the Flutter dev-server origin. `CORS_ORIGINS=*` is suitable for this
local prototype; use explicit origins in a deployed environment.

For a physical device, set `API_BASE_URL` to a reachable LAN or hosted API
address. Paw Snap uploads the image first, then creates the campaign through
`POST /content-productions`.

When using an Android emulator or a physical device, set the backend's
`PUBLIC_BASE_URL` to that same reachable address as well. For example, Android
emulators normally use `http://10.0.2.2:8000`; a phone needs your computer's
LAN IP instead of `localhost`.
