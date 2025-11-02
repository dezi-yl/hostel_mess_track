# Hostel Mess Management

A Flutter application for managing student attendance in a hostel mess. This app is built using the BLoC pattern for state management and utilizes a local SQLite database for data persistence.

## Features

*   **Student Management:** Add, view, and manage student information.
*   **Room Management:** Assign and manage student rooms.
*   **Food & Meal Tracking:** Define meals and track food consumption.
*   **Attendance System:** Mark student attendance for each meal.
*   **QR Code Scanning:** Quick attendance marking using qr code.
*   **Reporting:** Generate attendance reports and export them to CSV.

## Tech Stack

*   **Framework:** Flutter
*   **State Management:** BLoC
*   **Database:** SQLite (`sqflite`)
*   **Dependency Injection:** `get_it`
*   **UI:** `google_fonts`, `cupertino_icons`
*   **File Handling:** `file_saver`, `csv`

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/dezi-yl/hostel_mess_track
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the app:**

    ```bash
    flutter run
    ```