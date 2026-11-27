@FR-001
Feature: Sign in
  Baskit needs an account: lists live on the server so they can be shared.
  The app starts on the sign-in screen and, once signed in, stays signed in
  on this device until the user signs out.

  Scenario: The app starts on the sign-in screen
    When I open Baskit
    Then I see the sign-in screen

  Scenario: Sign in with a demo account
    Given I open Baskit
    When I sign in as "anna@baskit.demo" with password "baskit-demo"
    Then I see the search screen

  Scenario: A wrong password is refused
    Given I open Baskit
    When I sign in as "anna@baskit.demo" with password "not-the-password"
    Then I see the message "Email or password is incorrect"
    And I see the sign-in screen

  Scenario: Stay signed in when coming back later
    Given I am signed in as "anna@baskit.demo"
    When I close Baskit and open it again
    Then I see the search screen
    And my sign-in stays valid for at least 300 days

  Scenario: Sign out
    Given I am signed in as "anna@baskit.demo"
    When I sign out
    Then I see the sign-in screen
    When I close Baskit and open it again
    Then I see the sign-in screen

  Scenario: A disabled account cannot sign in
    Given I open Baskit
    When I sign in as "cees@baskit.demo" with password "baskit-demo"
    Then I see the message "This account has been disabled"
