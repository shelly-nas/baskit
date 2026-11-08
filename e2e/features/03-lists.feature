@FR-003
Feature: Shopping lists
  Lists are kept in the account, so they are the same on every device.

  Background:
    Given I am signed in with a new account named "Hanna"

  Scenario: Create a list and add items
    When I create a list called "Weekend"
    And I add "Coffee" to the list
    And I add "Bread" to the list
    Then the list "Weekend" has 2 items

  Scenario: Check off an item
    Given I have a list called "Weekend" with "Coffee"
    When I open the list "Weekend"
    And I check off "Coffee"
    Then I see "Completed (1)"

  Scenario: Lists are kept in the account
    Given I have a list called "Weekend" with "Coffee"
    When I sign out and sign in again
    And I open the list "Weekend"
    Then I see "Coffee"
