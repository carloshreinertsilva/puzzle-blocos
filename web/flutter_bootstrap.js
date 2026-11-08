{{flutter_js}}
{{flutter_build_config}}

// Same as Flutter's default bootstrap, plus:
// - the loading screen in index.html (the opening art and a loading bar)
//   stays up until the game draws its first frame, then the bar fills up;
// - the WebAssembly build also runs on Safari (Flutter allows it only on
//   Chrome-based browsers by default; on the iPhone it is much smoother).
//   `?wasm=1` in the address also allows it on Firefox, to try it there.
const tryWasm = new URLSearchParams(location.search).has('wasm');
_flutter.loader.load({
  config: { wasmAllowList: { webkit: true, gecko: tryWasm } },
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (!splash) return;
    // The bar runs to the end, then the loading screen fades out.
    const barra = splash.querySelector('.barra i');
    if (barra) {
      barra.style.width = getComputedStyle(barra).width;
      barra.classList.add('cheia');
      requestAnimationFrame(() => { barra.style.width = '100%'; });
    }
    setTimeout(() => {
      splash.classList.add('done');
      setTimeout(() => splash.remove(), 400);
    }, 280);
  },
});
