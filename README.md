
# Firebase Cloud Quest - CW03

## Project Overview

Cloud Quest is a Flutter Android application that uses Firebase Authentication, Cloud Firestore, Cloud Functions, and a Genkit-powered AI Quest Coach.

Users can create accounts, sign in, view a daily coding challenge, request AI-generated hints, and earn rewards for completing the challenge.

## Technologies

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Emulator Suite
- Genkit
- Ollama with Llama 3.2 (3B)

## Features

### Authentication
Users can register, sign in, and sign out using Firebase Authentication. Challenge access requires an authenticated account.

### Daily Challenge
Cloud Firestore stores the shared challenge at `challenges/today`.

### Reward System
The `completeToday` callable Cloud Function awards 10 points and the First Quest badge.

A Firestore transaction prevents duplicate rewards. The Flutter client cannot directly modify reward records.

### AI Quest Coach
The `askQuestCoach` callable Function uses Genkit and a locally hosted Llama 3.2 model to generate coding hints.

Its read-only `readMyQuestState` tool retrieves the authenticated user's challenge and progress.

The coach cannot modify points, award badges, or call the reward function.

## Running the Application

Target platform: Android emulator.

Install Flutter dependencies:

    flutter pub get

Start Ollama and ensure the llama3.2:3b model is installed and available.

Start Firebase emulators:

    firebase emulators:start --only auth,firestore,functions

In a separate terminal, launch Flutter:

    flutter run

The Android emulator connects to local Firebase services through 10.0.2.2.

The local Firestore Emulator must contain the `challenges/today` document with title and prompt fields.

## Testing

The following tests were performed:

1. Registered and signed in with Firebase Authentication.
2. Verified that the daily challenge loads from Firestore.
3. Confirmed the first completion awards 10 points and one badge.
4. Confirmed duplicate completion does not increase points.
5. Requested AI-generated hints through Quest Coach.
6. Submitted an adversarial request asking for 999 points.
7. Verified the score remained at 10 points.

## Evidence

Screenshots are available in the screenshots directory.

- 01_Authentication.png
- 02_Daily_Challenge.png
- 03_AI_Coach.png
- 04_AI_Safety.png
- 05_Firestore_Reward.png

## Security

Firebase Authentication identifies the current learner. Firestore Security Rules restrict client access to private progress and deny client-side reward writes.

Cloud Functions validate the authenticated user. The AI coach only reads challenge and progress information, while the separate reward function controls completion.

## Limitations

The AI model runs locally through Ollama rather than the course's preconfigured model gateway. The current application is tested using Firebase emulators and is not configured for production AI hosting.

Local emulator data is not automatically preserved between restarts unless exported and reimported.
