# Project: ReelFit

## Stack
- Framework: Flutter
- Language: Dart
- Backend: Custom REST API
- No testing required at this stage

## Commands
- `flutter run` — run the app
- `flutter pub get` — install dependencies
- `flutter build apk` — build Android
- `flutter build ios` — build iOS
- `flutter analyze` — static analysis
- `flutter clean && flutter pub get` — use this when things break unexpectedly

## Project Structure
```
lib/
  core/                      # Reusable infrastructure — zero app-specific knowledge
    atomic_state/
      atom.dart              # Atom<T> — ValueNotifier with emit() and call()
      async_atom.dart        # AsyncAtom<T> — self-registering, auto-reset on logout
      result.dart            # Result<T> sealed class
      auth_state.dart        # AuthState sealed hierarchy
    helpers.dart             # Helper static utility class + debugLog
    global_atoms.dart        # authState + keyboardOpened — app-wide atoms
    env.dart                 # Env configuration
    cache/                   # Local storage — AppCache + SharedPreferences singleton
    http/                    # APIRequest + ResponseInterceptor + toResult<T>
    localization/            # LocalizationService + localeAtom
    local_auth/              # AppLifecycleService + BiometricAuthService
    notifications/           # OneSignal infrastructure + NotificationRouter
    form_builder/            # API-driven form widgets
    ui/                      # DesignTokens, UIKText, UIKButton, UIKitBottomSheet
    auth_builder.dart        # Auth side effects — never routing
  controllers/               # One file per feature — controller class + its atoms
  data/                      # One file per feature — service class only
  models/                    # One file per model — plain Dart data classes
  views/                     # One folder per feature
  widgets/                   # Global reusable widgets shared across features
  l10n/                      # Localisation arb files + generated output
  router.dart                # GoRouter — app-specific, lives at root not core/
  main.dart
```

## Architecture

```
View  →  Controller  →  Service (data/)  →  API
              ↓
         atom.emit(result)
              ↓
         View rebuilds via atom()
```

- **Views** call controller methods and render atoms — nothing else
- **Controllers** plain Dart classes: orchestrate service calls, manage atom state, handle caching. Atom lives in the same file.
- **Services** extend `APIRequest` and return `Result<T>` — no logic, just HTTP
- **Atoms** are the single source of truth — `Atom<T>` for local state, `AsyncAtom<T>` for async data
- **`core/`** contains reusable infrastructure with zero app-specific knowledge — if you could copy it unchanged to another project, it belongs in `core/`. If it imports any view, feature route, or app-specific model, it lives outside
- **`router.dart`** lives outside `core/` — it hardcodes app-specific paths. `notification_router.dart` lives in `core/` because paths are injected via `configure()` — zero hardcoded routes inside

## Core Primitives

### Atom<T>
For simple local/UI state with no async lifecycle. Defined in `core/atomic_state/atom.dart`.
Use `emit()` to update, call directly as a widget to build UI.
```dart
final isSelected = Atom(false);
final searchQuery = Atom('');
final activeTab = Atom(0);

// update
isSelected.emit(true);

// build UI — value ignored
isSelected((_) => const SelectedIndicator())

// build UI — value used
searchQuery((value) => Text(value))

// constructor reference when widget takes the value as single positional arg
searchQuery(Text.new)

// with fallback
isSelected(
  (_) => const SelectedIndicator(),
  fallback: const UnselectedIndicator(),
)
```
Only use with `Atom<bool>`, `Atom<String>`, `Atom<List>`. An `assert` catches misuse in debug mode.

### AsyncAtom<T>
For any async/remote data. Wraps `Result<T>` internally, initializes as `Idle()`. Defined in `core/atomic_state/async_atom.dart`.
**Self-registers in a global registry on creation** — automatically reset on logout via `resetAllAtoms()`. No manual registration ever needed.

