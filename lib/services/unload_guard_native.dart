/// No browser tab-close event exists on native platforms, so this is a
/// no-op there.
void registerUnloadGuard(bool Function() shouldWarn) {}
