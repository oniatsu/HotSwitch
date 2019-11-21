# Developer Note

## Devloping Process

- Edit the code on Xcode
- Run it
- Turn on 2 app permissions again by double toggling the checkboxes
- Rerun it
- Check the result

## Release Process

### Create a application
- Switch `master` branch
- In Xcode, update the version
- Edit `ChangeLog.md`
- Commit and push `master` bransh
- Add a tag, and push it
- In Xcode, export as a Mac Application
- Archive the Mac Application to a zip file
  - `zip -ry HotSwitch.zip ~/app_directory/HotSwitch.app` (Edit the paths)

### Publish an update
- Switch `master` branch
- Copy the update's DSA signature
  - `./Sparkle/bin/sign_update.sh ~/zip_directory/HotSwitch.zip ~/key_directory/dsa_priv.pem | pbcopy` (Edit the paths)
- Switch `gh-page` branch
- Edit `./release/appcast.xml` by using the signature
- Replace `./release/zip/HotSwitch.zip` to new zip file
- Commit and push `gh-page` branch
- Try self upgrading and finish

