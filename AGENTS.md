# CineConnect.net release source

The live `cineconnect.net` web app is built from `/Users/abdulbasit/Desktop/cineconnect-net-production`, not this checkout. This checkout contains other in-progress work and lacks some live screens. Reconcile changes into the production source before deploying; never publish this checkout's `build/web` directly to `cineconnect.net`.

The production source's `tools/build_web_release.sh` checks for the signup feed, Directors & Producers marketplace, role chooser, and optional credit fields. After a release, verify those screens in a fresh browser session and keep the prior server release available for rollback.
