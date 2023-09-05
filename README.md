# Kong API Ops Samples

In this repository, there are a number of samples for generating and modifying specific common use-case scenarios, when trying to deploy your APIs from OpenAPI Spec documents, into Kong Konnect.

## Index

### 1. Old (Inso) Generation

Basic sample of the old generate process, using [Kong Insomnia Inso CLI](https://github.com/Kong/insomnia/releases/tag/lib%402023.5.7).

To run the sample, execute `./old-generate.sh`

### 2. New (Deck) Generation

**`Test Subject: openapi2kong`**

The same basic example as (1), but with the new [Kong Deck](https://github.com/Kong/deck) "file" options.

To run the sample, execute `./new-generate.sh`

### 3. Adding Plugins to All Runtime Groups

**`Test Subject: merge`**

This sample shows how you can use the new `deck file patch` command to add plugins that must appear on ALL APIs, e.g. a "centralised" plugin file that is merged into all API deployments.

You would use this when you have a requirement to enforce certain monitoring or security requirements on every published API.

To run the sample, execute `./new-generate-all-deployments-plugins.sh`

### 4. Adding Plugins to Specific Routes Only

**`Test Subject: patch`**

This sample shows how you can use the new `deck file patch` command to add plugins specifically to some routes only.

This means you can, for example, apply plugins at the deploy-time to specifc API methods or operations by tag presence, or method, or other common anchor.

To run the sample, execute `./new-generate-openid-patch.sh`

### 5. Adding Plugins to Specific Routes via YAML Anchor Template

**`Test Subject: patch`**

This sample is the same as (4), but shows how you can use a static YAML anchor containing a "shared" plugin configuration, e.g. redis connection details, and dynammically attach them to more than one instance of the same plugin type.

This lets you override only route-specific configuration items, such as "scopes_required" or "limits/window_sizes".

To run the sample, execute `./new-generate-openid-patch-anchors.sh`