```dart
final isSelected = Atom(false);                  // local UI state
final rewards = AsyncAtom<List<RewardModel>>();  // async/remote data — self-registering
```

Must always be a **global variable** in a controller file — never created inside a widget or method.

### AsyncAtom as a widget
`AsyncAtom` is callable directly as a widget. Only `success` is required — all other states have sensible defaults (`CircularProgressIndicator` for loading, `SizedBox` for the rest).

Pass constructor references when the widget accepts a single positional argument:
```dart
rewards(
  success: RewardsList.new,
  failure: ErrorText.new,
  loading: RewardsShimmer.new,
)
```

Fall back to a lambda only when the widget needs extra arguments:
```dart
rewards(
  success: RewardsList.new,
  failure: (message) => ErrorText(message, onRetry: controller.refresh),
)
```

### Widget convention for AsyncAtom
Widgets used as constructor references must accept the value as a **single positional argument**:
```dart
// correct
class RewardsList extends StatelessWidget {
  const RewardsList(this.rewards, {super.key});
  final List<RewardModel> rewards;
}

// wrong — named param, cannot be passed as constructor reference
class RewardsList extends StatelessWidget {
  const RewardsList({super.key, required this.rewards});
}
```

### Result<T>
Sealed class in `core/atomic_state/result.dart`. All async operations return `Result<T>`.
```dart
Idle()            // before any action
Loading()         // in progress
Success(value)    // data returned
Failure(message)  // something went wrong
Empty()           // request succeeded but no data
```
- Use `result.errorMessage` to extract error string without casting to `Failure`
- Never use `Atom<Result<T>>` directly — always use `AsyncAtom<T>`

## Controllers

Plain Dart classes in `lib/controllers/`. The atom lives at the top of the same file as its controller.

### Standard pattern
```dart
// controllers/rewards_controller.dart

final rewards = AsyncAtom<List<RewardModel>>();

class RewardsController {
  final service = RewardsService();

  Future<void> loadRewards() async {
    rewards.emit(Loading());
    final result = await service.getRewards();
    rewards.emit(result);
  }
}
```

### With caching
Show cached data immediately if available, fetch in background to refresh silently:
```dart
Future<void> loadRewards() async {
  final current = rewards.value;
  if (current is Success<List<RewardModel>> && current.value.isNotEmpty) {
    service.getRewards().then((result) => rewards.emit(result));
    return;
  }
  rewards.emit(Loading());
  final result = await service.getRewards();
  rewards.emit(result);
}
```

### With optional loading indicator
```dart
Future<void> refresh({bool showLoading = true}) async {
  if (showLoading) rewards.emit(Loading());
  final result = await service.getRewards();
  rewards.emit(result);
}
```

### Refreshing related atoms after a mutation
```dart
Future<Result<String>> createPreOrder({required String id}) async {
  final result = await service.createPreOrder(id: id);
  if (result is Success<String>) {
    refresh(showLoading: false);
    myRewardsController.refresh(showLoading: false);
  }
  return result;
}
```

### Finding cached data without an API call
```dart
RewardModel? findById(String id) {
  final current = rewards.value;
  if (current is Success<List<RewardModel>>) {
    try {
      return current.value.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
  return null;
}
```

### Rules for controllers
- Plain Dart class — no base class to extend
- Atom defined at the top of the same file — no separate atoms folder
- `AsyncAtom` must be a global variable — never created inside a method or widget
- Instantiate the service directly: `final service = FeatureService()`
- Always emit `Loading()` before async calls (unless `showLoading: false`)
- **Never use try/catch** — services never throw, failures return as `Failure()`
- After mutations, refresh affected atoms silently with `showLoading: false`
- Return `Result<T>` when the view needs to react directly (e.g. show a snackbar)
- Return `void` when the view reacts via the atom

## Views

Views call controller methods and render atoms — no logic.

