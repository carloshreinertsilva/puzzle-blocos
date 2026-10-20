{{flutter_js}}
{{flutter_build_config}}

// Same as Flutter's default bootstrap, plus: the loading screen in
// index.html stays up until the game draws its first frame.
//
// Flutter only runs the WebAssembly build on Chrome-based browsers by
// default. `?wasm=1` in the address also allows it on Safari and Firefox,
// to compare before turning it on for everyone.
const tryWasm = new URLSearchParams(location.search).has('wasm');
_flutter.loader.load({
  config: tryWasm ? { wasmAllowList: { webkit: true, gecko: true } } : {},
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (!splash) return;
    splash.classList.add('done');
    setTimeout(() => splash.remove(), 400);
  },
});
