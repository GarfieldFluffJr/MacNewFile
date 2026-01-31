<div align="center">

<img src="./MacNewFile/Assets.xcassets/AppIcon.appiconset/add (1) (1)-modified.png" width="100" height="100">

# MacNewFile
[![License](https://img.shields.io/github/license/GarfieldFluffJr/MacNewFile?color=007ec6)](https://github.com/GarfieldFluffJr/MacNewFile/blob/main/LICENSE)
![macOS](https://img.shields.io/badge/macOS-13.0+-A2AAAD)
[![Homebrew](https://img.shields.io/badge/Homebrew-supported-F97316)](https://brew.sh/)
[![Release](https://img.shields.io/github/v/release/GarfieldFluffJr/MacNewFile?color=2ea44f)](https://github.com/GarfieldFluffJr/MacNewFile/releases)

![Project Views](https://hits.sh/github.com/GarfieldFluffJr/MacNewFile.svg?label=Project%20Views&color=007ec6)

</div>

One of the many things that pissed me off after switching from Windows to Mac was that I couldn't create a new text file or word document off of a right click in Finder (file explorer).

So I made **MacNewFile**!!

MacNewFile is lightweight and simple. You right click anywhere in Finder (or on your desktop) and you get a menu to create new files!

<div align="center">
<img src="./MacNewFile Demo sped up.gif" width="600" alt="MacNewFile Demo">
</div>

**Please note:** This only doesn't work on directories inside of your iCloud, since Apple fully removed support for FinderSync in 2019.

## Features
- Can create the following apps from the Finder right-click menu:
    - Text file
    - Markdown file
    - Microsoft Word, Excel, and Powerpoint
    - Apple Pages, Numbers, and Keynote

- Settings menu to customize MacNewFile features

- Can **copy the filepath** of the current directory

- Can **open a new terminal** in the current directory

- Light/dark mode compatible

- To disable the app (fully stop running in the background), click the MacNewFile app icon in the top menu bar (plus sign) and click "Quit"
    - Or you can go to `System Settings -> General -> Login & Extensions -> File Providers / File System Extensions` and find MacNewFile and turn it off

# Installation

- **[Homebrew (Recommended)](#homebrew)**
- **[Manual Download](#manual-download)**

## Homebrew

### Install
```zsh
brew tap GarfieldFluffJr/macnewfile
brew install --cask macnewfile
```

### Complete uninstall
```zsh
brew uninstall --cask macnewfile
brew untap GarfieldFluffJr/macnewfile
```

**[Jump to Contributions and Issues](#contributions-and-issues)**

## Manual Download

### Install

1. **[Download `MacNewFile.zip` in the latest release](https://github.com/GarfieldFluffJr/MacNewFile/releases)**

2. Unzip the folder, delete the zip folder, and move `MacNewFile.app` to the `Applications` folder

3. Run `MacNewFile.app`
    - If prompted with Apple Security, open system settings, open `Privacy and Security`, scroll all the way to the bottom and click "open anyways"

4. Run `MacNewFile.app` again from the `Applications` folder

The reason for the many security concerns is because Apple is very strict on what apps may do, so I made exceptions that allows MacNewFile to create new apps in arbitrary locations. I also don't have Apple Developer Notarization.

### Debugging
- Move app out of quarantine: `xattr -dr com.apple.quarantine /Applications/MacNewFile.app`

- Restart Finder: `killall Finder`

- Go through Settings Privacy and Security

### Uninstall

Delete the `MacNewFile.app` file in the `Applications` folder.

You can delete with `AppCleaner` which will delete the tiny Finder extension bundles installed (~50KB)

## Contributions and Issues

Do you have a new idea you want to implement? Feel free to contribute! 

Fork the repository and make the project your own. Or, if you'd like to contribute to this project, submit a pull request when you're done. See **[CONTRIBUTING.md](./CONTRIBUTING.md)** for more details.

Or if you'd like to **suggest changes**, **[submit a github issue](https://github.com/GarfieldFluffJr/MacNewFile/issues)**.

You can also reach me by email if you have any questions: **louieyin6@gmail.com**

## My Promise as a Developer

- **I don't vibe-code my projects**
- This is not malware, everything is pushed to this repo which you can review
- It is **very easy to install and delete**, I steal no data, or hide anything on your device
- This app does not hide in the background, I tested this with my own MacBook, Activity Monitor shows no activity once the application is quit
    - You can view if it is running in `System Settings -> General -> Login Items & Extensions -> File Providers / File System Extensions`

## License

GNU GPL v3 License - see [LICENSE](./LICENSE) for details.
