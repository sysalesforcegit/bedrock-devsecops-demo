# Bedrock Badge Demo — Setup Checklist

All project files are already created. This checklist gets you from zero to a running pipeline.

---

## PART 1: Install Tools (do while VS Code downloads)

- [ ] **Node.js** — download LTS from nodejs.org, install
- [ ] **Salesforce CLI** — run in Terminal:
      `npm install --global @salesforce/cli@latest`
      Verify: `sf --version`
- [ ] **VS Code** — download from code.visualstudio.com
- [ ] **Salesforce Extension Pack (Expanded)** — install from VS Code Extensions panel
- [ ] **Git** — verify with `git --version` (pre-installed on Mac)

---

## PART 2: Set Up Your Two Salesforce Orgs

> Your Trailhead Developer Edition orgs work fine. You need TWO orgs:
> - **Org 1 (Dev)** — where you deploy and work locally
> - **Org 2 (CI)** — where the GitHub Actions pipeline deploys to automatically

- [ ] Identify or create **Org 1 (Dev)** — note the username and login URL
- [ ] Identify or create **Org 2 (CI)** — note the username and login URL
      Create new: developer.salesforce.com/signup (use a Gmail+ alias for the second)
- [ ] Log in to Org 1 from CLI:
      `sf org login web --alias DevOrg --instance-url https://login.salesforce.com`
- [ ] Verify connection: `sf org display --target-org DevOrg`

---

## PART 3: Create GitHub Repo and Push Code

- [ ] Go to github.com → New repository
      Name: `bedrock-devsecops-demo`  |  Visibility: Public  |  No README (we have files already)
- [ ] In Terminal, from this project folder:
      ```
      git init
      git add .
      git commit -m "feat: initial SFDX project — Service Request object, Apex handler, Flow, Permission Set"
      git branch -M main
      git remote add origin https://github.com/YOUR_USERNAME/bedrock-devsecops-demo.git
      git push -u origin main
      ```
- [ ] Create develop branch:
      ```
      git checkout -b develop
      git push -u origin develop
      ```
- [ ] In GitHub → Settings → Branches → change Default Branch to `develop`
- [ ] Add branch protection on `develop`:
      Require status checks → select `validate-and-deploy` → Save

---

## PART 4: Deploy to Org 1 (Dev) to Verify Everything Works

- [ ] Run from Terminal (in the project folder):
      `sf project deploy start --source-dir force-app --target-org DevOrg --test-level RunLocalTests`
- [ ] Watch for: `Deploy Succeeded` and all 6 tests passing
- [ ] If you see errors about object not found — the deploy itself creates the object, so ignore on first run
      (If still failing, check Apex API version matches your org: edit `cls-meta.xml` files, change 62.0 to 61.0)

---

## PART 5: Set Up JWT Auth for CI Org (Org 2)

### Generate the key pair (run in Terminal):
```bash
mkdir -p ~/bedrock-jwt && cd ~/bedrock-jwt
openssl genrsa -out server.key 2048
openssl req -new -x509 -days 365 -key server.key -out server.crt \
  -subj "/C=AU/ST=NSW/L=Sydney/O=Bedrock/CN=bedrock-ci"
```
> server.key = private (never commit)  |  server.crt = public (goes in Salesforce)

### Create Connected App in Org 2:
- [ ] Setup → App Manager → New Connected App
      - Name: `Bedrock CI Pipeline`
      - Enable OAuth: ✓
      - Callback URL: `http://localhost:1717/OauthRedirect`
      - Scopes: `api` + `refresh_token`
      - **Use Digital Signatures: ✓** → upload `server.crt`
      - Save
- [ ] Wait 2-10 minutes, then: Manage → Edit Policies → Permitted Users = **Admin approved users are pre-authorised**
- [ ] Manage → Manage Profiles → Add **System Administrator**
- [ ] Copy the **Consumer Key** (Client ID) from the Connected App

### Pre-authorise from local machine:
- [ ] Run (replace placeholders):
      ```
      sf org login jwt \
        --client-id YOUR_CONSUMER_KEY \
        --jwt-key-file ~/bedrock-jwt/server.key \
        --username YOUR_ORG2_USERNAME \
        --instance-url https://login.salesforce.com \
        --alias CIOrg
      ```
- [ ] Verify: `sf org display --target-org CIOrg` — should show org details

---

## PART 6: Add GitHub Secrets

