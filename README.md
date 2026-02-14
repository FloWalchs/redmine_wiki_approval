# Redmine Wiki Approval Plugin

[![build](https://github.com/FloWalchs/redmine_wiki_approval/actions/workflows/build.yml/badge.svg)](https://github.com/FloWalchs/redmine_wiki_approval/actions/workflows/build.yml)
[![Last release](https://img.shields.io/github/v/release/FloWalchs/redmine_wiki_approval?label=latest%20release&logo=github&style=flat-square)](https://github.com/FloWalchs/redmine_wiki_approval/releases/latest)
[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat-square)](http://www.redmine.org/plugins/redmine-wiki-approval)
![Redmine](https://img.shields.io/badge/redmine->=4.1-blue?logo=redmine&logoColor=%23B32024&labelColor=f0f0f0&link=https%3A%2F%2Fwww.redmine.org)
[![codecov](https://codecov.io/gh/FloWalchs/redmine_wiki_approval/graph/badge.svg?token=17Z5COBFM1)](https://codecov.io/gh/FloWalchs/redmine_wiki_approval)

This plugin adds an approval workflow to the wiki, allowing teams to review, approve, and control changes before they are published. It supports drafts, multi‑step approval processes, role‑based permissions, and status tracking to ensure content quality and traceability in collaborative documentation.

## 🧠 How it works

This plugin does **not** replace Redmine's wiki versioning.

- Every edit is saved as a normal Redmine wiki version
- Drafts and unapproved changes remain private
- Only **approved versions** are displayed as the public wiki page
- Viewers are automatically redirected to the latest approved version
- Permission 'View wiki history' should be enabled for the redirection

## 🌟 Features

- **Draft-Based Editing** – Work on changes without publishing them
- **Multi-Step Approval Workflow** – Configurable approval steps before publishing
- **Approval Activity View** – Track approval status by redmine activity feed
- **Role-Based Permissions** – Control who can draft, approve, or publish
- **Email Notifications** – Notifications for status and step changes
- **Per‑Project or Global Settings** – Configure behavior globally or individually per project, such as enabling approval requirements, drafts, or mandatory comments.
- **Mandatory Save Comment** – Requires users to enter a comment when saving Wiki content (configurable on/off)

## 🔐 Permissions Overview

| Permission           | Description                      |
| -------------------- | -------------------------------- |
| Manage Wiki approval | Configure workflow and settings  |
| Start approval       | Begin approval workflow          |
| Grant approval       | Approve a workflow step          |
| Forward approval     | Move to another approver         |
| View draft           | View unpublished versions        |
| Create draft         | Create unpublished wiki versions |

## 💡 Typical Use Case

1. Author creates or edits a wiki page as a draft
2. Changes are reviewed in one or more approval steps
3. Reviewers approve or reject the changes
4. Once approved, the page becomes publicly visible
5. Older versions remain accessible for audit and rollback

## 🌐 Internationalization
Supports 14+ languages including:
- English, Japanese, German, French, Spanish, Italian
- Portuguese, Russian, Korean, Chinese, and more

## 📋 Requirements

- **Redmine**: 4.1 or higher
- **Ruby**: 2.6 or higher
- **Rails**: Compatible with Redmine's Rails version

## 🚀 Installation

```bash
cd $REDMINE_ROOT/plugins
git clone https://github.com/FloWalchs/redmine_wiki_approval.git
cd $REDMINE_ROOT
bundle install
rake bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```
Restart your Redmine server to load the plugin.
Enable the Module "Wiki approval" per project

## ⚙️ Plugin/Project Configuration

1. Navigate to **Administation → Wiki approval**
   - Settings can be configured per project or system-wide
2. Navigate to **Project Settings → Wiki approval**
   - enable the modul per project
3. Available options:
     - Wiki comment required 
     - Wiki draft enabled
     - Wiki approval enabled
       - Approval required
       - Approval workflow for next version (required)

## ❌ Uninstall

```bash
cd $REDMINE_ROOT
bundle exec rake redmine:plugins:migrate NAME=redmine_wiki_approval VERSION=0 RAILS_ENV=production
```

## 🤝 Contributing
Pull requests, translations, and feedback are welcome.

## 📜 License
MIT License
