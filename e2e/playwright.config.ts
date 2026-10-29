import { defineConfig, devices } from "@playwright/test";
import { cucumberReporter, defineBddConfig } from "playwright-bdd";

// The scenarios in features/ are the source; bddgen turns them into
// Playwright tests in .features-gen/ (generated, not committed).
const testDir = defineBddConfig({
  features: "features/**/*.feature",
  steps: "steps/**/*.ts",
});

export default defineConfig({
  testDir,
  // The app talks to one shared acc database; scenarios use their own
  // accounts, but running them one by one keeps the log easy to follow.
  workers: 1,
  timeout: 60_000,
  expect: { timeout: 15_000 },
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ["list"],
    cucumberReporter("html", { outputFile: "reports/scenarios.html" }),
    ["html", { outputFolder: "reports/playwright", open: "never" }],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? "http://baskit-acc.shelly-nas.nl",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
});
