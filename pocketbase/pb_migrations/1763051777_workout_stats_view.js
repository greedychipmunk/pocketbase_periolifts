/// <reference path="../pb_data/types.d.ts" />

// No-op migration - workout stats are calculated on-demand from workout_history
// View-based aggregations are not needed as the app handles stats client-side
migrate((app) => {
  // No changes needed - stats are computed in the application layer
}, (app) => {
  // No rollback needed
})