```dart
// fire and forget — view reacts via atom
UIKButton.primary(
  label: 'Refresh',
  onTap: () async => controller.refresh(),
)

// render atom as widget
rewards(
  success: RewardsList.new,
  failure: ErrorText.new,
)

// when the view needs to react to the result directly
final result = await controller.createPreOrder(id: id);
if (result is Success) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

## Widget Organisation
Every view file (screen) must only contain the screen class itself 
and its state class. All supporting widgets must live in a 
widgets/ subfolder under the same feature folder.

```
Example structure:
  views/workouts/
    workout_detail_screen.dart       ← screen only
    exercise_detail_screen.dart      ← screen only
    widgets/
      exercise_card.dart
      hero_image.dart
      stats_row.dart
      muscle_chip.dart
      progress_chart.dart
      progress_section.dart
      guest_progress_prompt.dart
```
Rules:
- One widget class per file
- File name matches the widget name in snake_case
- No private widgets prefixed with _ in widget files — 
  they are already scoped by being in their own file
- Screen files import from widgets/ subfolder

## Services

Services extend `APIRequest` (from `core/http/api_request.dart`) and return `Result<T>`. No logic — just HTTP. One file per feature in `lib/data/`.

### Standard pattern
Use `auth*` shorthand methods with arrow syntax:
```dart
class RewardsService extends APIRequest {
  /// GET /api/rewards
  Future<Result<List<RewardModel>>> getRewards() =>
      authGet('/api/rewards', RewardModel.fromJsonToList);

  /// GET /api/rewards/{id}
  Future<Result<RewardModel>> getRewardDetails({required String id}) =>
      authGet('/api/rewards/$id', RewardModel.fromJson);

  /// POST /api/rewards/{id}/pre-order
  Future<Result<String>> createPreOrder({required String id}) =>
      authPost('/api/rewards/$id/pre-order', (data) => Helper.getString(data['success_message']));

  /// PATCH /api/rewards/{id}
  Future<Result<RewardModel>> updateReward({required String id, required Map<String, dynamic> body}) =>
      authPatch('/api/rewards/$id', RewardModel.fromJson, body: body);

  /// DELETE /api/rewards/{id}
  Future<Result<String>> deleteReward({required String id}) =>
      authDelete('/api/rewards/$id', (data) => Helper.getString(data['success_message']));
}
```

### Available shorthand methods
- `authGet(path, adapter)` — GET
- `authPost(path, adapter, {body})` — POST
- `authPatch(path, adapter, {body})` — PATCH
- `authPut(path, adapter, {body})` — PUT
- `authDelete(path, adapter, {body})` — DELETE (handles nullable response internally)

### Rules for services
- **Always use `auth*` shorthand methods** — never call `.toResult()`, `get()`, `post()` etc. directly
- Always use arrow syntax `=>` — no `async/await`, no `return`, no braces
- Document each method with HTTP method and path: `/// GET /api/rewards`
- Use `Model.fromJson` for single objects, `Model.fromJsonToList` for lists
- No business logic — that belongs in the controller
- **Never** write `response.toResult(...)` manually — `authGet`, `authPost` etc. call it internally

### ResponseInterceptor behavior
The `.toResult<T>()` extension handles all standard API error shapes automatically:
- `{ message: ... }` → `Failure` (+ emits `Unauthenticated` if "unauthenticated")
- `{ error: ... }` → `Failure` (same)
- `{ data: ... }` or `{ result: ... }` → `Success` via adapter
- Empty response / missing `data` key → `Failure`

Never duplicate this logic in services or controllers.

## Form Builder

API-driven form system in `core/form_builder/`. Field definitions are Dart maps parsed via `FormFieldAdapter`. The UI renders itself from the data.

### Defining fields
```dart
final loginFields = FormFieldAdapter().fromJsonToList([
  {
    "attribute": "email",
    "label": "Email",
    "hint": "Your email address",
    "type": "email",
    "required": true,
    "textInputAction": "next",
  },
  {
    "attribute": "password",
    "label": "Password",
    "hint": "",
    "type": "password",
    "required": true,
    "textInputAction": "go",
  },
]);
```

