---
title: GitHub Pages
layout: default
nav_order: 8
parent: Home
---

# GitHub Pages

This documentation site uses **[Just the Docs](https://just-the-docs.github.io/just-the-docs/)** (Jekyll **`remote_theme`**) and deploys with **GitHub Actions**.

## Enable Pages (repository admin)

1. In GitHub: **Settings** → **Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions** (not “Deploy from a branch”).
3. Merge or push **`main`** so workflow **`.github/workflows/pages.yml`** runs.

The workflow **Build** job runs **`bundle exec jekyll build`** and **Deploy** publishes **`_site`** via **`actions/deploy-pages`**.

## Local preview

```bash
cd FedoraRemix-LiveMedia
bundle install
bundle exec jekyll serve --livereload
```

Open **`http://127.0.0.1:4000/FedoraRemix-LiveMedia/`** (path must match **`baseurl`** in **`_config.yml`**).

## Site URL

After a successful deploy:

**`https://tmichett.github.io/FedoraRemix-LiveMedia/`**

If you fork the repo, update **`baseurl`**, **`url`**, and **`aux_links`** in **`_config.yml`** to match your GitHub username and repository name.
