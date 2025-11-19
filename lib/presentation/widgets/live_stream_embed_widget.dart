import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveStreamEmbedWidget extends StatefulWidget {
  const LiveStreamEmbedWidget({super.key});

  @override
  State<LiveStreamEmbedWidget> createState() => _LiveStreamEmbedWidgetState();
}

class _LiveStreamEmbedWidgetState extends State<LiveStreamEmbedWidget> with AutomaticKeepAliveClientMixin {

  late final WebViewController _controller;

  // --- 1. Define the Background Image URL ---
  final String backgroundImageUrl = "https://daawah.tv/app1.jpg"; // Main app background

  // --- 2. Enhanced Embed Code ---
  late final String embedCode;

  @override
  void initState() {
    super.initState();

    // Build the HTML code dynamically
    embedCode = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        body, html {
          margin: 0;
          padding: 0;
          height: 100%;
          overflow: hidden;
          background-color: #f0f0f0; /* Fallback background */
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
          color: white; /* Default text color */
        }
        .container {
          display: flex;
          flex-direction: column;
          height: 100vh; /* Full viewport height */
        }
        .video-container {
          width: 100%;
          /* Maintain 16:9 aspect ratio for video area */
          padding-top: 56.25%;
          position: relative;
          background-color: #000; /* Black background for video */
        }
        .video-container iframe {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          border: 0;
        }
        .info-panel {
          flex-grow: 1; /* Take remaining vertical space */
          background-image: url('$backgroundImageUrl'); /* App background */
          background-size: cover;
          background-position: center bottom; /* Adjust as needed */
          padding: 15px 20px;
          display: flex;
          flex-direction: column;
          box-sizing: border-box; /* Include padding in height */
          overflow-y: auto; /* Allow scrolling if content overflows */
        }
        .info-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 10px;
        }
        .title {
          font-size: 1.6em; /* Larger title */
          font-weight: bold;
          text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.6);
        }
        .heart-icon {
          font-size: 1.8em; /* Adjust size */
          color: #ff6b6b; /* Reddish color for heart */
          /* Simple heart symbol (could use SVG or icon font if needed) */
        }
        .info-line {
          display: flex;
          align-items: center;
          margin-bottom: 6px;
          font-size: 0.9em;
          opacity: 0.9;
          text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.5);
        }
        .info-line svg { /* Style for potential SVG icons */
            width: 16px;
            height: 16px;
            margin-right: 8px;
            fill: white; /* Make icons white */
        }
        .info-line span { /* For text next to icon */
           display: inline-block;
        }
        /* Basic icon placeholders (replace with actual SVG if possible) */
        .icon-tv::before { content: '📺'; margin-right: 8px; }
        .icon-time::before { content: '🕒'; margin-right: 8px; }

      </style>
    </head>
    <body>
      <div class="container">
        <div class="video-container">
          <iframe
            src="https://player.onestream.live/embed?token=NDA2NzYyNw==&type=up"
            scrolling="no"
            frameborder="0"
            allow="autoplay"
            allowfullscreen>
          </iframe>
        </div>
        <div class="info-panel">
          <div class="info-header">
            <div class="title">البث المباشر</div>
            <div class="heart-icon">&#x2661;</div> </div>
          <div class="info-line">
             <span class="icon-tv"></span> <span>قناة دعوة الفضائية</span>
          </div>
          <div class="info-line">
             <span class="icon-time"></span> <span>مستمر 24/7</span>
          </div>
          </div>
      </div>
       <script>
         // Optional JS if needed
       </script>
    </body>
    </html>
  ''';

    // Initialize WebView Controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black) // Initial background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            print("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow initial load and iframe source
            if (request.url == 'about:blank' || request.url.startsWith('https://player.onestream.live')) {
              return NavigationDecision.navigate;
            }
            // Prevent navigating away
            print("Prevented navigation to: ${request.url}");
            return NavigationDecision.prevent;
          },
        ),
      )
    // Load the built HTML string
      ..loadHtmlString(embedCode, baseUrl: null); // Use baseUrl: null for data URI
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Use AspectRatio to constrain the WebView height within the TabBarView
    // Adjust the ratio as needed (e.g., 9/16 for portrait video or less for more info panel space)
    return AspectRatio(
      aspectRatio: MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height * 0.8), // Adjust height dynamically or use a fixed ratio
      child: WebViewWidget(controller: _controller),
    );
  }
}