import Ember from 'ember';

export default Ember.Component.extend({

  filteredLoanTypes: Ember.computed('loanTypes', 'item.{itemType,notForLoan}', function() {

    const itemType = this.get('item.itemType');
    const notForLoan = this.get('item.notForLoan');
    const loanTypes = this.get('loanTypes');
    /*
        let filteredLoanTypes = loanTypes.filter(function(type) {
          if (type.id === 1) {
            return (itemType !== '8' && itemType !== '17' && notForLoan !== '-3');
          } else {
            return true;
          }
        });*/

    let filteredLoanTypes = loanTypes.map((type) => {
      type.set('disabled', false);
      if (type.id === 1) {
        if (itemType == '8' || itemType == '17' || notForLoan == '-3') {
          type.set('disabled', true);
        }
      }
    });

    return filteredLoanTypes;

  }),

  didInsertElement() {
    // First get the filtered list
    const filteredLoanTypes = this.get('filteredLoanTypes');
    const selectedItem = this.get('selectedItem');
    let defaultValue = filteredLoanTypes.get('firstObject').id;

    // Check if anything is selected
    if (selectedItem) {
      // Then check if what is selected is in the filtered list, and if so, keep that selected
      if (filteredLoanTypes.findBy('id', selectedItem)) {
        return;
      }
    }
    // If nothing is selected, or what is selected is not in the list, set a new default value
    this.get('onSelect')(defaultValue);
  }

});