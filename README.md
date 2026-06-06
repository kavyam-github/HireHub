# HireHub 💼

A beautiful, modern, and reactive Flutter application that pulls live job listings from the Arbeitnow API. This project is built using a clean **MVC (Model-View-Controller)** architecture and uses **GetX** for robust state management and dependency injection.

---

## 🌟 Key Features

*   **Live Job Feed**: Fetches real-time job openings from the Arbeitnow API.
*   **Modern Warm Light UI**: Redesigned from scratch using a professional blue-violet color theme with Harmonious layouts and smooth transitions.
*   **Smart Search & Filtering**: Responsively filter jobs by title or company name. Toggle between all listings and your bookmarked jobs.
*   **On-Demand Description Translation**: Auto-translates foreign (e.g. German) descriptions into English using a chunked Google Translate engine.
*   **Persistent Bookmarks**: Save your favorite job postings locally on the device using `shared_preferences`, keeping them saved even after closing the app.
*   **Exit Verification**: Double-back press verification on the dashboard prevents accidental app exits.
*   **Hero Animations**: Seamless transitions between the job list and detailed inspector view.

---

## 📸 Screenshots

| Job Dashboard | Job Detail Inspector | Translation Feature |
| :---: | :---: | :---: |
| _[Add Dashboard SS Here]_ | _[Add Details SS Here]_ | _[Add Translation SS Here]_ |

> *Tip: You can easily upload screenshots by dragging and dropping your images directly into this README file on GitHub.*

---

## 🛠️ Architecture & SOLID Principles

This project serves as a showcase of clean code standards:
*   **Single Responsibility Principle (SRP)**: Data models, business logic (caching/fetching), and visual UI widgets are strictly isolated into distinct modules.
*   **Dependency Inversion Principle (DIP)**: No hardcoded class instantiations. Controller dependencies are injected and located dynamically using GetX (`Get.put` & `Get.find`).
*   **Factory Constructors**: Utilized `JobModel.fromJson` to map dynamic API responses safely with default value fallbacks.
*   **Reactive State Binding**: Uses GetX observables (`.obs` and `Obx`) to rebuild only the widgets that depend on changing data rather than reloading full screens.

---

## 🚀 How to Run the App

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/kavyam-github/HireHub.git
    cd HireHub
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    ```bash
    flutter run
    ```

---

## 📦 Package Dependencies Used

*   [`get`](https://pub.dev/packages/get) - State management, reactive updates, routing, and dependency injection.
*   [`http`](https://pub.dev/packages/http) - Network HTTP requests to the job board API.
*   [`shared_preferences`](https://pub.dev/packages/shared_preferences) - Persistent local storage for bookmarks.
*   [`url_launcher`](https://pub.dev/packages/url_launcher) - Launching external links in the default browser.
