@FR-002
Feature: Search offers
  Offers come from the supermarket-scraper. Which offers exist changes every
  week, so these scenarios only check that searching works.

  Background:
    Given I am signed in as "anna@baskit.demo"

  Scenario: The search screen shows current offers
    Then I see offers from the supermarkets

  Scenario: Add an offer to a list
    Given I am signed in with a new account named "Kees"
    When I add the first offer to a new list "Groceries"
    Then the list "Groceries" has 1 item