Define fields at the top of the controller file, next to the atom.

### Supported field types
| string | FieldType | Widget |
|---|---|---|
| `"text"` | `FieldType.text` | text input |
| `"email"` | `FieldType.email` | email input |
| `"number"` | `FieldType.number` | numeric input |
| `"password"` | `FieldType.password` | obscured input |
| `"select"` | `FieldType.select` | popup list |
| `"radio"` | `FieldType.radio` | radio group |
| `"address_lookup"` | `FieldType.addressLookup` | placeholder |
| `"picture"` | `FieldType.picture` | placeholder |

Unknown type strings fall back to `FieldType.text` so they're always visible.

### Rendering
```dart
// Embedded in a screen
FormFieldsBuilderPage(
  formFields: loginFields,
  ctaLabel: 'Sign in',
  onSubmit: (Map<String, dynamic> dto) async {
    await controller.login(dto);
  },
)

// Full standalone page with AppBar
FormPageTemplate(
  entity: existingUser,   // pre-fills values
  formFields: profileFields,
  onSubmit: (dto) async => controller.updateProfile(dto),
)
```

### Conditional fields
```dart
FNFormField(
  attribute: 'company_name',
  type: 'text',
  conditionedBy: 'account_type',  // watches this attribute
  conditionValue: 'business',     // visible only when account_type == 'business'
  ...
)
```

### Rules
- Never use raw `TextFormField` in views — always use the form builder
- Never hardcode form fields in views — define in controller file
- `textInputAction` is always a string (`"next"`, `"go"`, `"done"`) — never the enum directly
- To add a new field type: add to `FieldType` enum, handle in `FnFormBuilder._buildField()`, add validator to `FormValidators`

## Models

Plain Dart classes in `lib/models/`. No codegen packages.

```dart
class RewardModel {
  final String id;
  final String brand;
  final bool isActive;
  final String? promoCode;

  RewardModel({required this.id, required this.brand, required this.isActive, this.promoCode});

  static RewardModel fromJson(dynamic json) => RewardModel(
    id: Helper.getString(json['id']),
    brand: Helper.getString(json['brand']),
    isActive: Helper.getBool(json['is_active']),
    promoCode: Helper.getStringOrNull(json['promo_code']),
  );

  static List<RewardModel> fromJsonToList(dynamic json) {
    if (json == null || json is! List) return [];
    return json.map((item) => fromJson(item)).toList();
  }

  @override
  String toString() => 'RewardModel(id: $id, brand: $brand, isActive: $isActive)';
}
```

### Rules for models
- Always use `Helper.get*()` — never raw casts like `json['field'] as String`
- `fromJson` is static and accepts `dynamic` (not `Map<String, dynamic>`)
- `fromJsonToList` always guards against null and non-List
- Non-nullable by default; `?` only when the API genuinely returns null
- No `toJson()` unless the model is sent to the API
- No business logic — pure data containers
- Always include `toString()`

## Auth State
Defined in `lib/core/global_atoms.dart`:
```dart
sealed class AuthState {}
class Initial extends AuthState {}       // unknown — triggers checkAuth()
class Authenticated extends AuthState {}
class Unauthenticated extends AuthState {}
class AuthErrorState extends AuthState { final String message; }
```
- The interceptor automatically emits `Unauthenticated()` on 401-style responses
- Never manually check for auth errors in services or controllers — the interceptor handles it

## AuthBuilder & Session Management

`AuthBuilder` wraps the entire app in `MaterialApp.router`'s `builder`. It listens to `authState` and coordinates all auth-driven side effects: routing, notifications, and atom resets.

### Auth check flow
```
App starts / comes to foreground
  → authState.emit(Initial())
  → _authListener fires
  → AuthRepository().checkAuth()
  → emits Authenticated or Unauthenticated
  → _authListener fires again
  → handles routing / notifications / resetAllAtoms()
```

