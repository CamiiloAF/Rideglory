class TrackingStore {
  constructor() {
    this.sessionsByEventId = new Map();
  }

  upsertRider(eventId, rider) {
    const eventSession = this._eventSession(eventId);
    eventSession.ridersByUserId.set(rider.userId, {
      ...rider,
      isActive: true,
      lastUpdated: rider.lastUpdated ?? new Date().toISOString(),
    });
    return this.snapshot(eventId);
  }

  removeRider(eventId, userId) {
    const eventSession = this._eventSession(eventId);
    eventSession.ridersByUserId.delete(userId);
    return this.snapshot(eventId);
  }

  snapshot(eventId) {
    const eventSession = this._eventSession(eventId);
    return Array.from(eventSession.ridersByUserId.values());
  }

  pruneInactive(ttlMs) {
    const nowMs = Date.now();
    for (const eventSession of this.sessionsByEventId.values()) {
      for (const [userId, rider] of eventSession.ridersByUserId.entries()) {
        const updatedMs = new Date(rider.lastUpdated).getTime();
        if (Number.isNaN(updatedMs) || nowMs - updatedMs > ttlMs) {
          eventSession.ridersByUserId.delete(userId);
        }
      }
    }
  }

  _eventSession(eventId) {
    if (!this.sessionsByEventId.has(eventId)) {
      this.sessionsByEventId.set(eventId, {
        ridersByUserId: new Map(),
      });
    }
    return this.sessionsByEventId.get(eventId);
  }
}

module.exports = {
  TrackingStore,
};
