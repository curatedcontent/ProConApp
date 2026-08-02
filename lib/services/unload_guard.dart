import 'unload_guard_native.dart'
    if (dart.library.html) 'unload_guard_web.dart' as platform;

/// Warns the user before they close/refresh the tab when [shouldWarn]
/// returns true at that moment (e.g. they have local-only entries and
/// aren't signed in, so nothing is backed up yet).
void registerUnloadGuard(bool Function() shouldWarn) =>
    platform.registerUnloadGuard(shouldWarn);