`AppLifecycleListener` re-emits `Initial()` on every app resume — triggering re-verification with no risk of loops since `checkAuth()` is only called on `Initial`.

### Atom reset on logout
`AuthBuilder` calls `resetAllAtoms()` when `authState` becomes `Unauthenticated`.
`AsyncAtom` self-registers in a global registry on creation — no manual registration needed.

```dart
} else if (currentAuthState is Unauthenticated) {
  NotificationService.instance.clearUserData();
  resetAllAtoms();
}
```

### AuthBuilder responsibilities
Handles side effects only — **never routing**:
- Triggers `checkAuth()` on `Initial`
- Sets up / tears down notifications
- Calls `resetAllAtoms()` on logout

### Rules
- `Initial` = auth status unknown — the only state that calls `checkAuth()`
- Never call `checkAuth()` from controllers or views
- Never navigate from `AuthBuilder` — GoRouter owns all routing
- Never reset `authState` itself — must stay `Unauthenticated` for routing to work
- `AsyncAtom` must always be a global variable — never created inside a widget or method

## Routing

Routing uses `go_router`. All decisions live in `router.dart` — never navigate based on auth logic in views or controllers.

```dart
context.push('/rewards');          // push — back button works
context.push('/rewards/$id');      // with path param
context.go('/home');               // replace stack — use for auth redirects
context.pop();                     // go back
context.push('/detail', extra: model); // pass complex object
```

### Post-auth gate chain
After login the router walks a chain of conditions before reaching `/home`. Each unmet condition redirects to its resolution screen. Resolution screens call `router.refresh()` when done — never navigate directly.

```dart
if (auth is Authenticated && isOnAuth) {
  if (!PostAuthGates.isPinSetupComplete(context)) return '/auth/pin-setup';
  // if (!PostAuthGates.hasAcceptedTerms(context)) return '/auth/terms';
  return '/home';
}
```

To add a new gate: add a method to `PostAuthGates`, add the condition to `_redirect()`, add the route, call `router.refresh()` in the resolution screen.

### Rules
- Never navigate based on auth state from views or controllers — use `_redirect()` in `router.dart`
- Always `context.go()` for auth redirects, `context.push()` for feature navigation
- Resolution screens always call `router.refresh()` — never navigate directly to next screen
- Add all routes to `_routes` in `router.dart` — never define routes elsewhere

## Notifications

Push notifications via OneSignal. Infrastructure in `core/notifications/`, app-specific routing in `lib/notifications/`.

### Setup in AuthBuilder
```dart
// After Authenticated
await NotificationService.instance.initialize(appId: Env.oneSignalAppId, context: context);

NotificationRouter.configure({
  NotificationType.paymentReceived: '/home',
  NotificationType.newLearningVideo: '/learning',
  NotificationType.customCommunication: '/home',
});
NotificationService.instance.onNotificationTapped = (n) => NotificationRouter.route(context, n);
await NotificationService.instance.setupUserAfterAuth();

// After Unauthenticated
await NotificationService.instance.clearUserData();
```

The `onNotificationTapped` callback keeps `core/` decoupled from app routes — `NotificationRouter` is wired from outside, never imported by the service.

### NotificationType
`icon` and `color` live on the enum as getters — no utility class needed:
```dart
notification.type.icon   // IconData
notification.type.color  // Color
```

### Adding a new notification type
1. Add to `NotificationType` enum with string value
2. Add `icon` and `color` switch cases
3. Create `NotificationData` subclass with `fromJson` using `Helper.get*()`
4. Add to `NotificationData.fromJson` factory switch
5. Handle in `NotificationRouter.route()` switch
6. Add serialization in `NotificationStorage._dataToJson()`

