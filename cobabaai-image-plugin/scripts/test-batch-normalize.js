import { normalizeBatchInput, resolveBatchItemReferences } from "../server/batch-normalize.js";

const items = normalizeBatchInput({
  items: [
    { prompt: "a", referenceImagePaths: ["/p1.jpg"] },
    { prompt: "b", referenceImagePaths: ["/p2.jpg"] },
  ],
});
const okItems =
  items.length === 2 &&
  items[0].referenceImagePaths[0] === "/p1.jpg" &&
  items[1].referenceImagePaths[0] === "/p2.jpg";

const legacy = normalizeBatchInput({
  prompts: ["x", "y"],
  referenceImagePaths: ["/shared.jpg"],
});
const okLegacy =
  legacy.length === 2 &&
  legacy[0].prompt === "x" &&
  legacy[0].referenceImagePaths[0] === "/shared.jpg";

const shared = ["data:image/png;base64,abc"];
const fallback = resolveBatchItemReferences({}, shared);
const okFallback = fallback === shared;

const pass = okItems && okLegacy && okFallback;
console.log(pass ? "PASS batch-normalize" : "FAIL batch-normalize");
process.exit(pass ? 0 : 1);
