describe('Cypress test', () => {
  it('Out1 time elapsed - 2', () => {
    cy.visit('/');
    cy.get('#run1').click();
    cy.get('#out1', {timeout: 10000}).should('be.visible');
  });

  // Test how long it takes to wait for out2
  it('Out2 time elapsed - 2', () => {
    cy.get('#run2').click();
    cy.get('#out2', {timeout: 10000}).should('be.visible');
  });

  // Test how long it takes to wait for out3
  it('Out3 time elapsed - 2', () => {
    cy.get('#run3').click();
    cy.get('#out3', {timeout: 10000}).should('be.visible');
  });
});
