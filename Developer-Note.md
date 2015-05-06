# Developer Note

## Release Process

- Create a application
  - In Xcode, update the version
  - Edit `ChangeLog.md`
  - Push `master` bransh
  - Add a tag, and push it
  - In Xcode, export as a Mac Application
  - Archive the Mac Application to a zip file
    - `% zip -ry HotSwitch.zip ~/app_directory/HotSwitch.app`
- Publish an update
  - See the update's DSA signature
    - `% ./Sparkle/bin/sign_update.sh ~/zip_directory/HotSwitch.zip ~/key_directory/dsa_priv.pem`
  - Edit `appcast.xml` by using the signature
  - Replace the `HotSwitch.zip`
  - Push `gh_page` branch
  - Try and finish

