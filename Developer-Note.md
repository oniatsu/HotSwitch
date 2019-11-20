# Developer Note

## Release Process

- Create a application
  - Switch `master` branch
  - In Xcode, update the version
  - Edit `ChangeLog.md`
  - Commit and push `master` bransh
  - Add a tag, and push it
  - In Xcode, export as a Mac Application
  - Archive the Mac Application to a zip file
    - `% zip -ry HotSwitch.zip ~/app_directory/HotSwitch.app`
- Publish an update
  - Switch `gh_page` branch
  - See the update's DSA signature
    - `% ./Sparkle/bin/sign_update.sh ~/zip_directory/HotSwitch.zip ~/key_directory/dsa_priv.pem`
  - Edit `appcast.xml` by using the signature
  - Replace the `HotSwitch.zip`
  - Commit and push `gh_page` branch
  - Try and finish

