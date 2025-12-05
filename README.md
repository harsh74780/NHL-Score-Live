# NHL Scores Live 🏒

A full-stack application that tracks live NHL scores, schedules, and team statistics. Built with a **Node.js** backend for data ingestion and a **Flutter** frontend for a premium mobile/web experience.

## ✨ Features

*   **Live Scoreboard**: Real-time updates for ongoing games with visual status indicators.
*   **Smart Schedule**: 3-Tab view organizing games into Results, Today, and Upcoming.
*   **Team Details**: Deep dive into team stats, season records, and a calculated "Last 5 Games" history.
*   **Premium Dark UI**: A sleek, modern interface with custom team logos and a dynamic background.
*   **Cross-Platform**: Runs on iOS, Android, and Web.

## 🏗️ Architecture

The project is divided into two main parts:

### 1. Backend (`/backend`)
*   **Tech Stack**: Node.js, TypeScript, Firebase Admin SDK.
*   **Function**: Fetches data from the official NHL API and syncs it to **Cloud Firestore**.
*   **Key Script**: `ingest.ts` - Implements a Dynamic Polling Strategy:
    *   **Live Game**: Polls every 60 seconds.
    *   **Scheduled**: Sleeps until 5 minutes before puck drop.
    *   **Off-Hours**: Sleeps for 1 hour to conserve resources.

### 2. Frontend (`/app`)
*   **Tech Stack**: Flutter (Dart), Cloud Firestore.
*   **Function**: Listens to Firestore streams to display real-time data without manual refreshing.
*   **State Management**: StreamBuilder (Reactive UI) for instant updates.

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

2.  **Backend Setup (Terminal 1):**
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

3.  **Frontend Setup (Terminal 2):**
    *   Ensure `firebase_options.dart` is configured in `app/lib/`.
    *   Run the app:
        ```bash
        cd app
        flutter run -d chrome --web-renderer html
        ```


## 🧠 Architecture & Reasoning

### The "Team Screen" Challenge
The requirements asked for a Team Screen showing the "Last 5 Games".
*   **The Constraint**: The App is not allowed to call the NHL API directly.
*   **The Problem**: If the ingestion script only fetched "Today's" games, the database would have no history, and the Team Screen would be empty.
*   **The Solution**: I implemented a **Denormalized Data Model**. The backend aggregates game history in memory during ingestion (fetching a 7-day backfill) and writes a summary directly to the `teams` collection. This keeps the client-side logic simple and fast.

### Data Model (Firestore)
*   **`games` Collection**: Stores individual game documents. Optimized for the real-time Schedule list.
*   **`teams` Collection**: Stores team profiles (Record, Logo, Last 5 Games list). Optimized for the Team Detail screen.

### Trade-offs & Scope
*   **Logos**: The NHL API provides SVGs which can be unstable in some Flutter renderers. I implemented a `TeamLogo` widget that maps team abbreviations to a reliable PNG source (ESPN) for a better UI experience.
*   **Venue Data**: I explicitly added venue data to the schema to enhance the Game Detail view.

## ⚠️ Assumptions & Limitations

### 1. Data Source
*   **Assumption**: I used the undocumented NHL API (`api-web.nhle.com/v1`) as it provides the most up-to-date JSON structure.
*   **Limitation**: Since this API is unofficial, field names could change.

### 2. Logo Assets
*   **Limitation**: SVG support on Windows/Web can be flaky.
*   **Workaround**: Used a custom widget to fetch high-quality PNGs based on team abbreviations.

## 🤖 AI Usage vs. Human Intelligence

*   **AI**: Used to generate the boilerplate code for Firestore serialization and to lookup API endpoints.
*   **Human Intelligence (HI)**: Used for the architectural decision to split data ingestion into three phases (Standings -> Schedule -> Team Profiles) and for designing the Dynamic Polling Loop to optimize cloud costs.

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

## 🎥 Presentation

To view the project presentation:
1. Navigate to the `presentation/` folder.
2. Open `presentation.html` in your web browser.

