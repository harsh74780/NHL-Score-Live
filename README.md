# NHL Scores Live 🏒

A full-stack application that tracks live NHL scores, schedules, and team statistics. Built with a **Node.js** backend for data ingestion and a **Flutter** frontend for a premium mobile/web experience.

## ✨ Features

*   **Live Scoreboard**: Real-time updates for ongoing games.
*   **Schedule View**: Browse past results and upcoming matchups.
*   **Team Details**: Deep dive into team stats, season records, and recent game history.
*   **Premium Dark UI**: A sleek, modern interface with custom team logos and a dynamic background.
*   **Cross-Platform**: Runs on iOS, Android, and Web.

## 🏗️ Architecture

The project is divided into two main parts:

### 1. Backend (`/backend`)
*   **Tech Stack**: Node.js, TypeScript, Firebase Admin SDK.
*   **Function**: Fetches data from the official NHL API and syncs it to **Cloud Firestore**.
*   **Key Script**: `ingest.ts` (Polls for live updates).

### 2. Frontend (`/app`)
*   **Tech Stack**: Flutter (Dart), Cloud Firestore.
*   **Function**: Listens to Firestore streams to display real-time data without manual refreshing.
*   **State Management**: StreamBuilder (Reactive UI).

## 🚀 Getting Started

### Prerequisites
*   Node.js & npm
*   Flutter SDK
*   Firebase Project (Firestore enabled)

### Setup

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/harsh74780/NHL-Score-Live.git
    cd NHL-Score-Live
    ```

2.  **Backend Setup:**
    *   Place your `serviceAccountKey.json` in `backend/`.
    *   Install dependencies:
        ```bash
        cd backend
        npm install
        ```
    *   Run the ingestion script:
        ```bash
        npx ts-node src/ingest.ts
        ```

3.  **Frontend Setup:**
    *   Ensure `firebase_options.dart` is configured in `app/lib/`.
    *   Run the app:
        ```bash
        cd app
        flutter run -d chrome
        ```


## 📸 Screenshots

| **Home Screen** | **Game Details** |
|:---:|:---:|
| <img src="screenshots/home_screen.png" width="300" /> | <img src="screenshots/game_detail.png" width="300" /> |

| **Team Details** | **Schedule (Results)** |
|:---:|:---:|
| <img src="screenshots/team_detail.png" width="300" /> | <img src="screenshots/results_tab.png" width="300" /> |

| **Schedule (Upcoming)** |
|:---:|
| <img src="screenshots/upcoming_tab.png" width="300" /> |


## 📄 License

MIT
