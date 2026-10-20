{{flutter_js}}
{{flutter_build_config}}

// Same as Flutter's default bootstrap, plus: the loading screen in
// index.html stays up until the game draws its first frame.
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (!splash) return;
    splash.classList.add('done');
    setTimeout(() => splash.remove(), 400);
  },
});
