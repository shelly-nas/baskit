import { expect, type APIRequestContext, type Locator, type Page } from "@playwright/test";
import { test as base, createBdd } from "playwright-bdd";

/** The password of every demo account in database/seed-demo.sql. */
export const DEMO_PASSWORD = "baskit-demo";

export type Account = { name: string; email: string; password: string; token?: string };

/**
 * What a scenario remembers between its steps: the accounts it created (by
 * name) and the one that is signed in in the browser.
 */
export class World {
  accounts = new Map<string, Account>();
  current?: Account;
}

export const test = base.extend<{ world: World; baskit: Baskit }>({
  world: async ({}, use) => use(new World()),
  baskit: async ({ page, request }, use) => use(new Baskit(page, request)),
});

export const { Given, When, Then } = createBdd(test);

/** A fresh email address per run, so scenarios never trip over each other. */
export function newEmail(name: string): string {
  const unique = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
  return `e2e-${name.toLowerCase().replace(/\W+/g, "-")}-${unique}@baskit.test`;
}

/**
 * Drives the Flutter web app. Flutter draws on a canvas; with its
 * accessibility tree switched on, buttons, fields and texts become real
 * elements with roles and names that Playwright can find.
 */
export class Baskit {
  constructor(
    readonly page: Page,
    readonly request: APIRequestContext,
  ) {}

  async open(): Promise<void> {
    await this.page.goto("/");
    await this.enableSemantics();
  }

  /** Open the app on the sign-in screen, forgetting an earlier sign-in. */
  async openSignedOut(): Promise<void> {
    await this.page.goto("/");
    await this.page.evaluate(() => localStorage.clear());
    await this.reopen();
  }

  /** Close the app (unload it) and start it again; the browser storage stays. */
  async reopen(): Promise<void> {
    await this.page.goto("about:blank");
    await this.open();
  }

  private async enableSemantics(): Promise<void> {
    // Flutter hides a "Enable accessibility" button off-screen until the
    // first frame; clicking it builds the accessibility tree.
    const placeholder = this.page.locator("flt-semantics-placeholder");
    await placeholder.waitFor({ state: "attached", timeout: 30_000 });
    await placeholder.evaluate((el: HTMLElement) => el.click());
    await this.page.locator("flt-semantics").first().waitFor({ state: "attached" });
  }

  button(name: string | RegExp) {
    return this.page.getByRole("button", { name, exact: typeof name === "string" });
  }

  field(name: string) {
    return this.page.getByRole("textbox", { name });
  }

  /**
   * A text on screen. Flutter's accessibility texts are present but not
   * "visible" to Playwright, so check them with toBeAttached().
   */
  text(text: string | RegExp) {
    // Some texts are part of a label, such as a row in the users overview.
    const label = typeof text === "string" ? new RegExp(escape(text)) : text;
    return this.page
      .getByText(text, { exact: typeof text === "string" })
      .or(this.page.getByLabel(label))
      .first();
  }

  async fill(name: string, value: string): Promise<void> {
    await this.type(this.field(name), value);
  }

  /**
   * Flutter swallows synthetic key presses, and fill() does not reach it
   * either. It does read the field on an "input" event, so focus the field,
   * set its value and send that event, like a paste would.
   */
  async type(field: Locator, value: string): Promise<void> {
    await field.click();
    await expect(field).toBeFocused();
    await field.evaluate((el: HTMLInputElement, text) => {
      el.value = text;
      el.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: text }));
    }, value);
  }

  async signIn(email: string, password: string): Promise<void> {
    await this.fill("Email", email);
    await this.fill("Password", password);
    await this.button("Sign in").click();
  }

  async expectSignInScreen(): Promise<void> {
    await expect(this.button("New here? Create an account")).toBeVisible();
    await expect(this.field("Email")).toBeVisible();
  }

  async expectSearchScreen(): Promise<void> {
    await expect(this.text("Find the best offers across all supermarkets")).toBeAttached();
  }

  /** Go to a tab, leaving a screen opened on top of the tabs (a list, the users overview). */
  async tab(name: "Search" | "Lists" | "Profile"): Promise<void> {
    const back = this.button("Back");
    while ((await back.count()) > 0) {
      await back.first().click();
    }
    await this.button(name).click();
  }

  async signOut(): Promise<void> {
    await this.tab("Profile");
    await this.button("Log Out").click();
    await this.expectSignInScreen();
  }

  /** Fill the single text field of an open dialog and press its button. */
  async answerDialog(value: string, confirm: string): Promise<void> {
    await this.type(this.page.getByRole("textbox").last(), value);
    await this.button(confirm).click();
  }

  /**
   * A card on the Lists tab. Its label starts with the list name, then
   * "<done>/<total> items completed". It holds its own options button, so
   * Flutter makes the card a group rather than a button.
   */
  listCard(name: string, details = "") {
    const label = new RegExp(`^${escape(name)}\\b${details}`);
    return this.page.getByRole("group", { name: label }).or(this.page.getByRole("button", { name: label })).first();
  }

  async openList(name: string): Promise<void> {
    await this.tab("Lists");
    await this.listCard(name).click();
    await this.expectListOpen(name);
  }

  /** The list screen's title: the name, and for a shared list who shares it. */
  async expectListOpen(name: string): Promise<void> {
    await expect(this.page.getByRole("heading", { name: new RegExp(`^${escape(name)}\\b`) })).toBeAttached();
  }

  // ---- Test data through the API, for the "Given" steps ----

  async register(account: Account): Promise<Account> {
    const res = await this.request.post("/api/auth/register", {
      data: { displayName: account.name, email: account.email, password: account.password },
    });
    expect(res.status(), await res.text()).toBe(201);
    account.token = (await res.json()).token;
    return account;
  }

  async login(email: string, password: string) {
    return this.request.post("/api/auth/login", { data: { email, password } });
  }

  async createList(account: Account, name: string, items: string[]): Promise<void> {
    const headers = { Authorization: `Bearer ${account.token}` };
    const res = await this.request.post("/api/lists", { headers, data: { name } });
    expect(res.status(), await res.text()).toBe(201);
    const list = await res.json();
    for (const item of items) {
      const added = await this.request.post(`/api/lists/${list.id}/items`, { headers, data: { name: item } });
      expect(added.status(), await added.text()).toBe(201);
    }
  }

  /** The sign-in token the app keeps in the browser (shared_preferences). */
  async storedToken(): Promise<string | undefined> {
    return this.page.evaluate(() => {
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)!;
        if (key.endsWith("baskit.auth.token")) return JSON.parse(localStorage.getItem(key)!);
      }
      return undefined;
    });
  }
}

export function escape(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
