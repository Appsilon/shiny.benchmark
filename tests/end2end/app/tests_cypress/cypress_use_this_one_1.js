describe('Cypress test', () => {
  // Test that the app starts at all
  // Also it is needed to start other tests
  it('The app starts', () => {
    cy.visit('/');
  });

  // Test how long it takes to wait for out1
  it('Out1 time elapsed', () => {
    cy.get('#run1').click();
    cy.get('#out1', {timeout: 10000}).should('be.visible');
  });

  // Test how long it takes to wait for out2
  it('Out2 time elapsed', () => {
    cy.get('#run2').click();
    cy.get('#out2', {timeout: 10000}).should('be.visible');
  });

  // Test how long it takes to wait for out3
  it('Out3 time elapsed', () => {
    cy.get('#run3').click();
    cy.get('#out3', {timeout: 10000}).should('be.visible');
  });

  // Test if we have a title
  it('App has a title', () => {
    cy.contains('Measuring time in different commits').should('be.visible');
  });
});
