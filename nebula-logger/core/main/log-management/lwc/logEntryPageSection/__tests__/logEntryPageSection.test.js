import { createElement } from '@lwc/engine-dom';
import LogEntryPageSection from 'c/logEntryPageSection';

describe('c-log-entry-page-section', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  test.todo('revisit how to test since data is passed using slots and wire service');

  // it('displays section title and content when data is available', async () => {
  //     const element = createElement('c-log-entry-page-section', {
  //         is: LogEntryPageSection
  //     });
  //     element.recordId = 'test-record-id';
  //     element.sectionType = 'Message';
  //     document.body.appendChild(element);
  //     
  //     // Wait for the component to load
  //     await Promise.resolve();
  //     
  //     const sectionTitle = element.shadowRoot.querySelector('span[slot="title"]');
  //     expect(sectionTitle).toBeTruthy();
  // });
});
