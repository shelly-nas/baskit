@FR-001
Feature: Admin
  Admins see who uses Baskit and can disable accounts.

  Scenario: An admin sees the users overview
    Given I am signed in as "admin@baskit.demo"
    When I open the users overview
    Then I see "anna@baskit.demo" in the overview

  Scenario: A normal user has no admin menu
    Given I am signed in as "anna@baskit.demo"
    When I go to my profile
    Then I do not see "Users and usage"
