import { createElement } from '@lwc/engine-dom';
import LoggerPageSection from 'c/loggerPageSection';

describe('c-logger-page-section', () => {
  let element;

  beforeEach(() => {
    element = createElement('c-logger-page-section', {
      is: LoggerPageSection
    });
    document.body.appendChild(element);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  describe('Initial State', () => {
    it('should render with correct initial CSS classes', () => {
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      expect(contentContainer).toBeTruthy();
      expect(contentContainer.className).toContain('slds-show');
      expect(contentContainer.className).not.toContain('slds-hide');
    });

    it('should render with correct initial icon', () => {
      const icon = element.shadowRoot.querySelector('lightning-icon');
      expect(icon).toBeTruthy();
      expect(icon.iconName).toBe('utility:chevrondown');
    });

    it('should render title and content slots', () => {
      const titleSlot = element.shadowRoot.querySelector('slot[name="title"]');
      const contentSlot = element.shadowRoot.querySelector('slot[name="content"]');

      expect(titleSlot).toBeTruthy();
      expect(contentSlot).toBeTruthy();
    });

    it('should render the toggle button', () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      expect(toggleButton).toBeTruthy();
    });
  });

  describe('Getters', () => {
    it('should return correct sectionToggleClass when content is visible', () => {
      // Test the getter by checking the actual DOM state
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      expect(contentContainer.className).toContain('slds-section__content');
      expect(contentContainer.className).toContain('slds-show');
    });

    it('should return correct sectionToggleIcon when content is visible', () => {
      const icon = element.shadowRoot.querySelector('lightning-icon');
      expect(icon.iconName).toBe('utility:chevrondown');
    });
  });

  describe('toggleSection Method', () => {
    it('should toggle content visibility when called', async () => {
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      const icon = element.shadowRoot.querySelector('lightning-icon');

      // Verify initial state
      expect(contentContainer.className).toContain('slds-show');
      expect(icon.iconName).toBe('utility:chevrondown');

      // Call the method
      element.toggleSection();

      // Wait for the component to re-render
      await Promise.resolve();

      // Verify state changed
      expect(contentContainer.className).toContain('slds-hide');
      expect(icon.iconName).toBe('utility:chevronright');
    });

    it('should toggle content visibility multiple times', async () => {
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      const icon = element.shadowRoot.querySelector('lightning-icon');

      // First toggle - hide content
      element.toggleSection();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-hide');
      expect(icon.iconName).toBe('utility:chevronright');

      // Second toggle - show content
      element.toggleSection();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-show');
      expect(icon.iconName).toBe('utility:chevrondown');

      // Third toggle - hide content again
      element.toggleSection();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-hide');
      expect(icon.iconName).toBe('utility:chevronright');
    });
  });

  describe('User Interaction', () => {
    it('should toggle content when toggle button is clicked', async () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      const icon = element.shadowRoot.querySelector('lightning-icon');

      // Verify initial state
      expect(contentContainer.className).toContain('slds-show');
      expect(icon.iconName).toBe('utility:chevrondown');

      // Click the toggle button
      toggleButton.click();

      // Wait for the component to re-render
      await Promise.resolve();

      // Verify state changed
      expect(contentContainer.className).toContain('slds-hide');
      expect(icon.iconName).toBe('utility:chevronright');
    });

    it('should update CSS classes when toggle button is clicked', async () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');

      // Verify initial classes
      expect(contentContainer.className).toContain('slds-show');
      expect(contentContainer.className).not.toContain('slds-hide');

      // Click the toggle button
      toggleButton.click();

      // Wait for the component to re-render
      await Promise.resolve();

      // Verify classes changed
      expect(contentContainer.className).toContain('slds-hide');
      expect(contentContainer.className).not.toContain('slds-show');
    });

    it('should toggle back to visible when clicked again', async () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');

      // First click - hide content
      toggleButton.click();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-hide');

      // Second click - show content
      toggleButton.click();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-show');
    });
  });

  describe('DOM Structure', () => {
    it('should have correct section structure', () => {
      const section = element.shadowRoot.querySelector('.slds-section');
      expect(section).toBeTruthy();
      expect(section.className).toContain('slds-is-open');
      expect(section.className).toContain('slds-m-vertical_none');
    });

    it('should have correct title structure', () => {
      const title = element.shadowRoot.querySelector('h3.slds-section__title');
      expect(title).toBeTruthy();
      expect(title.className).toContain('slds-truncate');
      expect(title.className).toContain('slds-p-around_xx-small');
      expect(title.className).toContain('slds-theme_shade');
    });

    it('should have correct layout structure', () => {
      const layout = element.shadowRoot.querySelector('lightning-layout');
      expect(layout).toBeTruthy();
      expect(layout.className).toContain('slds-p-horizontal_medium');

      const layoutItem = element.shadowRoot.querySelector('lightning-layout-item');
      expect(layoutItem).toBeTruthy();
      expect(layoutItem.size).toBe('12');
    });
  });

  describe('Edge Cases', () => {
    it('should handle rapid clicking', async () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');

      // Rapidly click multiple times
      toggleButton.click();
      toggleButton.click();
      toggleButton.click();
      toggleButton.click();

      await Promise.resolve();

      // Should end up in a consistent state
      expect(contentContainer.className).toContain('slds-section__content');
      expect(contentContainer.className.includes('slds-show') || contentContainer.className.includes('slds-hide')).toBe(true);
    });

    it('should maintain state consistency between DOM and getters', async () => {
      const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
      const icon = element.shadowRoot.querySelector('lightning-icon');

      // Test initial state consistency
      expect(contentContainer.className).toContain('slds-show');
      expect(icon.iconName).toBe('utility:chevrondown');

      // Toggle and test consistency
      element.toggleSection();
      await Promise.resolve();

      expect(contentContainer.className).toContain('slds-hide');
      expect(icon.iconName).toBe('utility:chevronright');
    });
  });

  describe('Accessibility', () => {
    it('should have proper button semantics', () => {
      const toggleButton = element.shadowRoot.querySelector('button.slds-section__title-action');
      expect(toggleButton).toBeTruthy();
      expect(toggleButton.tagName).toBe('BUTTON');
    });

    it('should have proper heading structure', () => {
      const heading = element.shadowRoot.querySelector('h3');
      expect(heading).toBeTruthy();
      expect(heading.tagName).toBe('H3');
    });
  });
});
