# University Database Application (Flutter + SQLite)

A university project demonstrating the design and implementation of a mobile application backed by a relational SQLite database. The project focuses on database modeling, UML design, and integration of persistent storage with application logic using Flutter.

---

## Overview

This project was developed as part of a university coursework assignment. The main goals were:

* Design a relational database schema for a real-world domain (zoo management example)
* Model the system using UML diagrams
* Implement a Flutter application connected to a local SQLite database
* Perform full CRUD operations (Create, Read, Update, Delete)

The application UI was implemented by a teammate, while the database design, UML modeling, coordination, and database integration were implemented by me.

---

## Technologies

* **Flutter** – mobile application framework
* **Dart** – programming language
* **SQLite** – local relational database
* **UML** – system modeling (use case, class, sequence diagrams)
* **DB Browser for SQLite** – database inspection and testing

---

## Project Structure

```
flutter_application_9/
│
├── lib/                 # Application source code
├── assets/
│   └── db/              # SQLite database file (zoo_english.sqlite)
├── android/             # Android platform files
├── ios/                 # iOS platform files
├── windows/             # Windows platform files
├── linux/               # Linux platform files
├── macos/               # macOS platform files
├── web/                 # Web platform files
├── test/                # Tests
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## Database

The database file is located in:

```
assets/db/zoo_english.sqlite
```

It contains the full schema and sample data used in the application.

You can open it using **DB Browser for SQLite** to inspect:

* Tables
* Relations
* Constraints
* Example records

---

## UML Design

The project includes the following UML diagrams:

* Use Case Diagram
* Class Diagram
* Sequence Diagram

These diagrams were created to model system behavior, structure, and interactions before implementation.


## My Responsibilities

* Designed the SQLite database schema and table structure
* Created relational constraints and normalized tables
* Built UML diagrams (use case, class, sequence)
* Integrated the SQLite database with Flutter application logic
* Implemented CRUD operations
* Coordinated development process