GitHub repo → Settings → Secrets and Variables → Actions → New repository secret

- [ ] `SFDX_JWT_KEY` → paste entire contents of `~/bedrock-jwt/server.key`
      (include `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines)
- [ ] `SFDX_CLIENT_ID` → paste Consumer Key from the Connected App
- [ ] `SFDX_USERNAME` → Org 2 username (e.g. yourname@example.com.demo)
- [ ] `SFDX_INSTANCE_URL` → `https://login.salesforce.com`

---

## PART 7: Fire the Pipeline — Full Test Run

- [ ] Create a test feature branch and open a PR to develop:
      ```
      git checkout develop
      git checkout -b feature/SR-001-initial-build
      # make a tiny edit — e.g. add a blank line to ServiceRequestHandler.cls
      git add .
      git commit -m "feat(SR-001): trigger CI pipeline test"
      git push origin feature/SR-001-initial-build
      ```
- [ ] Go to GitHub → open a PR from `feature/SR-001-initial-build` → `develop`
- [ ] Watch Actions tab — pipeline should run and go green
- [ ] All 3 stages should show green: Authenticate ✓  |  Static Analysis ✓  |  Deploy + Tests ✓

---

## PART 8: Demo Day Prep (night before)

- [ ] Re-run JWT auth to make sure it still works (tokens don't expire but good to verify)
- [ ] Have VS Code open with the project loaded
- [ ] Have your GitHub repo open in browser on the Actions tab
- [ ] Have Org 2 open in a browser tab (shows Service Request object was deployed)
- [ ] Have a prepared "dirty" branch with SOQL in a loop ready to show PMD catching it (optional but impressive)
      Add this to ServiceRequestHandler.cls temporarily:
      ```
      // PMD violation example — SOQL inside a for loop
      for (Service_Request__c sr : records) {
          List<User> u = [SELECT Id FROM User LIMIT 1]; // PMD catches this
      }
      ```
      Push it to a branch, open PR, show the pipeline fail on Static Analysis, then fix it

---

## PART 9: Demo Script (what to open in what order)

1. VS Code → show project structure in Explorer sidebar
2. Open `ServiceRequestHandler.cls` → explain the business logic
3. Open `ServiceRequestHandlerTest.cls` → explain 6 test methods, bulk test
4. Open `objects/Service_Request__c/` → show it's individual XML files, not a blob
5. Open `flows/Service_Request_Form.flow-meta.xml` → "Flow is just XML in source control"
6. Open `.github/workflows/ci.yml` → walk through each pipeline step
7. Terminal: `git checkout -b feature/SR-002-update-priority-logic`
8. Make the visible change to handler (update priority logic)
9. `git add . && git commit -m "feat(SR-002): refine priority logic" && git push origin feature/SR-002...`
10. Browser: GitHub → open PR → watch pipeline trigger
11. Click Actions → watch each step run live
12. All green → "PR is now mergeable — branch protection enforced this"

---

## Project File Structure (for reference)

```
bedrock-devsecops-demo/
├── .github/
│   └── workflows/
│       └── ci.yml                          ← GitHub Actions pipeline
├── force-app/main/default/
│   ├── classes/
│   │   ├── ServiceRequestHandler.cls       ← Apex business logic
│   │   ├── ServiceRequestHandler.cls-meta.xml
│   │   ├── ServiceRequestHandlerTest.cls   ← 6 test methods, 100% coverage
│   │   └── ServiceRequestHandlerTest.cls-meta.xml
│   ├── triggers/
│   │   ├── ServiceRequestTrigger.trigger   ← before insert/update
│   │   └── ServiceRequestTrigger.trigger-meta.xml
│   ├── objects/Service_Request__c/
│   │   ├── Service_Request__c.object-meta.xml
│   │   └── fields/
│   │       ├── Subject__c.field-meta.xml
│   │       ├── Category__c.field-meta.xml
│   │       ├── Status__c.field-meta.xml
│   │       ├── Priority__c.field-meta.xml
│   │       └── Description__c.field-meta.xml
│   ├── flows/
│   │   └── Service_Request_Form.flow-meta.xml  ← Screen flow, deployable
│   └── permissionsets/
│       └── Service_Request_Access.permissionset-meta.xml
├── sfdx-project.json
├── .forceignore
├── .gitignore
└── DEMO_CHECKLIST.md                       ← this file
```
