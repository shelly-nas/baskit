import { expect } from "@playwright/test";
import { DEMO_PASSWORD, Given, newEmail, Then, When, type Account } from "./fixtures";

const PASSWORD = "e2e-password";

// ---- Opening the app and signing in ----

Given("I open Baskit", async ({ baskit }) => {
  await baskit.open();
});

When("I close Baskit and open it again", async ({ baskit }) => {
  await baskit.reopen();
});

When("I sign in as {string} with password {string}", async ({ baskit }, email: string, password: string) => {
  await baskit.signIn(email, password);
});

Given("I am signed in as {string}", async ({ baskit, world }, email: string) => {
  world.current = { name: email, email, password: DEMO_PASSWORD };
  await baskit.openSignedOut();
  await baskit.signIn(email, DEMO_PASSWORD);
  await baskit.expectSearchScreen();
});

Given("an account exists for {string}", async ({ baskit, world }, name: string) => {
  const account = await baskit.register({ name, email: newEmail(name), password: PASSWORD });
  world.accounts.set(name, account);
});

Given("I am signed in with a new account named {string}", async ({ baskit, world }, name: string) => {
  const account = await baskit.register({ name, email: newEmail(name), password: PASSWORD });
  world.accounts.set(name, account);
  world.current = account;
  await baskit.openSignedOut();
  await baskit.signIn(account.email, account.password);
  await baskit.expectSearchScreen();
});

When("I sign out", async ({ baskit }) => {
  await baskit.signOut();
});

When("I sign out and sign in again", async ({ baskit, world }) => {
  await baskit.signOut();
  await baskit.signIn(world.current!.email, world.current!.password);
  await baskit.expectSearchScreen();
});

When("I sign in with a wrong password {int} times", async ({ baskit, world }, times: number) => {
  const account = onlyAccount(world.accounts);
  world.current = account;
  for (let i = 0; i < times; i++) {
    await baskit.signIn(account.email, "wrong-password");
    await expect(baskit.text("Email or password is incorrect")).toBeAttached();
  }
});

When("I sign in with the right password", async ({ baskit, world }) => {
  await baskit.signIn(world.current!.email, world.current!.password);
});

// ---- Creating and changing an account ----

When("I create an account named {string} with a new email address", async ({ baskit, world }, name: string) => {
  const account: Account = { name, email: newEmail(name), password: PASSWORD };
  world.current = account;
  await createAccount(baskit, account);
});

When(
  "I create an account named {string} with email {string}",
  async ({ baskit }, name: string, email: string) => {
    await createAccount(baskit, { name, email, password: PASSWORD });
  },
);

When("I change my name to {string}", async ({ baskit }, name: string) => {
  await baskit.tab("Profile");
  await baskit.button("Change name").click();
  await baskit.answerDialog(name, "Save");
});

When("I delete my account with my password", async ({ baskit, world }) => {
  await baskit.tab("Profile");
  await baskit.button("Delete account").click();
  await baskit.answerDialog(world.current!.password, "Delete");
});

When("I go to my profile", async ({ baskit }) => {
  await baskit.tab("Profile");
});

// ---- What the user sees ----

Then("I see the sign-in screen", async ({ baskit }) => {
  await baskit.expectSignInScreen();
});

Then("I see the search screen", async ({ baskit }) => {
  await baskit.expectSearchScreen();
});

Then("I see the message {string}", async ({ baskit }, message: string) => {
  await expect(baskit.text(message)).toBeAttached();
});

Then("I see {string}", async ({ baskit }, text: string) => {
  await expect(baskit.text(text)).toBeAttached();
});

Then("I do not see {string}", async ({ baskit }, text: string) => {
  // Wait until the screen is there, then check the text is absent.
  await expect(baskit.text("ACCOUNT")).toBeAttached();
  await expect(baskit.page.getByText(text, { exact: true })).toHaveCount(0);
});

Then("my profile shows the name {string}", async ({ baskit }, name: string) => {
  await baskit.tab("Profile");
  await expect(baskit.text(name)).toBeAttached();
});

Then("my sign-in stays valid for at least {int} days", async ({ baskit }, days: number) => {
  const token = await baskit.storedToken();
  expect(token, "the app keeps a sign-in token").toBeTruthy();
  const payload = JSON.parse(Buffer.from(token!.split(".")[1], "base64url").toString());
  const validDays = (payload.exp * 1000 - Date.now()) / 86_400_000;
  expect(validDays).toBeGreaterThanOrEqual(days);
});

Then("I can no longer sign in with that account", async ({ baskit, world }) => {
  const res = await baskit.login(world.current!.email, world.current!.password);
  expect(res.status()).toBe(401);
});

async function createAccount(baskit: import("./fixtures").Baskit, account: Account) {
  await baskit.button("New here? Create an account").click();
  await baskit.fill("Name", account.name);
  await baskit.fill("Email", account.email);
  await baskit.fill("Password", account.password);
  await baskit.button("Create account").click();
}

function onlyAccount(accounts: Map<string, Account>): Account {
  expect(accounts.size, "this step needs exactly one account").toBe(1);
  return [...accounts.values()][0];
}
