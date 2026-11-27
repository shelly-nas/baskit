@FR-006
Feature: In the shop
  The open items of a list are grouped in the order of a walk through the
  shop, and a wrong tap is easy to undo.

  Background:
    Given I am signed in with a new account named "Noor"
    And I have a list called "Weekend" with "Wc-papier"
    And I open the list "Weekend"

  Scenario: Items are in the order of the shop
    When I add "Appels" to the list
    Then I see "Vegetables and fruit" above "Household"
    And I see "Appels" above "Wc-papier"

  Scenario: Undo checking off an item
    When I check off "Wc-papier"
    And I undo it
    Then "Wc-papier" is on the list again, not checked off
