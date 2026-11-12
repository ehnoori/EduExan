 
<div align="center">

# 🎓 EduExan

### Class Management & Student Evaluation System

**A Flutter application for managing classes, evaluating students, organizing questionnaires, and maintaining assessment records.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Cross--Platform-green)](https://github.com/ehnoori/EduExan)
[![Version](https://img.shields.io/badge/Version-3.0.0-blue)](https://github.com/ehnoori/EduExan)

[**GitHub Repository**](https://github.com/ehnoori/EduExan) · [**Report an Issue**](https://github.com/ehnoori/EduExan/issues)

</div>

---

## 📖 Overview

**EduExan** is a Flutter-based class management and student evaluation application designed to simplify classroom administration and assessment processes.

The application helps users create and manage classes, organize evaluation questions, assess students, and maintain student evaluation records.

EduExan uses local data storage to preserve information and supports importing questions from Excel files.

## 📸 Screenshots

### Application Preview

![EduExan Application Preview](flutter_01.png)

More application screenshots are available in the [`screenshots`](screenshots/) directory.

---

## ✨ Key Features

### 🏫 Class Management
- Create and manage classes.
- View the list of available classes.
- Organize student evaluation activities by class.

### 📝 Student Evaluation
- Select students for evaluation.
- Evaluate students using structured questionnaires.
- Save evaluation answers and results.
- Prevent duplicate evaluations for the same student in a class.

### 📊 Excel Question Import
- Import questions from Excel (`.xlsx`) files.
- Support Persian question and column headers.
- Read multiple-choice questions and their options.
- Support question types such as choice, number, text, and project.
- Preview imported Excel data before saving.
- Store the selected Excel file in the application's permanent storage.

### 💾 Local Database
- Store classes, questions, and evaluation records locally.
- Use Isar database for data persistence.
- Retrieve previous evaluation records.
- Keep historical evaluation data separate from the current question bank.

### 🔒 Consistent Evaluation Questions
- Save a question snapshot when the first evaluation in a class is submitted.
- Use the same question set for subsequent students in that class.
- Keep previously saved evaluation records independent of later question imports.

### 📁 Data Management
- Import questionnaire data from Excel.
- Manage the question bank.
- Store evaluation results.
- Support sharing and file-related workflows where implemented.

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Main programming language |
| Isar Database | Local data persistence |
| Excel Plus | Excel file reading and processing |
| File Picker | Selecting files from the device |
| Path Provider | Application storage directories |
| Shared Preferences | Saving simple application settings |
| Google Fonts | Typography |
| Share Plus | Sharing application content |
| Syncfusion PDF | PDF functionality |

---

## 📱 Supported Platforms

| Platform | Status |
|---|---|
| Android | Primary target |
| iOS | Flutter project platform |
| Windows | Flutter project platform |
| Linux | Flutter project platform |
| macOS | Flutter project platform |
| Web | Flutter project platform |

*Platform support depends on the implementation and testing of individual features.*

---

## 🚀 Getting Started

### Prerequisites

Make sure you have installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- An Android emulator or physical device

### 1. Clone the Repository

```bash
git clone https://github.com/ehnoori/EduExan.git
```

### 2. Open the Project

```bash
cd EduExan
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

### 5. Analyze the Project

```bash
flutter analyze
```

---

## 🧱 Project Structure

The project is organized around Flutter screens, database services, and data models.

```text
EduExan/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── lib/
│   ├── database/
│   │   └── isar_service.dart
│   │
│   ├── models/
│   │   ├── class_model.dart
│   │   ├── question_model.dart
│   │   └── evaluation_model.dart
│   │
│   └── ...
│
├── screenshots/
│
├── test/
│
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## 📚 Evaluation Workflow

The application follows a structured evaluation process:

1. Create a class.
2. Import questions from an Excel file.
3. Review the imported questions.
4. Save questions to the local database.
5. Select a class and a student.
6. Complete the evaluation questionnaire.
7. Save the evaluation result.
8. Review previously saved evaluations.

### Question Snapshot System

EduExan preserves the question set used for a class evaluation.

When the first student in a class is evaluated, the question set is saved as a snapshot. Subsequent evaluations in that class use the same snapshot.

This helps maintain consistency when evaluating multiple students.

---

## 📊 Excel Import Format

EduExan supports Excel question files with columns such as:

| Column | Description |
|---|---|
| سوال | Question text |
| نوع سوال | Question type |
| گزینه A | First option |
| گزینه B | Second option |
| گزینه C | Third option |
| گزینه D | Fourth option |
| پاسخ صحیح | Correct answer |

Example question types:

- `choice`
- `number`
- `text`
- `project`

The first worksheet is used for importing questions.

---

## 🔐 Data Persistence

EduExan uses Isar to store application data locally.

The application maintains separate data for:

- Classes
- Question bank
- Student evaluations
- Question snapshots stored with evaluation records

Importing a new question file updates the question bank when the user saves it. Existing evaluation records are designed to remain available.

---

## 🗺️ Roadmap

- [x] Class management foundation
- [x] Student evaluation workflow
- [x] Local database integration
- [x] Excel question import
- [x] Question snapshot support
- [x] Persian Excel header support
- [ ] Improve reporting and analytics
- [ ] Expand PDF reporting features
- [ ] Improve backup and restore workflows
- [ ] Additional UI and usability improvements

---

## 🧪 Testing

Run the Flutter test suite:

```bash
flutter test
```

Analyze the project:

```bash
flutter analyze
```

---

## 🤝 Contributing

Contributions, suggestions, and bug reports are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Test your changes.
5. Submit a Pull Request.

---

## 👨‍💻 Author

**Hamed Noori**

- GitHub: [@ehnoori](https://github.com/ehnoori)
- Project: [EduExan](https://github.com/ehnoori/EduExan)

---

## 📄 License

No license has been confirmed for this repository yet. Add a `LICENSE` file if you intend to publish the project under an open-source license.

---

<div align="center">

**Built with Flutter ❤️**

⭐ If you find EduExan useful, consider giving the repository a star!

[Back to Top](#-eduexan)

</div>
