import React from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: '⚡ Multi-Platform Logging',
    description: (
      <>
        Log consistently across Apex, Lightning Web Components, Aura Components,
        Flow, and OmniStudio. One unified API for all Salesforce development contexts.
      </>
    ),
  },
  {
    title: '🚀 Event-Driven Architecture',
    description: (
      <>
        Built on Platform Events for async, scalable logging. No impact on user
        transactions. Handles 10,000+ logs/hour with minimal governor limit usage.
      </>
    ),
  },
  {
    title: '🏷️ Smart Organization',
    description: (
      <>
        Organize logs with tags and scenarios. Tag entries for filtering,
        track business processes with scenarios. Powerful search and querying.
      </>
    ),
  },
  {
    title: '🔒 Data Protection',
    description: (
      <>
        Built-in data masking for sensitive information. Automatically masks
        credit cards, SSNs, and custom patterns. GDPR and compliance-ready.
      </>
    ),
  },
  {
    title: '🔧 Extensible',
    description: (
      <>
        Plugin framework for custom functionality. Add Slack notifications,
        Big Object archiving, custom alerting. Build your own plugins in Apex or Flow.
      </>
    ),
  },
  {
    title: '📊 Production-Ready',
    description: (
      <>
        Used by thousands of Salesforce orgs. 90%+ test coverage, comprehensive
        documentation, active community. Open source with MIT license.
      </>
    ),
  },
];

function Feature({title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