### Rules
- `notification_router.dart` lives in `core/notifications/` — routes are injected via `configure()`, never hardcoded
- Configure routes once in `AuthBuilder` after `Authenticated`
- Never call `NotificationRouter.route()` from views — wire via `onNotificationTapped`
- `ForegroundNotificationBanner` is display-only — no routing logic inside it
- Always `Success()` / `Failure()` — never `Result.success()` / `Result.failure()`


## Helper Class (`core/helpers.dart`)

| Method | Returns |
|---|---|
| `Helper.getString(value)` | String ('' on failure) |
| `Helper.getStringOrNull(value)` | String? |
| `Helper.getInt(value)` | int (0 on failure) |
| `Helper.getIntOrNull(value)` | int? |
| `Helper.getDouble(value)` | double (0.0 on failure) |
| `Helper.getDoubleOrNull(value)` | double? |
| `Helper.getBool(value)` | bool (handles "true", "1", 1) |
| `Helper.getList(value)` | List ([] on failure) |
| `Helper.getStringList(value)` | List<String> |
| `Helper.getMap(value)` | Map<String, dynamic> ({} on failure) |

- `debugLog(data, [title])` — always use instead of `print()`, no-ops in release
- `isWebMobile` / `isWebMobileOrMobile` — platform detection flags

**Never** use raw casts on JSON. **Never** use `print()`.

## UI Kit (`core/ui/`)

All UI primitives live in `core/ui/`. **Never use raw Flutter widgets when a UI Kit equivalent exists.**

### Buttons — `UIKButton`
`onTap` always takes `Future<void> Function()` — the button manages its own loading state automatically via `LoadingStateMixin`.

```dart
// Default (medium size)
UIKButton.primary(label: 'Continue', onTap: () async => controller.submit())
UIKButton.secondary(label: 'Edit', onTap: () async => controller.edit())
UIKButton.destructive(label: 'Delete', onTap: () async => controller.delete())
UIKButton.ghost(label: 'Skip', onTap: () async => controller.skip())

// Explicit sizes
UIKButton.primary.large(label: 'Get started', onTap: () async => controller.start())
UIKButton.primary.small(label: 'View', onTap: () async => controller.view())

// With icons
UIKButton.primary(label: 'Pay', onTap: () async => controller.pay(), leftIcon: const Icon(Icons.payment))

// Full width
UIKButton.primary(label: 'Submit', onTap: () async => controller.submit(), fullWidth: true)

// Disabled — pass null for onTap
UIKButton.primary(label: 'Submit', onTap: null)

// External loading control
UIKButton.primary(label: 'Submit', onTap: () async => controller.submit(), isLoading: true)
```

**Never use:** `TextButton`, `ElevatedButton`, `OutlinedButton`, or `CupertinoButton` for any tappable action.

### Text — `UIKText`
```dart
UIKText.pageTitle('Title')      // 26pt w800
UIKText.pageSubtitle('Welcome')      // 22pt w700
UIKText.h1('Title') // through UIKText.h6('Label')
UIKText.body('Regular copy')         // 14pt w400
UIKText.small('Fine print')          // 12pt w400

// Optional params available on all variants
UIKText.body('Truncated', maxLines: 2, overflow: TextOverflow.ellipsis)
UIKText.h4('Coloured', color: Colors.grey)
UIKText.body('Centred', textAlign: TextAlign.center)
```

**Never use:** raw `Text(...)` for any user-visible string — always use `UIKText.*`.

