import { test } from "node:test";
import assert from "node:assert/strict";
import { positiveInt } from "../config";

test("positiveInt uses the default when the variable is not set", () => {
  assert.equal(positiveInt("AUTH_RATE_LIMIT", undefined, 20), 20);
  assert.equal(positiveInt("AUTH_RATE_LIMIT", "", 20), 20);
});

test("positiveInt reads a whole number", () => {
  assert.equal(positiveInt("AUTH_RATE_LIMIT", "1000", 20), 1000);
});

// A typo must not silently switch the sign-in limit off (NaN never exceeds).
test("positiveInt refuses anything but a positive whole number", () => {
  for (const value of ["abc", "0", "-5", "1.5", "10x"]) {
    assert.throws(() => positiveInt("AUTH_RATE_LIMIT", value, 20), /AUTH_RATE_LIMIT/);
  }
});
