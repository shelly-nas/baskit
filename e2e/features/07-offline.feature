@FR-007
Feature: Offline
  In the shop the connection can drop. The open app keeps working: changes
  are kept on the device and sent when the connection is back.

  Scenario: Check off an item without a connection
    Given I am signed in with a new account named "Mila"
    And I have a list called "Weekend" with "Coffee"
    And I open the list "Weekend"
    When the connection drops
    And I check off "Coffee"
    Then I see "Completed (1)"
    And I see that I am offline with 1 change waiting
    When the connection is back
    Then I no longer see that I am offline within 20 seconds
    And "Coffee" is checked off in "Weekend" on the server
