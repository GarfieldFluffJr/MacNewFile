1. Fork the repository
2. Open in Xcode
3. Sign into apple ID
4. Change the team in signing and capabilities in both MacNewFile and MacNewFileFinderExtension to this local apple ID
5. Change the app groups and bundle identifier username from louieyin to your name in both
6. In AppDelegate, change my apple ID to your App Group identifier (x2)
7. In FinderSync, change my apple ID to your App Group identifier (x1)
8. Products -> clean build
9. Products -> build
10. Open Products folder, right click MacNewFile and open in Finder
11. Move to Applications
12. Open it, if it doesn't work, go to settings -> Logins and Extensions -> Enable
13. Can delete Xcode and all other forked code
