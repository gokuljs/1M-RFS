import crypto from "node:crypto";

// 375 random bytes becomes 500 Base64 characters.
const generateCode = () =>
  crypto.randomBytes(375).toString("base64").substring(0, 500);

export { generateCode };
