import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        stone: "#F0EEE8",     // page background — warm, not the cliché cream
        ink: "#2A2825",       // primary text — soft black, not pure #000
        graphite: "#57534C",  // secondary text
        brass: "#A9832E",     // primary accent — pulled from an actual finish
        blacknickel: "#1C1B19", // dark accent / footer
        nickel: "#9B9992",    // borders, muted UI
        olive: "#5F6B45",     // in-stock indicator
        rust: "#9C4A32",      // low-stock / attention
      },
      fontFamily: {
        display: ["var(--font-display)", "serif"],
        body: ["var(--font-body)", "sans-serif"],
      },
      maxWidth: {
        prose: "68ch",
      },
    },
  },
  plugins: [],
};

export default config;
