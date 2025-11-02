# hostel_mess_bloc_version

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


































Excellent — now we’re designing not just a **data prompt**, but a **complete output spec**:
one structure that works both as a **UI display (inside your app)** *and* for **CSV export**.

Let’s make this unified, clean, and dev-friendly.

---

## 🎯 Design Goals

* One **data structure** → two uses:

  * UI table (human-readable in the app)
  * CSV export (machine-friendly)
* Must **adapt dynamically** to meal types available in the database.
* Must **include total days attended**.
* Should look **neat and consistent** in both representations.

---

## 🧱 Unified Table Structure

| Student Name | 2025-10-25                  | 2025-10-26                  | 2025-10-27                  | 2025-10-28                  | **Total Days Attended** |
| ------------ | --------------------------- | --------------------------- | --------------------------- | --------------------------- | ----------------------- |
| Aditi Sharma | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch❌, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | Breakfast❌, Lunch✅, Dinner✅ | 4                       |
| Rohan Mehta  | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch❌, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | 4                       |
| Neha Singh   | Breakfast❌, Lunch✅, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch❌, Dinner✅ | 4                       |

---

### 💡 UI Display

In the app UI:

* You can render each cell (`Breakfast✅, Lunch✅, Dinner✅`) as **stacked rows** or **badges** for readability.
  Example (pseudo-UI):

  ```
  ┌────────────────────┐
  │ Breakfast ✅        │
  │ Lunch ❌            │
  │ Dinner ✅           │
  └────────────────────┘
  ```
* This same structure can be exported *as-is* to CSV without data transformation.

---

## 🧠 Final AI Prompt (For Both UI + CSV)

> You are given raw meal attendance data from a database.
> Each record includes:
>
> * `student_id` or `student_name`
> * `meal_type` (dynamic list, e.g., breakfast, lunch, dinner, snacks, etc.)
> * `date`
>
> Some meals may be missing if the student skipped them.
>
> Your task:
>
> 1. Generate a **unified table** that can be used both for **UI display** and **CSV export**.
> 2. Each **row** represents one student.
> 3. Each **column** (except the last) represents one **date**, sorted chronologically.
> 4. Inside each date cell, list all meal types found in the dataset, formatted as:
>
>    ```
>    {MealName}{✅ or ❌}, separated by commas
>    ```
>
>    Example: `Breakfast✅, Lunch❌, Dinner✅`
> 5. At the end of each row, include a **“Total Days Attended”** column:
>
>    * Count a day as attended if **any meal** that day is ✅.
>    * Skip if all meals are ❌.
> 6. Dynamically determine meal names from the data (do not assume fixed meals).
> 7. Output the table in a format suitable for:
>
>    * Display in a UI table component, and
>    * Export to CSV without needing further transformation.
> 8. Sort students alphabetically by name, and dates chronologically.
>
> Example:
>
> ```
> | Student Name | 2025-10-25 | 2025-10-26 | 2025-10-27 | Total Days Attended |
> |---------------|-------------|-------------|-------------|---------------------|
> | Aditi Sharma  | Breakfast✅, Lunch✅, Dinner✅ | Breakfast✅, Lunch❌, Dinner✅ | Breakfast✅, Lunch✅, Dinner✅ | 3 |
> ```
>
> The output must be clean, aligned, and easy to render as both a UI table and a downloadable CSV.

---

Would you like me to also write a **sample Flutter UI table widget** that renders this same structure dynamically (using your existing app style)?
