export const CurrentPageReference = jest.fn();

const Navigate = Symbol('Navigate');
const GenerateUrl = Symbol('GenerateUrl');

export const NavigationMixin = Base => {
  return class extends Base {
    [Navigate](pageReference, replace) {
      const detailObj = {
        detail: {
          pageReference,
          replace
        }
      };
      this.dispatchEvent(new CustomEvent('navigate', detailObj));
    }
    [GenerateUrl](pageReference) {
      const detailObj = {
        detail: {
          pageReference
        }
      };
      this.dispatchEvent(new CustomEvent('generate', detailObj));
    }
  };
};
NavigationMixin.Navigate = Navigate;
NavigationMixin.GenerateUrl = GenerateUrl;
