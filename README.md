# template

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Developer

# Overview
This repository contains a fully functional application that provides features such as prayer times and Qibla direction. However, please note that certain operations require an internet connection to function properly.
# Features
Prayer Times: Access prayer times based on the user's location.
Qibla Direction: Find the direction of the Qibla from your current location.
Prerequisites
To enable the functionality of prayer times and Qibla, you need to connect the application to Firebase. Below are some tools and steps to help you set this up.
# Tools for Firebase Integration
* Firebase Console: Create a Firebase project and configure your app.
* Firebase SDK: Incorporate Firebase SDK into your application for authentication and database features.
* Firestore: Use Firestore for storing and retrieving prayer times and other relevant data.
# Setting Up Firebase
* Create a Firebase Project:
Go to the Firebase Console.
Click on "Add Project" and follow the setup instructions.
* Add App to Firebase:
Select your project, then click on "Add app" and choose your platform (iOS/Android).
Follow the instructions to register your app.
* Install Firebase SDK:
* Initialize Firebase:
In your application code, initialize Firebase using your config settings from the Firebase Console.
* Usage
This application is designed to work offline, but certain features require internet access. Ensure you have an active connection when trying to use the prayer time and Qibla functionalities.
