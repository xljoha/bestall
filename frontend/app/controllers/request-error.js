import Ember from 'ember';

const {
    computed,
    inject
} = Ember;

export default Ember.Controller.extend({
    i18n : inject.service(),

    reason: computed('errors', function(){
        const dictionary = this.get('i18n');
        const locale = this.get('i18n.locale');
        // the node 'request-errors' in the locale files contains nodes corresponding to the error code.
         const errors = this.get('errors').errors;

         let res = '';
         errors.map((obj) => {
         if(obj.code){
            const header = dictionary.t('request-errors.' + obj.code + '.header');
            let msg = dictionary.t('request-errors.' + obj.code + '.message');
            // todo: override 'Missing translation' in i18n, wherever that is?
            if(msg.string.indexOf('Missing translation:') > -1){
                msg = obj.detail;
            }
            res += `<h2>${header}</h2>
                    <p>${msg.string}</p>
            `;
         }else{
             // if obj doesent contain key 'code', obj equals koha user type => {categorycode: PE}
             console.log(obj);
         }
         });
         return res;
        //return dictionary.t('request-errors.');
    })
});

