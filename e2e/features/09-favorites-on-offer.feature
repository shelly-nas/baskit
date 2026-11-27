@FR-010
Feature: Favorites on offer
  When something you buy often is on offer, the Search tab shows it first.
  Which offers exist changes every week, so the scenario takes a product
  that is on offer now and makes it a favorite.

  Scenario: A favorite on offer shows on the Search tab
    Given I am signed in with a new account named "Sam"
    And a product on offer now is one of my favorites
    When I open Baskit again
    Then I see that favorite under "Your favorites on offer"
