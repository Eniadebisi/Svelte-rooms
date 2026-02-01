import adapter from "@sveltejs/adapter-vercel";
import { vitePreprocess } from "@sveltejs/vite-plugin-svelte";

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://kit.svelte.dev/docs/integrations#preprocessors
  // for more information about preprocessors
  preprocess: vitePreprocess(),

  kit: {
    alias: {
      $lib: "./src/lib",
      "$lib/*": "./src/lib/*",
      $src: "./src",
      $static: "./static/",
      "$src/*": "./src/*",
      $db: "./src/lib/server/db.js",
      // "$logs": ["./logs"],
      $styles: "./src/scss/*",
      $modals: "./src/lib/modals",
    },
    // adapter-auto only supports some environments, see https://kit.svelte.dev/docs/adapter-auto for a list.
    // If your environment is not supported, or you settled on a specific environment, switch out the adapter.
    // See https://kit.svelte.dev/docs/adapters for more information about adapters.
    adapter: adapter(),
  },
};

export default config;
