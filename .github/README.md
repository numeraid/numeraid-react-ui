# GitHub Actions CI workflow

This repository uses a single CI workflow to validate code quality, build the production bundle, and publish the Docker image for the main branches.

## Workflow name

- CI

## Triggers

The workflow runs when:

- code is pushed to `main`
- code is pushed to `development`
- a pull request targets `main` or `development`
- it is triggered manually via the GitHub Actions UI (`workflow_dispatch`)

## Concurrency control

The workflow uses a concurrency group to prevent duplicate runs for the same ref and cancels any in-progress run when a newer one starts.

This reduces wasted compute time and keeps branch validation fast.

## Jobs

### 1. Lint

Runs on the latest Ubuntu image.

Steps:

- checks out the source code
- installs the correct Node.js version using `actions/setup-node`
- runs `npm ci --no-audit --no-fund`
- executes `npm run lint`

Purpose:

- enforce coding standards before the application is built
- prevent broken or low-quality changes from reaching the next stage

### 2. Build

Depends on the `lint` job.

Steps:

- checks out the source code
- sets up Node.js
- installs dependencies
- runs `npm run build`
- uploads the generated `dist` folder as a workflow artifact

Purpose:

- confirm the Vite production build succeeds
- preserve the compiled output for inspection or deployment pipelines

### 3. Docker publish

Depends on the `build` job.

This stage only runs on pushes to `main` or `development`, not on pull requests. That prevents forked PRs from trying to push container images using the default GitHub token.

Steps:

- checks out the source code
- prepares Docker Buildx
- authenticates to GHCR using `GITHUB_TOKEN`
- generates Docker tags and labels
- builds and pushes the image to GitHub Container Registry

Published tags:

- `latest` for the `main` branch
- `development` for the `development` branch
- a short commit SHA tag
- branch-based tag metadata

## Permissions

The workflow declares:

- `contents: read`
- `packages: write`

This is required so the workflow can read the repository and push container images to GHCR.

## Why this setup is better

Compared with a simpler workflow, this version improves reliability by:

- using a stable Node LTS version instead of an unnecessarily new runtime
- preventing Docker image pushes on pull requests
- limiting package publishing to the main branch workflow runs
- reusing the GitHub Actions cache for npm and Docker layers
- making artifact output explicit and easier to review

## Local validation

The same checks used by CI can be run locally:

```bash
npm ci
npm run lint
npm run build
```

## Files involved

- `.github/workflows/ci.yml` — the GitHub Actions workflow definition
- `Dockerfile` — the container image built by the workflow
- `package.json` — the scripts and dependency versions used by CI
