# Web interface changelog

## Current

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
- Workout exercises and sets always render by their persisted order, independent of database response order.

## Deferred iOS parity

- Port the final approved responsive web workflow to iOS in one pass.
- Port exercise categories and the searchable add/replace picker to iOS.
- Confirm deterministic exercise and set ordering in the iOS workout editor.
