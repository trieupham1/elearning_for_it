# Copilot Instructions for AI Agents

## Project Overview
- **E-learning Management System**: Monorepo with Flutter frontend and Node.js/Express backend
- **Backend**: RESTful API using Express, MongoDB (Mongoose), JWT auth, GridFS file storage
- **Frontend**: Flutter app with role-based screens (students/instructors), tabbed course interface
- **Key entry points**: `backend/server.js`, `lib/main.dart`

## Critical Workflows

### Backend Development
- **Dev start**: `cd elearningit/backend && npm install && npm run dev` (nodemon auto-reload)
- **Prod start**: `npm start`
- **Environment**: Requires `.env` with `MONGODB_URI`, `PORT`, `JWT_SECRET`
- **Database seeding**: `npm run seed` (if available)
- **Testing**: Manual via `test-auth.js`, no formal test suite
- **Health check**: `GET /api/health` endpoint available

### Frontend Development  
- **Setup**: `cd elearningit && flutter pub get && flutter run`
- **Code gen**: `flutter packages pub run build_runner build` (for json_serializable)
- **Platform builds**: `flutter build apk|web|ios`
- **Linting**: Uses `flutter_lints` package, config in `analysis_options.yaml`

### API Configuration
- **Base URLs**: `lib/config/api_config.dart` handles web (`localhost:5000`) vs Android emulator (`10.0.2.2:5000`)
- **Auth flow**: JWT tokens stored via `shared_preferences`, managed by `TokenManager`
- **Error handling**: Centralized in `ApiService` with detailed logging

## Architecture Patterns

### Backend Structure
- **Routes**: `backend/routes/` - each file matches resource (e.g., `courses.js`, `assignments.js`)
- **Models**: `backend/models/` - Mongoose schemas with static/instance methods
- **Middleware**: `auth.js` provides `auth` and `instructorOnly` middlewares
- **Notifications**: **ALWAYS** use helpers from `utils/notificationHelper.js` when triggering events
- **File uploads**: GridFS via `/api/files/upload`, download via `/api/files/:id`

### Frontend Structure
- **Screens**: Role-based separation (`student/`, `instructor/`, shared screens)
- **Course interface**: Tabbed structure (`course_tabs/stream_tab.dart`, `classwork_tab.dart`, `people_tab.dart`)
- **Services**: One service per resource (`course_service.dart`, `notification_service.dart`)
- **Models**: Use `json_serializable` for API serialization (see `user.dart` + `user.g.dart`)
- **State**: Local widget state + SharedPreferences, no global state management

## Critical Integration Points

### Notification System
- **Backend**: Auto-triggered via helpers (`notifyNewAssignment()`, `notifyNewAnnouncement()`)
- **Frontend**: Pull-based via `NotificationService`, displayed in `notifications_screen.dart`
- **Pattern**: Always call notification helper after creating content (assignments, announcements, etc.)

### File Management
- **Upload**: POST to `/api/files/upload` with multipart/form-data
- **Download**: GET `/api/files/:fileId` returns file stream
- **Frontend**: Use `file_picker` package, handle via `file_service.dart`

### Authentication & Permissions
- **JWT**: Stored in SharedPreferences, attached to requests via `Authorization: Bearer <token>`
- **Role checks**: Backend uses `instructorOnly` middleware, frontend checks `userRole`
- **Auto-logout**: API service clears tokens on 401 responses

## Development Gotchas

### Backend
- **Always** populate user fields with `.populate()` for display names
- Use `instructorOnly` middleware for instructor-restricted endpoints
- File uploads require GridFS initialization in `server.js`
- Notification helpers expect arrays of student IDs for bulk notifications

### Frontend  
- Android emulator requires `10.0.2.2` instead of `localhost`
- Use `TimeAgo` package for relative timestamps in notifications
- Course screens use nested TabBarView with separate controllers
- API errors show detailed messages via `ApiException`

## Key Examples
- **Notification integration**: See `backend/README_NOTIFICATIONS.md` for complete patterns
- **API service usage**: Check `lib/services/api_service.dart` for error handling
- **Course navigation**: See `course_detail_screen.dart` for tabbed interface pattern
- **Role-based routing**: Check `main.dart` route definitions

---

**This project uses extensive documentation in `docs/` and `elearningit/docs/` - check these for feature-specific implementation details.**
