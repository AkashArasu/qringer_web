git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Enable Flutter web
flutter config --enable-web

# Get Flutter dependencies
flutter pub get

# Build web app
flutter build web --release