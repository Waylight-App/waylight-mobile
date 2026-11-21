/// What the last check of one server address found (#189).
enum AddressCheck {
  /// Not checked yet.
  unknown,

  /// Answers and accepts the session (or nobody is signed in yet).
  ok,

  /// Did not answer in time.
  unreachable,

  /// Answers, but does not accept the session: another server, or another
  /// instance under the same address in a different network.
  rejected,
}