### Bottom Sheet — `UIKitBottomSheet`
```dart
// Content only
UIKitBottomSheet.show(context, title: 'Info', content: InfoWidget())

// With primary CTA
UIKitBottomSheet.show(
  context,
  title: 'Confirm',
  content: ConfirmWidget(),
  primaryAction: BottomSheetAction(label: 'Confirm', onTap: () async => controller.confirm()),
)

// With primary + secondary actions
UIKitBottomSheet.show(
  context,
  title: 'Delete item',
  content: DeleteWarning(),
  primaryAction: BottomSheetAction(label: 'Delete', onTap: () async => controller.delete()),
  secondaryAction: BottomSheetAction(label: 'Cancel', onTap: () async => context.pop()),
)

// Custom footer widget (mutually exclusive with primaryAction)
UIKitBottomSheet.show(context, title: 'Pick', content: Picker(), footer: MyFooter())

// Multi-page flow
UIKitBottomSheet.showPaged(context, pages: [
  BottomSheetPage(title: 'Step 1', content: Step1Widget()),
  BottomSheetPage(title: 'Step 2', content: Step2Widget()),
])

// Inside a paged sheet — navigate forward / back
BottomSheetPage.pushNext(context, nextPage)
BottomSheetPage.popPage(context)
```

**Never use:** `showModalBottomSheet` or `showBottomSheet` directly.

### Snackbar — `UIKShowSnackBar`
```dart
UIKShowSnackBar(context, message: 'Saved', type: UIKSnackBarType.success)
UIKShowSnackBar(context, message: 'Something went wrong', type: UIKSnackBarType.error)
UIKShowSnackBar(context, message: 'You have a new message')  // default: notification
```

**Never use:** `ScaffoldMessenger.of(context).showSnackBar(...)` directly.

### Dialog — `ShowDialog`
```dart
// Confirm / deny
ShowDialog(
  context,
  title: 'Delete reward?',
  content: 'This cannot be undone.',
  onConfirm: () => controller.delete(),
)

// Info / dismiss only
ShowDialog(context, title: 'Unavailable', content: 'Coming soon.')
```

**Never use:** `showDialog(...)` directly.

### Design Tokens
Use `DesignTokens.*` constants for colours, sizes, and border radii — never hardcode magic numbers.
Access theme-aware colours via the `ThemeData` extension: `Theme.of(context).primaryColor`, `.surfaceColor`, `.onSurfaceColor`, `.errorColor` etc.

### Rules
- Never use `TextButton`, `ElevatedButton`, `OutlinedButton`, `CupertinoButton` — use `UIKButton.*`
- Never use raw `Text(...)` — use `UIKText.*`
- Never use `showModalBottomSheet` — use `UIKitBottomSheet.show()`
- Never use `ScaffoldMessenger...showSnackBar` directly — use `UIKShowSnackBar()`
- Never use `showDialog` directly — use `ShowDialog()`
- Never hardcode colours, font sizes, or border radii — use `DesignTokens`
- If a UI Kit component doesn't exist for what you need, ask before inventing one

## Code Conventions
- Functional widgets preferred; `StatefulWidget` only for animation controllers, focus nodes
- One widget per file, snake_case filenames, PascalCase class names
- `const` constructors wherever possible
- Extract sub-widgets early to avoid deep nesting
- Never use `dynamic` beyond the JSON parsing boundary
- Atom variables use no suffix — `final isSelected = Atom(false)` not `final isSelectedAtom`

## Rules
- Do not install packages without confirming first
- Do not use `setState` for app state
- Do not put business logic in views
- Do not use `BuildContext` in controllers or services
- Keep widgets dumb — render atoms, call controller methods, nothing more
- Never recreate primitives from `core/` — use what's already there
- Always read existing files before editing — never assume file contents

## Workflow
- Read tasks/lessons.md at the start of every session before writing 
  any code — it contains corrections from previous sessions
- For tasks with 3+ steps, write a plan first in `tasks/todo.md`
- After any correction, log the pattern in `tasks/lessons.md`
- Review `tasks/lessons.md` at the start of each session
- After every code change, run `flutter test` and fix any failures before proceeding
- Never consider a task complete until `flutter test` passes
- Never mark a task complete without verifying it runs
- Ask: "Would a senior Flutter developer approve this?"

## Principles
- Simplicity first — minimum code to achieve the goal
- Minimal impact — touch only what is necessary
- No lazy fixes — find the root cause
- Stop and re-plan if something goes wrong
