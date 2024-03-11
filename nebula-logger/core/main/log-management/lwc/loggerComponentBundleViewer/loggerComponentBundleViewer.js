import { LightningElement, api } from 'lwc';

export default class LoggerComponentBundleViewer extends LightningElement {
    @api
    recordId;

    componentBundle = {
        DeveloperName: 'loggerLWCDemo',
        NamespacePrefix: null
    };
    componentResources = [
        {
            FilePath: 'lwc/loggerLWCDemo/loggerLWCDemo.js',
            Format: 'js',
            LightningComponentBundleId: '0RbKf000000YBSlKAO',
            Source: '<TODO>'
        },
        {
            FilePath: 'lwc/loggerLWCDemo/loggerLWCDemo.js-meta.xml',
            Format: 'js', // Yes, this returns js, not xml?!
            LightningComponentBundleId: '0RbKf000000YBSlKAO',
            Source: '<TODO>'
        },
        {
            FilePath: 'lwc/loggerLWCDemo/loggerLWCDemo.js-meta.html',
            Format: 'html',
            LightningComponentBundleId: '0RbKf000000YBSlKAO',
            Source: '<TODO>'
        }
    ];
}
