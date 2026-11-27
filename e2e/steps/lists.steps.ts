import { expect } from "@playwright/test";
import { escape, Given, Then, When } from "./fixtures";

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
    world.lists.set(name, await baskit.createList(world.current!, name, [item]));
    // The app loads the lists at start; open it again to see the new one.
    await baskit.reopen();
  },
);

When(
  "{string} is added to the list {string} on another device",
  async ({ baskit, world }, item: string, list: string) => {
    await baskit.addItem(world.current!, world.lists.get(list)!, item);
  },
);

Then("I see {string} within {int} seconds", async ({ baskit }, text: string, seconds: number) => {
  await expect(baskit.text(text)).toBeAttached({ timeout: seconds * 1000 });
});

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

// ---- Suggestions ----

When("I type {string} to add an item", async ({ baskit }, text: string) => {
  await baskit.fill("Add an item", text);
});

When("I pick the suggestion {string}", async ({ baskit }, name: string) => {
  await baskit.button(name).click();
});

Then("{string} is on the list again, not checked off", async ({ baskit }, item: string) => {
  const open = baskit.page.getByRole("group", { name: item }).getByRole("checkbox", { name: "Mark as done" });
  await expect(open).toHaveCount(1);
});

// ---- Favorites ----

When("I make {string} a favorite", async ({ baskit }, item: string) => {
  await baskit.page.getByRole("group", { name: item }).click();
  await baskit.button("Add to favorites").click();
});

When("I tap the favorite {string}", async ({ baskit }, name: string) => {
  await baskit.button(`Add ${name}`).click();
});

// ---- In the shop ----

Then("I see {string} above {string}", async ({ baskit }, upper: string, lower: string) => {
  const top = async (text: string) => {
    const box = await baskit.text(text).boundingBox();
    expect(box, `"${text}" is on screen`).not.toBeNull();
    return box!.y;
  };
  await expect(baskit.text(lower)).toBeAttached();
  expect(await top(upper)).toBeLessThan(await top(lower));
});

When("I undo it", async ({ baskit }) => {
  await baskit.button("Undo").click();
});

// ---- Favorites on offer ----

Given("a product on offer now is one of my favorites", async ({ baskit, world }) => {
  const search = await baskit.request.get("/api/discounts/search?limit=1");
  expect(search.status(), await search.text()).toBe(200);
  const name: string = (await search.json()).items[0].name;
  const res = await baskit.request.post("/api/favorites", {
    headers: { Authorization: `Bearer ${world.current!.token}` },
    data: { name },
  });
  expect(res.status(), await res.text()).toBe(201);
  world.favoriteName = name;
});

When("I open Baskit again", async ({ baskit }) => {
  await baskit.reopen();
});

Then("I see that favorite under {string}", async ({ baskit, world }, title: string) => {
  await expect(baskit.text(title)).toBeAttached();
  await expect(baskit.text(new RegExp(escape(world.favoriteName!)))).toBeAttached();
});

// ---- Offline ----

When("the connection drops", async ({ baskit }) => {
  await baskit.page.context().setOffline(true);
});

When("the connection is back", async ({ baskit }) => {
  await baskit.page.context().setOffline(false);
});

Then("I see that I am offline with {int} change(s) waiting", async ({ baskit }, count: number) => {
  await expect(baskit.text(new RegExp(`^Offline:.*${count} changes? waiting`))).toBeAttached();
});

Then("I no longer see that I am offline within {int} seconds", async ({ baskit }, seconds: number) => {
  // The same lookup as "I see that I am offline", so this cannot pass early.
  await expect(baskit.text(/^Offline:/)).not.toBeAttached({ timeout: seconds * 1000 });
});

Then(
  "{string} is checked off in {string} on the server",
  async ({ baskit, world }, item: string, list: string) => {
    const items = await baskit.listItems(world.current!, world.lists.get(list)!);
    expect(items.find((i) => i.name === item)?.is_completed).toBe(true);
  },
);

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

/** The number in "123 offers" / "4567 products" above the results. */
async function resultCount(baskit: import("./fixtures").Baskit, unit: RegExp): Promise<number> {
  const label = baskit.text(new RegExp(`^\\d+ ${unit.source}$`));
  await expect(label).toBeAttached();
  const text = (await label.textContent()) || (await label.getAttribute("aria-label")) || "";
  return parseInt(text, 10);
}

When("I switch off {string}", async ({ baskit, world }, filter: string) => {
  await baskit.tab("Search");
  world.offerCount = await resultCount(baskit, /offers?/);
  await baskit.button(filter).click();
});

Then("I see products at their regular price", async ({ baskit, world }) => {
  // The catalog comes on top of the offers.
  await expect.poll(() => resultCount(baskit, /products?/)).toBeGreaterThan(world.offerCount!);
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
