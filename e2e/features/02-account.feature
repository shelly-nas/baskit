@FR-001
Feature: Account
  New users create their own account; no email is needed to confirm it.
  Users can change their name and password and delete their account.

  Scenario: Create an account
    Given I open Baskit
    When I create an account named "Dana" with a new email address
    Then I see the search screen
    And my profile shows the name "Dana"

  Scenario: An email address can only be used once
    Given I open Baskit
    When I create an account named "Anna" with email "anna@baskit.demo"
    Then I see the message "An account with this email already exists"

  Scenario: Change my name
    Given I am signed in with a new account named "Eva"
    When I change my name to "Eva de Vries"
    Then my profile shows the name "Eva de Vries"

  Scenario: Delete my account
    Given I am signed in with a new account named "Finn"
    When I delete my account with my password
    Then I see the sign-in screen
    And I can no longer sign in with that account

  Scenario: The account locks after 10 wrong passwords
    Given an account exists for "Gijs"
    And I open Baskit
    When I sign in with a wrong password 10 times
    And I sign in with the right password
    Then I see the message "Too many failed attempts, try again in 15 minutes"
