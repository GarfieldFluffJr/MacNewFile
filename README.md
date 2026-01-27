# MacNewFile

One of the many things that pissed me off after switching from Windows to Mac was that I couldn't create a new text file or word document off of a right click in Finder (file explorer).

So I fixed that! Introducing **MacNewFile**!!

MacNewFile is very lightweight and simple. You right click anywhere in Finder (or on your desktop) and you get a menu to create new files!

<img src="https://raw.githubusercontent.com/GarfieldFluffJr/MacNewFile/refs/heads/main/MacNewFile%20demo%20image.png" width="600" alt="MacNewFile Demo">

## Setup Instructions

1. Click on the latest release of this repository (right column)
2. Download `MacNewFile.zip`
3. Unzip the folder, delete the zip folder, and move `MacNewFile.app` to the `Applications` folder
4. Run `MacNewFile.app`
    - If prompted with Apple Security, open system settings, open `Privacy and Security`, scroll all the way to the bottom and click "open anyways"
5. Run `MacNewFile.app` again from the `Applications` folder
6. To disable the app (fully stop running in the background), click the MacNewFile app icon in the top menu bar (plus sign) and click "Quit"
    - Or you can go to `System Settings -> General -> Login & Extensions -> File Providers / File System Extensions` and find MacNewFile and turn it off

The reason for the many security concerns is because Apple is very strict on what apps may do, so I made exceptions that allows MacNewFile to create new apps in arbitrary locations.

## My Promise as a Developer

- This is not malware, everything is pushed to this repo which you can review
- This is a lightweight app, I optimized it as much as I could to not eat up your memory
- It is **very easy to install and delete**. To delete off your laptop, just delete the `MacNewFile.app` file in the `Applications` folder.
  - You can delete with `AppCleaner` which will delete the tiny Finder extension bundles installed (~50KB)
- This app does not hide in the background, I tested this with my own MacBook, Activity Monitor shows no activity once the application is quit
- You can view if it is running in `System Settings -> General -> Login Items & Extensions -> File Providers / File System Extensions`

If you have any concerns, please don't hesitate to reach me at louieyin6@gmail.com!