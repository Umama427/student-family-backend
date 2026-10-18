import 'dart:html' as html;

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}