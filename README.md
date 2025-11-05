# Lab Report: Hostel Mess Management System

**Git Repository URL:** [https://github.com/dezi-yl/hostel_mess_track](https://github.com/dezi-yl/hostel_mess_track)

## 1. Introduction

### 1.1. Project Title
Hostel Mess Management System

### 1.2. Problem Statement
Managing a hostel mess involves keeping accurate records of students, their meal preferences, and daily attendance. Manual systems, often reliant on paper-based registers, are inefficient, prone to human error, and make it difficult to generate timely reports for billing, inventory management, and attendance tracking. This project aims to solve these issues by providing a robust, digital solution using a Flutter mobile application.

### 1.3. Key Goals and Objectives
- **To develop a mobile application** for managing hostel mess operations efficiently.
- **To provide an intuitive and easy-to-use interface** for administrators to manage students, rooms, and food items.
- **To maintain a centralized and persistent database** of students, rooms, and meal records on the device.
- **To automate the process of tracking meal attendance** through both manual selection and QR code scanning.
- **To generate and export detailed monthly reports** for analysis and billing purposes.

---

## 2. System Architecture: Clean Architecture

This project is built upon the principles of **Clean Architecture**, a software design philosophy that separates the concerns of a program into distinct, independent layers. This approach enhances modularity, testability, and maintainability.

### 2.1. The Principles of Clean Architecture
The core idea of Clean Architecture is the **Dependency Rule**: *source code dependencies can only point inwards*. This means that inner layers (containing core business logic) should have no knowledge of outer layers (containing implementation details like UI or databases).

This creates a system where:
- The business logic is independent of the UI, database, or any external framework.
- The application is easier to test, as the business logic can be tested without the UI or database.
- The UI or database can be changed with minimal impact on the rest of the system.

### 2.2. Implementation in this Project
The application is structured into three primary layers, reflecting the Clean Architecture pattern:

#### a) Presentation Layer
This is the outermost layer, responsible for everything related to the UI and user interaction.
- **What it contains:** Flutter Widgets, BLoCs (for state management), and UI-specific logic.
- **Location:** `lib/features/` directory. Each feature (like `students_page`, `rooms_page`) has its own UI and BLoC.
- **How it works:** The UI widgets dispatch events to the BLoCs in response to user input. The BLoCs process these events, interact with the Domain layer's use cases, and emit new states. The UI then rebuilds itself based on these states. For example, `StudentsPage` (`lib/features/home_page/pages/students_page/students_page.dart`) listens to state changes from `StudentBloc` to display the list of students.

#### b) Domain Layer
This is the core of the application, containing the essential business logic and rules. It is completely independent of the UI and the database.
- **What it contains:**
    - **Entities:** Plain Dart objects representing the core data structures (e.g., `StudentEntity`, `RoomEntity`).
    - **Use Cases:** Classes that encapsulate specific business operations (e.g., `StudentOperationsUseCases` which contains methods like `addStudent`, `getAllStudents`).
    - **Repository Interfaces:** Abstract classes that define the contract for data operations (e.g., `StudentRepository`). The Domain layer depends on these interfaces, not their concrete implementations.
- **Location:** `lib/core/domain/`

#### c) Data Layer
This layer is responsible for retrieving data from and storing data to one or more sources (like a database or a remote API). It implements the repository interfaces defined in the Domain layer.
- **What it contains:**
    - **Repository Implementations:** Concrete implementations of the repository interfaces (e.g., `StudentRepositoryImpl`).
    - **Data Sources:** Classes responsible for interacting with specific data sources. In this project, `SQLiteLocalDatabaseHelper` is the data source that communicates with the `sqflite` database.
- **Location:** `lib/core/data/`
- **How it works:** The `StudentRepositoryImpl` takes a `LocalDatabaseHelper` as a dependency. When a method like `getAllStudents` is called from a use case, the repository implementation calls the corresponding method on the database helper, retrieves the raw data (as `Map<String, dynamic>`), and maps it to the `StudentEntity` objects that the Domain layer understands.

### 2.3. Dependency Injection with `get_it`
To connect these layers without violating the Dependency Rule, the project uses the `get_it` package for dependency injection. The setup is in `lib/core/di/dependency_injection.dart`.
This setup allows the Presentation layer to get an instance of a `StudentOperationsUseCases` without knowing how it's created or what its dependencies are.

---

## 3. State Management: BLoC Pattern

The **BLoC (Business Logic Component)** pattern is used for state management. It helps to separate the UI from the business logic, making the app more predictable and testable.

A BLoC consists of three main components:
- **Events:** Inputs to the BLoC, dispatched from the UI to signify a user action or a lifecycle event.
- **States:** Outputs from the BLoC, representing a part of the application's state. The UI listens to the stream of states and rebuilds accordingly.
- **BLoC:** The class that receives events, processes them (often using use cases), and emits new states.

---

## 4. Database Schema and Data Persistence

The application uses a local **SQLite** database for data persistence, managed via the `sqflite` package.

### 4.1. Database Schema
The database schema is defined in `lib/core/data/datasources/local/sqlite_database_helper.dart`. It consists of four tables:

1.  **`room`**
    - `id`: INTEGER, PRIMARY KEY, AUTOINCREMENT
    - `name`: TEXT, NOT NULL, UNIQUE
2.  **`student`**
    - `id`: INTEGER, PRIMARY KEY, AUTOINCREMENT
    - `name`: TEXT, NOT NULL
    - `reg`: TEXT, UNIQUE, NOT NULL
    - `room_id`: INTEGER (FOREIGN KEY to `room.id`)
3.  **`food`**
    - `id`: INTEGER, PRIMARY KEY, AUTOINCREMENT
    - `name`: TEXT, NOT NULL, UNIQUE
4.  **`student_food`** (Junction Table)
    - `id`: INTEGER, PRIMARY KEY, AUTOINCREMENT
    - `student_id`: INTEGER (FOREIGN KEY to `student.id`)
    - `food_id`: INTEGER (FOREIGN KEY to `food.id`)
    - `date`: INTEGER (stores `DateTime.millisecondsSinceEpoch`)

### 4.2. Data Access
The `SQLiteLocalDatabaseHelper` class contains all the SQL queries required to perform CRUD (Create, Read, Update, Delete) operations on these tables. It handles the database connection, table creation, and data manipulation.

---

## 5. Detailed Feature Implementation

The app is navigated via a `BottomNavigationBar` defined in `nav_bar_screen.dart`, providing access to five main features:

- **Students:** Manages all student-related operations. Users can view a list of all students, filter them by year group, and add new students. It supports a selection mode for bulk deletion. Student rooms can also be updated from this page.
- **Rooms:** Manages rooms. Users can view a list of rooms with a count of students in each, add new rooms, and see the list of students in a specific room. It also supports a selection mode for bulk deletion.
- **Food & Attendance:** This is the core operational feature. It displays a list of food items for the selected date with an attendance count for each. Users can take attendance manually by searching for a student or automatically by scanning a student's QR code.
- **Reports:** Generates a comprehensive monthly attendance report. The report is displayed in a scrollable table and can be exported as a CSV file using the `file_saver` package.
- **Debug:** A utility page that displays raw data from all database tables, which is useful for development and troubleshooting. This page now automatically loads data when it is first opened.

---

## 6. Error Handling

The application provides user feedback for operations that result in an error. For instance, since the name of each food item must be unique, attempting to add a food item that already exists will result in a `DatabaseException`. This exception is caught within the `FoodAttendanceBloc`, which then emits a new state containing a user-friendly error message: "Food item with this name already exists.". The UI, which is listening for state changes, detects this error message and displays it to the user in a temporary message at the bottom of the screen (a Snackbar), preventing the app from crashing and clearly informing the user of the issue.

---

## 7. Dependencies

- **`flutter_bloc`:** Core state management library.
- **`get_it`:** Service locator for dependency injection.
- **`sqflite` & `path`:** For local SQLite database creation and management.
- **`equatable`:** To compare Dart objects, primarily used in BLoC states and events.
- **`mobile_scanner`:** For the QR code scanning functionality.
- **`intl`:** For date formatting throughout the application.
- **`csv` & `file_saver`:** Used in the reports feature to generate and save CSV files.
- **`permission_handler`:** To request necessary permissions for saving files to device storage.

---

## 8. Conclusion & Future Scope

### 8.1. Summary
This project successfully implements a functional and well-architected mobile application for hostel mess management. The use of Clean Architecture and the BLoC pattern provides a solid foundation that is scalable, maintainable, and testable. The application addresses the core requirements of student management, attendance tracking, and reporting, providing a significant improvement over manual systems.

### 8.2. Future Enhancements
- **User Authentication:** Implement a login system to restrict access to authorized administrators.
- **Cloud Sync:** Integrate a backend service (like Firebase Firestore) to sync data across multiple devices and provide real-time updates.
- **Billing Module:** Automatically calculate monthly mess bills for each student based on their attendance records.
- **Inventory Management:** Add a feature to track mess inventory and generate alerts for low-stock items.
- **Enhanced Reporting:** Provide more advanced filtering and data visualization options for reports.
- **Student Profile Pictures:** Extend the `student` table to include a path to a profile picture and display it in the UI.
