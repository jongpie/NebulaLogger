import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/quick-start">
            Get Started in 5 Minutes ⏱️
          </Link>
          <Link
            className="button button--outline button--secondary button--lg margin-left--md"
            to="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg70000001jUXAAY">
            Install Package 📦
          </Link>
        </div>
        <div className={styles.badges}>
          <img src="https://github.com/jongpie/NebulaLogger/actions/workflows/build.yml/badge.svg" alt="Build Status" />
          <img src="https://codecov.io/gh/jongpie/NebulaLogger/branch/main/graph/badge.svg?token=1DJPDRM3N4" alt="Code Coverage" />
          <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License MIT" />
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - ${siteConfig.tagline}`}
      description="The most robust observability solution for Salesforce. Built 100% natively, works with Apex, LWC, Flow, OmniStudio.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
