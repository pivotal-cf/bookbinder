Feature: Support slim templating language
  In order to offer an alternative to Haml

  Scenario: Rendering Scss in a Slim filter
    Given the Server is running at "slim-app"
    When I go to "/scss.html"
    Then I should see "html, body, div"
    When I go to "/sass.html"
    Then I should see "html, body, div"
    When I go to "/error.html"
    Then I should see "Invalid CSS"