import 'dart:html' as html;

/// Registers a browser tab-close/refresh guard. Browsers only allow a
/// generic native "leave site?" confirmation - custom text isn't permitted
/// for security reasons, so [shouldWarn] just decides whether to show it.
void registerUnloadGuard(bool Function() shouldWarn) {
  html.window.onBeforeUnload.listen((event) {
    if (shouldWarn()) {
      (event as html.BeforeUnloadEvent).returnValue = '';
    }
  });
}
