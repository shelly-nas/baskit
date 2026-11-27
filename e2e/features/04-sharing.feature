@FR-003
Feature: Sharing a list
  A list can be shared with another Baskit account, for example someone in
  the same household.

  Scenario: Share a list with someone in my household
    Given an account exists for "Ilse"
    And I am signed in with a new account named "Joost"
    And I have a list called "Household" with "Milk"
    When I share the list "Household" with "Ilse"
    And "Ilse" signs in
    Then "Ilse" sees the list "Household" with "Milk"

  Scenario: Demo data: Bram sees the list Anna shared
    Given I am signed in as "bram@baskit.demo"
    When I go to my lists
    Then I see the list "Weekboodschappen"

  Scenario: Changes made elsewhere show up without reopening the list
    Given I am signed in with a new account named "Lotte"
    And I have a list called "Weekend" with "Coffee"
    And I open the list "Weekend"
    When "Milk" is added to the list "Weekend" on another device
    Then I see "Milk" within 20 seconds
