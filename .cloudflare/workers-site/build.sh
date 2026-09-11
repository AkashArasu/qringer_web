git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Enable Flutter web
flutter config --enable-web

# Get Flutter dependencies
flutter pub get

# Build web app
# The current Stream WebRTC dependency defaults to copying HTML video frames
# into Flutter textures. Some Chromium/CanvasKit combinations produce a blank
# texture even though the underlying MediaStream is live. Render the stream as
# a native HTML <video> platform view instead.
flutter build web --release --dart-define=WEBRTC_USE_HTML_ELEMENT_VIEW=true

# Preserve the root asset base so direct /p/{propertyId} QR links load Flutter
# assets from / rather than from /p/.
# Flutter does not copy Cloudflare's SPA rewrite file into build/web.
cp web/_redirects build/web/_redirects
