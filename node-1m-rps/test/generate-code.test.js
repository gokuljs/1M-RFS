import assert from "node:assert/strict";
import test from "node:test";

import { generateCode } from "../utils/generate-code.js";

test("generateCode returns a 500-character Base64 code", () => {
  const code = generateCode();

  assert.equal(code.length, 500);
  assert.match(code, /^[A-Za-z0-9+/]{500}$/);
});
