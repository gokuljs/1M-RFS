import { Worker, isMainThread } from "worker_threads";
import { fileURLToPath } from "url";

if (isMainThread) {
  for (let i = 0; i < 10; i++) {
    new Worker(fileURLToPath(import.meta.url));
  }
} else {
  while (true) {}
}
