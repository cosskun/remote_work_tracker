import 'dart:io';

Future<void> main() async {
  final buildDir = Directory('build/web');
  if (!buildDir.existsSync()) {
    print('build/web klasörü bulunamadı!');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8686);
  print('Sunucu http://localhost:8686 adresinde aktif!');

  final mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.mjs': 'application/javascript; charset=utf-8',
    '.wasm': 'application/wasm',
    '.json': 'application/json; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.otf': 'font/otf',
    '.ttf': 'font/ttf',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
  };

  await for (HttpRequest request in server) {
    try {
      String path = request.uri.path;
      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }

      final file = File('${buildDir.path}$path');
      if (await file.exists()) {
        final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
        final contentType = mimeTypes[ext] ?? 'application/octet-stream';
        
        request.response.headers.set('Content-Type', contentType);
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        await request.response.addStream(file.openRead());
        await request.response.close();
      } else {
        final indexFile = File('${buildDir.path}/index.html');
        request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        await request.response.addStream(indexFile.openRead());
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }
}
