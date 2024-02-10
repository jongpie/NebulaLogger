import { createElement } from 'lwc';
import LoggerPageSection from 'c/loggerPageSection';

describe('c-logger-page-section', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    test.todo('revisit how to test since data is passed using slots');

    // it('displays title and content', async () => {
    //     const element = createElement('c-logger-page-section', {
    //         is: LoggerPageSection
    //     });
    //     const elementContent = 'some content';
    //     const elementTitle = 'some content';
    //     element.content = elementContent;
    //     element.title = elementTitle;

    //     document.body.appendChild(element);

    //     const toggleIcon = element.shadowRoot.querySelector('lightning-icon');
    //     expect(toggleIcon.iconName).toBe('utility:chevrondown');
    //     const titleSlot = element.shadowRoot.querySelector('slot[name="title"]');
    //     expect(titleSlot.innerHTML).toBe(elementTitle);
    //     const contentSlot = element.shadowRoot.querySelector('slot[name="content"]');
    //     expect(contentSlot.innerHTML).toBe(elementContent);
    // });

    // it('toggles content when title is clicked', async () => {
    //     const element = createElement('c-logger-page-section', {
    //         is: LoggerPageSection
    //     });
    //     const elementContent = 'some content';
    //     element.content = elementContent;
    //     document.body.appendChild(element);
    //     const titleAction = element.shadowRoot.querySelector('button.slds-section__title-action');
    //     expect(titleAction).toBeTruthy();
    //     let contentSlot = element.shadowRoot.querySelector('slot[name="content"]');
    //     expect(contentSlot).toBeTruthy();
    //     let isContentExpectedToBeDisplayed = true;
    //     // Toggle the section content a few times to verify showing & hiding work as expected
    //     for (let i = 0; i < 5; i++) {
    //         isContentExpectedToBeDisplayed = !isContentExpectedToBeDisplayed;

    //         titleAction.click();

    //         await Promise.resolve('rerender template after button click');
    //         const contentContainer = element.shadowRoot.querySelector('.slds-section__content');
    //         const toggleIcon = element.shadowRoot.querySelector('lightning-icon');
    //         if (isContentExpectedToBeDisplayed) {
    //             expect(toggleIcon.iconName).toBe('utility:chevrondown');
    //             expect(contentContainer.className).not.toContain('slds-hide');
    //         } else {
    //             expect(toggleIcon.iconName).toBe('utility:chevronright');
    //             expect(contentContainer.className).toContain('slds-hide');
    //         }
    //     }
    // });
});
