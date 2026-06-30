import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { resolveReferenceImages } from "../server/resolve-reference-images.js";

const dir = mkdtempSync(join(tmpdir(), "cobabaai-ref-"));
const pngPath = join(dir, "test.png");
writeFileSync(pngPath, Buffer.from([0x89, 0x50, 0x4e, 0x47]));

const images = resolveReferenceImages({ referenceImagePaths: [pngPath] });
const ok =
  images.length === 1 && images[0].startsWith("data:image/png;base64,");

rmSync(dir, { recursive: true, force: true });
console.log(ok ? "PASS resolveReferenceImages" : "FAIL resolveReferenceImages");
process.exit(ok ? 0 : 1);
