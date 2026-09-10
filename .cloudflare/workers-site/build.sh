git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Enable Flutter web
flutter config --enable-web

# Get Flutter dependencies
flutter pub get

# Build web app
flutter build web --release

# Preserve the root asset base so direct /p/{propertyId} QR links load Flutter
# assets from / rather than from /p/.
# Flutter does not copy Cloudflare's SPA rewrite file into build/web.
cp web/_redirects build/web/_redirects
