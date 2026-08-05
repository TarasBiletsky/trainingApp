# Web interface changelog

## Current

- Responsive navigation now uses a fixed 56 px mobile header with a left-side drawer, a 232 px desktop sidebar, and a 72 px compact tablet rail; the redundant page-level logo and slogan are removed.
- Workout exercise actions are grouped under an overflow menu; mobile set rows use labelled SET, KG, REPS, and DONE columns without destructive buttons.
- The rest timer is a reserved bottom bar with ready, active, add-time, skip, completion, and vibration states.
- Mobile calendar controls use separate period navigation and view selection; month view is a true seven-column grid and week view is a seven-day strip.
- Exercise library search runs automatically after 300 ms, includes equipment chips, and uses Load more on mobile.
- Navigation labels are clarified as Training, Users, and Import & Export.

- The Workout tab is the primary full workout editor.
- Calendar workouts open in the same editor instead of a read-only dialog.
- Exercises can be added, replaced, and deleted.
- Sets can be added, edited independently, completed/uncompleted, and deleted.
- Workout lifecycle timing changes automatically only for today's workout.
- Mobile text scaling is fixed across tabs.
- Workouts can be deleted with all exercises and sets.
- Choosing a template fills the scheduling form and waits for explicit creation.
- Empty workout days use a focused start screen; blank and template workouts open in the same full editor.
- Mobile week and month calendars stack days vertically without horizontal clipping.
- Home and workout lifecycle use the browser's local day instead of the server's UTC day.
- The API rejects a second workout on the same local calendar day.
- Exercise and set order can be changed by dragging their handles, with the order persisted by the API.
- Exercise cards are read-only and show one of six color-coded target categories.
- Adding or replacing a workout exercise uses a dedicated searchable, category-filtered picker and preserves existing sets when replacing.
- Progress supports custom date ranges and clickable weekly volume bars that filter training history.
- Mobile exercise and set ordering uses long press on the whole card, keeps normal page scrolling, and shows a lifted card following the finger while dragging.
- Active drag automatically scrolls the workout when the lifted card reaches the top or bottom edge of the screen.
- Workout supports previous/next day browsing and a compact actions menu with skip and delete.
- Navigation is a right-side collapsible menu, hidden by default on mobile and open by default on desktop.
- The navigation burger follows the conventional top-left placement.
- Skipped workouts are visibly greyed out and read-only while day navigation and workout deletion remain available.
- Mobile calendar workout dots are larger and use a visible muted-purple highlight with a soft halo.
- Workout exercises and sets always render by their persisted order, independent of database response order.

## Deferred iOS parity

- Port the responsive navigation, workout action menus, set-row layout, rest bar, calendar controls, and library filters to iOS.
- Port the final approved responsive web workflow to iOS in one pass.
- Port exercise categories and the searchable add/replace picker to iOS.
- Confirm deterministic exercise and set ordering in the iOS workout editor.
