import { expect } from "@playwright/test";
import { Given, Then, When } from "./fixtures";

// ---- Lists and items ----

When("I go to my lists", async ({ baskit }) => {
  await baskit.tab("Lists");
});

When("I create a list called {string}", async ({ baskit }, name: string) => {
  await baskit.tab("Lists");
  await baskit.button("New list").click();
  await baskit.answerDialog(name, "Create");
  // A new list opens straight away.
  await baskit.expectListOpen(name);
});

When("I add {string} to the list", async ({ baskit }, item: string) => {
  await baskit.fill("Add an item", item);
  await baskit.button("Add").click();
  await expect(baskit.text(item)).toBeAttached();
});

Given(
  "I have a list called {string} with {string}",
  async ({ baskit, world }, name: string, item: string) => {
    await baskit.createList(world.current!, name, [item]);
    // The app loads the lists at start; open it again to see the new one.
    await baskit.reopen();
  },
);

When("I open the list {string}", async ({ baskit }, name: string) => {
  await baskit.openList(name);
});

When("I check off {string}", async ({ baskit }, item: string) => {
  // Each item is a group named after it, with its check box inside.
  await baskit.page.getByRole("group", { name: item }).getByRole("checkbox", { name: "Mark as done" }).click();
});

Then("the list {string} has {int} item(s)", async ({ baskit }, name: string, count: number) => {
  await baskit.tab("Lists");
  await expect(baskit.listCard(name, `.*\\d+/${count} items? completed`)).toBeAttached();
});

Then("I see the list {string}", async ({ baskit }, name: string) => {
  await expect(baskit.listCard(name)).toBeAttached();
});

// ---- Sharing ----

When("I share the list {string} with {string}", async ({ baskit, world }, list: string, name: string) => {
  await baskit.openList(list);
  await baskit.button("List options").click();
  await baskit.page.getByRole("menuitem", { name: "Share" }).or(baskit.button("Share")).first().click();
  await baskit.fill("Email address", world.accounts.get(name)!.email);
  await baskit.button("Share").last().click();
  await expect(baskit.text(name)).toBeAttached();
});

When("{string} signs in", async ({ baskit, world }, name: string) => {
  const account = world.accounts.get(name)!;
  await baskit.openSignedOut();
  await baskit.signIn(account.email, account.password);
  await baskit.expectSearchScreen();
  world.current = account;
});

Then("{string} sees the list {string} with {string}", async ({ baskit }, _name: string, list: string, item: string) => {
  await baskit.openList(list);
  await expect(baskit.text(item)).toBeAttached();
});

// ---- Offers ----

Then("I see offers from the supermarkets", async ({ baskit }) => {
  await expect(baskit.page.getByRole("button", { name: /€/ }).first()).toBeVisible();
});

When("I add the first offer to a new list {string}", async ({ baskit }, name: string) => {
  await baskit.tab("Search");
  await baskit.page.getByRole("button", { name: /€/ }).first().click();
  await baskit.button("Add to list").click();
  await baskit.button("New list").click();
  await baskit.answerDialog(name, "Create");
  await expect(baskit.text(`Added to ${name}`)).toBeAttached();
});

// ---- Admin ----

When("I open the users overview", async ({ baskit }) => {
  await baskit.tab("Profile");
  await baskit.button("Users and usage").click();
});

Then("I see {string} in the overview", async ({ baskit }, email: string) => {
  await expect(baskit.text(email)).toBeAttached();
});
