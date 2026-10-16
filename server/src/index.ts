import { config } from "./config";
import { createApp } from "./app";
import { runMigrations } from "./context/migrations";

async function main(): Promise<void> {
  await runMigrations();
  createApp().listen(config.port, () => {
    console.log(`Baskit server listening on port ${config.port}`);
  });
}

main().catch((error) => {
  console.error("Baskit server failed to start:", error);
  process.exit(1);
});
