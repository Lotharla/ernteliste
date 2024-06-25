# Ernteliste

A Flutter project for Solawi.

## Prerequsites

Installation of Flutter, Chrome and SQLite:  
    sudo apt install git sqlite3 libsqlite3-dev  
    sudo apt install -y chromium-browser  
    sudo snap install flutter --classic  
Look for possible problems:  
    flutter doctor -v  

## Getting Started

Download and start the 'Ernteliste' app.  
    git clone https://github.com/Lotharla/ernteliste  
    cd ernteliste  
    ./starter.sh  
Follow the menus to launch the web application or just the server only.  

## Assets

The `assets` directory houses images, fonts, and any other files you want to
include with your application.

The `assets/images` directory contains [resolution-aware
images](https://flutter.dev/docs/development/ui/assets-and-images#resolution-aware).

## Localization

This project generates localized messages based on arb files found in
the `lib/src/localization` directory.

To support additional languages, please visit the tutorial on
[Internationalizing Flutter
apps](https://flutter.dev/docs/development/accessibility-and-localization/intern)
