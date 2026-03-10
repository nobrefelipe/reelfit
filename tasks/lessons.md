# ReelFit — Lessons Learned
> Read this file at the start of every session, before writing any code.

---

## Atoms & State

**Never read atom.value directly in build()**
Reading `.value` is a snapshot — the widget won't rebuild when state changes.
Always use the atom as a widget instead:
```dart
// wrong
final result = extractResult.value;

// correct
extractResult(
  success: (video) => ...,
  failure: (_) => ...,
  loading: () => ...,
)
```

**Never use ValueListenableBuilder for Atom<T>**
`Atom<T>` is already callable as a widget. Use the call syntax directly:
```dart
// wrong
ValueListenableBuilder(valueListenable: myAtom, builder: (_, value, __) => ...)

// correct
myAtom((value) => Widget)
```

**AsyncAtom must always be a global variable**
Never create an `AsyncAtom` inside a widget or method — it self-registers in a global registry on creation, which would cause a leak.
```dart
// wrong — inside a class or method
final results = AsyncAtom<List<ItemModel>>();

// correct — top of controller file, global scope
final results = AsyncAtom<List<ItemModel>>();

class ItemsController { ... }
```

**When incrementing and saving to cache, use a local variable**
Reading the atom value after emitting can return a stale value. Compute first, then save and emit:
```dart
// wrong
count.emit(count.value + 1);
await cache.save(count.value); // may read old value

// correct
final newCount = count.value + 1;
await cache.save(newCount);
count.emit(newCount);
```

---

## Routing

**On Flutter Web, context.push() does not update the browser URL bar**
`context.push()` stacks routes internally but the browser URL never changes.
Use `context.go()` for any navigation that should update the URL.
Only use `context.push()` for modal-style overlays where back navigation should return to the previous screen:
```dart
// wrong — URL stays the same in the browser
context.push('/workout/${video.videoId}', extra: video);

// correct — URL updates in the browser
context.go('/workout/${video.videoId}', extra: video);

// correct use of push — modal overlay, back button should return here
context.push('/auth/pin-setup');
```

**Never use Navigator.of(context).pop() in a GoRouter app**
Always use `context.pop()` from `go_router`:
```dart
// wrong
Navigator.of(context).pop();
Navigator.of(context, rootNavigator: true).pop();

// correct
context.pop();
```

**Never store GoRouter.of(context) in a local variable**
Always call `context.push()` / `context.go()` / `context.pop()` directly:
```dart
// wrong
final router = GoRouter.of(context);
router.push('/somewhere');

// correct
context.push('/somewhere');
```

**Never rename context to ctx**
`context` is the standard Flutter convention. Renaming adds noise and confusion:
```dart
// wrong
final ctx = context;
ctx.push('/somewhere');

// correct
context.push('/somewhere');
```

**Never add mounted checks inline in button callbacks**
Navigation side effects belong in a listener on the atom, not inline in callbacks.
Add the listener in `initState` / `dispose` and navigate from there:
```dart
// wrong — inline navigation with mounted guard
onPressed: () async {
  final result = await SomeSheet.show(context);
  if (!context.mounted) return;
  if (result is Success) context.push('/somewhere');
},

// correct — listener handles navigation
void initState() {
  super.initState();
  someAtom.addListener(_onResult);
}
void _onResult() {
  if (!mounted) return;
  final result = someAtom.value;
  if (result is Success<Foo>) context.push('/somewhere');
}
```

**Never use authState directly in views**
`authState` is only read via `.value` inside controllers and in `router.dart` redirect.
In views, use controller getters that return a plain bool:
```dart
// wrong — reading atom in view
ValueListenableBuilder<AuthState>(
  valueListenable: authState,
  builder: (_, state, __) => state is Authenticated ? ... : ...,
)

// correct — controller getter, setState listener for rebuilds
extractController.isGuest ? const _SignInButton() : const _ProfileButton()
// with authState.addListener(_onAuthChanged) in initState
// and void _onAuthChanged() => setState(() {});
```

**After any mutation that changes the history list, always refresh history**
After extract, migrate, or delete — call `historyController.load()` (guest) or
`historyController.refresh(showLoading: false)` (authenticated) so the UI stays in sync:
```dart
if (isGuest) {
  // ... save to cache ...
  historyController.load();
} else {
  historyController.refresh(showLoading: false);
}
```

**Bottom sheets should not return values when the result is handled by an atom listener**
If the caller already listens to an atom, the sheet just pops itself — it never passes
a return value back. The caller's listener reacts to the atom directly:
```dart
// wrong — sheet returns a value, caller switches on it
static Future<dynamic> show(BuildContext context) => UIKitBottomSheet.show<dynamic>(...);
// caller:
final result = await SomeSheet.show(context);
if (result is Foo) context.push('/somewhere');

// correct — sheet pops itself, caller's atom listener navigates
static Future<void> show(BuildContext context) => UIKitBottomSheet.show<void>(...);
// in sheet's _onResult:
if (result is Success<Foo>) context.pop();
// in caller's initState:
fooAtom.addListener(_onResult);
// in caller's _onResult:
if (fooAtom.value is Success<Foo>) context.push('/somewhere');
```

---

## Services

**Use post() not authPost() for unauthenticated endpoints**
`authPost` attaches a Bearer token, which is wrong for endpoints that accept guest (unauthenticated) requests. Use the non-auth variant:
```dart
// wrong — sends token even for guests
Future<Result<VideoModel>> extract({required String url}) =>
    authPost('/functions/v1/extract', VideoModel.fromJson, body: {'url': url});

// correct — no token attached
Future<Result<VideoModel>> extract({required String url}) =>
    post('/functions/v1/extract', VideoModel.fromJson, body: {'url': url});
```

---

## Code Quality

**Always wrap initState controller calls in addPostFrameCallback**
Controller methods called from `initState` that emit to atoms synchronously can trigger
`setState during build` errors. Wrap them in `WidgetsBinding.instance.addPostFrameCallback`:
```dart
// wrong — may fire synchronously during the first build
void initState() {
  super.initState();
  historyController.findByVideoId(widget.videoId);
}

// correct — deferred until after the first frame
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    historyController.findByVideoId(widget.videoId);
  });
}
```
If the controller method itself calls `emit(Loading())` synchronously before any `await`,
also add a microtask delay to that emit so it never fires inline:
```dart
// wrong — emits synchronously, can cause setState during build
Future<void> findByVideoId(String videoId) async {
  workout.emit(Loading());
  ...
}

// correct — deferred to next microtask
Future<void> findByVideoId(String videoId) async {
  await Future.microtask(() => workout.emit(Loading()));
  ...
}
```

---

**Never suppress warnings with // ignore: unawaited_futures**
Fix the underlying issue by adding `await`:
```dart
// wrong
// ignore: unawaited_futures
someAsyncCall();

// correct
await someAsyncCall();
```
