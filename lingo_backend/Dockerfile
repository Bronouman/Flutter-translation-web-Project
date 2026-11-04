FROM dart:stable

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline

ENV PORT=10000
EXPOSE 10000
CMD ["dart", "run", "bin/server.dart"]
